import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'services/push_notification_service.dart';

class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({super.key});

  @override
  State<PushNotificationScreen> createState() =>
      _PushNotificationScreenState();
}

class _PushNotificationScreenState
    extends State<PushNotificationScreen> {
  final service = PushNotificationService();

  bool isBusy = false;
  String? errorMessage;

  String statusMessage =
      'Choose Enable daily reminders to receive notifications '
      'on this device. Opening this page does not change your preference.';

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
            const Text(
              'We check daily for active groceries expiring today '
              'or within the next three days.',
              style: TextStyle(height: 1.5),
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
      canPop: !isBusy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expiry reminders'),
          automaticallyImplyLeading: !isBusy,
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
                          onPressed:
                              isBusy ? null : enableNotifications,
                          icon:
                              const Icon(Icons.notifications_outlined),
                          label: const Text('Enable daily reminders'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed:
                              isBusy ? null : disableNotifications,
                          icon: const Icon(
                            Icons.notifications_off_outlined,
                          ),
                          label: const Text(
                            'Turn off on this device',
                          ),
                        ),
                        if (isBusy) ...[
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
                                color:
                                    Theme.of(context).colorScheme.error,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
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