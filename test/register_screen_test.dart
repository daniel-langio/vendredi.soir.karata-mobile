import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/screens/register_screen.dart';
import 'package:poker_client/widgets/common/karata_button.dart';
import 'test_helpers.dart';

void main() {
  group('RegisterScreen validation', () {
    testWidgets('renders the form', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapForTest(
          const RegisterScreen(serverUrl: 'https://test.poker/poker'),
        ),
      );
      await tester.pump();

      expect(find.text('Create account'), findsWidgets);
      expect(fieldLabelled('Username'), findsOneWidget);
      expect(fieldLabelled('Password'), findsOneWidget);
    });

    testWidgets('rejects a too-short username without making a network call', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          const RegisterScreen(serverUrl: 'https://test.poker/poker'),
        ),
      );
      await tester.pump();

      await tester.enterText(fieldLabelled('Username'), 'ab');
      await tester.enterText(fieldLabelled('Password'), 'longenough');
      await tester.tap(find.widgetWithText(KarataButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('At least 3 characters'), findsOneWidget);
    });

    testWidgets('rejects a too-short password without making a network call', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          const RegisterScreen(serverUrl: 'https://test.poker/poker'),
        ),
      );
      await tester.pump();

      await tester.enterText(fieldLabelled('Username'), 'poker_champ');
      await tester.enterText(fieldLabelled('Password'), '123');
      await tester.tap(find.widgetWithText(KarataButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('At least 6 characters'), findsOneWidget);
    });

    testWidgets('shows a banner naming the promo code that will be applied', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          const RegisterScreen(
            serverUrl: 'https://test.poker/poker',
            promoCode: 'EARLY-USER-2026',
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('EARLY-USER-2026'), findsOneWidget);
    });

    testWidgets('shows no promo banner when no promo code was given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          const RegisterScreen(serverUrl: 'https://test.poker/poker'),
        ),
      );
      await tester.pump();

      expect(find.textContaining('will be applied'), findsNothing);
    });
  });
}
