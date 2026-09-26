import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import 'karata_icon.dart';
import 'karata_icons.dart';

/// The eye pinned inside a password field, 44px square and 3px from the edge.
class PasswordRevealButton extends StatelessWidget {
  const PasswordRevealButton({
    super.key,
    required this.revealed,
    required this.onPressed,
    required this.semanticLabel,
  });

  final bool revealed;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: KarataIcon(
              KarataIcons.eye,
              size: 20,
              color: revealed ? KarataColors.gold : KarataColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
