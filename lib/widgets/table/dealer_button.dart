import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// The dealer button, parked beside whichever seat is on the button.
class DealerButton extends StatelessWidget {
  const DealerButton({super.key, this.diameter = 22});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: KarataColors.gold,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'D',
        style: karataText(
          size: diameter * 0.55,
          weight: 800,
          color: KarataColors.onAccent,
          height: 1,
        ),
      ),
    );
  }
}
