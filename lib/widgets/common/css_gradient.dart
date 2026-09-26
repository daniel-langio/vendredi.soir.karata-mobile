import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Builds a [LinearGradient] from a CSS angle, so a gradient can be transcribed from the design
/// as written rather than converted by hand.
///
/// CSS measures the angle clockwise from "to top", which puts 0deg pointing up, 90deg right and
/// 180deg down. Flutter instead wants the two endpoints in [Alignment] space, with y growing
/// downwards.
LinearGradient cssLinearGradient({
  required double angleDegrees,
  required List<Color> colors,
  List<double>? stops,
}) {
  final radians = angleDegrees * math.pi / 180;
  final dx = math.sin(radians);
  final dy = -math.cos(radians);
  return LinearGradient(
    begin: Alignment(-dx, -dy),
    end: Alignment(dx, dy),
    colors: colors,
    stops: stops,
  );
}

/// The shader for a CSS `radial-gradient(ellipse at X% Y%, ...)` under its default
/// `farthest-corner` sizing, over a box of [size].
///
/// Flutter's [RadialGradient] draws a circle scaled by the box's shortest side, which is not the
/// shape CSS produces: on a box that is much taller than it is wide - the page backdrop, the teal
/// panel beside the auth screens - the two differ enough to move where the colour stops
/// changing. Building the shader against an elliptical rect instead puts the falloff where the
/// mockups put it at any size.
///
/// CSS sizes a `farthest-corner` ellipse by taking the farthest-side ellipse and growing it until
/// it passes through the farthest corner. Because that corner sits at exactly the farthest-side
/// distance on both axes, solving (x/ka)^2 + (y/kb)^2 = 1 always gives k = sqrt(2) - so the radii
/// are just the farthest-side distances scaled by it.
Shader cssRadialGradient({
  required Size size,
  required Offset origin,
  required List<Color> colors,
  required List<double> stops,
}) {
  final center = Offset(size.width * origin.dx, size.height * origin.dy);
  final radiusX = math.max(center.dx, size.width - center.dx) * math.sqrt2;
  final radiusY = math.max(center.dy, size.height - center.dy) * math.sqrt2;
  return RadialGradient(colors: colors, stops: stops).createShader(
    Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2),
  );
}
