import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// Whose turn it is, and how long they have left.
///
/// Always present, never conditional. The server auto-folds whoever is on the clock once their
/// deadline passes (DealService.TURN_TIMEOUT), so this has to be visible when it is your move -
/// but a row that appears only then would grow the controls beneath the felt, and the felt is
/// sized from the space left over, so the whole table stepped up as your turn began and back down
/// the moment you acted. Holding the row always, and changing what it says, is what keeps the
/// table still.
class TurnStatusBar extends StatelessWidget {
  const TurnStatusBar({
    super.key,
    this.label,
    this.remaining,
    this.fraction = 0,
    this.isYours = false,
  });

  /// Already localised. Null between hands, when there is nothing to say and the row simply
  /// holds its height.
  final String? label;

  final Duration? remaining;

  /// How much of the turn is left, 0 to 1.
  final double fraction;

  /// Whether the clock is on the player reading this, which is the only case worth colouring.
  final bool isYours;

  /// Below this the bar turns warm, because the fold is close enough to act on.
  static const _urgent = Duration(seconds: 15);

  @override
  Widget build(BuildContext context) {
    final urgent = isYours && (remaining ?? Duration.zero) <= _urgent;
    final Color colour;
    if (!isYours) {
      colour = KarataColors.inkFaint;
    } else if (urgent) {
      colour = KarataColors.orangeLight;
    } else {
      colour = KarataColors.gold;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          // A space rather than nothing, so an idle table keeps the line's height.
          label ?? ' ',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: karataText(
            size: 12,
            weight: 700,
            color: isYours ? colour : KarataColors.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: KarataColors.surfaceRaised),
                ),
                // heightFactor as well as widthFactor: without it the fill's height is left
                // unconstrained inside the stack and the ColoredBox collapses to nothing.
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  heightFactor: 1,
                  alignment: AlignmentDirectional.centerStart,
                  child: ColoredBox(color: colour),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
