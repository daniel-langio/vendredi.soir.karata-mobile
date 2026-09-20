import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_client.dart';

/// How chip counts are rendered across the app: as raw chips, or converted to Ariary.
///
/// [arPerChip] tracks the real global chip price (`GET /economy/price` - see EconomyScreen), kept
/// in memory only and refreshed via [refreshRateFromServer] whenever a screen that already has an
/// [ApiClient] on hand (MenuScreen, SettingsScreen) calls it. It is not persisted and not
/// player-editable - unlike the toggle, a stale or made-up rate would misrepresent real money.
@immutable
class ChipDisplaySettings {
  const ChipDisplaySettings({this.asMoney = false, this.arPerChip = 1});

  /// Render chips as money rather than as a bare chip count.
  final bool asMoney;

  /// Ariary one chip is worth, per the server's current global price.
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

  /// Fire-and-forget from main(), the way LocaleController.load is - every chip label is wrapped in a
  /// ValueListenableBuilder, so they re-render once this resolves. Only the toggle is loaded here -
  /// the rate needs a logged-in session's ApiClient, see [refreshRateFromServer].
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = value.copyWith(asMoney: prefs.getBool(_asMoneyKey) ?? false);
  }

  Future<void> setAsMoney(bool asMoney) async {
    value = value.copyWith(asMoney: asMoney);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_asMoneyKey, asMoney);
  }

  /// Best-effort refresh of the Ar-per-chip rate from the real global price. Silent on failure -
  /// this is a display multiplier, not something the player acts on, so an unreachable server just
  /// means the previous rate (or the 1:1 default) stays in place rather than surfacing an error.
  Future<void> refreshRateFromServer(ApiClient apiClient) async {
    try {
      final price = await apiClient.getChipPrice();
      value = value.copyWith(arPerChip: (price['arPerChip'] as num).toInt());
    } catch (_) {
      // Keep whatever rate is already in memory.
    }
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
