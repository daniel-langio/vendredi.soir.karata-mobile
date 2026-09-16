import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How chip counts are rendered across the app: as raw chips, or converted to Ariary.
///
/// Nothing in the system defines an official chip price - a marketplace listing carries its own
/// seller-chosen `unitPriceAr` and nothing else does - so [arPerChip] is the player's own
/// valuation, typed in the settings screen. It is deliberately not fetched from the server: it is
/// a reading aid, not a quote, and must keep working with no listings and no network.
@immutable
class ChipDisplaySettings {
  const ChipDisplaySettings({this.asMoney = false, this.arPerChip = 1});

  /// Render chips as money rather than as a bare chip count.
  final bool asMoney;

  /// Ariary one chip is worth. Whole Ariary, matching `ChipListing.unitPriceAr` on the server.
  final int arPerChip;

  ChipDisplaySettings copyWith({bool? asMoney, int? arPerChip}) =>
      ChipDisplaySettings(
        asMoney: asMoney ?? this.asMoney,
        arPerChip: arPerChip ?? this.arPerChip,
      );
}

class ChipDisplay extends ValueNotifier<ChipDisplaySettings> {
  ChipDisplay._() : super(const ChipDisplaySettings());
  static final ChipDisplay instance = ChipDisplay._();

  static const _asMoneyKey = 'chips_as_money';
  static const _arPerChipKey = 'ar_per_chip';

  /// Smallest rate worth offering: the server prices chips in whole Ariary, so anything below one
  /// would round every small pot to the same number.
  static const minArPerChip = 1;
  static const maxArPerChip = 1000000;

  /// Fire-and-forget from main(), the way LocaleController.load is - every chip label is wrapped in a
  /// ValueListenableBuilder, so they re-render once this resolves.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = ChipDisplaySettings(
      asMoney: prefs.getBool(_asMoneyKey) ?? false,
      arPerChip: prefs.getInt(_arPerChipKey) ?? 1,
    );
  }

  Future<void> setAsMoney(bool asMoney) async {
    value = value.copyWith(asMoney: asMoney);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_asMoneyKey, asMoney);
  }

  Future<void> setArPerChip(int arPerChip) async {
    final clamped = arPerChip.clamp(minArPerChip, maxArPerChip);
    value = value.copyWith(arPerChip: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_arPerChipKey, clamped);
  }

  /// Formats a chip count for display under the current setting. With money off this is the plain
  /// digits the table has always shown, so turning the setting off restores the old look exactly.
  String format(num? chips) => formatWith(value, chips);

  static String formatWith(ChipDisplaySettings settings, num? chips) {
    final amount = chips?.toInt() ?? 0;
    if (!settings.asMoney) return amount.toString();
    return '${_group(amount * settings.arPerChip)} Ar';
  }

  /// Groups thousands with a space, the usual Ariary style. Chip counts are shown
  /// ungrouped, so this only ever runs on the money path where the numbers get long.
  static String _group(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
