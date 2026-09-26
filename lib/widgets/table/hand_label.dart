import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// The name of the hand on the felt - "Pair of aces", "Two pair" - under the board it describes.
class HandLabel extends StatelessWidget {
  const HandLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: karataText(size: 18, weight: 800, color: KarataColors.gold),
    );
  }
}
