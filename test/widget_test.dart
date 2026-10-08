import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faithful_pantry/main.dart';

void main() {
  testWidgets('The four tabs select their matching pages',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          testPages: [
            Text('Test pantry page'),
            Text('Test add grocery page'),
            Text('Test budget page'),
            Text('Test profile page'),
          ],
        ),
      ),
    );

    expect(find.text('Test pantry page'), findsOneWidget);

    Future<void> checkTab(
      String label,
      int expectedIndex,
      String pageText,
    ) async {
      await tester.tap(
        find.widgetWithText(NavigationDestination, label),
      );
      await tester.pumpAndSettle();

      expect(find.text(pageText), findsOneWidget);

      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigationBar.selectedIndex, expectedIndex);
    }

    await checkTab('Scan', 1, 'Test add grocery page');
    await checkTab('Budget', 2, 'Test budget page');
    await checkTab('Profile', 3, 'Test profile page');
    await checkTab('Home', 0, 'Test pantry page');
  });
}