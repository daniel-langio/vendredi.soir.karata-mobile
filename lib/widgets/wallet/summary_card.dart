import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/karata_card.dart';

/// One line of a money breakdown: what it is on the left, how much on the right.
typedef SummaryLine = ({String label, String value, bool emphasised});

/// The card that totals up a deposit or a withdrawal - "Chips you get / Fee / You pay", with the
/// figure that actually moves picked out in gold.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.lines});

  final List<SummaryLine> lines;

  @override
  Widget build(BuildContext context) {
    return KarataCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in lines) ...[
            if (line != lines.first) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    line.label,
                    style: karataText(
                      size: 14,
                      weight: 500,
                      color: KarataColors.inkMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  line.value,
                  style: line.emphasised
                      ? karataText(
                          size: 22,
                          weight: 800,
                          color: KarataColors.gold,
                        )
                      : karataText(size: 15, weight: 800),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
