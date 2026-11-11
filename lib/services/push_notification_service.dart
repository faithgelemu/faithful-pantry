
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationService {
  static const vapidKey =
      'BI-euvdXz6UWmBrBVzjPW0CzoserKOJ-oVc-LRx4i3NZr1aW2y7-wnMk0C6zYe02EewLR0OBK-lPdiEILgmi2P8';

  static const _registrationKey = 'pantry_push_registration_v1';

  // Shared between service instances in this running app.
  static bool _isBusy = false;

  final _preferences = SharedPreferencesAsync();

  FirebaseMessaging get messaging => FirebaseMessaging.instance;

  DocumentReference<Map<String, dynamic>> _registrationDocument(
    String uid,
    String documentId,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pushTokens')
        .doc(documentId);
  }

  void _checkUser(String uid) {
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError(
        'Your account changed. Please reopen notifications and try again.',
      );
    }
  }

  /// Checks whether reminders are genuinely enabled for this device.
  ///
  /// This method does not request permission, create a token,
  /// or create a Firestore registration.
  Future<bool> isEnabledOnThisDevice() async {
    if (!kIsWeb) return false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final saved = await _preferences.getString(_registrationKey);
    if (saved == null) return false;

    try {
      final decoded = jsonDecode(saved);

      if (decoded is! Map<String, dynamic>) return false;

      final uid = decoded['uid'];
      final documentId = decoded['documentId'];

      if (uid is! String || documentId is! String) {
        return false;
      }

      if (uid != user.uid) return false;

      final settings = await messaging.getNotificationSettings();

      if (settings.authorizationStatus !=
          AuthorizationStatus.authorized) {
        return false;
      }

      _checkUser(user.uid);

      // Confirm that the saved registration has not changed while
      // the permission check was running.
      final latest = await _preferences.getString(_registrationKey);
      if (latest != saved) return false;

      final snapshot = await _registrationDocument(
        user.uid,
        documentId,
      ).get().timeout(const Duration(seconds: 20));

      _checkUser(user.uid);

      // Check once more in case another tab disabled reminders.
      final finalSaved = await _preferences.getString(_registrationKey);
      if (finalSaved != saved) return false;

      return snapshot.exists &&
          snapshot.data()?['enabled'] == true;
    } on FormatException {
      return false;
    }
  }

  Future<String> enable() async {
    if (!kIsWeb) {
      throw StateError(
        'This notification experiment currently supports web apps only.',
      );
    }

    if (_isBusy) {
      throw StateError(
        'Another notification action is still running. Please wait.',
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('Please log in before enabling notifications.');
    }

    if (vapidKey.trim().isEmpty ||
        vapidKey == 'PASTE_YOUR_PUBLIC_VAPID_KEY_HERE') {
      throw StateError(
        'The public notification key has not been configured.',
      );
    }

    _isBusy = true;

    try {
      // Keep this request directly connected to the user's button press.
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus !=
          AuthorizationStatus.authorized) {
        throw StateError(
          'Notifications are not enabled. You can change permission '
          'in your browser or device settings.',
        );
      }

      _checkUser(user.uid);

      // Retire any previous registration before creating a new one.
      await _removeRegistration();

      _checkUser(user.uid);

      final token = await messaging.getToken(vapidKey: vapidKey);

      if (token == null || token.isEmpty) {
        throw StateError(
          'Unable to register this installation. '
          'Check your connection and try again.',
        );
      }

      final documentId = sha256.convert(utf8.encode(token)).toString();

      // Save the cleanup reference before attempting the cloud write.
      // The raw delivery token is not stored in shared preferences.
      await _preferences.setString(
        _registrationKey,
        jsonEncode({
          'uid': user.uid,
          'documentId': documentId,
        }),
      );

      try {
        _checkUser(user.uid);

        await _registrationDocument(user.uid, documentId).set({
          'token': token,
          'enabled': true,
          'platform': 'web',
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 20));

        _checkUser(user.uid);
      } catch (_) {
        // A failed or delayed database write must not leave a live
        // token ready to receive account-specific messages.
        // Keep the local cleanup reference so removal can be retried.
        await messaging.deleteToken();
        rethrow;
      }

      return token;
    } finally {
      _isBusy = false;
    }
  }

  Future<void> disable() async {
    if (!kIsWeb) return;

    if (_isBusy) {
      throw StateError(
        'Another notification action is still running. Please wait.',
      );
    }

    _isBusy = true;

    try {
      await _removeRegistration();
    } finally {
      _isBusy = false;
    }
  }

  Future<void> refreshExistingRegistration() async {
    if (!kIsWeb || _isBusy) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isBusy = true;

    try {
      final saved = await _preferences.getString(_registrationKey);
      if (saved == null) return;

      final decoded = jsonDecode(saved);

      if (decoded is! Map<String, dynamic>) return;

      final uid = decoded['uid'];
      final documentId = decoded['documentId'];

      if (uid != user.uid || documentId is! String) return;

      final settings = await messaging.getNotificationSettings();

      // Refresh must never request notification permission.
      if (settings.authorizationStatus !=
          AuthorizationStatus.authorized) {
        return;
      }

      _checkUser(user.uid);

      final token = await messaging.getToken(vapidKey: vapidKey);

      if (token == null || token.isEmpty) return;

      // Another tab may have disabled notifications while we waited.
      final latest = await _preferences.getString(_registrationKey);

      if (latest != saved) return;

      _checkUser(user.uid);

      final document = _registrationDocument(user.uid, documentId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(document);
        final data = snapshot.data();

        // Do not recreate a registration deleted during logout.
        if (!snapshot.exists || data?['enabled'] != true) return;

        transaction.update(document, {
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } finally {
      _isBusy = false;
    }
  }

  Future<void> prepareForLogout() async {
    // Does not request permission or create a token.
    await disable();
  }

  Future<void> _removeRegistration() async {
    final saved = await _preferences.getString(_registrationKey);

    // Also handles registrations made by our earlier experiment,
    // which did not save a local cleanup reference.
    final settings = await messaging.getNotificationSettings();

    if (saved != null ||
        settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Invalidate delivery first, even if Firestore cleanup later fails.
      await messaging.deleteToken();
    }

    if (saved == null) return;

    final decoded = jsonDecode(saved);

    if (decoded is! Map<String, dynamic>) {
      throw StateError('Unable to read the notification registration.');
    }

    final uid = decoded['uid'];
    final documentId = decoded['documentId'];

    if (uid is! String || documentId is! String) {
      throw StateError('Unable to read the notification registration.');
    }

    if (FirebaseAuth.instance.currentUser?.uid == uid) {
      await _registrationDocument(uid, documentId)
          .delete()
          .timeout(const Duration(seconds: 20));
    }

    // If another account is now signed in, its rules cannot delete
    // the previous owner's document. The old token was invalidated
    // above; the future sender must remove invalid-token records.
    await _preferences.remove(_registrationKey);
  }
}
