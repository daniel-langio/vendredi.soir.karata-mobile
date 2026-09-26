import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/dashed_ring.dart';
import '../common/section_card.dart';

/// The three-step explainer beside the balance on the wide wallet: deposit, play, withdraw.
///
/// Wide-only. The phone's wallet has no room for it and the mockups leave it off there, so it
/// appears on artboard 25 and nowhere else.
class HowItWorksCard extends StatelessWidget {
  const HowItWorksCard({super.key, required this.title, required this.steps});

  final String title;

  /// Each step as the lead word the design bolds and the sentence that follows it.
  final List<(String, String)> steps;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      children: [
        for (var i = 0; i < steps.length; i++)
          _Step(number: i + 1, lead: steps[i].$1, body: steps[i].$2),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.lead, required this.body});

  final int number;
  final String lead;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '$lead. ',
              style: karataText(size: 14, weight: 800, height: 1.45),
              children: [
                TextSpan(
                  text: body,
                  style: karataText(
                    size: 14,
                    weight: 500,
                    color: KarataColors.inkMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
