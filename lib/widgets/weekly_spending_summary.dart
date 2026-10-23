import 'package:flutter/material.dart';

import '../models/purchase_record.dart';
import '../services/pantry_service.dart';
import '../services/settings_service.dart';
import '../utils/day_refresh_mixin.dart';
import '../utils/spending_utils.dart';

class WeeklySpendingSummary extends StatefulWidget {
  const WeeklySpendingSummary({super.key});

  @override
  State<WeeklySpendingSummary> createState() =>
      _WeeklySpendingSummaryState();
}

class _WeeklySpendingSummaryState
    extends State<WeeklySpendingSummary>
    with DayRefreshMixin<WeeklySpendingSummary> {
  final pantryService = PantryService();
  final settingsService = SettingsService();

  Stream<List<PurchaseRecord>>? purchasesStream;
  Stream<int?>? budgetStream;

  @override
  void initState() {
    super.initState();

    try {
      purchasesStream = pantryService.watchPurchases();
      budgetStream = settingsService.watchWeeklyBudgetPence();
    } on StateError {
      purchasesStream = null;
      budgetStream = null;
    }
  }

  String money(int pence) {
    return '£${(pence / 100).toStringAsFixed(2)}';
  }

  String dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget budgetDetails(int spentPence) {
    return StreamBuilder<int?>(
      stream: budgetStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Unable to load your budget setting.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const LinearProgressIndicator();
        }

        final budgetPence = snapshot.data;

        if (budgetPence == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6EC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Give your spending a little direction.\n'
              'Set a weekly limit in the Budget tab.',
              style: TextStyle(
                color: Color(0xFF20382B),
                height: 1.5,
              ),
            ),
          );
        }

        final remainingPence = SpendingUtils.remainingBudgetPence(
          budgetPence: budgetPence,
          spentPence: spentPence,
        );

        final isOverBudget = remainingPence < 0;
        final accentColor = isOverBudget
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF176B3A);

        // A zero budget has no percentage to calculate.
        final progress = budgetPence > 0
            ? (spentPence / budgetPence).clamp(0.0, 1.0).toDouble()
            : null;

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
                isOverBudget ? 'Over budget by' : 'Still available',
                style: TextStyle(
                  color: isOverBudget
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : const Color(0xFF20382B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                money(
                  isOverBudget ? -remainingPence : remainingPence,
                ),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isOverBudget
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : const Color(0xFF123C25),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Weekly limit: ${money(budgetPence)}',
                style: TextStyle(
                  color: isOverBudget
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : const Color(0xFF20382B),
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: accentColor,
                    backgroundColor: isOverBudget
                        ? Theme.of(context).colorScheme.surface
                        : const Color(0xFFD3E6CC),
                    semanticsLabel: 'Weekly budget spent',
                    semanticsValue:
                        '${(spentPence / budgetPence * 100).round()}%',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOverBudget
                      ? 'Spending has exceeded your weekly limit.'
                      : 'The bar shows how much of your limit is spent.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverBudget
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : const Color(0xFF20382B),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Your weekly limit is £0.00.',
                  style: TextStyle(
                    color: isOverBudget
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : const Color(0xFF20382B),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (purchasesStream == null || budgetStream == null) {
      return const Text('Please log in to view your spending.');
    }

    final monday = SpendingUtils.startOfWeek(DateTime.now());
    final sunday = DateTime(
      monday.year,
      monday.month,
      monday.day + 6,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF6E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF176B3A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This week',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dateLabel(monday)} – ${dateLabel(sunday)}',
                        style: const TextStyle(
                          color: Color(0xFF536458),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder<List<PurchaseRecord>>(
              stream: purchasesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'Unable to load spending. '
                    'Check your connection and try again.',
                  );
                }

                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                final spentPence = SpendingUtils.weeklyTotalPence(
                  snapshot.data!,
                  monday,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Total spent',
                      style: TextStyle(
                        color: Color(0xFF536458),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      money(spentPence),
                      style: const TextStyle(
                        fontSize: 38,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF123C25),
                      ),
                    ),
                    const SizedBox(height: 20),
                    budgetDetails(spentPence),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Open Budget for daily spending and purchase details.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF536458),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}