
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'services/push_notification_service.dart';
import 'services/settings_service.dart';

class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({super.key});

  @override
  State<PushNotificationScreen> createState() =>
      _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen>
    with WidgetsBindingObserver {
  final service = PushNotificationService();
  final settingsService = SettingsService();

  bool isBusy = false;
  bool isCheckingStatus = false;
  bool notificationsEnabled = false;

  bool isLoadingReminderPeriod = true;
  bool isSavingReminderPeriod = false;

  int selectedReminderDays =
      SettingsService.defaultExpiryReminderDays;
  int savedReminderDays =
      SettingsService.defaultExpiryReminderDays;

  String? errorMessage;
  String? reminderPeriodError;
  String? reminderPeriodMessage;

  String statusMessage = 'Checking your notification settings...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkNotificationStatus();
    loadReminderPeriod();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !isBusy) {
      checkNotificationStatus();
      loadReminderPeriod();
    }
  }

  Future<void> loadReminderPeriod() async {
    if (isSavingReminderPeriod) return;

    setState(() {
      isLoadingReminderPeriod = true;
      reminderPeriodError = null;
    });

    try {
      final days = await settingsService
          .watchExpiryReminderDays()
          .first;

      if (!mounted) return;

      setState(() {
        selectedReminderDays = days;
        savedReminderDays = days;
        isLoadingReminderPeriod = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingReminderPeriod = false;
        reminderPeriodError =
            'Unable to load your reminder period. Please try again.';
      });
    }
  }

  Future<void> saveReminderPeriod() async {
    if (isSavingReminderPeriod ||
        isLoadingReminderPeriod ||
        selectedReminderDays == savedReminderDays) {
      return;
    }

    setState(() {
      isSavingReminderPeriod = true;
      reminderPeriodError = null;
      reminderPeriodMessage = null;
    });

    try {
      await settingsService.saveExpiryReminderDays(
        selectedReminderDays,
      );

      if (!mounted) return;

      setState(() {
        savedReminderDays = selectedReminderDays;
        reminderPeriodMessage =
            'Your reminder period has been saved.';
      });
    } on FirebaseException catch (_) {
      if (!mounted) return;

      setState(() {
        reminderPeriodError =
            'Unable to save your preference. Check your connection '
            'and try again.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        reminderPeriodError =
            'Unable to save your reminder period. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isSavingReminderPeriod = false;
        });
      }
    }
  }

  Future<void> checkNotificationStatus() async {
    if (isCheckingStatus || isBusy) return;

    setState(() {
      isCheckingStatus = true;
      errorMessage = null;
      statusMessage = 'Checking your notification settings...';
    });

    try {
      final enabled = await service.isEnabledOnThisDevice();

      if (!mounted) return;

      setState(() {
        notificationsEnabled = enabled;
        statusMessage = enabled
            ? 'Daily reminders are enabled on this device '
                'for your signed-in account.'
            : 'Daily reminders are not currently enabled on this device. '
                'Choose Enable daily reminders if you want to turn them on.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to check your notification settings. '
            'Please check your connection and try again.';
        statusMessage = 'Your notification status could not be confirmed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isCheckingStatus = false;
        });
      }
    }
  }

  Future<void> enableNotifications() async {
    if (isBusy) return;

    setState(() {
      isBusy = true;
      errorMessage = null;
      statusMessage = 'Enabling reminders...';
    });

    try {
      await service.enable();

      if (!mounted) return;

      setState(() {
        notificationsEnabled = true;
        statusMessage =
            'Daily reminders are enabled on this device '
            'for your signed-in account.';
      });
    } on StateError catch (error) {
      showError(error.message);
    } on FirebaseException catch (_) {
      showError(
        'Unable to enable reminders. Check your connection '
        'and try again.',
      );
    } catch (_) {
      showError(
        'Unable to confirm reminders are enabled. '
        'Check your connection and try again. On iPhone, '
        'use the app installed on your Home Screen.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Future<void> disableNotifications() async {
    if (isBusy) return;

    setState(() {
      isBusy = true;
      errorMessage = null;
      statusMessage = 'Turning off reminders...';
    });

    try {
      await service.disable();

      if (!mounted) return;

      setState(() {
        notificationsEnabled = false;
        statusMessage =
            'Reminders are turned off on this device. '
            'Your other devices are unchanged.';
      });
    } on StateError catch (error) {
      showError(error.message);
    } catch (_) {
      showError(
        'Unable to finish turning off reminders. '
        'Check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  void showError(String message) {
    if (!mounted) return;

    setState(() {
      errorMessage = message;
      statusMessage =
          'Your change could not be confirmed. Please try again.';
    });
  }

  Widget reminderPeriodCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Reminder period',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how many days before expiry you would like '
              'Faithful Pantry to start reminding you.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            if (isLoadingReminderPeriod)
              const LinearProgressIndicator()
            else
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Remind me before expiry',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedReminderDays,
                    isExpanded: true,
                    items: List.generate(7, (index) {
                      final days = index + 1;

                      return DropdownMenuItem<int>(
                        value: days,
                        child: Text(
                          '$days ${days == 1 ? 'day' : 'days'} before expiry',
                        ),
                      );
                    }),
                    onChanged: isSavingReminderPeriod
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              selectedReminderDays = value;
                              reminderPeriodMessage = null;
                              reminderPeriodError = null;
                            });
                          },
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isLoadingReminderPeriod ||
                      isSavingReminderPeriod ||
                      selectedReminderDays == savedReminderDays
                  ? null
                  : saveReminderPeriod,
              icon: isSavingReminderPeriod
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                isSavingReminderPeriod
                    ? 'Saving...'
                    : 'Save reminder period',
              ),
            ),
            if (reminderPeriodMessage != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  reminderPeriodMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            if (reminderPeriodError != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  reminderPeriodError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    height: 1.5,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: isSavingReminderPeriod
                    ? null
                    : loadReminderPeriod,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget reminderDetails() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How reminders work',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We check daily for active groceries expiring today '
              'or within $savedReminderDays days.',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reminders use UK calendar dates. Delivery may be '
              'delayed by network availability, notification settings '
              'or the daily scheduling service.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Notifications use a general message without listing '
              'your groceries. Open the app to review your items.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isBusy && !isSavingReminderPeriod,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expiry reminders'),
          automaticallyImplyLeading: !isBusy && !isSavingReminderPeriod,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF123C25),
                        Color(0xFF227447),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFE5F6BD),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: Color(0xFF123C25),
                          size: 30,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'A little reminder,\nless forgotten food.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Optional reminders to help you keep '
                        'an eye on recorded expiry dates.',
                        style: TextStyle(
                          color: Color(0xFFE3F1E6),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Reminders on this device',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            statusMessage,
                            style: const TextStyle(height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: isBusy || isCheckingStatus
                              ? null
                              : enableNotifications,
                          icon: const Icon(Icons.notifications_outlined),
                          label: const Text('Enable daily reminders'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: isBusy || isCheckingStatus
                              ? null
                              : disableNotifications,
                          icon: const Icon(
                            Icons.notifications_off_outlined,
                          ),
                          label: const Text('Turn off on this device'),
                        ),
                        if (isBusy || isCheckingStatus) ...[
                          const SizedBox(height: 20),
                          const LinearProgressIndicator(),
                        ],
                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                        if (!isBusy && !isCheckingStatus) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: checkNotificationStatus,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Check status again'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                reminderPeriodCard(),
                const SizedBox(height: 16),
                reminderDetails(),
                const SizedBox(height: 20),
                const Text(
                  'On iPhone, enable reminders from the app installed '
                  'on your Home Screen. Logging out turns off this '
                  'device’s registration; enable again after logging in '
                  'if you want reminders.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF536458),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Date reminders do not determine whether food is safe. '
                  'Always follow the packaging and storage instructions.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF536458),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
