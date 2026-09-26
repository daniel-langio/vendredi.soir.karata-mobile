import 'package:flutter/widgets.dart';

import 'svg_path.dart';

/// One shape inside an icon. The design's icons are a mix of `<path>`, `<circle>` and `<rect>`,
/// and keeping that distinction avoids having to re-express a circle as four arcs by hand.
sealed class IconShape {
  const IconShape();
}

class PathShape extends IconShape {
  const PathShape(this.d);
  final String d;
}

class CircleShape extends IconShape {
  const CircleShape(this.cx, this.cy, this.r);
  final double cx, cy, r;
}

class RectShape extends IconShape {
  const RectShape(this.x, this.y, this.width, this.height, {this.radius = 0});
  final double x, y, width, height, radius;
}

/// An icon as the design draws it: shapes on a 24x24 viewBox, stroked rather than filled unless
/// [filled] says otherwise.
class KarataIconData {
  const KarataIconData(
    this.shapes, {
    this.filled = false,
    this.strokeWidth = 2.2,
    this.viewBox = 24,
  });

  final List<IconShape> shapes;
  final bool filled;
  final double strokeWidth;
  final double viewBox;
}

/// Draws a [KarataIconData] at [size], scaled from its viewBox.
class KarataIcon extends StatelessWidget {
  const KarataIcon(this.icon, {super.key, this.size = 20, required this.color});

  final KarataIconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _IconPainter(icon, color)),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.color);

  final KarataIconData icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / icon.viewBox;
    canvas.save();
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    if (icon.filled) {
      paint.style = PaintingStyle.fill;
    } else {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = icon.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    }

    for (final shape in icon.shapes) {
      switch (shape) {
        case PathShape(:final d):
          canvas.drawPath(parseSvgPath(d), paint);
        case CircleShape(:final cx, :final cy, :final r):
          canvas.drawCircle(Offset(cx, cy), r, paint);
        case RectShape(
          :final x,
          :final y,
          :final width,
          :final height,
          :final radius,
        ):
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, width, height),
              Radius.circular(radius),
            ),
            paint,
          );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.icon != icon;
}
