import 'dart:async';

import 'package:flutter/widgets.dart';

mixin DayRefreshMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  Timer? _dayTimer;
  late DateTime _lastCheckedDay;
  DateTime get currentDateTime => DateTime.now();

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  void initState() {
    super.initState();

    _lastCheckedDay = _dateOnly(currentDateTime);
    WidgetsBinding.instance.addObserver(this);

    _dayTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkDay(),
    );
  }

  void _checkDay() {
    if (!mounted) return;

    final currentDay = _dateOnly(currentDateTime);

    if (currentDay == _lastCheckedDay) return;

    final previousDay = _lastCheckedDay;
    _lastCheckedDay = currentDay;

    setState(() {
      onCalendarDayChanged(previousDay, currentDay);
    });
  }

  // Screens can override this if they need to adjust a selected week.
  void onCalendarDayChanged(
    DateTime previousDay,
    DateTime currentDay,
  ) {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDay();
    }
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}