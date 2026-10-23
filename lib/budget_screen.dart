import 'package:flutter/material.dart';

import 'models/purchase_record.dart';
import 'services/pantry_service.dart';
import 'services/settings_service.dart';
import 'utils/day_refresh_mixin.dart';
import 'utils/spending_utils.dart';
import 'weekly_budget_screen.dart';

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

  Widget budgetBalance(int totalPence) {
    return StreamBuilder<int?>(
      stream: budgetStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Unable to load your budget. '
            'Spending is still shown above.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const LinearProgressIndicator();
        }

        final budgetPence = snapshot.data;
        final remainingPence = budgetPence == null
            ? null
            : SpendingUtils.remainingBudgetPence(
                budgetPence: budgetPence,
                spentPence: totalPence,
              );

        final isOverBudget =
            remainingPence != null && remainingPence < 0;

        final foreground = isOverBudget
            ? Theme.of(context).colorScheme.onErrorContainer
            : const Color(0xFF123C25);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isOverBudget
                ? Theme.of(context).colorScheme.errorContainer
                : const Color(0xFFEDF6E8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                budgetPence == null
                    ? 'Give your week a limit'
                    : isOverBudget
                        ? 'Over budget by'
                        : 'Remaining',
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                remainingPence == null
                    ? 'No budget set'
                    : money(remainingPence.abs()),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
              if (budgetPence != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Weekly limit: ${money(budgetPence)}',
                  style: TextStyle(color: foreground),
                ),
              ],
              if (budgetPence != null &&
                  weekStart.isBefore(currentWeekStart)) ...[
                const SizedBox(height: 8),
                Text(
                  'Compared with your current weekly limit.',
                  style: TextStyle(
                    fontSize: 13,
                    color: foreground,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isEditingBudget
                    ? null
                    : () => editBudget(budgetPence),
                style: OutlinedButton.styleFrom(
                  foregroundColor: foreground,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  budgetPence == null ? 'Set budget' : 'Edit budget',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget spendingSummary(int totalPence) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Total spent',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF536458),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              money(totalPence),
              style: const TextStyle(
                fontSize: 38,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF123C25),
              ),
            ),
            const SizedBox(height: 20),
            budgetBalance(totalPence),
          ],
        ),
      ),
    );
  }

  Widget dailySpendingChart(Map<String, int> dailyTotals) {
    final entries = dailyTotals.entries.toList();
    final highestPence = dailyTotals.values.fold<int>(
      0,
      (highest, amount) => amount > highest ? amount : highest,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by day',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap a day for its total',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF536458),
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = constraints.maxWidth < 280
                    ? 280.0
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: entries.map((entry) {
                        final date = DateTime.parse(entry.key);
                        final amount = entry.value;
                        final barHeight = highestPence == 0
                            ? 0.0
                            : amount / highestPence * 100;

                        final description =
                            '${dayNames[date.weekday - 1]}, '
                            '${dateLabel(date)}: ${money(amount)}';

                        return Expanded(
                          child: Semantics(
                            label: description,
                            button: true,
                            child: Tooltip(
                              message: description,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(description),
                                    ),
                                  );
                                },
                                child: ExcludeSemantics(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 10,
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 108,
                                          child: Align(
                                            alignment:
                                                Alignment.bottomCenter,
                                            child: Container(
                                              width: 24,
                                              height: amount == 0
                                                  ? 3
                                                  : barHeight,
                                              decoration: BoxDecoration(
                                                color: amount == 0
                                                    ? const Color(
                                                        0xFFDCE7D8,
                                                      )
                                                    : const Color(
                                                        0xFF176B3A,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  8,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          dayNames[date.weekday - 1]
                                              .substring(0, 3),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
            if (highestPence == 0) ...[
              const SizedBox(height: 8),
              const Text('No spending recorded this week.'),
            ],
          ],
        ),
      ),
    );
  }

  Widget purchaseHistory(List<PurchaseRecord> purchases) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey(weekStart),
        leading: const Icon(
          Icons.receipt_long_outlined,
          color: Color(0xFF176B3A),
        ),
        title: const Text(
          'Purchase history',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${purchases.length} '
          '${purchases.length == 1 ? 'purchase' : 'purchases'}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          if (purchases.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No purchases recorded for this week.'),
            )
          else
            ...purchases.map((purchase) {
              final date = DateTime.parse(purchase.purchaseDate);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      purchase.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${purchase.category} • '
                      '${purchase.purchasedQuantity} purchased',
                      style: const TextStyle(
                        color: Color(0xFF536458),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel(date),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF536458),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      money(purchase.totalPricePence),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF176B3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                  ],
                ),
              );
            }),
        ],
      ),
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
                  'Your spending, simply.',
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF123C25),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A clearer view of your grocery week.',
                  style: TextStyle(
                    color: Color(0xFF536458),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF6E8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous week',
                        onPressed: () => changeWeek(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          child: Text(
                            '${dateLabel(weekStart)} – '
                            '${dateLabel(weekEnd)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                ),
                const SizedBox(height: 20),
                spendingSummary(totalPence),
                const SizedBox(height: 20),
                dailySpendingChart(dailyTotals),
                const SizedBox(height: 20),
                purchaseHistory(purchases),
                const SizedBox(height: 16),
                const Text(
                  'Monday–Sunday, by purchase date. '
                  'Used, wasted and removed groceries stay included.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF536458),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}