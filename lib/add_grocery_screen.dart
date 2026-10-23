import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'models/pantry_item.dart';
import 'services/pantry_service.dart';
import 'dart:async';

class AddGroceryScreen extends StatefulWidget {
  const AddGroceryScreen({super.key});

  @override
  State<AddGroceryScreen> createState() => _AddGroceryScreenState();
}

class _AddGroceryScreenState extends State<AddGroceryScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final priceController = TextEditingController();
  final service = PantryService();

  static const categories = [
    'Fruit and vegetables',
    'Dairy and eggs',
    'Meat and fish',
    'Bread and bakery',
    'Frozen food',
    'Cupboard essentials',
    'Drinks',
    'Other',
  ];

  String category = 'Other';
  DateTime purchaseDate = DateUtils.dateOnly(DateTime.now());
  DateTime? expiryDate;
  bool isSaving = false;
  Timer? slowSaveTimer;
  String? errorMessage;

  @override
  void dispose() {
    slowSaveTimer?.cancel();
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  String dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String dateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int? priceInPence(String value) {
    final text = value.trim();

    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
      return null;
    }

    final parts = text.split('.');
    final pounds = int.tryParse(parts.first);
    final pence = parts.length == 2
        ? int.tryParse(parts[1].padRight(2, '0'))
        : 0;

    if (pounds == null || pence == null) return null;
    return pounds * 100 + pence;
  }

  Future<void> chooseDate({required bool isExpiry}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isExpiry ? (expiryDate ?? purchaseDate) : purchaseDate,
      firstDate: isExpiry ? purchaseDate : DateTime(2000),
      lastDate: isExpiry
          ? DateTime(2100, 12, 31)
          : DateUtils.dateOnly(DateTime.now()),
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (isExpiry) {
        expiryDate = selected;
      } else {
        purchaseDate = selected;
        if (expiryDate != null && expiryDate!.isBefore(purchaseDate)) {
          expiryDate = null;
        }
      }
      errorMessage = null;
    });
  }

  Future<void> saveGrocery() async {
    if (isSaving || !formKey.currentState!.validate()) return;

    if (expiryDate == null) {
      setState(() {
        errorMessage = 'Please choose an expiry date.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    slowSaveTimer?.cancel();
slowSaveTimer = Timer(const Duration(seconds: 10), () {
  if (!mounted || !isSaving) return;

  setState(() {
    errorMessage =
        'Saving is taking longer than usual. Check your connection. '
        'Keep this form open; the save may still complete. '
        'Please do not submit the item again.';
  });
});

    try {
      final quantity = int.parse(quantityController.text.trim());

      final item = PantryItem(
        id: '',
        name: nameController.text.trim(),
        category: category,
        purchasedQuantity: quantity,
        currentQuantity: quantity,
        unitPricePence: priceInPence(priceController.text)!,
        purchaseDate: dateValue(purchaseDate),
        expiryDate: dateValue(expiryDate!),
        status: 'active',
      );

      // The service assigns an ID and saves both records together.
      await service.addGrocery(item);

      if (!mounted) return;

      formKey.currentState!.reset();
      nameController.clear();
      quantityController.text = '1';
      priceController.clear();

      setState(() {
        category = 'Other';
        purchaseDate = DateUtils.dateOnly(DateTime.now());
        expiryDate = null;
        errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grocery saved to your pantry.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = switch (error.code) {
          'permission-denied' =>
            'Unable to save. Check your login and Firestore rules.',
          'unavailable' =>
            'The database is unavailable. Check your connection.',
          _ => 'Unable to save your grocery. Please try again.',
        };
      });
    } on ArgumentError catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.message?.toString() ?? 'Check your details.';
      });
    } on StateError catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      slowSaveTimer?.cancel();
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add a grocery',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the item details to track expiry and spending.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  enabled: !isSaving,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    hintText: 'For example, Milk',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter an item name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            category = value;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: quantityController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity purchased',
                    helperText: 'Number of items or packs purchased',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final quantity = int.tryParse(value?.trim() ?? '');
                    if (quantity == null || quantity < 1 || quantity > 999) {
                      return 'Enter a whole number from 1 to 999.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  enabled: !isSaving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price per item or pack',
                    prefixText: '£ ',
                    hintText: '1.50',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final pence = priceInPence(value ?? '');
                    if (pence == null || pence > 1000000) {
                      return 'Enter a price from 0 to 10000, e.g. 1.50.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () => chooseDate(isExpiry: false),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Purchased: ${dateLabel(purchaseDate)}'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () => chooseDate(isExpiry: true),
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    expiryDate == null
                        ? 'Choose expiry date'
                        : 'Expires: ${dateLabel(expiryDate!)}',
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: isSaving ? null : saveGrocery,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isSaving ? 'Saving...' : 'Save grocery'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}