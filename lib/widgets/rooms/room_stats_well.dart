import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/karata_icon.dart';
import '../common/karata_icons.dart';

/// The sunken strip across a room card reporting how busy the room is: how many of its tables
/// have someone at them, and how many people that is in total.
///
/// Only drawn for a room that has both - a room with neither shows [RoomQuietWell] instead,
/// because "0 tables / 0 players" printed in the same shape reads like a failed load.
class RoomStatsWell extends StatelessWidget {
  const RoomStatsWell({
    super.key,
    required this.tableCount,
    required this.tablesLabel,
    required this.playerCount,
    required this.playersLabel,
    this.height = 58,
    this.gap = 18,
  });

  final int tableCount;
  final String tablesLabel;
  final int playerCount;
  final String playersLabel;

  /// 58 on the phone card, 62 on the wide row.
  final double height;

  /// The space between the two counts - wider on the wide row, which has more of it.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Count(
            icon: KarataIcons.pokerTable,
            value: '$tableCount',
            label: tablesLabel,
          ),
          SizedBox(width: gap),
          Flexible(
            child: _Count(
              icon: KarataIcons.players,
              value: '$playerCount',
              label: playersLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.value, required this.label});

  final KarataIconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KarataIcon(icon, size: 15, color: KarataColors.inkMuted),
        const SizedBox(width: 6),
        Text(value, style: karataText(size: 14, weight: 800)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: karataText(
              size: 13,
              weight: 500,
              color: KarataColors.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}
