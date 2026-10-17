import 'package:flutter/material.dart';

import 'models/purchase_record.dart';
import 'services/pantry_service.dart';
import 'services/settings_service.dart';
import 'utils/spending_utils.dart';
import 'weekly_budget_screen.dart';
import 'utils/day_refresh_mixin.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> 
  with DayRefreshMixin<BudgetScreen> {
  final service = PantryService();
  final settingsService = SettingsService();

  Stream<List<PurchaseRecord>>? purchasesStream;
  Stream<int?>? budgetStream;

  DateTime get currentWeekStart =>
    SpendingUtils.startOfWeek(DateTime.now());
  late DateTime weekStart;

  bool isEditingBudget = false;

  static const dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();

    weekStart = currentWeekStart;

    try {
      purchasesStream = service.watchPurchases();
      budgetStream = settingsService.watchWeeklyBudgetPence();
    } on StateError {
      purchasesStream = null;
      budgetStream = null;
    }
  }

@override
void onCalendarDayChanged(
  DateTime previousDay,
  DateTime currentDay,
) {
  weekStart = SpendingUtils.weekAfterDayChange(
    selectedWeek: weekStart,
    previousDay: previousDay,
    currentDay: currentDay,
  );
}

  String dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String money(int pence) {
    return '£${(pence / 100).toStringAsFixed(2)}';
  }

  void changeWeek(int direction) {
    setState(() {
      weekStart = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + direction * 7,
      );
    });
  }

  Future<void> editBudget(int? currentBudgetPence) async {
    if (isEditingBudget) return;

    setState(() {
      isEditingBudget = true;
    });

    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => WeeklyBudgetScreen(
            currentBudgetPence: currentBudgetPence,
          ),
        ),
      );

      if (!mounted || saved != true) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weekly budget saved.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isEditingBudget = false;
        });
      }
    }
  }

  Widget budgetCard(int totalPence) {
    return StreamBuilder<int?>(
      stream: budgetStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Unable to load your budget setting. '
              'Your spending total is still shown above.',
            ),
          );
        }

        // A null value can mean "unset", so hasData alone
        // cannot distinguish that from loading.
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final budgetPence = snapshot.data;
        final remainingPence = budgetPence == null
            ? null
            : SpendingUtils.remainingBudgetPence(
                budgetPence: budgetPence,
                spentPence: totalPence,
              );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly budget',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (budgetPence == null)
                  const Text('No weekly budget set.')
                else ...[
                  Text('Current weekly limit: ${money(budgetPence)}'),
                  const SizedBox(height: 8),
                  Text(
                    remainingPence! < 0
                        ? 'Over budget by ${money(-remainingPence)}'
                        : 'Remaining: ${money(remainingPence)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: remainingPence < 0
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'This is your current reusable weekly limit. '
                  'For earlier weeks, the comparison uses this same '
                  'limit, not a historical budget.',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: isEditingBudget
                      ? null
                      : () => editBudget(budgetPence),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    budgetPence == null
                        ? 'Set weekly budget'
                        : 'Edit weekly budget',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (purchasesStream == null || budgetStream == null) {
      return const Center(
        child: Text('Please log in to view your spending.'),
      );
    }

    final weekEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 6,
    );

    return StreamBuilder<List<PurchaseRecord>>(
      stream: purchasesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to load spending. '
                'Check your connection and access rules.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allPurchases = snapshot.data!;

        final purchases = SpendingUtils.purchasesForWeek(
          allPurchases,
          weekStart,
        );

        final totalPence = SpendingUtils.weeklyTotalPence(
          allPurchases,
          weekStart,
        );

        final dailyTotals = SpendingUtils.dailyTotalsPence(
          allPurchases,
          weekStart,
        );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Weekly spending',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous week',
                      onPressed: () => changeWeek(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        '${dateLabel(weekStart)} – ${dateLabel(weekEnd)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next week',
                      onPressed: weekStart.isBefore(currentWeekStart)
                          ? () => changeWeek(1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total spent in selected week'),
                        const SizedBox(height: 8),
                        Text(
                          money(totalPence),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1DB954),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${purchases.length} purchase entries'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Based on purchase dates, Monday to Sunday '
                  'using local calendar dates. Used, wasted and '
                  'removed groceries remain included.',
                ),
                const SizedBox(height: 16),
                budgetCard(totalPence),
                const SizedBox(height: 24),
                const Text(
                  'Daily breakdown',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...dailyTotals.entries.map((entry) {
                  final date = DateTime.parse(entry.key);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(dayNames[date.weekday - 1]),
                    subtitle: Text(dateLabel(date)),
                    trailing: Text(
                      money(entry.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                const Text(
                  'Purchases',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (purchases.isEmpty)
                  const Text('No purchases recorded for this week.')
                else
                  ...purchases.map((purchase) {
                    final date = DateTime.parse(purchase.purchaseDate);

                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.receipt_long_outlined,
                        ),
                        title: Text(purchase.name),
                        subtitle: Text(
                          '${purchase.category}\n'
                          'Purchased: ${purchase.purchasedQuantity}'
                          ' • ${dateLabel(date)}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          money(purchase.totalPricePence),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}