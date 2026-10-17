import 'package:flutter_test/flutter_test.dart';
import 'package:faithful_pantry/utils/spending_utils.dart';

void main() {
  group('Budget week rollover', () {
    test('Current-week view advances from Sunday to Monday', () {
      final result = SpendingUtils.weekAfterDayChange(
        selectedWeek: DateTime(2026, 10, 12),
        previousDay: DateTime(2026, 10, 18),
        currentDay: DateTime(2026, 10, 19),
      );

      expect(result, DateTime(2026, 10, 19));
    });

    test('A deliberately selected older week stays selected', () {
      final result = SpendingUtils.weekAfterDayChange(
        selectedWeek: DateTime(2026, 9, 21),
        previousDay: DateTime(2026, 10, 18),
        currentDay: DateTime(2026, 10, 19),
      );

      expect(result, DateTime(2026, 9, 21));
    });

    test('A day change within the same week keeps its Monday', () {
      final result = SpendingUtils.weekAfterDayChange(
        selectedWeek: DateTime(2026, 10, 12),
        previousDay: DateTime(2026, 10, 14),
        currentDay: DateTime(2026, 10, 15),
      );

      expect(result, DateTime(2026, 10, 12));
    });

    test('Current-week view follows after several weeks away', () {
      final result = SpendingUtils.weekAfterDayChange(
        selectedWeek: DateTime(2026, 10, 12),
        previousDay: DateTime(2026, 10, 14),
        currentDay: DateTime(2026, 11, 3),
      );

      expect(result, DateTime(2026, 11, 2));
    });

    test('Current-week view advances across a year boundary', () {
      final result = SpendingUtils.weekAfterDayChange(
        selectedWeek: DateTime(2026, 12, 28),
        previousDay: DateTime(2027, 1, 3),
        currentDay: DateTime(2027, 1, 4),
      );

      expect(result, DateTime(2027, 1, 4));
    });
  });
}