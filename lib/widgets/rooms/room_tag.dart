import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// What a [RoomTag] is saying, which is the only thing that changes its colours.
enum RoomTagTone {
  /// The variant, and "Play chips" on a room whose winnings never leave the table.
  neutral,

  /// This room's chips convert back to real money.
  cashout,

  /// You are already sitting in this room.
  seated,

  /// Every seat the room is allowed to open is taken.
  full,
}

extension on RoomTagTone {
  Color get foreground => switch (this) {
    RoomTagTone.neutral => KarataColors.inkMuted,
    RoomTagTone.cashout => KarataColors.teal,
    RoomTagTone.seated => KarataColors.gold,
    RoomTagTone.full => KarataColors.orangeLight,
  };

  Color get background => switch (this) {
    RoomTagTone.neutral => KarataColors.surfaceRaised,
    RoomTagTone.cashout => const Color(0x291F9D8B),
    RoomTagTone.seated => const Color(0x24E9C46A),
    RoomTagTone.full => const Color(0x29C4502A),
  };
}

/// The small rounded tag on a room card - its variant, whether it cashes out, and whichever of
/// "Seated" / "Full" applies. Squarer and quieter than a [StatusPill]: no glyph, 12px type.
class RoomTag extends StatelessWidget {
  const RoomTag({
    super.key,
    required this.label,
    this.tone = RoomTagTone.neutral,
  });

  final String label;
  final RoomTagTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: karataText(size: 12, weight: 700, color: tone.foreground),
      ),
    );
  }
}
