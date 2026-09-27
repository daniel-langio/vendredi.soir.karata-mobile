import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// Where a room card's "Sit down" sits once the room has no seat to offer.
///
/// Shaped like the button it replaces but drawn flat and muted, and it is not a [KarataButton]
/// with a null callback: a disabled button is the same pill at 45% opacity, which the design does
/// not draw, and this reads as a state rather than as something that failed to respond.
class RoomFullPill extends StatelessWidget {
  const RoomFullPill({super.key, required this.label, this.height = 42});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: false,
      label: label,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: KarataColors.surfaceRaised,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: karataText(
            size: 15,
            weight: 700,
            color: KarataColors.inkFaint,
          ),
        ),
      ),
    );
  }
}
