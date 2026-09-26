import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/dashed_ring.dart';

/// A numbered step on the deposit and withdrawal screens - the number inside a dashed gold chip,
/// the step's name beside it.
class StepHeading extends StatelessWidget {
  const StepHeading({super.key, required this.number, required this.label});

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const DashedRing(diameter: 26, color: KarataColors.gold),
              Text(
                '$number',
                style: karataText(
                  size: 13,
                  weight: 800,
                  color: KarataColors.gold,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: karataText(size: 17, weight: 800))),
      ],
    );
  }
}
