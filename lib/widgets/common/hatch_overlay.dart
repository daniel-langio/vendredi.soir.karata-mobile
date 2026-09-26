import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The woven sheen on a card face:
/// `repeating-linear-gradient(135deg, rgba(255,255,255,0.07) 0 3px, transparent 3px 9px)`.
///
/// A hard-stop repeating linear gradient is a set of parallel stripes, so this draws them
/// directly: [stripe] wide, every [spacing], running perpendicular to the CSS angle.
class HatchOverlay extends StatelessWidget {
  const HatchOverlay({
    super.key,
    this.color = const Color(0x12FFFFFF),
    this.angleDegrees = 135,
    this.stripe = 3,
    this.spacing = 9,
  });

  final Color color;
  final double angleDegrees;
  final double stripe;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HatchPainter(color, angleDegrees, stripe, spacing),
      size: Size.infinite,
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.color, this.angleDegrees, this.stripe, this.spacing);

  final Color color;
  final double angleDegrees;
  final double stripe;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final radians = angleDegrees * math.pi / 180;
    // The axis the pattern repeats along, in CSS's clockwise-from-up convention.
    final normal = Offset(math.sin(radians), -math.cos(radians));
    // Stripes run across that axis.
    final along = Offset(-normal.dy, normal.dx);

    final centre = size.center(Offset.zero);
    final reach = size.width + size.height;
    final paint = Paint()
      ..color = color
      ..strokeWidth = stripe
      ..isAntiAlias = false;

    canvas.clipRect(Offset.zero & size);
    for (var d = -reach; d < reach; d += spacing) {
      final anchor = centre + normal * d;
      canvas.drawLine(anchor - along * reach, anchor + along * reach, paint);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.angleDegrees != angleDegrees ||
      oldDelegate.stripe != stripe ||
      oldDelegate.spacing != spacing;
}
