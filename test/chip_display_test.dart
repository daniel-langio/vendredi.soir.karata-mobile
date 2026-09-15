import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_client/chip_display.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ChipDisplay.instance.load();
  });

  group('formatting', () {
    test('with money off, a chip count is the plain digits it always was', () {
      expect(
        ChipDisplay.formatWith(const ChipDisplaySettings(), 1500),
        '1500',
        reason: 'turning the setting off must restore the old table exactly',
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
      expect(ChipDisplay.formatWith(const ChipDisplaySettings(), null), '0');
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
    test('the mode and the rate both survive a reload', () async {
      await ChipDisplay.instance.setAsMoney(true);
      await ChipDisplay.instance.setArPerChip(250);

      await ChipDisplay.instance.load();

      expect(ChipDisplay.instance.value.asMoney, isTrue);
      expect(ChipDisplay.instance.value.arPerChip, 250);
      expect(ChipDisplay.instance.format(4), '1 000 Ar');
    });

    test('a rate below one is clamped rather than stored', () async {
      await ChipDisplay.instance.setArPerChip(0);
      expect(ChipDisplay.instance.value.arPerChip, ChipDisplay.minArPerChip);
    });

    test('defaults are chips, so an upgrading player sees no change', () async {
      await ChipDisplay.instance.load();
      expect(ChipDisplay.instance.value.asMoney, isFalse);
      expect(ChipDisplay.instance.value.arPerChip, 1);
    });
  });
}
