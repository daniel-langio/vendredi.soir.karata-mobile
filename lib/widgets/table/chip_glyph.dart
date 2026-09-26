import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/dashed_path.dart';

/// A casino chip, drawn at the denomination it stands for.
///
/// The design cuts three: a lavender 1, a laterite 5 and a teal 25. Only the wide layout shows
/// them - the phone's table prints the pot as a bare number, which is what its own mockup does.
enum ChipDenomination {
  one(1, KarataColors.chipPale, Color(0xFF3A3A5C), 7.5),
  five(5, KarataColors.orange, Color(0xFF8A3417), 7.5),
  twentyFive(25, KarataColors.teal, Color(0xFF0D5048), 6.5);

  const ChipDenomination(this.value, this.face, this.ink, this.labelSize);

  final int value;
  final Color face;
  final Color ink;

  /// 25 needs two digits in the same well, so the design drops its type a point.
  final double labelSize;

  /// Highest first, which is the order the greedy breakdown in [chipsFor] wants.
  static const ladder = [twentyFive, five, one];
}

/// Which chips stand in for [amount].
///
/// The mockups print one or two: the largest denomination a greedy breakdown of the amount uses,
/// and the smallest. Artboard 07 draws a pot of 3 as a single 1, a pot of 62 as 25 and 1, and
/// artboard 03 draws a bet of 35 as 25 and 5 - which is exactly that rule, since 62 breaks into
/// 25s, 5s and 1s while 35 breaks into a 25 and two 5s.
List<ChipDenomination> chipsFor(int amount) {
  if (amount <= 0) return const [];
  final used = <ChipDenomination>[];
  var left = amount;
  for (final chip in ChipDenomination.ladder) {
    if (left >= chip.value) {
      used.add(chip);
      left %= chip.value;
    }
  }
  if (used.isEmpty) return const [];
  return used.length == 1 ? [used.first] : [used.first, used.last];
}

/// One chip: a coloured disc, a dashed white edge, and the denomination in a white well.
class ChipGlyph extends StatelessWidget {
  const ChipGlyph(this.denomination, {super.key, this.size = 22});

  final ChipDenomination denomination;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ChipPainter(denomination),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              // The white well is r=5.5 on a 22-unit chip; the label lives inside it.
              padding: EdgeInsets.all(size * (11 - 5.5) / 22),
              child: Text(
                '${denomination.value}',
                style: karataText(
                  size: denomination.labelSize * size / 22,
                  weight: 800,
                  color: denomination.ink,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  const _ChipPainter(this.denomination);

  final ChipDenomination denomination;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 22);
    const centre = Offset(11, 11);
    final paint = Paint()..isAntiAlias = true;

    canvas.drawCircle(centre, 10, paint..color = denomination.face);
    canvas.drawPath(
      dashPath(circlePath(centre, 8), const [2.2, 2.4]),
      Paint()
        ..color = KarataColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..isAntiAlias = true,
    );
    canvas.drawCircle(centre, 5.5, paint..color = KarataColors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChipPainter oldDelegate) =>
      oldDelegate.denomination != denomination;
}

/// The row of chips standing in for an amount, on the design's 3px gap.
class ChipStack extends StatelessWidget {
  const ChipStack({super.key, required this.amount, this.size = 22});

  final int amount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final chips = chipsFor(amount);
    if (chips.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          ChipGlyph(chips[i], size: size),
        ],
      ],
    );
  }
}
