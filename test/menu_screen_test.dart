import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_client/screens/menu_screen.dart';
import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Both table lists are fetched from the server, and TestWidgetsFlutterBinding answers every
  // request with a 400 - so this exercises the unreachable-server path. That is deliberate: the
  // screen must say the load failed rather than render an empty list, which would read as "you
  // have no tables" when the truth is "we could not find out".
  testWidgets(
    'MenuScreen renders identity, entry points, and both table sections',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapForTest(
          const MenuScreen(
            serverUrl: 'https://test.poker/poker',
            token: 'mock-token',
            username: 'eli',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('eli'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Create a table'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Join with a link'),
        findsOneWidget,
      );

      expect(find.text('Your tables'), findsOneWidget);
      expect(find.text('Public tables'), findsOneWidget);

      expect(find.textContaining('Could not load your tables'), findsOneWidget);
      expect(
        find.text('No tables yet. Create or join one to see it here.'),
        findsNothing,
        reason: 'a failed load must not be reported as an empty list',
      );
    },
  );
}
