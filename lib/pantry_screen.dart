import 'package:flutter/material.dart';

import 'edit_grocery_screen.dart';
import 'models/pantry_item.dart';
import 'services/pantry_service.dart';
import 'utils/day_refresh_mixin.dart';
import 'utils/expiry_utils.dart';
import 'widgets/grocery_quantity_dialog.dart';
import 'widgets/grocery_category_icon.dart';

enum PantryView {
  inventory,
  alerts,
}

class PantryScreen extends StatefulWidget {
  const PantryScreen({
    super.key,
    this.view = PantryView.inventory,
  });

  final PantryView view;

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen>
    with DayRefreshMixin<PantryScreen> {
  final searchController = TextEditingController();
  final service = PantryService();

  Stream<List<PantryItem>>? pantryStream;
  String searchQuery = '';
  String selectedCategory = 'All categories';
  bool isBusy = false;

  bool get isAlerts => widget.view == PantryView.alerts;

  @override
  void initState() {
    super.initState();
    loadPantry();
  }

  void loadPantry() {
    try {
      pantryStream = service.watchPantry();
    } on StateError {
      pantryStream = null;
    }
  }

  void retry() {
    setState(loadPantry);
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

  String dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String expiryLabel(String value, DateTime today) {
    final date = ExpiryUtils.parseDate(value);
    final days = ExpiryUtils.daysUntil(value, today: today);

    if (date == null || days == null) {
      return 'Expiry date unavailable';
    }

    if (days < 0) return 'Expired ${dateLabel(date)}';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';

    return 'Expires in $days days • ${dateLabel(date)}';
  }

  Color expiryColor(String value, DateTime today) {
    return switch (ExpiryUtils.statusFor(value, today: today)) {
      ExpiryStatus.expired => Theme.of(context).colorScheme.error,
      ExpiryStatus.expiringSoon => Colors.orange.shade800,
      ExpiryStatus.later => Colors.green.shade800,
      ExpiryStatus.unknown =>
        Theme.of(context).colorScheme.onSurfaceVariant,
    };
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
        builder: (_) => GroceryQuantityDialog(
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

  Widget groceryCard(PantryItem item, DateTime today) {
    final color = expiryColor(item.expiryDate, today);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GroceryCategoryIcon(
  category: item.category,
),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
  item.category,
  style: const TextStyle(
    fontSize: 13,
    color: Color(0xFF536458),
  ),
),
const SizedBox(height: 10),
Text(
  '${item.currentQuantity} remaining',
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Color(0xFF20382B),
  ),
),
const SizedBox(height: 10),
Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 7,
  ),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Text(
    expiryLabel(item.expiryDate, today),
    style: TextStyle(
      fontSize: 13,
      height: 1.4,
      color: color,
      fontWeight: FontWeight.w700,
    ),
  ),
),
                    ],
                  ),
                ),
                if (!isAlerts)
                  PopupMenuButton<String>(
                    tooltip: 'Options for ${item.name}',
                    enabled: !isBusy,
                    onSelected: (value) {
                      if (value == 'edit') {
                        editGrocery(item);
                      } else if (value == 'remove') {
                        removeGrocery(item);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove'),
                      ),
                    ],
                  ),
              ],
            ),
            if (isAlerts) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Use it'),
                    onPressed:
                        isBusy ? null : () => markGrocery(item, 'used'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Wasted'),
                    onPressed:
                        isBusy ? null : () => markGrocery(item, 'wasted'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> expirySection(
    String title,
    List<PantryItem> items,
    DateTime today, {
    String? emptyMessage,
  }) {
    if (items.isEmpty && emptyMessage == null) return [];

    return [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Text(
          '$title (${items.length})',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      if (items.isEmpty)
        Text(emptyMessage!)
      else
        ...items.map((item) => groceryCard(item, today)),
    ];
  }

  Widget inventoryFilters(List<String> categories) {
    return Column(
      children: [
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pantryStream == null) {
      return const Center(
        child: Text('Please log in to view your groceries.'),
      );
    }

    return StreamBuilder<List<PantryItem>>(
      stream: pantryStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Unable to load groceries. '
                    'Check your connection and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final today = DateTime.now();

        final items = snapshot.data!
            .where((item) => item.isActive)
            .toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

        final categories = {
          ...items.map((item) => item.category),
          if (selectedCategory != 'All categories') selectedCategory,
        }.toList()
          ..sort();

        final query = searchQuery.trim().toLowerCase();

        final matchingItems = items.where((item) {
          return item.name.toLowerCase().contains(query) &&
              (selectedCategory == 'All categories' ||
                  item.category == selectedCategory);
        }).toList();

        final expired = items.where((item) {
          return ExpiryUtils.statusFor(
                item.expiryDate,
                today: today,
              ) ==
              ExpiryStatus.expired;
        }).toList();

        final soon = items.where((item) {
          return ExpiryUtils.statusFor(
                item.expiryDate,
                today: today,
              ) ==
              ExpiryStatus.expiringSoon;
        }).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  isAlerts ? 'Expiry Alerts' : 'My Pantry',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAlerts
                      ? 'Review dates and record use or waste.'
                      : '${items.length} active grocery entries'
                          ' • Soonest expiry first',
                ),
                const SizedBox(height: 20),
                if (!isAlerts) ...[
                  inventoryFilters(categories),
                  const SizedBox(height: 20),
                ],
                if (isBusy) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Your pantry is empty.\n'
                      'Open the Add tab to record a grocery.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (isAlerts) ...[
                  const Text(
                    'Expiring Soon includes today and the next '
                    '${ExpiryUtils.soonThresholdDays} days. '
                    'Date reminders do not determine food safety.',
                  ),
                  const SizedBox(height: 12),
                  ...expirySection(
                    'Expired',
                    expired,
                    today,
                  ),
                  ...expirySection(
                    'Expiring Soon',
                    soon,
                    today,
                    emptyMessage:
                        'No active groceries are approaching expiry '
                        'within this period.',
                  ),
                ] else if (matchingItems.isEmpty)
                  const Text(
                    'No groceries match your search and category.',
                  )
                else
                  ...matchingItems.map(
                    (item) => groceryCard(item, today),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}