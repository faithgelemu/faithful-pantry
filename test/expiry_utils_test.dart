import 'package:flutter_test/flutter_test.dart';
import 'package:faithful_pantry/utils/expiry_utils.dart';

void main() {
  final today = DateTime(2026, 10, 14);

  group('Expiry date classification', () {
    test('Yesterday is expired', () {
      expect(
        ExpiryUtils.daysUntil('2026-10-13', today: today),
        -1,
      );
      expect(
        ExpiryUtils.statusFor('2026-10-13', today: today),
        ExpiryStatus.expired,
      );
    });

    test('Today is expiring soon', () {
      expect(
        ExpiryUtils.daysUntil('2026-10-14', today: today),
        0,
      );
      expect(
        ExpiryUtils.statusFor('2026-10-14', today: today),
        ExpiryStatus.expiringSoon,
      );
    });

    test('Tomorrow is expiring soon', () {
      expect(
        ExpiryUtils.daysUntil('2026-10-15', today: today),
        1,
      );
      expect(
        ExpiryUtils.statusFor('2026-10-15', today: today),
        ExpiryStatus.expiringSoon,
      );
    });

    test('Three days ahead is included in expiring soon', () {
      expect(
        ExpiryUtils.daysUntil('2026-10-17', today: today),
        3,
      );
      expect(
        ExpiryUtils.statusFor('2026-10-17', today: today),
        ExpiryStatus.expiringSoon,
      );
    });

    test('Four days ahead is later', () {
      expect(
        ExpiryUtils.daysUntil('2026-10-18', today: today),
        4,
      );
      expect(
        ExpiryUtils.statusFor('2026-10-18', today: today),
        ExpiryStatus.later,
      );
    });

    test('Missing, malformed and impossible dates are unknown', () {
      for (final value in ['', 'not-a-date', '2026-02-30']) {
        expect(
          ExpiryUtils.daysUntil(value, today: today),
          isNull,
        );
        expect(
          ExpiryUtils.statusFor(value, today: today),
          ExpiryStatus.unknown,
        );
      }
    });

    test('Calendar-day difference works across a year boundary', () {
      expect(
        ExpiryUtils.daysUntil(
          '2027-01-01',
          today: DateTime(2026, 12, 31, 23, 30),
        ),
        1,
      );
    });
  });
}