import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../common/status_pill.dart';

/// What a seat last did, or is being asked to do, shown as a pill tucked under their avatar.
enum SeatAction { waiting, turn, checked, called, bet, folded, allIn, winner }

/// The pill under a seat's avatar - "Fold", "Call 8", "Your turn", "Winner".
class SeatActionBadge extends StatelessWidget {
  const SeatActionBadge({super.key, required this.action, required this.label});

  final SeatAction action;

  /// The already-localised text, since a call or a bet carries its amount with it.
  final String label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, ring) = switch (action) {
      SeatAction.turn => (
        KarataColors.blue,
        KarataColors.white,
        const Color(0xFFA8C6F0),
      ),
      SeatAction.checked || SeatAction.called || SeatAction.bet => (
        KarataColors.teal,
        KarataColors.white,
        KarataColors.tealLight,
      ),
      SeatAction.allIn => (
        KarataColors.orange,
        KarataColors.white,
        KarataColors.goldWash,
      ),
      SeatAction.winner => (
        KarataColors.gold,
        KarataColors.onGoldBadge,
        KarataColors.goldWash,
      ),
      // Folded and waiting share the muted navy chip.
      _ => (
        const Color(0xFF35355F),
        KarataColors.inkMuted,
        const Color(0xFF6C6B92),
      ),
    };

    return StatusPill(
      label: label,
      height: 22,
      background: background,
      foreground: foreground,
      ringColor: ring,
    );
  }
}
