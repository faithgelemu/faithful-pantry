import 'package:flutter/material.dart';

import '../models/pantry_item.dart';

class GroceryQuantityDialog extends StatefulWidget {
  const GroceryQuantityDialog({
    super.key,
    required this.item,
    required this.action,
  });

  final PantryItem item;
  final String action;

  @override
  State<GroceryQuantityDialog> createState() =>
      _GroceryQuantityDialogState();
}

class _GroceryQuantityDialogState
    extends State<GroceryQuantityDialog> {
  final formKey = GlobalKey<FormState>();
  final quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.action == 'used' ? 'Record food used' : 'Record food wasted',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.item.name}: '
                '${widget.item.currentQuantity} remaining.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                ),
                validator: (value) {
                  final quantity = int.tryParse(value?.trim() ?? '');

                  if (quantity == null ||
                      quantity < 1 ||
                      quantity > widget.item.currentQuantity) {
                    return 'Enter 1 to ${widget.item.currentQuantity}.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Your original purchase and spending stay unchanged.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;

            Navigator.pop(
              context,
              int.parse(quantityController.text.trim()),
            );
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}