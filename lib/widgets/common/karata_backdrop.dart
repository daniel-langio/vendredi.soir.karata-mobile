import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';

/// The page background: `radial-gradient(ellipse at 50% -10%, #23234a 0%, #14142a 55%)`.
///
/// Flutter's [RadialGradient] draws a circle scaled by the shortest side, which is not the shape
/// CSS produces for an `ellipse` under the default `farthest-corner` sizing - on a tall phone the
/// two differ enough to move where the navy stops lightening. This paints the CSS geometry so the
/// falloff lands where the mockups put it at any screen size.
class KarataBackdrop extends StatelessWidget {
  const KarataBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _BackdropPainter(), child: child);
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  /// The gradient's origin as a fraction of the box: `at 50% -10%`.
  static const _origin = Offset(0.5, -0.1);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * _origin.dx, size.height * _origin.dy);

    // CSS sizes a `farthest-corner` ellipse by taking the farthest-side ellipse and growing it
    // until it passes through the farthest corner. Because the farthest corner sits at exactly
    // the farthest-side distance on both axes, solving (x/ka)^2 + (y/kb)^2 = 1 always gives
    // k = sqrt(2) - so the radii are just the farthest-side distances scaled by that.
    final radiusX = math.max(center.dx, size.width - center.dx) * math.sqrt2;
    final radiusY = math.max(center.dy, size.height - center.dy) * math.sqrt2;

    final paint = Paint()
      ..shader =
          const RadialGradient(
            colors: [KarataColors.backdropTop, KarataColors.backdrop],
            stops: [0, 0.55],
          ).createShader(
            Rect.fromCenter(
              center: center,
              width: radiusX * 2,
              height: radiusY * 2,
            ),
          );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => false;
}
