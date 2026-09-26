import 'package:flutter/widgets.dart';

import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// Announces who took the pot, over the board they won it on.
///
/// Sized to its own text rather than to the felt: it is a sentence, and a pill stretched across
/// the whole table reads as a section header for the board beneath it.
class OutcomeBanner extends StatelessWidget {
  const OutcomeBanner({
    super.key,
    required this.outcome,
    required this.myUsername,
  });

  final Map<String, dynamic> outcome;
  final String myUsername;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final winners = outcome['winners'] as List<dynamic>? ?? const [];
    if (winners.isEmpty) return const SizedBox.shrink();

    final iWon = winners.any((w) => w['username'] == myUsername);
    final names = winners
        .map((w) => w['username'] == myUsername ? t.you : '${w['username']}')
        .join(' & ');
    final total = winners.fold<int>(
      0,
      (sum, w) => sum + ((w['amount'] as num?)?.toInt() ?? 0),
    );
    final amount = ChipDisplay.instance.format(total);

    // Picks the phrasing that agrees with who actually won - see AppLocalizations.won.
    final line = winners.length > 1
        ? t.wonBySeveral(names, amount)
        : (iWon ? t.wonByYou(amount) : t.won(names, amount));

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: iWon ? KarataColors.gold : KarataColors.surfaceRaised,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          line,
          textAlign: TextAlign.center,
          style: karataText(
            size: 14,
            weight: 800,
            color: iWon ? KarataColors.onGoldBadge : KarataColors.ink,
          ),
        ),
      ),
    );
  }
}
