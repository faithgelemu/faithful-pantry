import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faithful_pantry/main.dart';

Widget testApp() {
  return MaterialApp(
    home: HomeScreen(
      testPages: const [
        Text('Test home page'),
        Text('Test add grocery page'),
        Text('Test budget page'),
        Text('Test profile page'),
      ],
      dashboardBuilder: (openPantry, openAlerts) {
        return Column(
          children: [
            const Text('Test home page'),
            TextButton(
              onPressed: openPantry,
              child: const Text('Open pantry'),
            ),
            TextButton(
              onPressed: openAlerts,
              child: const Text('Open alerts'),
            ),
          ],
        );
      },
      detailBuilder: (detail) {
        return Text(
          detail == HomeDetail.pantry
              ? 'Test pantry detail'
              : 'Test alerts detail',
        );
      },
    ),
  );
}

void expectSelectedTab(WidgetTester tester, int index) {
  final navigationBar = tester.widget<NavigationBar>(
    find.byType(NavigationBar),
  );

  expect(navigationBar.selectedIndex, index);
}

Future<void> selectTab(
  WidgetTester tester,
  String label,
) async {
  await tester.tap(
    find.widgetWithText(NavigationDestination, label),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('The four tabs select their matching pages',
      (tester) async {
    await tester.pumpWidget(testApp());

    expect(find.text('Test home page'), findsOneWidget);
    expectSelectedTab(tester, 0);

    await selectTab(tester, 'Add');
    expect(find.text('Test add grocery page'), findsOneWidget);
    expectSelectedTab(tester, 1);

    await selectTab(tester, 'Budget');
    expect(find.text('Test budget page'), findsOneWidget);
    expectSelectedTab(tester, 2);

    await selectTab(tester, 'Profile');
    expect(find.text('Test profile page'), findsOneWidget);
    expectSelectedTab(tester, 3);

    await selectTab(tester, 'Home');
    expect(find.text('Test home page'), findsOneWidget);
    expectSelectedTab(tester, 0);
  });

  testWidgets('My Pantry opens within Home and the back arrow returns',
      (tester) async {
    await tester.pumpWidget(testApp());

    await tester.tap(find.text('Open pantry'));
    await tester.pumpAndSettle();

    expect(find.text('Test pantry detail'), findsOneWidget);
    expect(find.text('My Pantry'), findsOneWidget);
    expectSelectedTab(tester, 0);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Test home page'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('Expiry Alerts opens within Home and back returns',
      (tester) async {
    await tester.pumpWidget(testApp());

    await tester.tap(find.text('Open alerts'));
    await tester.pumpAndSettle();

    expect(find.text('Test alerts detail'), findsOneWidget);
    expect(find.text('Expiry Alerts'), findsOneWidget);
    expectSelectedTab(tester, 0);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Test home page'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('Switching tabs clears the Home detail selection',
      (tester) async {
    await tester.pumpWidget(testApp());

    await tester.tap(find.text('Open alerts'));
    await tester.pumpAndSettle();

    await selectTab(tester, 'Budget');

    expect(find.text('Test budget page'), findsOneWidget);
    expectSelectedTab(tester, 2);
    expect(find.byType(BackButton), findsNothing);

    await selectTab(tester, 'Home');

    expect(find.text('Test home page'), findsOneWidget);
    expect(find.text('Test alerts detail'), findsNothing);
    expectSelectedTab(tester, 0);
  });

  testWidgets('A navigation back request closes the detail view',
      (tester) async {
    await tester.pumpWidget(testApp());

    await tester.tap(find.text('Open pantry'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Test home page'), findsOneWidget);
    expect(find.text('Test pantry detail'), findsNothing);
    expectSelectedTab(tester, 0);
  });
}