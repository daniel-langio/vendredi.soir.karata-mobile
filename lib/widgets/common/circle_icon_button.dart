import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import 'karata_icon.dart';

/// The 44px round icon button in a screen's header - back, refresh, brightness.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.diameter = 44,
    this.iconSize = 20,
    this.background = KarataColors.surface,
    this.color = KarataColors.ink,
  });

  final KarataIconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double diameter;
  final double iconSize;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Center(
            child: KarataIcon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );
  }
}
