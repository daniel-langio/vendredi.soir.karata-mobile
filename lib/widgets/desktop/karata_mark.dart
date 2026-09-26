import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../common/dashed_path.dart';

/// The compact Karata mark the wide layout wears in its sidebar: a gold disc inside a dashed
/// laterite ring, with a die face punched into the middle of it.
///
/// This is deliberately not [KarataLogo]. The phone screens and the three auth screens show the
/// app icon - the two fanned cards, the same artwork as the launcher icon - but all nine sidebar
/// drawings in the V2 desktop set draw this instead, at 34px beside a 26px wordmark. It is drawn
/// rather than shipped as an asset because it is nine flat shapes on a 200-unit box, and a
/// CustomPaint of it stays sharp at any size without a second PNG to keep in step with the first.
class KarataMark extends StatelessWidget {
  const KarataMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  /// The drawing's own box; every coordinate below is in these units.
  static const _viewBox = 200.0;

  /// The five pips of a die's five-face, as the mockup places them.
  static const _pips = [
    Offset(82, 82),
    Offset(118, 82),
    Offset(100, 100),
    Offset(82, 118),
    Offset(118, 118),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBox);

    const center = Offset(100, 100);
    final fill = Paint()..isAntiAlias = true;

    canvas.drawCircle(center, 94, fill..color = KarataColors.gold);

    // `stroke-dasharray: 14 8 6 8` - a long dash and a short one alternating, which is what gives
    // the ring its woven look at the size it is actually seen.
    canvas.drawPath(
      dashPath(circlePath(center, 80), const [14, 8, 6, 8]),
      Paint()
        ..color = KarataColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..isAntiAlias = true,
    );

    canvas.drawCircle(center, 60, fill..color = KarataColors.backdrop);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(66, 66, 68, 68),
        const Radius.circular(14),
      ),
      fill..color = KarataColors.gold,
    );
    for (final pip in _pips) {
      canvas.drawCircle(pip, 8, fill..color = KarataColors.onAccent);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
