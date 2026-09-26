import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../common/karata_icon.dart';

/// The 40px filled circle at either end of the table's action area - hand strength on the left,
/// reactions on the right.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.iconSize = 16,
  });

  final KarataIconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: KarataColors.surfaceRaised,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Stack(
              children: [
                Center(
                  child: KarataIcon(
                    icon,
                    size: iconSize,
                    color: KarataColors.ink,
                  ),
                ),
                // `inset 0 1px 0 rgba(255,255,255,0.1)`.
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: ColoredBox(color: Color(0x1AFFFFFF)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
