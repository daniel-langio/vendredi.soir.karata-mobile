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
    this.radius = 9,
    this.rankSize = 17,
    this.cornerSuitSize = 12,
    this.pipSize = 42,
    this.cornerInset = const Offset(7, 6),
    this.centrePip = false,
  });

  final String rank;
  final KarataIconData suit;
  final MascotPalette palette;
  final double width;
  final double height;

  /// The corner radius, the two type sizes, the big suit in the middle, and how far the corner
  /// index is inset. All default to the phone's own 84x118 card; the wide layout draws the same
  /// card at 92x128 on a lobby tile and 110x152 behind the auth screens, and the design scales
  /// the printing on it by hand rather than proportionally at each.
  final double radius;
  final double rankSize;
  final double cornerSuitSize;
  final double pipSize;
  final Offset cornerInset;

  /// Whether the big suit is centred on the card. The phone's card sits it slightly up and left
  /// of centre, which is where the mockup puts it; every wide drawing centres it exactly.
  final bool centrePip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
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
        borderRadius: BorderRadius.circular(radius - 2),
        child: Stack(
          children: [
            const Positioned.fill(child: HatchOverlay()),
            if (centrePip)
              Positioned.fill(
                child: Center(
                  child: KarataIcon(suit, size: pipSize, color: palette.ink),
                ),
              )
            else
              Positioned(
                left: 19,
                top: 36,
                child: KarataIcon(suit, size: pipSize, color: palette.ink),
              ),
            Positioned(
              left: cornerInset.dx,
              top: cornerInset.dy,
              child: _CornerIndex(
                rank: rank,
                suit: suit,
                ink: palette.ink,
                rankSize: rankSize,
                suitSize: cornerSuitSize,
              ),
            ),
            Positioned(
              right: cornerInset.dx,
              bottom: cornerInset.dy,
              child: Transform.rotate(
                angle: 3.14159265,
                child: _CornerIndex(
                  rank: rank,
                  suit: suit,
                  ink: palette.ink,
                  rankSize: rankSize,
                  suitSize: cornerSuitSize,
                ),
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
    required this.rankSize,
    required this.suitSize,
  });

  final String rank;
  final KarataIconData suit;
  final Color ink;
  final double rankSize;
  final double suitSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rank,
          style: karataText(size: rankSize, weight: 800, color: ink, height: 1),
        ),
        const SizedBox(height: 1),
        KarataIcon(suit, size: suitSize, color: ink),
      ],
    );
  }
}
