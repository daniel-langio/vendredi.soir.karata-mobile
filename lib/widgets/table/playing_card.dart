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
class PlayingCard extends StatefulWidget {
  const PlayingCard({
    super.key,
    required this.code,
    this.width = 52,
    this.muted = false,
    this.highlighted = false,
    this.pulseDelay = Duration.zero,
  });

  final CardCode code;
  final double width;

  /// A card that is no longer live - greyed, with its pips darkened to match.
  final bool muted;

  /// Part of the winning hand: a gold rim and a glow around it.
  final bool highlighted;

  /// How far behind the other winning cards this one starts its glow pulse - the showdown board
  /// staggers them left to right rather than pulsing as one block.
  final Duration pulseDelay;

  double get height => width * 1.385;

  @override
  State<PlayingCard> createState() => _PlayingCardState();
}

class _PlayingCardState extends State<PlayingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.highlighted) _startPulse();
  }

  @override
  void didUpdateWidget(PlayingCard old) {
    super.didUpdateWidget(old);
    if (widget.highlighted && !old.highlighted) {
      _startPulse();
    } else if (!widget.highlighted && old.highlighted) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  void _startPulse() {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    Future.delayed(widget.pulseDelay, () {
      if (mounted && widget.highlighted) _pulse.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.code;
    final width = widget.width;
    final height = widget.height;
    final muted = widget.muted;
    final highlighted = widget.highlighted;
    if (!code.isValid) return SizedBox(width: width, height: height);
    final ink = muted ? code.mutedColor : code.color;
    final radius = width >= 58 ? 7.0 : 6.0;
    final inset = width >= 58 ? 5.0 : 4.0;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = highlighted
            ? Tween<double>(
                begin: 6,
                end: 22,
              ).transform(Curves.easeInOut.transform(_pulse.value))
            : 0.0;
        final glowOpacity = highlighted
            ? Tween<double>(
                begin: 0.35,
                end: 0.95,
              ).transform(Curves.easeInOut.transform(_pulse.value))
            : 0.0;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: muted ? KarataColors.cardMuted : KarataColors.cardFace,
            borderRadius: BorderRadius.circular(radius),
            border: highlighted
                ? Border.all(color: KarataColors.gold, width: 3)
                : null,
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: KarataColors.gold.withValues(alpha: glowOpacity),
                      blurRadius: glow,
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x73000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: child,
        );
      },
      child: Stack(
        children: [
          Center(
            child: KarataIcon(code.suit, size: width * 0.5, color: ink),
          ),
          Positioned(
            left: inset,
            top: inset,
            child: _Index(code: code, width: width, color: ink),
          ),
          Positioned(
            right: inset,
            bottom: inset,
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
