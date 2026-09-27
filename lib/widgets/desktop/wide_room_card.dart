import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/clickable.dart';
import '../common/karata_button.dart';
import '../common/karata_icons.dart';
import '../rooms/room_card_state.dart';
import '../rooms/room_full_pill.dart';
import '../rooms/room_quiet_well.dart';
import '../rooms/room_stats_well.dart';
import '../rooms/room_tag.dart';

/// The same room as [RoomCard], laid out as the wide layout's full-width row.
///
/// The phone stacks the four pieces; here they run along one 106px line, which is why the list is
/// one room per row rather than the two-up grid the tables use - a room is a short line of facts,
/// not a tile.
class WideRoomCard extends StatelessWidget {
  const WideRoomCard({
    super.key,
    required this.name,
    required this.blindsLabel,
    required this.variantLabel,
    required this.statusLabel,
    required this.statusTone,
    required this.state,
    required this.tableCount,
    required this.tablesLabel,
    required this.playerCount,
    required this.playersLabel,
    required this.quietTitle,
    required this.quietCaption,
    required this.footerPrefix,
    required this.footerAmount,
    required this.actionLabel,
    required this.onPressed,
  });

  final String name;
  final String blindsLabel;
  final String variantLabel;
  final String statusLabel;
  final RoomTagTone statusTone;
  final RoomCardState state;
  final int tableCount;
  final String tablesLabel;
  final int playerCount;
  final String playersLabel;
  final String quietTitle;
  final String quietCaption;
  final String footerPrefix;
  final String footerAmount;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // The stripe is laid over the row rather than beside it, so it does not have to be
            // stretched to a height the row has not worked out yet.
            const Positioned.fill(
              child: ColoredBox(color: KarataColors.surface),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: ColoredBox(color: state.accent),
            ),
            Padding(
              // 5px of stripe plus the design's own 26px of padding inside it.
              padding: const EdgeInsets.fromLTRB(31, 22, 26, 22),
              child: SizedBox(
                height: 62,
                // The mockup pins each column to a pixel width, which it can do because its
                // sample stakes are three-digit. Real amounts in Ariary are far longer, and
                // fixed columns simply cut them off - so the three text columns share the row
                // in the mockup's proportions instead, and the tags and the button keep the
                // width they need.
                child: Row(
                  children: [
                    Expanded(flex: 5, child: _identity()),
                    const SizedBox(width: 20),
                    Flexible(flex: 7, child: _well()),
                    const SizedBox(width: 20),
                    _tags(),
                    const SizedBox(width: 20),
                    // The widest share of the three, because the buy-in is the number the row
                    // exists to quote and half of it is worse than half the room's name.
                    Flexible(flex: 6, child: _buyIn()),
                    const SizedBox(width: 20),
                    _action(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identity() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: karataText(size: 24, weight: 800),
        ),
        const SizedBox(height: 4),
        Text(
          blindsLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: karataText(
            size: 14,
            weight: 500,
            color: KarataColors.inkMuted,
          ),
        ),
      ],
    );
  }

  Widget _well() {
    return state == RoomCardState.quiet
        ? RoomQuietWell(title: quietTitle, caption: quietCaption, height: 62)
        : RoomStatsWell(
            tableCount: tableCount,
            tablesLabel: tablesLabel,
            playerCount: playerCount,
            playersLabel: playersLabel,
            height: 62,
            gap: 16,
          );
  }

  Widget _tags() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoomTag(label: variantLabel),
        const SizedBox(width: 8),
        RoomTag(label: statusLabel, tone: statusTone),
      ],
    );
  }

  Widget _buyIn() {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$footerPrefix '),
          TextSpan(
            text: footerAmount,
            style: karataText(
              size: 14,
              weight: 700,
              color: state == RoomCardState.full
                  ? KarataColors.inkFaint
                  : KarataColors.gold,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: karataText(size: 14, weight: 500, color: KarataColors.inkMuted),
    );
  }

  Widget _action() {
    if (state == RoomCardState.full) {
      return RoomFullPill(label: actionLabel, height: 46);
    }
    return KarataButton(
      label: actionLabel,
      onPressed: onPressed,
      style: state == RoomCardState.seated
          ? KarataButtonStyle.surface
          : KarataButtonStyle.primary,
      trailingIcon: state == RoomCardState.seated
          ? KarataIcons.chevronRight
          : null,
      height: 46,
      expand: false,
      horizontalPadding: 22,
    );
  }
}
