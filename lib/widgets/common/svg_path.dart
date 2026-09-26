import 'dart:math' as math;
import 'dart:ui';

/// Parses the subset of SVG path syntax the Karata icons are drawn with.
///
/// The icons come straight out of the design as `d` attributes, and keeping them in that form
/// means an icon can be re-copied from a mockup without redrawing it by hand. Only the commands
/// the design actually uses are supported - move, line, horizontal, vertical, cubic, quadratic,
/// arc and close, in both absolute and relative spellings. Anything else throws, loudly, rather
/// than silently dropping a segment and leaving a half-drawn icon on screen.
///
/// Elliptical arcs assume no x-axis rotation, which holds for every arc in the icon set; a
/// rotated arc would need bezier approximation instead of [Path.arcTo].
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = _tokenize(d);
  var i = 0;
  var current = Offset.zero;
  var subpathStart = Offset.zero;
  Offset? lastCubicControl;
  var command = '';

  double next() {
    if (i >= tokens.length) {
      throw FormatException('Ran out of numbers in path: $d');
    }
    return tokens[i++] as double;
  }

  while (i < tokens.length) {
    if (tokens[i] is String) {
      command = tokens[i++] as String;
    } else if (command == 'M') {
      command = 'L'; // Repeated pairs after a moveto are implicit linetos.
    } else if (command == 'm') {
      command = 'l';
    }

    final relative = command.toLowerCase() == command;
    final origin = relative ? current : Offset.zero;

    switch (command.toUpperCase()) {
      case 'M':
        current = Offset(next(), next()) + origin;
        subpathStart = current;
        path.moveTo(current.dx, current.dy);
      case 'L':
        current = Offset(next(), next()) + origin;
        path.lineTo(current.dx, current.dy);
      case 'H':
        current = Offset(next() + origin.dx, current.dy);
        path.lineTo(current.dx, current.dy);
      case 'V':
        current = Offset(current.dx, next() + origin.dy);
        path.lineTo(current.dx, current.dy);
      case 'C':
        final c1 = Offset(next(), next()) + origin;
        final c2 = Offset(next(), next()) + origin;
        current = Offset(next(), next()) + origin;
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, current.dx, current.dy);
        lastCubicControl = c2;
      case 'S':
        final c1 = lastCubicControl == null
            ? current
            : current * 2 - lastCubicControl;
        final c2 = Offset(next(), next()) + origin;
        current = Offset(next(), next()) + origin;
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, current.dx, current.dy);
        lastCubicControl = c2;
      case 'Q':
        final c = Offset(next(), next()) + origin;
        current = Offset(next(), next()) + origin;
        path.quadraticBezierTo(c.dx, c.dy, current.dx, current.dy);
      case 'A':
        final rx = next();
        final ry = next();
        final rotation = next();
        final largeArc = next() != 0;
        final sweep = next() != 0;
        final end = Offset(next(), next()) + origin;
        _arcTo(path, current, end, rx, ry, rotation, largeArc, sweep);
        current = end;
      case 'Z':
        path.close();
        current = subpathStart;
      default:
        throw FormatException('Unsupported path command "$command" in: $d');
    }

    if (command.toUpperCase() != 'C' && command.toUpperCase() != 'S') {
      lastCubicControl = null;
    }
  }
  return path;
}

/// Splits a `d` attribute into command letters and numbers. SVG allows numbers to run together
/// without separators (`M1-2.5.3`), so this reads them character by character rather than
/// splitting on whitespace.
List<Object> _tokenize(String d) {
  final out = <Object>[];
  var i = 0;
  while (i < d.length) {
    final c = d[i];
    if (c == ' ' || c == ',' || c == '\n' || c == '\t' || c == '\r') {
      i++;
    } else if (RegExp(r'[A-Za-z]').hasMatch(c)) {
      out.add(c);
      i++;
    } else {
      final start = i;
      if (d[i] == '-' || d[i] == '+') i++;
      while (i < d.length && RegExp(r'[0-9.]').hasMatch(d[i])) {
        // A second '.' starts the next number: "1.5.3" is 1.5 then .3
        if (d[i] == '.' && d.substring(start, i).contains('.')) break;
        i++;
      }
      if (i < d.length && (d[i] == 'e' || d[i] == 'E')) {
        i++;
        if (i < d.length && (d[i] == '-' || d[i] == '+')) i++;
        while (i < d.length && RegExp(r'[0-9]').hasMatch(d[i])) {
          i++;
        }
      }
      if (i == start) throw FormatException('Bad character "$c" in path: $d');
      out.add(double.parse(d.substring(start, i)));
    }
  }
  return out;
}

/// Endpoint-to-centre arc conversion, per the SVG spec's implementation notes (F.6.5), reduced to
/// the unrotated case so the result can be handed to [Path.arcTo].
void _arcTo(
  Path path,
  Offset start,
  Offset end,
  double rx,
  double ry,
  double rotation,
  bool largeArc,
  bool sweep,
) {
  if (rotation != 0) {
    throw UnsupportedError('Rotated elliptical arcs are not supported');
  }
  if (rx == 0 || ry == 0 || start == end) {
    path.lineTo(end.dx, end.dy);
    return;
  }
  rx = rx.abs();
  ry = ry.abs();

  final dx2 = (start.dx - end.dx) / 2;
  final dy2 = (start.dy - end.dy) / 2;

  // Scale the radii up if they are too small to span the two endpoints.
  final lambda = (dx2 * dx2) / (rx * rx) + (dy2 * dy2) / (ry * ry);
  if (lambda > 1) {
    final s = math.sqrt(lambda);
    rx *= s;
    ry *= s;
  }

  final sign = largeArc == sweep ? -1.0 : 1.0;
  final numerator =
      rx * rx * ry * ry - rx * rx * dy2 * dy2 - ry * ry * dx2 * dx2;
  final denominator = rx * rx * dy2 * dy2 + ry * ry * dx2 * dx2;
  final coefficient = sign * math.sqrt(math.max(0, numerator / denominator));

  final cx = coefficient * rx * dy2 / ry + (start.dx + end.dx) / 2;
  final cy = -coefficient * ry * dx2 / rx + (start.dy + end.dy) / 2;

  final startAngle = math.atan2((start.dy - cy) / ry, (start.dx - cx) / rx);
  final endAngle = math.atan2((end.dy - cy) / ry, (end.dx - cx) / rx);
  var sweepAngle = endAngle - startAngle;
  if (sweep && sweepAngle < 0) {
    sweepAngle += 2 * math.pi;
  } else if (!sweep && sweepAngle > 0) {
    sweepAngle -= 2 * math.pi;
  }

  path.arcTo(
    Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
    startAngle,
    sweepAngle,
    false,
  );
}
