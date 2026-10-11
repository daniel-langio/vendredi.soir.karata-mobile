import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/avatar.dart';
import 'seat_action_badge.dart';
import 'turn_ring.dart';
import 'winner_badge.dart';

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
    this.avatarDiameter = 56,
    this.nameSize = 12,
    this.stackSize = 13,
    this.cards,
    this.isWinner = false,
    this.turnFraction,
  });

  final String username;

  /// Already formatted - the seat lays out the number, it does not convert it.
  final String stack;

  final SeatAction? action;
  final String? actionLabel;
  final bool dimmed;
  final double width;

  /// The seat's own scale. The wide table draws a bigger avatar with bigger type under it, which
  /// is the only way the two seats differ.
  final double avatarDiameter;
  final double nameSize;
  final double stackSize;

  /// A revealed hand at showdown, shown in place of the avatar.
  final Widget? cards;

  /// Whether this is a showdown seat that took the pot - only meaningful alongside [cards].
  final bool isWinner;

  /// How much of this seat's turn clock is left, 1 down to 0 - drawn as a ring around their
  /// avatar. Null whenever it is not their turn.
  final double? turnFraction;

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
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  cards!,
                  // The avatar shrinks to a ring on top of the revealed pair - gold for the
                  // winner, a dim white for everyone else shown down.
                  Positioned(
                    top: -16,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: KarataColors.backdrop,
                        border: Border.all(
                          color: isWinner
                              ? KarataColors.gold
                              : const Color(0x4DFFFFFF),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (isWinner)
                    Positioned(
                      bottom: -12,
                      child: WinnerBadge(
                        label: actionLabel ?? '',
                        height: 24,
                      ),
                    ),
                ],
              )
            else
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  turnFraction == null
                      ? Avatar(
                          name: username,
                          diameter: avatarDiameter,
                          ringColor: const Color(0x40FFFFFF),
                        )
                      : TurnRing(
                          diameter: avatarDiameter,
                          fraction: turnFraction!,
                          child: Avatar(
                            name: username,
                            diameter: avatarDiameter,
                            ringColor: const Color(0x40FFFFFF),
                          ),
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
              style: karataText(size: nameSize, weight: 600),
            ),
            Text(
              stack,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: karataText(
                size: stackSize,
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
