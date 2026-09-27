import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/dashed_border.dart';
import '../common/dashed_ring.dart';
import '../common/karata_icon.dart';
import '../common/karata_icons.dart';

/// What a room with nobody in it shows in place of [RoomStatsWell].
///
/// Nothing is ever seated to pad the numbers, so a genuinely quiet room is a state the lobby has
/// to be able to say out loud. Drawn dashed and in gold as an invitation rather than in the solid
/// well, where the same two zeroes would read as a list that failed to load.
class RoomQuietWell extends StatelessWidget {
  const RoomQuietWell({
    super.key,
    required this.title,
    required this.caption,
    this.height = 58,
  });

  /// "Be the first to sit".
  final String title;

  /// "0 tables running yet".
  final String caption;

  final double height;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: const Color(0x59E9C46A),
      radius: 12,
      background: const Color(0x0DE9C46A),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const SizedBox.square(dimension: 30, child: _SeatGlyph()),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: karataText(
                        size: 14,
                        weight: 800,
                        color: KarataColors.gold,
                      ),
                    ),
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: karataText(
                        size: 12,
                        weight: 500,
                        color: KarataColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plus inside a dashed ring: the open seat being offered. Built from the two pieces rather
/// than transcribed as one icon because [KarataIconData] strokes a whole icon the same way, and
/// only the ring is dashed.
class _SeatGlyph extends StatelessWidget {
  const _SeatGlyph();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 18,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DashedRing(
              diameter: 18,
              color: KarataColors.gold,
              strokeWidth: 1.6,
            ),
            KarataIcon(KarataIcons.plus, size: 10, color: KarataColors.gold),
          ],
        ),
      ),
    );
  }
}
