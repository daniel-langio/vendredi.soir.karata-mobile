import 'package:flutter/widgets.dart';

import '../../theme/karata_text_styles.dart';
import '../common/css_gradient.dart';
import '../common/hatch_overlay.dart';
import '../common/karata_icon.dart';
import 'mascot_palette.dart';

/// One of the oversized cards fanned across the right of a lobby table card.
///
/// Decoration rather than game state: it takes the rank and suit it should show rather than
/// reading a hand, and the metal it is cut from says whether the table is public or your own.
class MascotCardFace extends StatelessWidget {
  const MascotCardFace({
    super.key,
    required this.rank,
    required this.suit,
    required this.palette,
    this.width = 84,
    this.height = 118,
  });

  final String rank;
  final KarataIconData suit;
  final MascotPalette palette;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.rim, width: 2),
        gradient: cssLinearGradient(
          angleDegrees: 150,
          colors: [palette.bright, palette.mid, palette.deep],
          stops: const [0, 0.45, 1],
        ),
        boxShadow: [
          BoxShadow(color: palette.glow, blurRadius: 18),
          const BoxShadow(
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
              child: KarataIcon(suit, size: 42, color: palette.ink),
            ),
            Positioned(
              left: 7,
              top: 6,
              child: _CornerIndex(rank: rank, suit: suit, ink: palette.ink),
            ),
            Positioned(
              right: 7,
              bottom: 6,
              child: Transform.rotate(
                angle: 3.14159265,
                child: _CornerIndex(rank: rank, suit: suit, ink: palette.ink),
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
  const _CornerIndex({
    required this.rank,
    required this.suit,
    required this.ink,
  });

  final String rank;
  final KarataIconData suit;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rank,
          style: karataText(size: 17, weight: 800, color: ink, height: 1),
        ),
        const SizedBox(height: 1),
        KarataIcon(suit, size: 12, color: ink),
      ],
    );
  }
}
