import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';

/// The blurred, rotating glow under the felt - gold and teal while a hand is live, a brighter
/// four-point gold burst once a winner is known.
class TableLight extends StatefulWidget {
  const TableLight({
    super.key,
    required this.size,
    this.winning = false,
    this.mobile = false,
  });

  /// The light's own box, drawn a little larger than the felt it sits behind.
  final Size size;

  final bool winning;

  /// The phone table turns a touch faster than the wide one.
  final bool mobile;

  @override
  State<TableLight> createState() => _TableLightState();
}

class _TableLightState extends State<TableLight>
    with TickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: _rotationDuration,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  Duration get _rotationDuration => widget.winning
      ? const Duration(milliseconds: 2500)
      : Duration(seconds: widget.mobile ? 8 : 9);

  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(TableLight old) {
    super.didUpdateWidget(old);
    if (old.winning != widget.winning || old.mobile != widget.mobile) {
      _rotation.duration = _rotationDuration;
      _apply();
    }
  }

  void _apply() {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _rotation.stop();
      _pulse.stop();
      return;
    }
    _rotation.repeat();
    if (widget.winning) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotation, _pulse]),
      builder: (context, _) {
        final opacity = widget.winning ? 0.7 + 0.3 * _pulse.value : 1.0;
        return ClipPath(
          clipper: _OvalClipper(),
          child: CustomPaint(
            size: widget.size,
            painter: _LightPainter(
              rotation: _rotation.value,
              winning: widget.winning,
              opacity: opacity,
            ),
          ),
        );
      },
    );
  }
}

class _OvalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));

  @override
  bool shouldReclip(_OvalClipper oldClipper) => false;
}

class _LightPainter extends CustomPainter {
  const _LightPainter({
    required this.rotation,
    required this.winning,
    required this.opacity,
  });

  final double rotation;
  final bool winning;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 1.6;
    final wedges = winning
        ? const [(0.0, 45.0), (90.0, 45.0), (180.0, 45.0), (270.0, 45.0)]
        : const [(20.0, 50.0), (200.0, 50.0)];
    final blur = winning ? 18.0 : 20.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);

    for (var i = 0; i < wedges.length; i++) {
      final (startDeg, sweepDeg) = wedges[i];
      final color = winning
          ? const Color(0xFFFFE278)
          : (i == 0 ? KarataColors.gold : KarataColors.teal);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.95 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startDeg * math.pi / 180,
          sweepDeg * math.pi / 180,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LightPainter old) =>
      old.rotation != rotation ||
      old.winning != winning ||
      old.opacity != opacity;
}
