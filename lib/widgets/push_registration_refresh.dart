import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/push_notification_service.dart';

class PushRegistrationRefresh extends StatefulWidget {
  const PushRegistrationRefresh({
    super.key,
    required this.userId,
    required this.child,
  });

  final String userId;
  final Widget child;

  @override
  State<PushRegistrationRefresh> createState() =>
      _PushRegistrationRefreshState();
}

class _PushRegistrationRefreshState
    extends State<PushRegistrationRefresh>
    with WidgetsBindingObserver {
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(refreshRegistration());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshRegistration());
    }
  }

  Future<void> refreshRegistration() async {
    if (!mounted || isRefreshing) return;

    if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
      return;
    }

    isRefreshing = true;

    try {
      await PushNotificationService().refreshExistingRegistration();
    } catch (_) {
      // A failed background refresh must not prevent app startup.
      // Retry on the next resume, or through explicit enabling.
      debugPrint(
        'Push registration refresh failed; retry on next app resume.',
      );
    } finally {
      isRefreshing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}