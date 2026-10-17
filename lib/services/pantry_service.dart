import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pantry_item.dart';
import '../models/purchase_record.dart';

class PantryService {
  FirebaseFirestore get _database => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userDocument {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('Please log in before accessing groceries.');
    }

    return _database.collection('users').doc(user.uid);
  }

  Stream<List<PantryItem>> watchPantry() {
    return _userDocument.collection('pantry').snapshots().map(
          (snapshot) => snapshot.docs
              .map((document) => PantryItem.fromDocument(document))
              .toList(),
        );
  }

  Stream<List<PurchaseRecord>> watchPurchases() {
    return _userDocument.collection('purchases').snapshots().map(
          (snapshot) => snapshot.docs
              .map((document) => PurchaseRecord.fromDocument(document))
              .toList(),
        );
  }

  DateTime _calendarDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw ArgumentError('Choose a valid calendar date.');
    }

    final date = DateTime.tryParse(value);

    if (date == null || date.toIso8601String().substring(0, 10) != value) {
      throw ArgumentError('Choose a valid calendar date.');
    }

    return date;
  }

  void _validate(PantryItem item) {
    if (item.name.trim().isEmpty || item.name.trim().length > 100) {
      throw ArgumentError('Enter an item name of 1 to 100 characters.');
    }

    if (item.category.trim().isEmpty) {
      throw ArgumentError('Choose a category.');
    }

    if (item.purchasedQuantity < 1 || item.purchasedQuantity > 999) {
      throw ArgumentError('Purchased quantity must be from 1 to 999.');
    }

    if (item.currentQuantity < 0 ||
        item.currentQuantity > item.purchasedQuantity) {
      throw ArgumentError('Remaining quantity is invalid.');
    }

    if (item.unitPricePence < 0 || item.unitPricePence > 1000000) {
      throw ArgumentError('Enter a unit price from £0 to £10000.');
    }

    final purchased = _calendarDate(item.purchaseDate);
    final expires = _calendarDate(item.expiryDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (purchased.isAfter(today)) {
      throw ArgumentError('Purchase date cannot be in the future.');
    }

    if (expires.isBefore(purchased)) {
      throw ArgumentError('Expiry date cannot be before purchase.');
    }

    if (!['active', 'used', 'wasted'].contains(item.status)) {
      throw ArgumentError('Invalid pantry status.');
    }

    if ((item.status == 'active') != (item.currentQuantity > 0)) {
      throw ArgumentError('Status must match the remaining quantity.');
    }
  }

  PurchaseRecord _purchaseFor(PantryItem item) {
    return PurchaseRecord(
      id: item.id,
      pantryItemId: item.id,
      name: item.name.trim(),
      category: item.category,
      purchasedQuantity: item.purchasedQuantity,
      unitPricePence: item.unitPricePence,
      purchaseDate: item.purchaseDate,
    );
  }

  Future<void> addGrocery(PantryItem details) async {
    _validate(details);

    if (details.currentQuantity != details.purchasedQuantity ||
        details.status != 'active') {
      throw ArgumentError('A new grocery must start with its full quantity.');
    }

    final user = _userDocument;
    final pantry = user.collection('pantry').doc();

    final item = PantryItem(
      id: pantry.id,
      name: details.name.trim(),
      category: details.category,
      purchasedQuantity: details.purchasedQuantity,
      currentQuantity: details.currentQuantity,
      unitPricePence: details.unitPricePence,
      purchaseDate: details.purchaseDate,
      expiryDate: details.expiryDate,
      status: 'active',
    );

    final purchase = user.collection('purchases').doc(pantry.id);
    final batch = _database.batch();

    batch.set(pantry, {
      ...item.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(purchase, {
      ..._purchaseFor(item).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> editGrocery(PantryItem corrections) async {
    _validate(corrections);

    final user = _userDocument;
    final pantry = user.collection('pantry').doc(corrections.id);
    final purchase = user.collection('purchases').doc(corrections.id);

    await _database.runTransaction((transaction) async {
      final snapshot = await transaction.get(pantry);

      if (!snapshot.exists) {
        throw StateError('This grocery no longer exists.');
      }

      final existing = PantryItem.fromDocument(snapshot);

      // Preserve quantities already used or wasted.
      final resolvedQuantity =
          existing.purchasedQuantity - existing.currentQuantity;
      final remaining = corrections.purchasedQuantity - resolvedQuantity;

      if (remaining < 0) {
        throw StateError(
          'Purchased quantity cannot be less than the amount already '
          'used or wasted.',
        );
      }

      final updated = PantryItem(
        id: existing.id,
        name: corrections.name.trim(),
        category: corrections.category,
        purchasedQuantity: corrections.purchasedQuantity,
        currentQuantity: remaining,
        unitPricePence: corrections.unitPricePence,
        purchaseDate: corrections.purchaseDate,
        expiryDate: corrections.expiryDate,
        status: remaining > 0
            ? 'active'
            : existing.status == 'active'
                ? 'used'
                : existing.status,
      );

      _validate(updated);

      transaction.update(pantry, {
        ...updated.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(purchase, {
        ..._purchaseFor(updated).toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> removeGrocery(String itemId) async {
    // Only inventory is deleted. Purchase history remains.
    await _userDocument.collection('pantry').doc(itemId).delete();
  }

  String newActionId() {
    return _userDocument.collection('inventoryActions').doc().id;
  }

  Future<void> resolveQuantity({
  required String itemId,
  required int quantity,
  required String action,
  required String actionId,
}) async {
  if (quantity < 1 || !['used', 'wasted'].contains(action)) {
    throw ArgumentError('Choose a valid quantity and action.');
  }

  final user = _userDocument;
  final pantry = user.collection('pantry').doc(itemId);
  final actionRecord = user.collection('inventoryActions').doc(actionId);

  final accepted = await _database.runTransaction<bool>(
    (transaction) async {
      final previousAction = await transaction.get(actionRecord);

      // This action already succeeded, so do not subtract again.
      if (previousAction.exists) return true;

      final snapshot = await transaction.get(pantry);

      if (!snapshot.exists) return false;

      final item = PantryItem.fromDocument(snapshot);

      if (!item.isActive || quantity > item.currentQuantity) {
        return false;
      }

      final remaining = item.currentQuantity - quantity;

      transaction.update(pantry, {
        'purchasedQuantity': item.purchasedQuantity,
        'currentQuantity': remaining,
        'status': remaining == 0 ? action : 'active',
        'updatedAt': FieldValue.serverTimestamp(),
        if (remaining == 0)
          'resolvedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(actionRecord, {
        'pantryItemId': itemId,
        'action': action,
        'quantity': quantity,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    },
  );

  // Raise the application error outside the transaction callback.
  if (!accepted) {
    throw StateError(
      'This grocery is no longer available in that quantity.',
    );
  }
}
}