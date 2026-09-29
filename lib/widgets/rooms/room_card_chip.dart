import 'package:flutter/widgets.dart';

import '../common/dashed_path.dart';

/// The glossy gold casino token that peeks out from under a room card's felt.
///
/// Unlike [ChipGlyph] it carries no denomination - it is the card's own decoration, not a stand-in
/// for an amount, which is why it gets its own painter rather than a third [ChipGlyph] variant.
class RoomCardChip extends StatelessWidget {
  const RoomCardChip({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 4,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: CustomPaint(painter: _RoomCardChipPainter()),
      ),
    );
  }
}

class _RoomCardChipPainter extends CustomPainter {
  const _RoomCardChipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200);

    // The rim: a flat disc peeking out from under the face, offset down to read as thickness.
    canvas.drawCircle(
      const Offset(100, 106),
      94,
      Paint()..color = const Color(0xFF8A6206),
    );

    canvas.drawCircle(
      const Offset(100, 100),
      94,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE066), Color(0xFFC48F0E)],
        ).createShader(const Rect.fromLTWH(6, 6, 188, 188)),
    );
    canvas.drawPath(
      dashPath(circlePath(const Offset(100, 100), 80), const [24, 36]),
      Paint()
        ..color = const Color(0xFFFFF1A8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..isAntiAlias = true,
    );

    canvas.drawCircle(
      const Offset(100, 100),
      60,
      Paint()..color = const Color(0xFFB8860B),
    );
    canvas.drawCircle(
      const Offset(100, 100),
      54,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3C52E), Color(0xFFD49D12)],
        ).createShader(const Rect.fromLTWH(46, 46, 108, 108)),
    );
    canvas.drawPath(
      dashPath(circlePath(const Offset(100, 100), 48), const [4, 6]),
      Paint()
        ..color = const Color(0xB2FFF1A8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = true,
    );

    // The token's center glyph, traced from the design's own path.
    final glyph = Path()
      ..moveTo(12, 2)
      ..cubicTo(8, 7, 3, 10, 3, 14)
      ..cubicTo(3, 17, 5.5, 19, 8, 19)
      ..cubicTo(9.5, 19, 10.7, 18.3, 11.3, 17.5)
      ..lineTo(10, 22)
      ..lineTo(14, 22)
      ..lineTo(12.7, 17.5)
      ..cubicTo(13.3, 18.3, 14.5, 19, 16, 19)
      ..cubicTo(18.5, 19, 21, 17, 21, 14)
      ..cubicTo(21, 10, 16, 7, 12, 2)
      ..close();
    canvas.translate(78, 78);
    canvas.scale(1.8);
    canvas.drawPath(glyph, Paint()..color = const Color(0xFF5E3F00));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoomCardChipPainter oldDelegate) => false;
}
