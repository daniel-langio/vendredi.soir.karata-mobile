import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/avatar.dart';
import 'seat_action_badge.dart';

/// One player around the table: their avatar, what they last did, their name and their stack.
///
/// A seat that is out of the hand drops to 38% opacity as a whole rather than being restyled
/// piece by piece, which is how the design greys a folded player out.
class TableSeat extends StatelessWidget {
  const TableSeat({
    super.key,
    required this.username,
    required this.stack,
    this.action,
    this.actionLabel,
    this.dimmed = false,
    this.width = 110,
    this.cards,
  });

  final String username;

  /// Already formatted - the seat lays out the number, it does not convert it.
  final String stack;

  final SeatAction? action;
  final String? actionLabel;
  final bool dimmed;
  final double width;

  /// A revealed hand at showdown, shown in place of the avatar.
  final Widget? cards;

  @override
  Widget build(BuildContext context) {
    final badge = action != null && actionLabel != null;

    return Opacity(
      opacity: dimmed ? 0.38 : 1,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cards != null)
              cards!
            else
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Avatar(
                    name: username,
                    diameter: 56,
                    ringColor: const Color(0x40FFFFFF),
                  ),
                  if (badge)
                    Positioned(
                      bottom: -10,
                      child: SeatActionBadge(
                        action: action!,
                        label: actionLabel!,
                      ),
                    ),
                ],
              ),
            // The name clears the badge where there is one, since it hangs below the avatar.
            SizedBox(height: badge || cards != null ? 16 : 8),
            Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: karataText(size: 12, weight: 600),
            ),
            Text(
              stack,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: karataText(
                size: 13,
                weight: 800,
                color: KarataColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
