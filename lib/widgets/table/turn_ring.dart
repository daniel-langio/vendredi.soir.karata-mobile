import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';

/// The draining ring an active seat's avatar sits inside while their turn clock runs.
///
/// [fraction] is how much of the turn is left, 1 down to 0 - the same number [TurnStatusBar]
/// drains its bar with, so the two always agree. The ring's own colour follows the same
/// teal-to-gold-to-laterite handoff as that bar's urgency colouring.
class TurnRing extends StatelessWidget {
  const TurnRing({
    super.key,
    required this.diameter,
    required this.fraction,
    required this.child,
  });

  final double diameter;
  final double fraction;
  final Widget child;

  static const _padding = 4.0;
  static const _strokeWidth = 3.0;

  static Color colorFor(double fraction) {
    final elapsed = 1 - fraction;
    if (elapsed < 0.60) return KarataColors.teal;
    if (elapsed < 0.85) return KarataColors.gold;
    return KarataColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final ringDiameter = diameter + _padding * 2;
    return SizedBox.square(
      dimension: ringDiameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(ringDiameter),
            painter: _TurnRingPainter(
              fraction: fraction.clamp(0.0, 1.0),
              color: colorFor(fraction),
              strokeWidth: _strokeWidth,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _TurnRingPainter extends CustomPainter {
  const _TurnRingPainter({
    required this.fraction,
    required this.color,
    required this.strokeWidth,
  });

  final double fraction;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - strokeWidth) / 2;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (fraction <= 0) return;
    final remaining = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    // Starts at 12 o'clock and drains clockwise, matching the avatar ring the spec describes.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      remaining,
    );
  }

  @override
  bool shouldRepaint(_TurnRingPainter old) =>
      old.fraction != fraction || old.color != color;
}
