import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The faint concentric rings behind the balance card:
/// `repeating-radial-gradient(circle at 85% 30%, rgba(233,196,106,0.07) 0 1px, transparent 1px 9px)`.
///
/// A hard-stop repeating radial gradient is a set of 1px rings every 9px, which is what this
/// draws - Flutter has no repeating gradient, and a [SweepGradient] cannot express one.
class RippleTexture extends StatelessWidget {
  const RippleTexture({
    super.key,
    this.color = const Color(0x12E9C46A),
    this.origin = const Offset(0.85, 0.30),
    this.spacing = 9,
  });

  final Color color;

  /// Where the rings radiate from, as a fraction of the box.
  final Offset origin;

  final double spacing;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RipplePainter(color, origin, spacing),
      size: Size.infinite,
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter(this.color, this.origin, this.spacing);

  final Color color;
  final Offset origin;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width * origin.dx, size.height * origin.dy);
    // Far enough to cover whichever corner is furthest from the origin.
    final reach = math.sqrt(
      math.pow(math.max(centre.dx, size.width - centre.dx), 2) +
          math.pow(math.max(centre.dy, size.height - centre.dy), 2),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;

    canvas.clipRect(Offset.zero & size);
    for (var r = spacing; r < reach; r += spacing) {
      canvas.drawCircle(centre, r, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.origin != origin ||
      oldDelegate.spacing != spacing;
}
