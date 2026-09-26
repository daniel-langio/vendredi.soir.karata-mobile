import 'package:flutter/widgets.dart';

import '../common/dashed_border.dart';

/// A board position the deal has not reached yet.
///
/// Drawn rather than left out, so the board is always five slots wide: the row keeps its size
/// from preflop to river, and nothing on the felt shifts as cards arrive.
class EmptyCardSlot extends StatelessWidget {
  const EmptyCardSlot({super.key, this.width = 52});

  final double width;

  double get height => width * 1.385;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const DashedBorder(
        color: Color(0x24FFFFFF),
        background: Color(0x29000000),
        radius: 7,
        strokeWidth: 1.5,
        child: SizedBox.expand(),
      ),
    );
  }
}
