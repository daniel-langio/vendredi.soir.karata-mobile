import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// How long you have left to act, above the buttons you have to act with.
///
/// The server auto-folds whoever is on the clock once their turn's deadline passes
/// (DealService.TURN_TIMEOUT), so without this a player can be folded out of a hand with no
/// warning at all. The V2 design has no slot for it, so it sits where your eyes already are when
/// it is your move.
class TurnClockBar extends StatelessWidget {
  const TurnClockBar({
    super.key,
    required this.label,
    required this.remaining,
    required this.fraction,
  });

  /// Already localised, and already carrying the seconds.
  final String label;

  final Duration remaining;

  /// How much of the turn is left, 0 to 1.
  final double fraction;

  /// Below this the bar turns warm, because the fold is close enough to act on.
  static const _urgent = Duration(seconds: 15);

  @override
  Widget build(BuildContext context) {
    final urgent = remaining <= _urgent;
    final colour = urgent ? KarataColors.orangeLight : KarataColors.gold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: karataText(size: 12, weight: 700, color: colour),
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
