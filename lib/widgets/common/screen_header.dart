import 'package:flutter/widgets.dart';

import 'circle_icon_button.dart';
import 'karata_icons.dart';

/// The row of round buttons at the top of a screen: back on the left, screen actions on the right.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    this.onBack,
    this.backLabel = 'Back',
    this.actions = const [],
  });

  final VoidCallback? onBack;
  final String backLabel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onBack != null)
            CircleIconButton(
              icon: KarataIcons.back,
              onPressed: onBack,
              semanticLabel: backLabel,
            )
          else
            const SizedBox(width: 44, height: 44),
          Row(
            children: [
              for (final action in actions) ...[
                if (action != actions.first) const SizedBox(width: 8),
                action,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
