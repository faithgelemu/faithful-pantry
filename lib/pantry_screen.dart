import 'package:flutter/material.dart';

import 'edit_grocery_screen.dart';
import 'models/pantry_item.dart';
import 'services/pantry_service.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final searchController = TextEditingController();
  final service = PantryService();

  Stream<List<PantryItem>>? pantryStream;
  String searchQuery = '';
  String selectedCategory = 'All categories';
  bool isBusy = false;

  @override
  void initState() {
    super.initState();

    try {
      pantryStream = service.watchPantry();
    } on StateError {
      pantryStream = null;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int daysUntil(DateTime date) {
    final today = DateTime.now();
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    final expiryUtc = DateTime.utc(date.year, date.month, date.day);

    return expiryUtc.difference(todayUtc).inDays;
  }

  String dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String expiryLabel(DateTime? date) {
    if (date == null) return 'Expiry date unavailable';

    final days = daysUntil(date);

    if (days < 0) return 'Expired ${dateLabel(date)}';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';

    return 'Expires in $days days • ${dateLabel(date)}';
  }

  Color expiryColor(DateTime? date) {
    if (date == null) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }

    final days = daysUntil(date);

    if (days < 0) return Theme.of(context).colorScheme.error;
    if (days <= 3) return Colors.orange.shade800;

    return Colors.green.shade800;
  }

  Future<void> editGrocery(PantryItem item) async {
    if (isBusy) return;

    setState(() {
      isBusy = true;
    });

    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EditGroceryScreen(item: item),
        ),
      );

      if (saved == true) showMessage('Grocery updated.');
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Future<void> removeGrocery(PantryItem item) async {
    if (isBusy) return;

    setState(() {
      isBusy = true;
    });

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove grocery?'),
          content: Text(
            'Remove ${item.name} from your pantry? '
            'Its purchase record will remain in your spending history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      await service.removeGrocery(item.id);
      showMessage('${item.name} removed from your pantry.');
    } catch (_) {
      showMessage('Unable to remove the grocery. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Future<void> markGrocery(PantryItem item, String action) async {
    if (isBusy) return;

    setState(() {
      isBusy = true;
    });

    try {
      final quantity = await showDialog<int>(
        context: context,
        builder: (_) => _QuantityDialog(
          item: item,
          action: action,
        ),
      );

      if (quantity == null || !mounted) return;

      final actionId = service.newActionId();

      await service.resolveQuantity(
        itemId: item.id,
        quantity: quantity,
        action: action,
        actionId: actionId,
      );

      showMessage('$quantity of ${item.name} marked as $action.');
    } on StateError catch (error) {
      showMessage(error.message);
    } on ArgumentError catch (error) {
      showMessage(error.message?.toString() ?? 'Check the quantity.');
    } catch (_) {
      showMessage(
        'Unable to confirm the update. Check the pantry quantity '
        'before trying again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Widget groceryCard(PantryItem item) {
    final expiry = DateTime.tryParse(item.expiryDate);
    final purchaseTotal = item.purchasedQuantity * item.unitPricePence;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(item.category),
            const SizedBox(height: 8),
            Text('Remaining: ${item.currentQuantity}'),
            Text('Originally purchased: ${item.purchasedQuantity}'),
            Text(
              'Original purchase total: '
              '£${(purchaseTotal / 100).toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            Text(
              expiryLabel(expiry),
              style: TextStyle(
                color: expiryColor(expiry),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  onPressed: isBusy ? null : () => editGrocery(item),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                  onPressed: isBusy ? null : () => removeGrocery(item),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as used'),
                  onPressed:
                      isBusy ? null : () => markGrocery(item, 'used'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Mark as wasted'),
                  onPressed:
                      isBusy ? null : () => markGrocery(item, 'wasted'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pantryStream == null) {
      return const Center(
        child: Text('Please log in to view your pantry.'),
      );
    }

    return StreamBuilder<List<PantryItem>>(
      stream: pantryStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to load your pantry. '
                'Check your connection and access rules.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!
            .where((item) => item.isActive)
            .toList();

        items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

        final categories = {
          ...items.map((item) => item.category),
          if (selectedCategory != 'All categories') selectedCategory,
        }.toList()
          ..sort();

        final query = searchQuery.trim().toLowerCase();

        final matchingItems = items.where((item) {
          final matchesName = item.name.toLowerCase().contains(query);
          final matchesCategory = selectedCategory == 'All categories' ||
              item.category == selectedCategory;

          return matchesName && matchesCategory;
        }).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'My Pantry',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${items.length} active grocery entries '
                  '• Soonest expiry first',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search your pantry',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Filter by category',
                    border: OutlineInputBorder(),
                  ),
                  items: ['All categories', ...categories].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Date alerts are reminders, not a judgement '
                  'that food is safe to eat.',
                ),
                const SizedBox(height: 20),
                if (isBusy) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                if (items.isEmpty)
                  const Text(
                    'Your pantry is empty.\n'
                    'Open the Scan tab to add a grocery.',
                  )
                else if (matchingItems.isEmpty)
                  const Text('No groceries match your search and category.')
                else
                  ...matchingItems.map(groceryCard),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({
    required this.item,
    required this.action,
  });

  final PantryItem item;
  final String action;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
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
      title: Text('Mark as ${widget.action}?'),
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
                  border: OutlineInputBorder(),
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
          child: Text('Mark as ${widget.action}'),
        ),
      ],
    );
  }
}