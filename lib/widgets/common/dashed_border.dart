import 'package:flutter/widgets.dart';

import 'dashed_path.dart';

/// A rounded panel outlined with a dashed stroke - the design's way of marking something as
/// provisional: an instruction you have not carried out yet, a step you have not finished.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 18,
    this.strokeWidth = 1.5,
    this.background,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color, radius, strokeWidth, background),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter(
    this.color,
    this.radius,
    this.strokeWidth,
    this.background,
  );

  final Color color;
  final double radius;
  final double strokeWidth;
  final Color? background;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    if (background != null) {
      canvas.drawRRect(outline, Paint()..color = background!);
    }

    // CSS picks its own dash length for `border: Npx dashed`; browsers land near three times the
    // border width, which is the proportion used here.
    final dash = strokeWidth * 3;
    canvas.drawPath(
      dashPath(Path()..addRRect(outline), [dash, dash]),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.background != background;
}
