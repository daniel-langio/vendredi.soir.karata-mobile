import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_client/screens/signup_screen.dart';
import 'package:poker_client/utils/jwt_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SignUpScreen Tests', () {
    testWidgets('renders initial components correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: SignUpScreen(initialServerUrl: 'https://test.poker/poker'),
      ));

      expect(find.text('Sign Up / Register Player'), findsOneWidget);
      expect(find.text('Generate standard credentials and API Key'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Server Base URL'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Generate API Key'), findsOneWidget);

      // Credentials should not be shown initially
      expect(find.text('Your Generated Credentials'), findsNothing);
    });

    testWidgets('shows validation errors for empty username', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: SignUpScreen(initialServerUrl: 'https://test.poker/poker'),
      ));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Generate API Key'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a username'), findsOneWidget);
    });

    testWidgets('shows validation errors for short username', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: SignUpScreen(initialServerUrl: 'https://test.poker/poker'),
      ));

      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'ab');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Generate API Key'));
      await tester.pumpAndSettle();

      expect(find.text('Username must be at least 3 characters long'), findsOneWidget);
    });

    testWidgets('generates credentials correctly and decodes JWT successfully', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: SignUpScreen(initialServerUrl: 'https://test.poker/poker'),
      ));

      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'poker_champ');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Generate API Key'));
      await tester.pumpAndSettle();

      // Ensure credential section appears
      expect(find.text('Your Generated Credentials'), findsOneWidget);
      expect(find.text('Username:'), findsOneWidget);
      expect(find.text('poker_champ'), findsAtLeast(1));

      // Find the generated token in the SelectableText widget
      final selectableTextFinder = find.byType(SelectableText);
      expect(selectableTextFinder, findsOneWidget);
      final SelectableText selectableTextWidget = tester.widget(selectableTextFinder);
      final generatedToken = selectableTextWidget.data;

      expect(generatedToken, isNotNull);
      expect(generatedToken, isNotEmpty);

      // Decode generated token with JwtHelper to verify payload content
      final decoded = JwtHelper.decode(generatedToken!);
      expect(decoded, isNotNull);
      expect(decoded!['username'], 'poker_champ');
      expect(decoded['playerId'], isNotNull);

      // Verify buttons are rendered
      expect(find.text('Copy Token to Clipboard'), findsOneWidget);
      expect(find.text('Use on Config'), findsOneWidget);
      expect(find.text('Proceed to Lobby'), findsOneWidget);
    });
  });
}
