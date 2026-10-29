import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  String? token;
  String? errorMessage;

  String statusMessage =
      'Choose Enable notifications to register this installation '
      'for your signed-in account. Opening this screen does not '
      'enable notifications.';

  Future<void> enableNotifications() async {
    if (isBusy) return;

    setState(() {
      isBusy = true;
      token = null;
      errorMessage = null;
      statusMessage = 'Registering notifications for your account...';
    });

    try {
      final result = await service.enable();

      if (!mounted) return;

      setState(() {
        token = result;
        statusMessage =
            'This installation is registered for your account. '
            'Automatic expiry reminders are not scheduled yet.';
      });
    } on StateError catch (error) {
      showError(error.message);
    } on FirebaseException catch (_) {
      showError(
        'Unable to confirm account registration. Check your connection '
        'and Firestore access rules, then try again.',
      );
    } catch (_) {
      showError(
        'Unable to confirm notification registration. '
        'Check your connection and try again. On iPhone, '
        'use the installed Home Screen app.',
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
      token = null;
      errorMessage = null;
      statusMessage = 'Removing this installation’s registration...';
    });

    try {
      await service.disable();

      if (!mounted) return;

      setState(() {
        statusMessage =
            'This installation’s registration was removed. '
            'Your other devices are unchanged. Browser permission '
            'is managed separately in device settings.';
      });
    } on StateError catch (error) {
      showError(error.message);
    } catch (_) {
      showError(
        'Unable to finish notification cleanup. '
        'Check your connection and try disabling again.',
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
      token = null;
      errorMessage = message;
      statusMessage =
          'The operation was not confirmed. '
          'You can retry when connected.';
    });
  }

  Future<void> copyToken() async {
    final value = token;

    if (value == null || isBusy) return;

    try {
      await Clipboard.setData(ClipboardData(text: value));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Test token copied. Paste it only into Firebase’s test tool.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to copy the test token.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isBusy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Push notification experiment'),
          automaticallyImplyLeading: !isBusy,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 56,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your notification preferences',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enable notifications only if you want to receive them. '
                  'On iPhone, open the app installed on your Home Screen.',
                ),
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: Text(statusMessage),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: isBusy ? null : enableNotifications,
                  icon: const Icon(Icons.notifications_outlined),
                  label: const Text('Enable notifications'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : disableNotifications,
                  icon: const Icon(Icons.notifications_off_outlined),
                  label: const Text('Disable on this installation'),
                ),
                if (token != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : copyToken,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copy test delivery token'),
                  ),
                ],
                if (isBusy) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Enabling links this installation to your account. '
                  'Logging out removes its registration; enable again '
                  'after logging back in if you want notifications.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'This remains an experiment. Use generic test messages '
                  'until account-change and token-refresh checks are complete.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}