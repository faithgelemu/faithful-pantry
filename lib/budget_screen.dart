import 'package:flutter/material.dart';

import 'models/purchase_record.dart';
import 'services/pantry_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final service = PantryService();
  Stream<List<PurchaseRecord>>? purchasesStream;

  late final DateTime currentWeekStart;
  late DateTime weekStart;

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();

    currentWeekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    weekStart = currentWeekStart;

    try {
      purchasesStream = service.watchPurchases();
    } on StateError {
      purchasesStream = null;
    }
  }

  String dateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

  @override
  Widget build(BuildContext context) {
    if (purchasesStream == null) {
      return const Center(
        child: Text('Please log in to view your spending.'),
      );
    }

    final nextWeekStart = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 7,
    );

    final weekEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 6,
    );

    final startValue = dateValue(weekStart);
    final endValue = dateValue(nextWeekStart);

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

        final purchases = snapshot.data!.where((purchase) {
          final date = DateTime.tryParse(purchase.purchaseDate);

          if (date == null ||
              purchase.purchasedQuantity < 1 ||
              purchase.unitPricePence < 0) {
            return false;
          }

          // Include Monday; exclude the following Monday.
          return purchase.purchaseDate.compareTo(startValue) >= 0 &&
              purchase.purchaseDate.compareTo(endValue) < 0;
        }).toList();

        purchases.sort(
          (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
        );

        final totalPence = purchases.fold<int>(
          0,
          (runningTotal, purchase) =>
              runningTotal + purchase.totalPricePence,
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
                const SizedBox(height: 24),
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