import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';

/// The API returns `lastAction` as a pre-formatted English string (e.g. "CALL 20", "SMALL BLIND
/// 10") derived from the domain action itself, not a translation key - re-parse it here rather
/// than changing the API contract just for client-side display purposes.
/// The chips a seat staked with [raw], or null when the action moved none.
///
/// Reads the same trailing number [formatLastAction] puts in the badge, so the chips the wide
/// table pushes onto the felt and the badge under the avatar always agree.
int? lastActionAmount(String raw) {
  final parts = raw.split(' ');
  if (parts.length < 2) return null;
  return switch (parts.first) {
    'CALL' || 'BET' || 'RAISE' || 'SMALL' || 'BIG' => int.tryParse(parts.last),
    _ => null,
  };
}

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
