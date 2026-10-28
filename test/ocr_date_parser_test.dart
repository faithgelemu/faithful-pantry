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

      expect(results, hasLength(1), reason: text);
      expect(results.single.date, DateTime(2026, 10, 28));
      expect(results.single.assumedYear, isFalse);
      expect(results.single.assumedDay, isFalse);
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

      expect(results, hasLength(1), reason: text);
      expect(results.single.date, DateTime(2026, 10, 12));
      expect(results.single.assumedYear, isTrue);
      expect(results.single.assumedDay, isFalse);
    }
  });

  test('Reads full month names and explicit years', () {
    for (final text in [
      '12 October 2027',
      'October 12, 2027',
      '12-OCT-27',
    ]) {
      final results = parse(text);

      expect(results, hasLength(1), reason: text);
      expect(results.single.date, DateTime(2027, 10, 12));
      expect(results.single.assumedYear, isFalse);
    }
  });

  test('Keeps a past date in the assumed current year', () {
    final results = parse('JAN 5');

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2026, 1, 5));
    expect(results.single.date.isBefore(today), isTrue);
    expect(results.single.assumedYear, isTrue);
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

  test('Month and year explicitly marks the assumed last day', () {
    final results = parse('Best before OCT 2026');

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2026, 10, 31));
    expect(results.single.assumedDay, isTrue);
    expect(results.single.assumedYear, isFalse);
    expect(results.single.label, 'Best before');
  });

  test('Excludes packed date and retains use-by date', () {
    final results = parse(
      'Packed 20/10/2026. Use by 28/10/2026.',
    );

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2026, 10, 28));
    expect(results.single.label, 'Use by');
  });

  test('Keeps multiple unlabelled dates for review', () {
    final results = parse(
      '20/10/2026 and 28/10/2026',
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

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2026, 4, 3));
  });

  test('Reads the spaced date from the wrap packaging', () {
    final results = parse(
      'Best before:\n14 11 26\n6283 01:24 T9',
    );

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2026, 11, 14));
    expect(results.single.label, 'Best before');
    expect(results.single.assumedDay, isFalse);
    expect(results.single.assumedYear, isFalse);
  });

  test('Reads the rice month and year without using the time', () {
    final results = parse(
      'BEST BEFORE END\nSEP 2028 20:27\nWF6266C',
    );

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2028, 9, 30));
    expect(results.single.assumedDay, isTrue);
    expect(results.single.assumedYear, isFalse);
    expect(results.single.label, 'Best before end');
  });

  test('Reads numeric month and year from packaging', () {
    final results = parse(
      'BEST BEFORE END\n05/2027\n6232B204 21:10',
    );

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2027, 5, 31));
    expect(results.single.assumedDay, isTrue);
    expect(results.single.assumedYear, isFalse);
  });

  test('Reads short month and year with best-before wording', () {
    for (final text in [
      'BB: 05 27',
      'BB 05 27',
      'BBE: 05/27',
      'Best before end 05 27',
    ]) {
      final results = parse(text);

      expect(results, hasLength(1), reason: text);
      expect(results.single.date, DateTime(2027, 5, 31));
      expect(results.single.assumedDay, isTrue);
      expect(results.single.assumedYear, isFalse);
    }
  });

  test('Does not guess an unlabelled short numeric pair', () {
    expect(parse('05 27'), isEmpty);
  });

  test('Reads BB date with a written month and explicit year', () {
    final results = parse('BB: 27 MAR 27');

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2027, 3, 27));
    expect(results.single.label, 'Best before');
    expect(results.single.assumedDay, isFalse);
    expect(results.single.assumedYear, isFalse);
  });

  test('Reads a joined day month and year', () {
    final results = parse('BB: 27MAR27');

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2027, 3, 27));
    expect(results.single.assumedYear, isFalse);
  });

  test('Excludes manufacturing date beside a best-before date', () {
    final results = parse(
      'MFG: 12/03/2026\nBB: 12/03/2027',
    );

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2027, 3, 12));
    expect(results.single.label, 'Best before');
  });

  test('Does not treat times and batch codes as dates', () {
    expect(
      parse('20:27 WF6266C 6232B204 21:10'),
      isEmpty,
    );
  });

  test('Month-end calculation handles leap years', () {
    final results = parse('BBE FEB 2028');

    expect(results, hasLength(1));
    expect(results.single.date, DateTime(2028, 2, 29));
    expect(results.single.assumedDay, isTrue);
  });

  test('Does not supply a missing day for a use-by date', () {
    expect(parse('Use by SEP 2028'), isEmpty);
  });
}