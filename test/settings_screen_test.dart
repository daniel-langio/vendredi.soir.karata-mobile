import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_client/chip_display.dart';
import 'package:poker_client/screens/settings_screen.dart';
import 'package:poker_client/sound_settings.dart';
import 'test_helpers.dart';

// TestWidgetsFlutterBinding answers every request with a 400, so the phone-number lookup always
// fails here. That is the point: settings is mostly local state, and an unreachable server must
// cost only the phone-number row - the rest of the screen has to stay usable.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ChipDisplay.instance.load();
    await SoundSettings.instance.load();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(
        const SettingsScreen(
          serverUrl: 'https://test.poker/poker',
          token: 'mock-token',
          username: 'eli',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders every section even when the server is unreachable', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Table sounds'), findsOneWidget);
    expect(find.text('Show chips as money'), findsOneWidget);
    expect(
      find.textContaining('Could not load your phone number'),
      findsOneWidget,
    );
  });

  testWidgets('the rate field appears only once money display is on', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(
      find.text('Ariary per chip'),
      findsNothing,
      reason: 'a rate is meaningless while amounts are shown as chips',
    );

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Show chips as money'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ariary per chip'), findsOneWidget);
    expect(ChipDisplay.instance.value.asMoney, isTrue);
  });

  testWidgets('typing a rate updates the worked example', (tester) async {
    await ChipDisplay.instance.setAsMoney(true);
    await pumpSettings(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Ariary per chip'),
      '50',
    );
    await tester.pumpAndSettle();

    expect(ChipDisplay.instance.value.arPerChip, 50);
    expect(find.textContaining('5 000 Ar'), findsOneWidget);
  });

  testWidgets('muting sound persists so the next table starts silent', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Table sounds'));
    await tester.pumpAndSettle();

    expect(SoundSettings.instance.value, isFalse);
    await SoundSettings.instance.load();
    expect(SoundSettings.instance.value, isFalse);
  });
}
