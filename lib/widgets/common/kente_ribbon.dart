import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';

/// The woven stripe that runs along the top of the page and of most cards.
///
/// The mockups draw it as a CSS `repeating-linear-gradient` with hard stops, so it is a run of
/// flat bands rather than a blend - painted here as plain rects on a 44px cycle, the same cycle
/// the design uses.
class KenteRibbon extends StatelessWidget {
  const KenteRibbon({super.key, this.height = 6});

  final double height;

  /// One cycle of the weave: (width, colour), summing to [_cycle].
  static const _bands = <(double, Color)>[
    (14, KarataColors.orange),
    (4, KarataColors.gold),
    (12, KarataColors.teal),
    (4, KarataColors.gold),
    (10, KarataColors.tealDeep),
  ];

  static const _cycle = 44.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: const _KentePainter()),
    );
  }
}

class _KentePainter extends CustomPainter {
  const _KentePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var origin = 0.0; origin < size.width; origin += KenteRibbon._cycle) {
      var x = origin;
      for (final (width, color) in KenteRibbon._bands) {
        paint.color = color;
        canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
        x += width;
      }
    }
  }

  @override
  bool shouldRepaint(_KentePainter oldDelegate) => false;
}
