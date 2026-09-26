import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/css_gradient.dart';
import '../common/hatch_overlay.dart';
import '../common/karata_icon.dart';

/// One of the oversized gold cards fanned across the right of a lobby table card.
///
/// Decoration rather than game state - it is the same pair on every table card, so it takes the
/// rank and suit it should show rather than reading a hand.
class GoldCardFace extends StatelessWidget {
  const GoldCardFace({
    super.key,
    required this.rank,
    required this.suit,
    this.width = 84,
    this.height = 118,
  });

  final String rank;
  final KarataIconData suit;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: KarataColors.goldWash, width: 2),
        gradient: cssLinearGradient(
          angleDegrees: 150,
          colors: const [
            KarataColors.goldBright,
            KarataColors.gold,
            KarataColors.goldDeep,
          ],
          stops: const [0, 0.45, 1],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x59E9C46A), blurRadius: 18),
          BoxShadow(
            color: Color(0x8C000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            const Positioned.fill(child: HatchOverlay()),
            Positioned(
              left: 19,
              top: 36,
              child: KarataIcon(suit, size: 42, color: KarataColors.onAccent),
            ),
            Positioned(
              left: 7,
              top: 6,
              child: _CornerIndex(rank: rank, suit: suit),
            ),
            Positioned(
              right: 7,
              bottom: 6,
              child: Transform.rotate(
                angle: 3.14159265,
                child: _CornerIndex(rank: rank, suit: suit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rank stacked over its suit, as it appears in a card's corner.
class _CornerIndex extends StatelessWidget {
  const _CornerIndex({required this.rank, required this.suit});

  final String rank;
  final KarataIconData suit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rank,
          style: karataText(
            size: 17,
            weight: 800,
            color: KarataColors.onAccent,
            height: 1,
          ),
        ),
        const SizedBox(height: 1),
        KarataIcon(suit, size: 12, color: KarataColors.onAccent),
      ],
    );
  }
}
