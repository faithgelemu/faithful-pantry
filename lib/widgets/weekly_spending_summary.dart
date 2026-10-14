import 'package:flutter/material.dart';

import '../models/purchase_record.dart';
import '../services/pantry_service.dart';
import '../services/settings_service.dart';
import '../utils/spending_utils.dart';
import '../utils/day_refresh_mixin.dart';

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This week',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text('${dateLabel(monday)} – ${dateLabel(sunday)}'),
            const SizedBox(height: 12),
            StreamBuilder<List<PurchaseRecord>>(
              stream: purchasesStream,
              builder: (context, purchaseSnapshot) {
                if (purchaseSnapshot.hasError) {
                  return const Text(
                    'Unable to load spending. '
                    'Check your connection and try again.',
                  );
                }

                if (!purchaseSnapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                final spentPence = SpendingUtils.weeklyTotalPence(
                  purchaseSnapshot.data!,
                  monday,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent: ${money(spentPence)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<int?>(
                      stream: budgetStream,
                      builder: (context, budgetSnapshot) {
                        if (budgetSnapshot.hasError) {
                          return const Text(
                            'Unable to load your budget setting.',
                          );
                        }

                        if (budgetSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            budgetSnapshot.connectionState ==
                                ConnectionState.none) {
                          return const LinearProgressIndicator();
                        }

                        final budgetPence = budgetSnapshot.data;

                        if (budgetPence == null) {
                          return const Text(
                            'No weekly budget set. '
                            'Set one in the Budget tab.',
                          );
                        }

                        final remainingPence =
                            SpendingUtils.remainingBudgetPence(
                          budgetPence: budgetPence,
                          spentPence: spentPence,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Weekly limit: ${money(budgetPence)}'),
                            const SizedBox(height: 6),
                            Text(
                              remainingPence < 0
                                  ? 'Over budget by '
                                      '${money(-remainingPence)}'
                                  : 'Remaining: ${money(remainingPence)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: remainingPence < 0
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Open Budget for daily spending and purchase details.',
            ),
          ],
        ),
      ),
    );
  }
}