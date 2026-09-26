import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/karata_icon.dart';
import 'card_code.dart';

/// A face-up playing card: the rank and suit in opposite corners, the suit again at its centre.
///
/// The design draws three sizes - 48 for a revealed opponent hand, 52 on the board, 58 for the
/// player's own cards - built to one set of proportions, so everything here is derived from
/// [width] rather than passed in separately.
class PlayingCard extends StatelessWidget {
  const PlayingCard({
    super.key,
    required this.code,
    this.width = 52,
    this.muted = false,
    this.highlighted = false,
  });

  final CardCode code;
  final double width;

  /// A card that is no longer live - greyed, with its pips darkened to match.
  final bool muted;

  /// Part of the winning hand: a gold rim and a glow around it.
  final bool highlighted;

  double get height => width * 1.385;
  double get _radius => width >= 58 ? 7 : 6;
  double get _inset => width >= 58 ? 5 : 4;

  @override
  Widget build(BuildContext context) {
    if (!code.isValid) return SizedBox(width: width, height: height);
    final ink = muted ? code.mutedColor : code.color;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: muted ? KarataColors.cardMuted : KarataColors.cardFace,
        borderRadius: BorderRadius.circular(_radius),
        border: highlighted
            ? Border.all(color: KarataColors.gold, width: 3)
            : null,
        boxShadow: highlighted
            ? const [BoxShadow(color: Color(0x99E9C46A), blurRadius: 14)]
            : const [
                BoxShadow(
                  color: Color(0x73000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
          Center(
            child: KarataIcon(code.suit, size: width * 0.5, color: ink),
          ),
          Positioned(
            left: _inset,
            top: _inset,
            child: _Index(code: code, width: width, color: ink),
          ),
          Positioned(
            right: _inset,
            bottom: _inset,
            child: Transform.rotate(
              angle: 3.14159265,
              child: _Index(code: code, width: width, color: ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// The rank stacked over its suit, as it appears in a card's corner.
class _Index extends StatelessWidget {
  const _Index({required this.code, required this.width, required this.color});

  final CardCode code;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          code.rank,
          style: karataText(
            size: width * 0.26,
            weight: 800,
            color: color,
            height: 1,
            letterSpacing: -0.03,
          ),
        ),
        const SizedBox(height: 1),
        KarataIcon(code.suit, size: width * 0.172, color: color),
      ],
    );
  }
}
