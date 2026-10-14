import 'package:flutter_test/flutter_test.dart';
import 'package:faithful_pantry/models/purchase_record.dart';
import 'package:faithful_pantry/utils/spending_utils.dart';

PurchaseRecord purchase({
  required String id,
  required String date,
  int quantity = 1,
  int unitPricePence = 100,
}) {
  return PurchaseRecord(
    id: id,
    pantryItemId: id,
    name: 'Test item',
    category: 'Other',
    purchasedQuantity: quantity,
    unitPricePence: unitPricePence,
    purchaseDate: date,
  );
}

void main() {
  final selectedDate = DateTime(2026, 10, 14);

  group('Weekly spending', () {
    test('Finds Monday from a date containing a time', () {
      expect(
        SpendingUtils.startOfWeek(DateTime(2026, 10, 14, 18, 30)),
        DateTime(2026, 10, 12),
      );
    });

    test('Includes Monday and Sunday, excludes adjacent weeks', () {
      final records = [
        purchase(id: 'before', date: '2026-10-11'),
        purchase(id: 'monday', date: '2026-10-12'),
        purchase(id: 'sunday', date: '2026-10-18'),
        purchase(id: 'after', date: '2026-10-19'),
      ];

      final included = SpendingUtils.purchasesForWeek(
        records,
        selectedDate,
      );

      expect(
        included.map((record) => record.id).toList(),
        ['sunday', 'monday'],
      );
      expect(
        SpendingUtils.weeklyTotalPence(records, selectedDate),
        200,
      );
    });

    test('Total matches the hand calculation of £4.60', () {
      final records = [
        purchase(
          id: 'yoghurts',
          date: '2026-10-14',
          quantity: 3,
          unitPricePence: 120,
        ),
        purchase(
          id: 'bread',
          date: '2026-10-14',
          unitPricePence: 100,
        ),
      ];

      expect(
        SpendingUtils.weeklyTotalPence(records, selectedDate),
        460,
      );
    });

    test('Daily totals include seven days and add to weekly total', () {
      final records = [
        purchase(
          id: 'monday',
          date: '2026-10-12',
          unitPricePence: 200,
        ),
        purchase(
          id: 'wednesday-a',
          date: '2026-10-14',
          quantity: 3,
          unitPricePence: 120,
        ),
        purchase(
          id: 'wednesday-b',
          date: '2026-10-14',
          unitPricePence: 100,
        ),
      ];

      final daily = SpendingUtils.dailyTotalsPence(
        records,
        selectedDate,
      );

      expect(daily.length, 7);
      expect(daily['2026-10-12'], 200);
      expect(daily['2026-10-13'], 0);
      expect(daily['2026-10-14'], 460);
      expect(daily['2026-10-18'], 0);

      final dailySum = daily.values.fold<int>(
        0,
        (runningTotal, amount) => runningTotal + amount,
      );

      expect(dailySum, 660);
      expect(
        dailySum,
        SpendingUtils.weeklyTotalPence(records, selectedDate),
      );
    });

    test('An empty week has zero spending', () {
      expect(
        SpendingUtils.weeklyTotalPence(
          <PurchaseRecord>[],
          selectedDate,
        ),
        0,
      );

      expect(
        SpendingUtils.dailyTotalsPence(
          <PurchaseRecord>[],
          selectedDate,
        ).values,
        everyElement(0),
      );
    });

    test('Week selection works across a year boundary', () {
      final date = DateTime(2027, 1, 1);

      expect(
        SpendingUtils.startOfWeek(date),
        DateTime(2026, 12, 28),
      );

      final records = [
        purchase(id: 'before', date: '2026-12-27'),
        purchase(id: 'monday', date: '2026-12-28'),
        purchase(id: 'sunday', date: '2027-01-03'),
        purchase(id: 'after', date: '2027-01-04'),
      ];

      expect(
        SpendingUtils.weeklyTotalPence(records, date),
        200,
      );
    });

    test('Invalid dates and invalid purchase amounts are excluded', () {
      final records = [
        purchase(id: 'valid', date: '2026-10-14'),
        purchase(id: 'bad-date', date: '2026-02-30'),
        purchase(id: 'missing-date', date: ''),
        purchase(
          id: 'bad-quantity',
          date: '2026-10-14',
          quantity: 0,
        ),
        purchase(
          id: 'bad-price',
          date: '2026-10-14',
          unitPricePence: -100,
        ),
      ];

      expect(
        SpendingUtils.purchasesForWeek(records, selectedDate)
            .map((record) => record.id)
            .toList(),
        ['valid'],
      );
    });

    test('A zero-price purchase is valid', () {
      final records = [
        purchase(
          id: 'free',
          date: '2026-10-14',
          unitPricePence: 0,
        ),
      ];

      expect(
        SpendingUtils.purchasesForWeek(records, selectedDate).length,
        1,
      );
      expect(
        SpendingUtils.weeklyTotalPence(records, selectedDate),
        0,
      );
    });
  });

  group('Remaining budget', () {
    test('Subtracts spending from the budget', () {
      expect(
        SpendingUtils.remainingBudgetPence(
          budgetPence: 1000,
          spentPence: 460,
        ),
        540,
      );
    });

    test('Preserves a negative result when over budget', () {
      expect(
        SpendingUtils.remainingBudgetPence(
          budgetPence: 1000,
          spentPence: 1250,
        ),
        -250,
      );
    });

    test('Rejects negative budget or spending inputs', () {
      expect(
        () => SpendingUtils.remainingBudgetPence(
          budgetPence: -1,
          spentPence: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SpendingUtils.remainingBudgetPence(
          budgetPence: 100,
          spentPence: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}