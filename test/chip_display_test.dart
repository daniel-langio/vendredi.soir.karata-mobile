import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_client/api/api_client.dart';
import 'package:poker_client/chip_display.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ChipDisplay.instance.load();
  });

  group('formatting', () {
    test('with money off, a chip count is the plain digits it always was', () {
      expect(
        ChipDisplay.formatWith(const ChipDisplaySettings(asMoney: false), 1500),
        '1500',
        reason: 'turning the setting off must restore the old table exactly',
      );
    });

    test('money display waits for a real rate before converting anything', () {
      expect(
        ChipDisplay.formatWith(const ChipDisplaySettings(), 1500),
        '1500',
        reason:
            'the default settings carry no rate yet, and converting a stack at a '
            'placeholder one would put a wrong price on real money',
      );
    });

    test('with money on, chips are multiplied and grouped', () {
      const settings = ChipDisplaySettings(asMoney: true, arPerChip: 50);
      expect(ChipDisplay.formatWith(settings, 100), '5 000 Ar');
      expect(ChipDisplay.formatWith(settings, 20), '1 000 Ar');
      expect(ChipDisplay.formatWith(settings, 1), '50 Ar');
    });

    test('grouping holds past a million', () {
      const settings = ChipDisplaySettings(asMoney: true, arPerChip: 1);
      expect(ChipDisplay.formatWith(settings, 1000000), '1 000 000 Ar');
    });

    test('a missing amount reads as zero, not as a crash or a blank', () {
      expect(
        ChipDisplay.formatWith(const ChipDisplaySettings(asMoney: false), null),
        '0',
      );
      expect(
        ChipDisplay.formatWith(
          const ChipDisplaySettings(asMoney: true, arPerChip: 50),
          null,
        ),
        '0 Ar',
      );
    });
  });

  group('persistence', () {
    test('the money-display mode survives a reload', () async {
      await ChipDisplay.instance.setAsMoney(true);

      await ChipDisplay.instance.load();

      expect(ChipDisplay.instance.value.asMoney, isTrue);
    });

    test(
      'money display is the default for a player who never set it',
      () async {
        await ChipDisplay.instance.load();
        expect(ChipDisplay.instance.value.asMoney, isTrue);
        expect(
          ChipDisplay.instance.value.arPerChip,
          0,
          reason: 'no rate is known until one is fetched, and none is invented',
        );
      },
    );

    test(
      'a player who turned money off keeps it off across a reload',
      () async {
        await ChipDisplay.instance.setAsMoney(false);

        await ChipDisplay.instance.load();

        expect(ChipDisplay.instance.value.asMoney, isFalse);
      },
    );
  });

  group('refreshRateFromServer', () {
    test(
      'an unreachable server leaves whatever rate is already in memory',
      () async {
        ChipDisplay.instance.value = const ChipDisplaySettings(
          asMoney: true,
          arPerChip: 50,
        );
        final apiClient = ApiClient(
          baseUrl: 'https://unreachable.invalid/poker',
        );

        await ChipDisplay.instance.refreshRateFromServer(apiClient);

        expect(ChipDisplay.instance.value.arPerChip, 50);
      },
    );
  });
}
