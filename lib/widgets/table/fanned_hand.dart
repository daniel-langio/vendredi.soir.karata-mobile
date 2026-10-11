import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'card_back.dart';
import 'card_code.dart';
import 'playing_card.dart';

/// A player's own cards, tilted apart the way the design fans them - the first rotated back, the
/// rest forward, each overlapping the one before.
class FannedHand extends StatelessWidget {
  const FannedHand({
    super.key,
    required this.cards,
    this.cardWidth = 58,
    this.faceDown = false,
    this.muted = false,
    this.winningCards,
  });

  /// The hand, in deal order. Nulls draw as card backs.
  final List<String?> cards;

  final double cardWidth;
  final bool faceDown;

  /// Ignored once [winningCards] is given - a showdown hand's own cards decide this per card
  /// instead of as a single flag.
  final bool muted;

  /// When set, cards making the winning hand are highlighted and the rest dimmed, the way the
  /// board greys down once a showdown is known.
  final Set<String>? winningCards;

  /// How far each card sits to the right of the one before it.
  double get _step => cardWidth;

  /// The tilt applied to the first and last card, in degrees; the rest interpolate between.
  static const _tiltDegrees = 5.0;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final height = cardWidth * 1.385;
    final width = _step * (cards.length - 1) + cardWidth;
    final showdown = winningCards?.isNotEmpty ?? false;

    return SizedBox(
      width: width,
      height: height + 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < cards.length; i++)
            Positioned(
              left: i * _step,
              // The tilt lifts each card's far corner, so the outer ones sit slightly lower.
              top: (i == 0 || i == cards.length - 1) ? 6 : 2,
              child: Transform.rotate(
                angle: _angleFor(i) * math.pi / 180,
                child: faceDown || cards[i] == null
                    ? CardBack(width: cardWidth)
                    : PlayingCard(
                        code: CardCode(cards[i]!),
                        width: cardWidth,
                        muted: showdown
                            ? !winningCards!.contains(cards[i])
                            : muted,
                        highlighted:
                            showdown && winningCards!.contains(cards[i]),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  double _angleFor(int index) {
    if (cards.length == 1) return 0;
    final t = index / (cards.length - 1);
    return -_tiltDegrees + t * (_tiltDegrees * 2);
  }
}
