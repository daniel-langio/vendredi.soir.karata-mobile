import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';

/// The API returns `lastAction` as a pre-formatted English string (e.g. "CALL 20", "SMALL BLIND
/// 10") derived from the domain action itself, not a translation key - re-parse it here rather
/// than changing the API contract just for client-side display purposes.
String formatLastAction(AppLocalizations t, String raw) {
  final parts = raw.split(' ');
  if (parts.isEmpty) return raw;
  final amount = int.tryParse(parts.last) ?? 0;
  switch (parts.first) {
    case 'FOLD':
      return t.fold;
    case 'CHECK':
      return t.check;
    case 'CALL':
      return t.call(ChipDisplay.instance.format(amount));
    case 'BET':
      return t.bet(ChipDisplay.instance.format(amount));
    case 'RAISE':
      return t.raise(ChipDisplay.instance.format(amount));
    case 'SMALL':
      return '${t.sb} ${ChipDisplay.instance.format(amount)}';
    case 'BIG':
      return '${t.bb} ${ChipDisplay.instance.format(amount)}';
    default:
      return raw;
  }
}
