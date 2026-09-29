import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// What a [KarataTag] is saying, which is the only thing that changes its colours.
enum KarataTagTone {
  /// The variant, and "Play chips" on a room whose winnings never leave the table.
  neutral,

  /// This room's chips convert back to real money.
  cashout,

  /// You are already sitting in this room.
  seated,

  /// Every seat the room is allowed to open is taken.
  full,
}

extension on KarataTagTone {
  Color get foreground => switch (this) {
    KarataTagTone.neutral => KarataColors.inkMuted,
    // Translucent teal on translucent teal nearly disappeared once the room card grew a felt
    // background: this is a near-opaque dark teal backdrop with a brighter mint text, so it
    // stays legible regardless of what is underneath.
    KarataTagTone.cashout => const Color(0xFF7FEAD6),
    KarataTagTone.seated => KarataColors.gold,
    KarataTagTone.full => KarataColors.orangeLight,
  };

  Color get background => switch (this) {
    KarataTagTone.neutral => KarataColors.surfaceRaised,
    KarataTagTone.cashout => const Color(0xBF081C19),
    KarataTagTone.seated => const Color(0x24E9C46A),
    KarataTagTone.full => const Color(0x29C4502A),
  };
}

/// The small rounded tag on a room card - its variant, whether it cashes out, and whichever of
/// "Seated" / "Full" applies, and a table's status in the admin lists. Squarer and quieter than
/// a [StatusPill]: no glyph, 12px type.
class KarataTag extends StatelessWidget {
  const KarataTag({
    super.key,
    required this.label,
    this.tone = KarataTagTone.neutral,
    this.dense = true,
  });

  final String label;
  final KarataTagTone tone;

  /// The room card's proportions. The admin tables draw the same tag a size up, which is what
  /// their roomier rows are built for.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(dense ? 10 : 12),
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
