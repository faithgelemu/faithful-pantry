import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faithful_pantry/main.dart';

void main() {
  testWidgets('The four navigation tabs open their screens',
      (WidgetTester tester) async {
    await tester.pumpWidget(
  const MaterialApp(
    home: HomeScreen(),
  ),
);
    expect(
      find.text('Welcome to Faithful Pantry'),
      findsOneWidget,
    );

    await tester.tap(
      find.widgetWithText(NavigationDestination, 'Scan'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add your groceries'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(NavigationDestination, 'Budget'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Understand your spending'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(NavigationDestination, 'Profile'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your profile'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(NavigationDestination, 'Home'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Welcome to Faithful Pantry'),
      findsOneWidget,
    );
  });
}