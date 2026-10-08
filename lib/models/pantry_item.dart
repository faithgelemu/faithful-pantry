import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItem {
  const PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasedQuantity,
    required this.currentQuantity,
    required this.unitPricePence,
    required this.purchaseDate,
    required this.expiryDate,
    required this.status,
  });

  final String id;
  final String name;
  final String category;

  // Original number of items or packs purchased.
  final int purchasedQuantity;

  // Number still available in the pantry.
  final int currentQuantity;

  final int unitPricePence;

  // Calendar dates in YYYY-MM-DD format.
  final String purchaseDate;
  final String expiryDate;

  // active, used or wasted.
  final String status;

  bool get isActive => status == 'active' && currentQuantity > 0;

  factory PantryItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return PantryItem.fromMap(
      id: document.id,
      data: document.data() ?? {},
    );
  }

  factory PantryItem.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final status = _readString(data['status'], fallback: 'active');

    // Older records stored the purchased amount as "quantity".
    final purchasedQuantity = _readInt(
      data['purchasedQuantity'],
      fallback: _readInt(data['quantity']),
    );

    // Older used/wasted entries have no remaining inventory.
    final currentQuantity = _readInt(
      data['currentQuantity'],
      fallback: status == 'active' ? purchasedQuantity : 0,
    );

    return PantryItem(
      id: id,
      name: _readString(data['name'], fallback: 'Unnamed item'),
      category: _readString(data['category'], fallback: 'Other'),
      purchasedQuantity: purchasedQuantity,
      currentQuantity: currentQuantity,
      unitPricePence: _readInt(data['unitPricePence']),
      purchaseDate: _readString(data['purchaseDate']),
      expiryDate: _readString(data['expiryDate']),
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'purchasedQuantity': purchasedQuantity,
      'currentQuantity': currentQuantity,
      'unitPricePence': unitPricePence,
      'purchaseDate': purchaseDate,
      'expiryDate': expiryDate,
      'status': status,
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