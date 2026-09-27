import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:karata_ui/screens/menu_screen.dart';
import 'package:karata_ui/widgets/common/karata_button.dart';
import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Every list is fetched from the server, and TestWidgetsFlutterBinding answers every request
  // with a 400 - so this exercises the unreachable-server path. That is deliberate: the screen
  // must say the load failed rather than render an empty list, which would read as "you have no
  // tables" when the truth is "we could not find out".
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
      expect(find.widgetWithText(KarataButton, 'New table'), findsOneWidget);
      expect(
        find.widgetWithText(KarataButton, 'Join with link'),
        findsOneWidget,
      );

      expect(find.text('Rooms'), findsOneWidget);
      expect(find.text('Your tables'), findsOneWidget);
      expect(find.text('Public tables'), findsOneWidget);

      // The lobby opens on Rooms, so the table lists are a tab away.
      await tester.tap(find.text('Public tables'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not load your tables'), findsOneWidget);
      expect(
        find.text('No tables yet. Create or join one to see it here.'),
        findsNothing,
        reason: 'a failed load must not be reported as an empty list',
      );
    },
  );
}
