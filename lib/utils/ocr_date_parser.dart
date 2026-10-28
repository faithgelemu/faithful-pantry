class OcrDateSuggestion {
  const OcrDateSuggestion({
    required this.date,
    required this.originalText,
    required this.assumedYear,
    this.assumedDay = false,
    this.label = 'Date',
  });

  final DateTime date;
  final String originalText;
  final bool assumedYear;
  final bool assumedDay;
  final String label;
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

  static const _monthNames =
      r'JAN(?:UARY)?|FEB(?:RUARY)?|MAR(?:CH)?|APR(?:IL)?|'
      r'MAY|JUN(?:E)?|JUL(?:Y)?|AUG(?:UST)?|'
      r'SEP(?:TEMBER|T)?|OCT(?:OBER)?|NOV(?:EMBER)?|DEC(?:EMBER)?';

  static final _labelPattern = RegExp(
    r'\b(BEST[\s-]+BEFORE(?:[\s-]+END)?|'
    r'USE[\s-]+BY|'
    r'BBE|BB|'
    r'EXP(?:IRY|IRATION)?(?:[\s-]+DATE)?|'
    r'MFG|MFD|MANUFACTURED(?:[\s-]+ON)?|'
    r'MANUFACTUR(?:E|ING)[\s-]+DATE|'
    r'PRODUCTION(?:[\s-]+DATE)?|'
    r'PROD(?:[\s-]+DATE)?|'
    r'PACKED(?:[\s-]+ON)?|'
    r'PACKAGING[\s-]+DATE|'
    r'FROZEN[\s-]+ON|'
    r'SELL[\s-]+BY|DISPLAY[\s-]+UNTIL)\b',
    caseSensitive: false,
  );

  static List<OcrDateSuggestion> findDates(
    String text, {
    DateTime? today,
  }) {
    final currentYear = (today ?? DateTime.now()).year;
    final suggestions = <OcrDateSuggestion>[];
    final occupied = <Match>[];

    bool overlaps(Match match) {
      return occupied.any(
        (previous) =>
            match.start < previous.end &&
            match.end > previous.start,
      );
    }

    void addDate({
      required Match match,
      required int month,
      required int year,
      int? day,
      bool assumedYear = false,
      bool requireBestBefore = false,
    }) {
      if (overlaps(match)) return;

      // Reserve the whole match even when invalid. This prevents
      // interpreting a smaller part of an invalid date as another date.
      occupied.add(match);

      final label = _labelFor(text, match.start);

      if (label == 'Ignore') return;

      if (requireBestBefore &&
          label != 'Best before' &&
          label != 'Best before end') {
        return;
      }

      if (year < 2000 || year > 2100) return;
      if (month < 1 || month > 12) return;

      // A use-by date needs a printed day.
      if (day == null && label == 'Use by') return;

      final assumedDay = day == null;
      final resolvedDay =
          day ?? DateTime(year, month + 1, 0).day;

      if (resolvedDay < 1 || resolvedDay > 31) return;

      final date = DateTime(year, month, resolvedDay);

      if (date.year != year ||
          date.month != month ||
          date.day != resolvedDay) {
        return;
      }

      suggestions.add(
        OcrDateSuggestion(
          date: date,
          originalText: match.group(0)!,
          assumedYear: assumedYear,
          assumedDay: assumedDay,
          label: label,
        ),
      );
    }

    // Full dates are processed before partial dates.
    final isoPattern = RegExp(
      r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b',
    );

    for (final match in isoPattern.allMatches(text)) {
      addDate(
        match: match,
        year: int.parse(match.group(1)!),
        month: int.parse(match.group(2)!),
        day: int.parse(match.group(3)!),
      );
    }

    final numericPattern = RegExp(
      r'\b(\d{1,2})([/.-])(\d{1,2})\2(\d{4}|\d{2})\b',
    );

    for (final match in numericPattern.allMatches(text)) {
      addDate(
        match: match,
        day: int.parse(match.group(1)!),
        month: int.parse(match.group(3)!),
        year: _readYear(match.group(4)!, currentYear),
      );
    }

    final spacedNumericPattern = RegExp(
      r'\b(\d{1,2})[ \t]+(\d{1,2})[ \t]+(\d{4}|\d{2})\b',
    );

    for (final match in spacedNumericPattern.allMatches(text)) {
      addDate(
        match: match,
        day: int.parse(match.group(1)!),
        month: int.parse(match.group(2)!),
        year: _readYear(match.group(3)!, currentYear),
      );
    }

    final dayFirstPattern = RegExp(
      r'\b(\d{1,2})[ \t-]*(' +
          _monthNames +
          r')(?:[ \t,-]*(\d{4}|\d{2}))?\b',
      caseSensitive: false,
    );

    for (final match in dayFirstPattern.allMatches(text)) {
      final yearText = match.group(3);

      addDate(
        match: match,
        day: int.parse(match.group(1)!),
        month: _monthNumber(match.group(2)!),
        year: _readYear(yearText, currentYear),
        assumedYear: yearText == null,
      );
    }

    final monthFirstFullPattern = RegExp(
      r'\b(' +
          _monthNames +
          r')[ \t-]*(\d{1,2})[ \t,-]+(\d{4}|\d{2})\b',
      caseSensitive: false,
    );

    for (final match in monthFirstFullPattern.allMatches(text)) {
      addDate(
        match: match,
        month: _monthNumber(match.group(1)!),
        day: int.parse(match.group(2)!),
        year: _readYear(match.group(3)!, currentYear),
      );
    }

    // Examples: SEP 2028, SEP2028.
    final namedMonthYearPattern = RegExp(
      r'\b(' + _monthNames + r')[ \t/-]*(\d{4})\b',
      caseSensitive: false,
    );

    for (final match in namedMonthYearPattern.allMatches(text)) {
      addDate(
        match: match,
        month: _monthNumber(match.group(1)!),
        year: int.parse(match.group(2)!),
      );
    }

    // Examples: 05/2027, 05 2027.
    final numericMonthYearPattern = RegExp(
      r'\b(\d{1,2})[/. \t-]+(\d{4})\b',
    );

    for (final match in numericMonthYearPattern.allMatches(text)) {
      addDate(
        match: match,
        month: int.parse(match.group(1)!),
        year: int.parse(match.group(2)!),
      );
    }

    // BBE MAR 27 means March 2027.
    // Without BBE wording, MAR 27 remains 27 March,
    // with the current year assumed.
    final shortNamedPattern = RegExp(
      r'\b(' + _monthNames + r')[ \t/-]*(\d{2})\b',
      caseSensitive: false,
    );

    for (final match in shortNamedPattern.allMatches(text)) {
      final label = _labelFor(text, match.start);
      final value = int.parse(match.group(2)!);

      if (label == 'Best before end') {
        addDate(
          match: match,
          month: _monthNumber(match.group(1)!),
          year: 2000 + value,
        );
      } else {
        addDate(
          match: match,
          month: _monthNumber(match.group(1)!),
          day: value,
          year: currentYear,
          assumedYear: true,
        );
      }
    }

    // Month-first dates with a one-digit day.
    final monthFirstShortPattern = RegExp(
      r'\b(' + _monthNames + r')[ \t-]+(\d)\b',
      caseSensitive: false,
    );

    for (final match in monthFirstShortPattern.allMatches(text)) {
      addDate(
        match: match,
        month: _monthNumber(match.group(1)!),
        day: int.parse(match.group(2)!),
        year: currentYear,
        assumedYear: true,
      );
    }

    // Short numeric month/year needs best-before wording.
    // Examples: BB: 05 27, BBE 05/27.
    final shortNumericMonthYearPattern = RegExp(
      r'\b(\d{1,2})[/. \t-]+(\d{2})\b',
    );

    for (final match
        in shortNumericMonthYearPattern.allMatches(text)) {
      addDate(
        match: match,
        month: int.parse(match.group(1)!),
        year: _readYear(match.group(2)!, currentYear),
        requireBestBefore: true,
      );
    }

    // Keep distinct label/assumption information when removing duplicates.
    final seen = <String>{};

    return suggestions.where((suggestion) {
      final key = '${suggestion.date.year}-'
          '${suggestion.date.month}-'
          '${suggestion.date.day}-'
          '${suggestion.label}-'
          '${suggestion.assumedYear}-'
          '${suggestion.assumedDay}';

      return seen.add(key);
    }).toList();
  }

  static int _monthNumber(String value) {
    return _months[value.toUpperCase().substring(0, 3)]!;
  }

  static int _readYear(String? value, int currentYear) {
    if (value == null) return currentYear;

    final year = int.parse(value);
    return value.length == 2 ? 2000 + year : year;
  }

  static String _labelFor(String text, int dateStart) {
    final precedingText = text.substring(0, dateStart);

    final matches = _labelPattern.allMatches(precedingText).toList();

    if (matches.isEmpty) return 'Date';

    final match = matches.last;
    final gap = precedingText.substring(match.end);

    // Only associate nearby wording: the same line or the line above.
    if (gap.length > 80 || '\n'.allMatches(gap).length > 1) {
      return 'Date';
    }

    // A reference such as "see base" does not identify a nearby
    // production date as the best-before date.
    if (RegExp(r'\bSEE\b', caseSensitive: false).hasMatch(gap)) {
      return 'Date';
    }

    final wording = match.group(0)!
        .toUpperCase()
        .replaceAll(RegExp(r'[\s-]+'), ' ');

    if (wording == 'BBE' || wording == 'BEST BEFORE END') {
      return 'Best before end';
    }

    if (wording == 'BB' || wording == 'BEST BEFORE') {
      return 'Best before';
    }

    if (wording == 'USE BY') return 'Use by';

    if (wording.startsWith('EXP')) return 'Expiry';

    return 'Ignore';
  }
}