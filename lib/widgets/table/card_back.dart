import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../common/css_gradient.dart';
import '../common/hatch_overlay.dart';

/// A card that exists but has not been shown: an opponent's hole cards, or a board slot the deal
/// has not reached yet.
///
/// Drawn as a silver weave rather than a gold one: gold on this table marks a winning card, and
/// a hand still face down has won nothing yet.
class CardBack extends StatelessWidget {
  const CardBack({super.key, this.width = 52});

  final double width;

  double get height => width * 1.385;

  @override
  Widget build(BuildContext context) {
    final radius = width >= 58 ? 7.0 : 6.0;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: KarataColors.cardBackDeep, width: 1.5),
        gradient: cssLinearGradient(
          angleDegrees: 150,
          colors: const [
            KarataColors.cardBackLight,
            KarataColors.cardBack,
            KarataColors.cardBackDeep,
          ],
          stops: const [0, 0.45, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1.5),
        child: const HatchOverlay(color: Color(0x1F000000)),
      ),
    );
  }
}
