import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small hand-drawn poker chip - purely decorative (pot stacks, dealer marker background),
/// not meant to represent a real denomination.
class ChipIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ChipIcon({super.key, this.size = 18, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ChipPainter(color: color)),
    );
  }
}

class _ChipPainter extends CustomPainter {
  final Color color;
  _ChipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, Paint()..color = color);

    final rimWidth = radius * 0.16;
    canvas.drawCircle(
      center,
      radius - rimWidth / 2,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimWidth,
    );

    // Evenly spaced edge notches - the classic chip-edge look.
    final notchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.2
      ..strokeCap = StrokeCap.round;
    const notchCount = 6;
    for (var i = 0; i < notchCount; i++) {
      final angle = (2 * math.pi / notchCount) * i;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius * 0.72),
        center + direction * (radius * 0.92),
        notchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChipPainter oldDelegate) =>
      oldDelegate.color != color;
}
