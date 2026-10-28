import 'package:flutter_test/flutter_test.dart';
import 'package:faithful_pantry/utils/ocr_date_parser.dart';

void main() {
  final today = DateTime(2026, 10, 28);

  List<OcrDateSuggestion> parse(String text) {
    return OcrDateParser.findDates(text, today: today);
  }

  test('Reads UK numeric dates with different separators', () {
    for (final text in [
      '28/10/2026',
      '28-10-2026',
      '28.10.2026',
    ]) {
      final results = parse(text);

      expect(results, hasLength(1));
      expect(results.single.date, DateTime(2026, 10, 28));
      expect(results.single.assumedYear, isFalse);
    }
  });

  test('Reads ISO year month day', () {
    final results = parse('2026-10-28');

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2026, 10, 28));
  });

  test('Reads a two digit year as 2000 onwards', () {
    final results = parse('28/10/27');

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2027, 10, 28));
    expect(results.single.assumedYear, isFalse);
  });

  test('Uses current year for OCT 12 and 12 OCT', () {
    for (final text in ['OCT 12', '12 OCT']) {
      final results = parse(text);

      expect(results, hasLength(1));
      expect(results.single.date, DateTime(2026, 10, 12));
      expect(results.single.assumedYear, isTrue);
    }
  });

  test('Reads full month names and explicit years', () {
    for (final text in [
      '12 October 2027',
      'October 12, 2027',
      '12-OCT-27',
    ]) {
      final results = parse(text);

      expect(results, hasLength(1));
      expect(results.single.date, DateTime(2027, 10, 12));
      expect(results.single.assumedYear, isFalse);
    }
  });

  test('Keeps a past date in the assumed current year', () {
    final results = parse('JAN 5');

    expect(results.single.date, DateTime(2026, 1, 5));
    expect(results.single.date.isBefore(today), isTrue);
  });

  test('Rejects impossible dates', () {
    for (final text in [
      '31/04/2026',
      '29/02/2026',
      '2026-13-10',
      '31 NOV 2026',
    ]) {
      expect(parse(text), isEmpty, reason: text);
    }
  });

  test('Accepts a valid leap day', () {
    final results = parse('29/02/2028');

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2028, 2, 29));
  });

  test('Does not invent a day for a month and year', () {
    expect(parse('Best before OCT 2026'), isEmpty);
  });

  test('Returns multiple dates for the user to review', () {
    final results = parse(
      'Packed 20/10/2026. Use by 28/10/2026.',
    );

    expect(results, hasLength(2));
    expect(
      results.map((result) => result.date),
      containsAll([
        DateTime(2026, 10, 20),
        DateTime(2026, 10, 28),
      ]),
    );
  });

  test('Does not repeat the same calendar date', () {
    final results = parse('28/10/2026 and 28 OCT 2026');

    expect(results, hasLength(1));
  });

  test('Uses UK interpretation for ambiguous numeric dates', () {
    final results = parse('03/04/26');

    expect(results.single.date, DateTime(2026, 4, 3));
  });
}