import 'dart:ui';

/// Rewrites [source] as a run of dashes following an SVG-style `stroke-dasharray` [pattern] of
/// alternating on/off lengths.
///
/// Flutter has no dashed stroke, and the design leans on them - the logo's ring, the "seats open"
/// marker, the dashed chip on a pending-payout badge. Walking the path's metrics is the only way
/// to get dashes that follow a curve rather than a straight edge.
Path dashPath(Path source, List<double> pattern) {
  assert(pattern.isNotEmpty, 'A dash pattern needs at least one length');
  final dashed = Path();
  // An odd-length dasharray repeats to become even, exactly as SVG specifies: "4 2 1" means
  // 4 on, 2 off, 1 on, 4 off, 2 on, 1 off.
  final lengths = pattern.length.isEven ? pattern : [...pattern, ...pattern];

  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    var index = 0;
    var drawing = true;
    while (distance < metric.length) {
      final step = lengths[index % lengths.length];
      final end = (distance + step).clamp(0.0, metric.length);
      if (drawing && step > 0) {
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
      }
      distance = end;
      drawing = !drawing;
      index++;
    }
  }
  return dashed;
}

/// A circle as a [Path], starting at the top and running clockwise.
Path circlePath(Offset center, double radius) =>
    Path()..addOval(Rect.fromCircle(center: center, radius: radius));
