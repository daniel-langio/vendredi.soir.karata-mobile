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
    // The display settings are a singleton, so a rate left behind by one test would leak into the
    // next - reset to the shipped defaults before each.
    ChipDisplay.instance.value = const ChipDisplaySettings();
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

  testWidgets(
    'the worked example waits for a real rate, which no field here can invent',
    (tester) async {
      await pumpSettings(tester);

      // Money display ships on, but every request here gets a 400, so no rate is known - and an
      // example is worse than no example if it prices a stack at a rate nobody quoted.
      expect(ChipDisplay.instance.value.asMoney, isTrue);
      expect(find.textContaining('shows as'), findsNothing);

      // The rate arrives from the server, never from a field the player fills in.
      ChipDisplay.instance.value = ChipDisplay.instance.value.copyWith(
        arPerChip: 50,
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('100 chips shows as 5 000 Ar'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a player who turns money display off is taken at their word', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Show chips as money'),
    );
    await tester.pumpAndSettle();

    expect(ChipDisplay.instance.value.asMoney, isFalse);
    await ChipDisplay.instance.load();
    expect(
      ChipDisplay.instance.value.asMoney,
      isFalse,
      reason: 'the default only applies to a player who never chose',
    );
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
