import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static const vapidKey = 'BI-euvdXz6UWmBrBVzjPW0CzoserKOJ-oVc-LRx4i3NZr1aW2y7-wnMk0C6zYe02EewLR0OBK-lPdiEILgmi2P8';

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<String> enable() async {
    if (!kIsWeb) {
      throw StateError(
        'This notification experiment currently supports web apps only.',
      );
    }

    if (vapidKey == 'PASTE_YOUR_PUBLIC_VAPID_KEY_HERE') {
      throw StateError('The public notification key has not been configured.');
    }

    // Call enable directly from a button press so the permission
    // request follows an explicit user action.
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      throw StateError(
        'Notifications are not enabled. You can change permission '
        'in your browser or device settings.',
      );
    }

    // The web SDK registers firebase-messaging-sw.js using its
    // separate messaging scope, alongside our offline worker.
    final token = await messaging.getToken(
      vapidKey: vapidKey,
    );

    if (token == null || token.isEmpty) {
      throw StateError(
        'Unable to register this device for notifications. '
        'Check your connection and try again.',
      );
    }

    return token;
  }

  Future<void> disable() async {
    await messaging.deleteToken();
  }
}