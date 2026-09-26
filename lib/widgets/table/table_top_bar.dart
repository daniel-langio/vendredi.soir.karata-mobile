import 'package:flutter/widgets.dart';

import '../../theme/karata_text_styles.dart';
import '../common/circle_icon_button.dart';
import '../common/karata_icons.dart';

/// The table's own header: leave on the left, the table's name in the middle, settings on the
/// right. Transparent, because it sits over the page's own backdrop rather than on a card.
class TableTopBar extends StatelessWidget {
  const TableTopBar({
    super.key,
    required this.title,
    required this.onLeave,
    required this.onSettings,
    required this.leaveLabel,
    required this.settingsLabel,
  });

  final String title;
  final VoidCallback onLeave;
  final VoidCallback onSettings;
  final String leaveLabel;
  final String settingsLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          CircleIconButton(
            icon: KarataIcons.back,
            iconSize: 22,
            background: const Color(0x00000000),
            onPressed: onLeave,
            semanticLabel: leaveLabel,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: karataText(size: 16, weight: 700),
            ),
          ),
          CircleIconButton(
            icon: KarataIcons.brightness,
            iconSize: 22,
            background: const Color(0x00000000),
            onPressed: onSettings,
            semanticLabel: settingsLabel,
          ),
        ],
      ),
    );
  }
}
