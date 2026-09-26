import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// The pot, printed on the felt under the board - where the chips it counts are sitting.
class PotAmount extends StatelessWidget {
  const PotAmount(this.amount, {super.key});

  /// Already formatted.
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Text(
      amount,
      textAlign: TextAlign.center,
      style: karataText(size: 18, weight: 800, color: KarataColors.white),
    );
  }
}
