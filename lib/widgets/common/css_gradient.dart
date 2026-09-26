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
