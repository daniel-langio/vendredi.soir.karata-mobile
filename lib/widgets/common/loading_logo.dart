import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../table/card_back.dart';
import '../table/flip_card.dart';
import 'karata_logo.dart';

/// A golden card dealt from a small stack beside it, flipping face-up to reveal the mark - the
/// app's loading state in place of a plain spinner.
///
/// [size] sets the whole badge: 140 with a [label] underneath, 84 compact, 44 inside a button.
class LoadingLogo extends StatefulWidget {
  const LoadingLogo({super.key, this.size = 84, this.label});

  final double size;

  /// "Loading...", "Shuffling the deck..." - shown under the mark, already localised.
  final String? label;

  @override
  State<LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<LoadingLogo>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _labelFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      // The settled, face-up frame rather than a frozen mid-flight one.
      _controller.value = 0.5;
    } else {
      _controller.repeat();
      _labelFade.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _labelFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final cardWidth = size * 0.42;
    final deckOffset = Offset(-size * 0.414, -size * 0.1);
    final label = widget.label;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: _reduceMotion
              ? Center(child: KarataLogo(size: size * 0.78))
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final v = _controller.value;
                    final fly = _flySegment(v);
                    final flip = _flipSegment(v);
                    final glow = _glowSegment(v);
                    final pos = Offset.lerp(deckOffset, Offset.zero, fly)!;
                    final scale = 0.72 + 0.28 * fly;
                    final rotationDeg = -10 + 14 * fly;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: glow,
                          child: Container(
                            width: size * 0.7,
                            height: size * 0.7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  KarataColors.gold.withValues(alpha: 0.55),
                                  KarataColors.gold.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: pos,
                          child: Transform.rotate(
                            angle: rotationDeg * 3.14159265 / 180,
                            child: Transform.scale(
                              scale: scale,
                              child: CardFlip(
                                t: flip,
                                front: SizedBox(
                                  width: cardWidth,
                                  height: cardWidth * 1.385,
                                  child: Center(
                                    child: KarataLogo(size: cardWidth * 0.86),
                                  ),
                                ),
                                back: CardBack(width: cardWidth),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        if (label != null) ...[
          const SizedBox(height: 10),
          _reduceMotion
              ? Text(label, style: _labelStyle)
              : AnimatedBuilder(
                  animation: _labelFade,
                  builder: (context, child) => Opacity(
                    opacity: 0.45 + 0.55 * _labelFade.value,
                    child: child,
                  ),
                  child: Text(label, style: _labelStyle),
                ),
        ],
      ],
    );
  }

  TextStyle get _labelStyle =>
      karataText(size: 13, weight: 600, color: KarataColors.inkMuted);

  /// Out to centre by 30%, holds, back to the deck from 70%.
  double _flySegment(double v) {
    if (v <= 0.30) return Curves.easeOut.transform(v / 0.30);
    if (v <= 0.70) return 1.0;
    return 1 - Curves.easeOut.transform((v - 0.70) / 0.30);
  }

  /// Face-down until 18%, face-up by 38%, holds to 62%, back to face-down by 82%.
  double _flipSegment(double v) {
    if (v <= 0.18) return 0;
    if (v <= 0.38) return Curves.easeInOut.transform((v - 0.18) / 0.20);
    if (v <= 0.62) return 1;
    if (v <= 0.82) return 1 - Curves.easeInOut.transform((v - 0.62) / 0.20);
    return 0;
  }

  /// .3 -> .95 between 45% and 55%, back down by 65%.
  double _glowSegment(double v) {
    if (v <= 0.45) return 0.3;
    if (v <= 0.55) return 0.3 + 0.65 * ((v - 0.45) / 0.10);
    if (v <= 0.65) return 0.95 - 0.65 * ((v - 0.55) / 0.10);
    return 0.3;
  }
}
