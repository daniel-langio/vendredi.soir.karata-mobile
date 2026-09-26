import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/screens/login_screen.dart';
import 'package:poker_client/widgets/common/karata_button.dart';
import 'test_helpers.dart';

void main() {
  group('LoginScreen validation', () {
    testWidgets('renders the form', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapForTest(const LoginScreen(serverUrl: 'https://test.poker/poker')),
      );
      await tester.pump();

      expect(find.text('Log in'), findsWidgets);
      expect(fieldLabelled('Username'), findsOneWidget);
      expect(fieldLabelled('Password'), findsOneWidget);
    });

    testWidgets('rejects empty fields without making a network call', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(const LoginScreen(serverUrl: 'https://test.poker/poker')),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(KarataButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsWidgets);
    });
  });
}
