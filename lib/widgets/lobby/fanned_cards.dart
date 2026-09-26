import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../common/karata_icon.dart';
import 'gold_card_face.dart';

/// The pair of gold cards tucked into the right edge of a lobby table card, one tilted back and
/// one forward, with a warm glow behind them.
class FannedCards extends StatelessWidget {
  const FannedCards({super.key, required this.left, required this.right});

  /// Rank and suit of the card that sits behind, rotated anticlockwise.
  final (String, KarataIconData) left;

  /// Rank and suit of the card in front, rotated clockwise. The design pairs two different cards
  /// - an ace over a king, a ten over a nine - rather than showing the same card twice.
  final (String, KarataIconData) right;

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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(0.2, 0),
                    radius: 0.65,
                    colors: [Color(0x29E9C46A), Color(0x00E9C46A)],
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
              child: GoldCardFace(rank: left.$1, suit: left.$2),
            ),
          ),
          Positioned(
            left: 66,
            top: 6,
            child: Transform.rotate(
              angle: 7 * math.pi / 180,
              child: GoldCardFace(rank: right.$1, suit: right.$2),
            ),
          ),
        ],
      ),
    );
  }
}
