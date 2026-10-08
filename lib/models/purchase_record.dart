import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseRecord {
  const PurchaseRecord({
    required this.id,
    required this.pantryItemId,
    required this.name,
    required this.category,
    required this.purchasedQuantity,
    required this.unitPricePence,
    required this.purchaseDate,
  });

  final String id;
  final String pantryItemId;
  final String name;
  final String category;

  // Original quantity purchased, independent of remaining inventory.
  final int purchasedQuantity;
  final int unitPricePence;

  // Calendar date in YYYY-MM-DD format.
  final String purchaseDate;

  int get totalPricePence => purchasedQuantity * unitPricePence;

  factory PurchaseRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return PurchaseRecord.fromMap(
      id: document.id,
      data: document.data() ?? {},
    );
  }

  factory PurchaseRecord.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return PurchaseRecord(
      id: id,
      pantryItemId: _readString(data['pantryItemId'], fallback: id),
      name: _readString(data['name'], fallback: 'Unnamed item'),
      category: _readString(data['category'], fallback: 'Other'),

      // Support older records that used "quantity".
      purchasedQuantity: _readInt(
        data['purchasedQuantity'],
        fallback: _readInt(data['quantity']),
      ),
      unitPricePence: _readInt(data['unitPricePence']),
      purchaseDate: _readString(data['purchaseDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pantryItemId': pantryItemId,
      'name': name,
      'category': category,
      'purchasedQuantity': purchasedQuantity,
      'unitPricePence': unitPricePence,
      'totalPricePence': totalPricePence,
      'purchaseDate': purchaseDate,
    };
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    return value is int ? value : fallback;
  }

  static String _readString(
    Object? value, {
    String fallback = '',
  }) {
    return value is String && value.trim().isNotEmpty
        ? value
        : fallback;
  }
}