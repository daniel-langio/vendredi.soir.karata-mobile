import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import 'avatar.dart';

/// The overlapping row of player avatars on a table card, each tucked 8px under the one before.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.names,
    this.diameter = 26,
    this.max = 3,
    this.ringColor = KarataColors.teal,
  });

  final List<String> names;
  final double diameter;

  /// How many faces to show before the rest are left to the "N players" line beside the stack.
  final int max;
  final Color ringColor;

  static const _overlap = 8.0;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(max).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: diameter,
      width: diameter + (shown.length - 1) * (diameter - _overlap),
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (diameter - _overlap),
              child: Avatar(
                name: shown[i],
                diameter: diameter,
                ringColor: ringColor,
              ),
            ),
        ],
      ),
    );
  }
}
