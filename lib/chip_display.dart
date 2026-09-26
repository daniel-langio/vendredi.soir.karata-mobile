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
  const ChipDisplaySettings({this.asMoney = true, this.arPerChip = 0});

  /// Render chips as money rather than as a bare chip count. On by default: the chips are bought
  /// with real money and cashed back out to it, so Ariary is the unit players actually reason in.
  final bool asMoney;

  /// Ariary one chip is worth, per the server's current global price. Zero until a real rate has
  /// been fetched - the placeholder 1:1 it used to hold was itself a made-up rate, harmless only
  /// while money display was opt-in, and a lie on a stack the moment it is the default.
  final int arPerChip;

  ChipDisplaySettings copyWith({bool? asMoney, int? arPerChip}) =>
      ChipDisplaySettings(
        asMoney: asMoney ?? this.asMoney,
        arPerChip: arPerChip ?? this.arPerChip,
      );

  /// Whether amounts are both read *and typed* in Ariary. A rate of zero would make the
  /// conversion meaningless (every entry would come out as no chips at all), so the app quietly
  /// stays on chips until a usable rate is known rather than asking for money it can't convert.
  bool get inMoney => asMoney && arPerChip > 0;

  /// Chips for a number the player typed into a field. Every amount field in the app runs its
  /// entry through here, so what is typed always means the same thing as what the rest of the
  /// screen shows - the API itself only ever speaks chips.
  int chipsFromEntry(num entered) =>
      inMoney ? (entered / arPerChip).round() : entered.toInt();

  /// The reverse, for prefilling a field (a suggested buy-in, a default quantity) in whatever
  /// unit that field is currently asking for.
  int entryFromChips(num chips) =>
      inMoney ? (chips * arPerChip).round() : chips.toInt();
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
    value = value.copyWith(asMoney: prefs.getBool(_asMoneyKey) ?? true);
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
      applyRate(await apiClient.getChipPrice());
    } catch (_) {
      // Keep whatever rate is already in memory.
    }
  }

  /// Adopts the rate out of a `GET /economy/price` body a screen has already fetched for its own
  /// reasons (the deposit/withdrawal screens both need it), so those screens convert with exactly
  /// the rate they quote instead of paying for a second round trip to stay in sync.
  void applyRate(Map<String, dynamic> price) {
    value = value.copyWith(arPerChip: (price['arPerChip'] as num).toInt());
  }

  /// Formats a chip count for display under the current setting. With money off this is the plain
  /// digits the table has always shown, so turning the setting off restores the old look exactly.
  ///
  /// Keys off [ChipDisplaySettings.inMoney] rather than the toggle alone, so the seconds between
  /// launch and the first rate fetch show honest chip counts instead of every stack converted at
  /// a placeholder rate. The wording around them still follows the toggle (see AppLocalizations):
  /// the player asked for a wallet, the app just can't price it yet.
  String format(num? chips) => formatWith(value, chips);

  static String formatWith(ChipDisplaySettings settings, num? chips) {
    final amount = chips?.toInt() ?? 0;
    if (!settings.inMoney) return amount.toString();
    return '${groupDigits(amount * settings.arPerChip)} Ar';
  }

  /// Groups thousands with a space, the usual Ariary style. Chip counts are shown ungrouped, so
  /// this only runs on amounts that are genuinely money - the converted balances here, and the
  /// real Ariary totals the deposit/withdrawal screens quote, which are in Ar in either mode.
  static String groupDigits(int value) {
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
