import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faithful_pantry/utils/day_refresh_mixin.dart';

class TestClock {
  TestClock(this.now);

  DateTime now;
}

class DayRefreshTestScreen extends StatefulWidget {
  const DayRefreshTestScreen({
    super.key,
    required this.clock,
    required this.onDayChanged,
  });

  final TestClock clock;
  final void Function(DateTime, DateTime) onDayChanged;

  @override
  State<DayRefreshTestScreen> createState() =>
      _DayRefreshTestScreenState();
}

class _DayRefreshTestScreenState
    extends State<DayRefreshTestScreen>
    with DayRefreshMixin<DayRefreshTestScreen> {
  int changes = 0;

  @override
  DateTime get currentDateTime => widget.clock.now;

  @override
  void onCalendarDayChanged(
    DateTime previousDay,
    DateTime currentDay,
  ) {
    changes++;
    widget.onDayChanged(previousDay, currentDay);
  }

  @override
  Widget build(BuildContext context) {
    return Text('Day changes: $changes');
  }
}

void main() {
  testWidgets('Time changes within the same day do not trigger refresh',
      (tester) async {
    final clock = TestClock(DateTime(2026, 10, 14, 10));
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DayRefreshTestScreen(
          clock: clock,
          onDayChanged: (_, _) {
            calls++;
          },
        ),
      ),
    );

    clock.now = DateTime(2026, 10, 14, 18);
    await tester.pump(const Duration(minutes: 1));

    expect(calls, 0);
    expect(find.text('Day changes: 0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Crossing midnight triggers one day-change refresh',
      (tester) async {
    final clock = TestClock(DateTime(2026, 10, 14, 23, 59));
    final changes = <List<DateTime>>[];

    await tester.pumpWidget(
      MaterialApp(
        home: DayRefreshTestScreen(
          clock: clock,
          onDayChanged: (previous, current) {
            changes.add([previous, current]);
          },
        ),
      ),
    );

    clock.now = DateTime(2026, 10, 15, 0, 1);
    await tester.pump(const Duration(minutes: 1));

    expect(changes.length, 1);
    expect(changes.single[0], DateTime(2026, 10, 14));
    expect(changes.single[1], DateTime(2026, 10, 15));
    expect(find.text('Day changes: 1'), findsOneWidget);

    // Another check on the same day must not repeat the callback.
    await tester.pump(const Duration(minutes: 1));
    expect(changes.length, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Resuming checks the date without waiting for the timer',
      (tester) async {
    final clock = TestClock(DateTime(2026, 10, 14));
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DayRefreshTestScreen(
          clock: clock,
          onDayChanged: (_, _) {
            calls++;
          },
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );

    clock.now = DateTime(2026, 10, 15);

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );

    await tester.pump();

    expect(calls, 1);
    expect(find.text('Day changes: 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Closing the screen cancels its timer', (tester) async {
    final clock = TestClock(DateTime(2026, 10, 14));
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DayRefreshTestScreen(
          clock: clock,
          onDayChanged: (_, _) {
            calls++;
          },
        ),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());

    clock.now = DateTime(2026, 10, 15);
    await tester.pump(const Duration(minutes: 2));

    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
}