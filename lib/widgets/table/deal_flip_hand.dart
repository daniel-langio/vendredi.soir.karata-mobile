import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'card_back.dart';
import 'card_code.dart';
import 'flip_card.dart';
import 'playing_card.dart';

/// The hero's hand the moment it is dealt: each card drops into place and flips face-up, rather
/// than simply appearing the way [FannedHand] draws a settled hand.
///
/// Plays once, on mount. The table screen gives this a key derived from the deal id, which is
/// what restarts it hand to hand rather than replaying on every rebuild.
///
/// The reference board flies both cards to one overlapping point; here they fall straight into
/// their own fanned slot instead, since that is where [FannedHand] actually lands them.
class DealFlipHand extends StatefulWidget {
  const DealFlipHand({
    super.key,
    required this.cards,
    this.cardWidth = 58,
    this.muted = false,
    this.winningCards,
  });

  /// The hand, in deal order. Nulls draw as card backs.
  final List<String?> cards;
  final double cardWidth;
  final bool muted;

  /// When set, cards making the winning hand are highlighted and the rest dimmed, exactly as
  /// [FannedHand] does once a showdown is known.
  final Set<String>? winningCards;

  static const _tiltDegrees = 5.0;

  @override
  State<DealFlipHand> createState() => _DealFlipHandState();
}

class _DealFlipHandState extends State<DealFlipHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _restingAngle(int index, int count) {
    if (count == 1) return 0;
    final t = index / (count - 1);
    return -DealFlipHand._tiltDegrees + t * (DealFlipHand._tiltDegrees * 2);
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    if (cards.isEmpty) return const SizedBox.shrink();
    final cardWidth = widget.cardWidth;
    final height = cardWidth * 1.385;
    final width = cardWidth * (cards.length - 1) + cardWidth;
    final showdown = widget.winningCards?.isNotEmpty ?? false;

    return SizedBox(
      width: width,
      height: height + 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < cards.length; i++)
            _card(i, cards.length, cards[i], cardWidth, height, showdown),
        ],
      ),
    );
  }

  Widget _card(
    int index,
    int count,
    String? code,
    double cardWidth,
    double height,
    bool showdown,
  ) {
    // Each card's own slice of the shared controller, staggered so the second card lands and
    // flips just after the first.
    final start = index * 0.12;
    final fly = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        start,
        (start + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    );
    final flip = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (start + 0.55).clamp(0.0, 1.0),
        (start + 0.85).clamp(0.0, 1.0),
        curve: Curves.easeInOut,
      ),
    );
    final restingAngle = _restingAngle(index, count);
    final restingTop = (index == 0 || index == count - 1) ? 6.0 : 2.0;
    final winningCards = widget.winningCards;

    final front = code == null
        ? CardBack(width: cardWidth)
        : PlayingCard(
            code: CardCode(code),
            width: cardWidth,
            muted: showdown && !winningCards!.contains(code),
            highlighted: showdown && winningCards!.contains(code),
          );
    final back = CardBack(width: cardWidth);

    return AnimatedBuilder(
      animation: Listenable.merge([fly, flip]),
      builder: (context, _) {
        final t = fly.value;
        final startAngleDeg = restingAngle < 0 ? -30.0 : 30.0;
        final angleDeg = startAngleDeg + (restingAngle - startAngleDeg) * t;
        final dy = (1 - t) * -(height * 1.6);
        return Positioned(
          left: index * cardWidth,
          top: restingTop + dy,
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: angleDeg * math.pi / 180,
              child: code == null
                  ? back
                  : CardFlip(t: flip.value, front: front, back: back),
            ),
          ),
        );
      },
    );
  }
}
