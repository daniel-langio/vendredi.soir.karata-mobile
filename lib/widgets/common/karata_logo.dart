import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import 'dashed_path.dart';

/// Karata's mark: a gold coin with an orange dashed rim and a five-pip die at its centre.
///
/// Drawn rather than shipped as an image so it stays crisp at any size and needs no asset.
class KarataLogo extends StatelessWidget {
  const KarataLogo({super.key, this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: const _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  /// The design's viewBox. Every coordinate below is in these units.
  static const _viewBox = 200.0;

  /// The darker gold sitting 6 units low, which reads as the coin's thickness.
  static const _edge = Color(0xFF7A5410);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBox);

    const centre = Offset(100, 100);
    final fill = Paint()..isAntiAlias = true;

    // The coin's rim, offset downwards so it shows beneath the face.
    canvas.drawCircle(const Offset(100, 106), 94, fill..color = _edge);

    // The face, lit from the top-left.
    canvas.drawCircle(
      centre,
      94,
      fill
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KarataColors.goldBright, KarataColors.goldDeep],
        ).createShader(Rect.fromCircle(center: centre, radius: 94)),
    );
    fill.shader = null;

    // The orange dashed ring: `stroke-dasharray: 14 8 6 8` on a 16-wide stroke.
    canvas.drawPath(
      dashPath(circlePath(centre, 82), const [14, 8, 6, 8]),
      Paint()
        ..color = KarataColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..isAntiAlias = true,
    );

    // The navy well the die sits in.
    canvas.drawCircle(centre, 62, fill..color = KarataColors.backdrop);

    // The die, and its five pips.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(64, 64, 72, 72),
        const Radius.circular(16),
      ),
      fill..color = KarataColors.gold,
    );
    fill.color = KarataColors.onAccent;
    for (final pip in const [
      Offset(80, 80),
      Offset(120, 80),
      Offset(100, 100),
      Offset(80, 120),
      Offset(120, 120),
    ]) {
      canvas.drawCircle(pip, 8, fill);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}
