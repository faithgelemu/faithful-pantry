enum ExpiryStatus {
  expired,
  expiringSoon,
  later,
  unknown,
}

class ExpiryUtils {
  static const int soonThresholdDays = 3;

  static DateTime? parseDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }

    final date = DateTime.tryParse(value);

    // Reject invalid dates that Dart might otherwise roll forward.
    if (date == null ||
        date.toIso8601String().substring(0, 10) != value) {
      return null;
    }

    return date;
  }

  static int? daysUntil(
    String expiryDate, {
    DateTime? today,
  }) {
    final expiry = parseDate(expiryDate);
    if (expiry == null) return null;

    final current = today ?? DateTime.now();

    // Compare calendar days without daylight-saving time differences.
    final currentDay = DateTime.utc(
      current.year,
      current.month,
      current.day,
    );

    final expiryDay = DateTime.utc(
      expiry.year,
      expiry.month,
      expiry.day,
    );

    return expiryDay.difference(currentDay).inDays;
  }

  static ExpiryStatus statusFor(
    String expiryDate, {
    DateTime? today,
  }) {
    final days = daysUntil(expiryDate, today: today);

    if (days == null) return ExpiryStatus.unknown;
    if (days < 0) return ExpiryStatus.expired;
    if (days <= soonThresholdDays) {
      return ExpiryStatus.expiringSoon;
    }

    return ExpiryStatus.later;
  }
}