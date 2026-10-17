import '../models/purchase_record.dart';
import 'expiry_utils.dart';

class SpendingUtils {
  static DateTime startOfWeek(DateTime date) {
    // Monday is weekday 1.
    return DateTime(
      date.year,
      date.month,
      date.day - (date.weekday - 1),
    );
  }

    static DateTime weekAfterDayChange({
    required DateTime selectedWeek,
    required DateTime previousDay,
    required DateTime currentDay,
  }) {
    final selectedMonday = startOfWeek(selectedWeek);
    final previousMonday = startOfWeek(previousDay);

    if (selectedMonday == previousMonday) {
      return startOfWeek(currentDay);
    }

    return selectedMonday;
  }

  static String dateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static List<PurchaseRecord> purchasesForWeek(
    Iterable<PurchaseRecord> purchases,
    DateTime selectedDate,
  ) {
    final monday = startOfWeek(selectedDate);
    final followingMonday = DateTime(
      monday.year,
      monday.month,
      monday.day + 7,
    );

    final start = dateValue(monday);
    final end = dateValue(followingMonday);

    final matching = purchases.where((purchase) {
      final date = ExpiryUtils.parseDate(purchase.purchaseDate);

      if (date == null ||
          purchase.purchasedQuantity < 1 ||
          purchase.unitPricePence < 0) {
        return false;
      }

      // Include this Monday and exclude the following Monday.
      return purchase.purchaseDate.compareTo(start) >= 0 &&
          purchase.purchaseDate.compareTo(end) < 0;
    }).toList();

    matching.sort(
      (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
    );

    return matching;
  }

  static int weeklyTotalPence(
    Iterable<PurchaseRecord> purchases,
    DateTime selectedDate,
  ) {
    return purchasesForWeek(purchases, selectedDate).fold<int>(
      0,
      (runningTotal, purchase) =>
          runningTotal + purchase.totalPricePence,
    );
  }

  static Map<String, int> dailyTotalsPence(
    Iterable<PurchaseRecord> purchases,
    DateTime selectedDate,
  ) {
    final monday = startOfWeek(selectedDate);

    // Include all seven days, even days with no purchases.
    final totals = <String, int>{
      for (var day = 0; day < 7; day++)
        dateValue(
          DateTime(monday.year, monday.month, monday.day + day),
        ): 0,
    };

    for (final purchase in purchasesForWeek(purchases, selectedDate)) {
      totals[purchase.purchaseDate] =
          totals[purchase.purchaseDate]! + purchase.totalPricePence;
    }

    return totals;
  }

  static int remainingBudgetPence({
    required int budgetPence,
    required int spentPence,
  }) {
    if (budgetPence < 0 || spentPence < 0) {
      throw ArgumentError('Budget and spending cannot be negative.');
    }

    return budgetPence - spentPence;
  }
}