import 'package:flutter/widgets.dart';

import 'dashed_path.dart';

/// The small dashed circle the design uses as a chip glyph - beside "Seats open", and on the
/// gold badge that counts pending payouts.
class DashedRing extends StatelessWidget {
  const DashedRing({
    super.key,
    required this.diameter,
    required this.color,
    this.strokeWidth = 2,
  });

  final double diameter;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: diameter,
      child: CustomPaint(painter: _RingPainter(color, strokeWidth)),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.color, this.strokeWidth);

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width - strokeWidth) / 2;
    // CSS `border: Npx dashed` picks its own dash length; browsers settle near three times the
    // border width, which is the proportion reproduced here.
    final dash = strokeWidth * 3;
    canvas.drawPath(
      dashPath(circlePath(size.center(Offset.zero), radius), [dash, dash]),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
