import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../common/karata_icon.dart';
import 'mascot_card_face.dart';
import 'mascot_palette.dart';

/// The pair of cards tucked into the right edge of a lobby table card, one tilted back and one
/// forward, with a glow behind them.
class FannedCards extends StatelessWidget {
  const FannedCards({
    super.key,
    required this.left,
    required this.right,
    required this.palette,
  });

  /// Rank and suit of the card that sits behind, rotated anticlockwise.
  final (String, KarataIconData) left;

  /// Rank and suit of the card in front, rotated clockwise. The design pairs two different cards
  /// - an ace over a king, a ten over a nine - rather than showing the same card twice.
  final (String, KarataIconData) right;

  /// Gold for a public table, silver for your own.
  final MascotPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -20,
            top: -16,
            child: IgnorePointer(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(0.2, 0),
                    radius: 0.65,
                    colors: [palette.halo, palette.halo.withAlpha(0)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 10,
            child: Transform.rotate(
              angle: -10 * math.pi / 180,
              child: MascotCardFace(
                rank: left.$1,
                suit: left.$2,
                palette: palette,
              ),
            ),
          ),
          Positioned(
            left: 66,
            top: 6,
            child: Transform.rotate(
              angle: 7 * math.pi / 180,
              child: MascotCardFace(
                rank: right.$1,
                suit: right.$2,
                palette: palette,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
