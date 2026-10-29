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
      'Choose Enable notifications to request permission '
      'and register this browser installation.';

  Future<void> enableNotifications() async {
    if (isBusy) return;

    setState(() {
      isBusy = true;
      errorMessage = null;
    });

    try {
      final result = await service.enable();

      if (!mounted) return;

      setState(() {
        token = result;
        statusMessage =
            'This browser installation is registered. '
            'Automatic expiry reminders are not scheduled yet.';
      });
    } on StateError catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.message;
      });
    } on FirebaseException catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Notification registration failed. Check your connection '
            'and notification configuration, then try again.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to enable notifications. On iPhone, open the '
            'installed Home Screen app and try again.';
      });
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
    });

    try {
      await service.disable();

      if (!mounted) return;

      setState(() {
        token = null;
        statusMessage =
            'This installation’s notification registration was removed. '
            'Browser permission is managed separately in device settings.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to confirm notifications were disabled. '
            'Check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
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

      setState(() {
        errorMessage = 'Unable to copy the test token.';
      });
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
                  'Try push notifications',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enable notifications only if you want to test them. '
                  'On iPhone, use the app installed on your Home Screen.',
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
                  'This experiment registers this browser installation, '
                  'not a particular account. Do not send personal grocery '
                  'details yet. The token is not stored in Firestore.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}