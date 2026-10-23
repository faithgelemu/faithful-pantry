import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  DocumentReference<Map<String, dynamic>> get _preferences {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('Please log in to access your settings.');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('preferences');
  }

  Stream<int?> watchWeeklyBudgetPence() {
    return _preferences.snapshots().map((snapshot) {
      final value = snapshot.data()?['weeklyBudgetPence'];

      if (value == null) return null;

      if (value is! int || value < 0 || value > 1000000) {
        throw StateError('The saved budget is invalid.');
      }

      return value;
    });
  }

  Future<void> saveWeeklyBudgetPence(int budgetPence) async {
    if (budgetPence < 0 || budgetPence > 1000000) {
      throw ArgumentError('Enter a weekly budget from £0 to £10000.');
    }

    await _preferences.set(
      {
        'weeklyBudgetPence': budgetPence,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
  Stream<String?> watchPreferredName() {
  return _preferences.snapshots().map((snapshot) {
    final value = snapshot.data()?['preferredName'];

    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  });
}

Future<void> savePreferredName(String name) async {
  final cleanedName = name.trim();

  if (cleanedName.runes.length > 40) {
    throw ArgumentError(
      'Use a preferred name of up to 40 characters.',
    );
  }

  await _preferences.set(
    {
      'preferredName': cleanedName.isEmpty
          ? FieldValue.delete()
          : cleanedName,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}
}