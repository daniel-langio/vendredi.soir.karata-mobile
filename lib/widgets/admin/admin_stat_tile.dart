import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/karata_card.dart';

/// One figure across the top of an admin list - how many rooms there are, how many players are
/// seated right now.
///
/// The caption underneath is where the number is qualified ("2 empty, 1 full"), because a bare
/// count on an operator's dashboard invites exactly the wrong reading of it.
class AdminStatTile extends StatelessWidget {
  const AdminStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return KarataCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: karataText(size: 13, weight: 600, color: KarataColors.gold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            style: karataText(size: 28, weight: 800, height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: karataText(
              size: 13,
              weight: 500,
              color: KarataColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
