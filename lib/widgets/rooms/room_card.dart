import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/clickable.dart';
import '../common/karata_button.dart';
import '../common/karata_icons.dart';
import 'room_card_state.dart';
import 'room_full_pill.dart';
import 'room_quiet_well.dart';
import 'room_stats_well.dart';
import 'room_tag.dart';

/// One stake tier in the lobby's Rooms tab, on the phone.
///
/// It offers a seat, not a table: there is no table list behind it and nothing here identifies
/// one. Tapping anywhere on the card does what its button does, the way [LobbyTableCard] works -
/// the button stays because the design draws it, and because it is what names the action.
class RoomCard extends StatelessWidget {
  const RoomCard({
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

  /// "Blinds 50 / 100 Ar".
  final String blindsLabel;

  /// "Hold'em".
  final String variantLabel;

  /// The second tag: "Cashout", "Play chips", "Seated" or "Full".
  final String statusLabel;
  final RoomTagTone statusTone;

  final RoomCardState state;

  final int tableCount;
  final String tablesLabel;
  final int playerCount;
  final String playersLabel;

  /// Shown instead of the counts while the room is [RoomCardState.quiet].
  final String quietTitle;
  final String quietCaption;

  /// "Default buy-in" / "You're in for", and the amount it introduces.
  final String footerPrefix;
  final String footerAmount;

  /// "Sit down", "Return to your table", or "Room full" on the pill that replaces the button.
  final String actionLabel;

  /// Null while the room cannot be sat at, which is also when [state] is [RoomCardState.full].
  final VoidCallback? onPressed;

  /// Both halves of the header are drawn to this height in the mockup, so a one-line name and a
  /// two-tag stack still line up with each other.
  static const _headerHeight = 58.0;

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // The stripe is laid over the card rather than beside it in a Row, because the card
            // is as tall as its own contents and a Row cannot stretch a sibling to a height it
            // has not worked out yet.
            const Positioned.fill(
              child: ColoredBox(color: KarataColors.surface),
            ),
            // The design's `border-left: 4px solid`, transparent - so the card's own navy shows
            // through - until the room has something to flag.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: ColoredBox(color: state.accent),
            ),
            Padding(
              // 4px of stripe plus the design's own 18px of padding inside it.
              padding: const EdgeInsets.fromLTRB(22, 16, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  state == RoomCardState.quiet
                      ? RoomQuietWell(title: quietTitle, caption: quietCaption)
                      : RoomStatsWell(
                          tableCount: tableCount,
                          tablesLabel: tablesLabel,
                          playerCount: playerCount,
                          playersLabel: playersLabel,
                        ),
                  const SizedBox(height: 14),
                  _footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            height: _headerHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: karataText(size: 20, weight: 800),
                ),
                const SizedBox(height: 2),
                Text(
                  blindsLabel,
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
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: _headerHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RoomTag(label: variantLabel),
              const SizedBox(height: 6),
              RoomTag(label: statusLabel, tone: statusTone),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return Row(
      children: [
        // Flexible rather than Expanded: the action is sized first, at whatever its label needs,
        // and the buy-in line takes what is left over - "Return to your table" is a good deal
        // wider than "Sit down", and it is the half that must not be cut.
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$footerPrefix '),
                TextSpan(
                  text: footerAmount,
                  style: karataText(
                    size: 13,
                    weight: 700,
                    // A price you cannot pay is not an offer, so the gold comes off it.
                    color: state == RoomCardState.full
                        ? KarataColors.inkFaint
                        : KarataColors.gold,
                  ),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: karataText(
              size: 13,
              weight: 500,
              color: KarataColors.inkMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (state == RoomCardState.full)
          RoomFullPill(label: actionLabel)
        else
          KarataButton(
            label: actionLabel,
            onPressed: onPressed,
            style: state == RoomCardState.seated
                ? KarataButtonStyle.surface
                : KarataButtonStyle.primary,
            trailingIcon: state == RoomCardState.seated
                ? KarataIcons.chevronRight
                : null,
            height: 42,
            expand: false,
            horizontalPadding: state == RoomCardState.seated ? 18 : 22,
          ),
      ],
    );
  }
}
