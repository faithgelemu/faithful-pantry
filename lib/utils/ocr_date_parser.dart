class OcrDateSuggestion {
  const OcrDateSuggestion({
    required this.date,
    required this.originalText,
    required this.assumedYear,
  });

  final DateTime date;
  final String originalText;
  final bool assumedYear;
}

class OcrDateParser {
  static const _months = {
    'JAN': 1,
    'FEB': 2,
    'MAR': 3,
    'APR': 4,
    'MAY': 5,
    'JUN': 6,
    'JUL': 7,
    'AUG': 8,
    'SEP': 9,
    'OCT': 10,
    'NOV': 11,
    'DEC': 12,
  };

  static List<OcrDateSuggestion> findDates(
    String text, {
    DateTime? today,
  }) {
    final currentYear = (today ?? DateTime.now()).year;
    final suggestions = <OcrDateSuggestion>[];
    final seenDates = <String>{};
    final acceptedMatches = <Match>[];

    void addDate({
      required int day,
      required int month,
      required int year,
      required Match match,
      required bool assumedYear,
    }) {
      // Do not interpret part of an already recognised date again.
      final overlaps = acceptedMatches.any(
        (previous) =>
            match.start < previous.end &&
            match.end > previous.start,
      );

      if (overlaps) return;

      if (year < 2000 || year > 2100) return;
      if (month < 1 || month > 12 || day < 1 || day > 31) return;

      final date = DateTime(year, month, day);

      // Reject impossible dates instead of accepting normalisation.
      if (date.year != year ||
          date.month != month ||
          date.day != day) {
        return;
      }

      acceptedMatches.add(match);

      final key = '$year-$month-$day';
      if (!seenDates.add(key)) return;

      suggestions.add(
        OcrDateSuggestion(
          date: date,
          originalText: match.group(0)!,
          assumedYear: assumedYear,
        ),
      );
    }

    final isoPattern = RegExp(
      r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b',
    );

    for (final match in isoPattern.allMatches(text)) {
      addDate(
        year: int.parse(match.group(1)!),
        month: int.parse(match.group(2)!),
        day: int.parse(match.group(3)!),
        match: match,
        assumedYear: false,
      );
    }

    final numericPattern = RegExp(
      r'\b(\d{1,2})([/.-])(\d{1,2})\2(\d{4}|\d{2})\b',
    );

    for (final match in numericPattern.allMatches(text)) {
      final yearText = match.group(4)!;

      addDate(
        day: int.parse(match.group(1)!),
        month: int.parse(match.group(3)!),
        year: _readYear(yearText, currentYear),
        match: match,
        assumedYear: false,
      );
    }

    const monthNames =
        r'JAN(?:UARY)?|FEB(?:RUARY)?|MAR(?:CH)?|APR(?:IL)?|'
        r'MAY|JUN(?:E)?|JUL(?:Y)?|AUG(?:UST)?|'
        r'SEP(?:TEMBER|T)?|OCT(?:OBER)?|NOV(?:EMBER)?|DEC(?:EMBER)?';

    final dayFirstPattern = RegExp(
      r'\b(\d{1,2})[\s-]+(' +
          monthNames +
          r')(?:[\s,-]+(\d{4}|\d{2})\b)?\b',
      caseSensitive: false,
    );

    for (final match in dayFirstPattern.allMatches(text)) {
      final yearText = match.group(3);
      final monthText = match.group(2)!.toUpperCase();

      addDate(
        day: int.parse(match.group(1)!),
        month: _months[monthText.substring(0, 3)]!,
        year: _readYear(yearText, currentYear),
        match: match,
        assumedYear: yearText == null,
      );
    }

    final monthFirstPattern = RegExp(
      r'\b(' +
          monthNames +
          r')[\s-]+(\d{1,2})\b(?:[\s,-]+(\d{4}|\d{2})\b)?',
      caseSensitive: false,
    );

    for (final match in monthFirstPattern.allMatches(text)) {
      final yearText = match.group(3);
      final monthText = match.group(1)!.toUpperCase();

      addDate(
        day: int.parse(match.group(2)!),
        month: _months[monthText.substring(0, 3)]!,
        year: _readYear(yearText, currentYear),
        match: match,
        assumedYear: yearText == null,
      );
    }

    return suggestions;
  }

  static int _readYear(String? value, int currentYear) {
    if (value == null) return currentYear;

    final year = int.parse(value);
    return value.length == 2 ? 2000 + year : year;
  }
}