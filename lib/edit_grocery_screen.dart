
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models/pantry_item.dart';
import 'services/pantry_service.dart';

class EditGroceryScreen extends StatefulWidget {
  const EditGroceryScreen({
    super.key,
    this.grocery,
    this.item,
  }) : assert(grocery != null || item != null);

  final DocumentSnapshot<Map<String, dynamic>>? grocery;
  final PantryItem? item;

  @override
  State<EditGroceryScreen> createState() => _EditGroceryScreenState();
}

class _EditGroceryScreenState extends State<EditGroceryScreen> {
  final formKey = GlobalKey<FormState>();
  final service = PantryService();

  late final PantryItem original;
  late final TextEditingController nameController;
  late final TextEditingController quantityController;
  late final TextEditingController priceController;

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

  late String category;
  late DateTime purchaseDate;
  DateTime? expiryDate;

  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    original = widget.item ??
        PantryItem.fromDocument(widget.grocery!);

    nameController = TextEditingController(text: original.name);
    quantityController = TextEditingController(
      text: '${original.purchasedQuantity}',
    );
    priceController = TextEditingController(
      text: (original.unitPricePence / 100).toStringAsFixed(2),
    );

    category = categories.contains(original.category)
        ? original.category
        : 'Other';

    purchaseDate = DateTime.tryParse(original.purchaseDate) ??
        DateUtils.dateOnly(DateTime.now());
    expiryDate = DateTime.tryParse(original.expiryDate);
  }

  @override
  void dispose() {
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
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = isExpiry ? purchaseDate : DateTime(2000);
    final lastDate = isExpiry ? DateTime(2100, 12, 31) : today;
    var initialDate = isExpiry
        ? (expiryDate ?? purchaseDate)
        : purchaseDate;

    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
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

  Future<void> saveChanges() async {
    if (isSaving || !formKey.currentState!.validate()) return;

    if (expiryDate == null || expiryDate!.isBefore(purchaseDate)) {
      setState(() {
        errorMessage = 'Choose an expiry date on or after purchase.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final purchasedQuantity =
          int.parse(quantityController.text.trim());

      final resolvedQuantity =
          original.purchasedQuantity - original.currentQuantity;
      final remaining = purchasedQuantity - resolvedQuantity;

      final corrections = PantryItem(
        id: original.id,
        name: nameController.text.trim(),
        category: category,
        purchasedQuantity: purchasedQuantity,
        currentQuantity: remaining,
        unitPricePence: priceInPence(priceController.text)!,
        purchaseDate: dateValue(purchaseDate),
        expiryDate: dateValue(expiryDate!),
        status: remaining > 0
            ? 'active'
            : original.status == 'active'
                ? 'used'
                : original.status,
      );

      // The service checks the latest inventory in a transaction
      // and updates the matching purchase record.
      await service.editGrocery(corrections);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = switch (error.code) {
          'permission-denied' =>
            'Unable to save. Check your login and access rules.',
          'not-found' =>
            'The grocery or purchase record no longer exists.',
          'unavailable' =>
            'The database is unavailable. Check your connection.',
          _ => 'Unable to save changes. Please try again.',
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
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit grocery'),
          automaticallyImplyLeading: !isSaving,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Correct your grocery details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Corrections update the original purchase. '
                      'Use the pantry actions to record use or waste.',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Remaining when opened: '
                      '${original.currentQuantity} of '
                      '${original.purchasedQuantity}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameController,
                      enabled: !isSaving,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Item name',
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
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final quantity = int.tryParse(value?.trim() ?? '');

                        if (quantity == null ||
                            quantity < 1 ||
                            quantity > 999) {
                          return 'Enter a whole number from 1 to 999.';
                        }

                        final resolved = original.purchasedQuantity -
                            original.currentQuantity;

                        if (quantity < resolved) {
                          return 'At least $resolved have already been '
                              'used or wasted.';
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
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isSaving ? null : saveChanges,
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
