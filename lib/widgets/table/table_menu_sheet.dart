import 'package:flutter/material.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/karata_icon.dart';

/// One row of the table's menu.
typedef TableMenuEntry = ({
  KarataIconData icon,
  String label,
  VoidCallback onTap,
  bool danger,
});

/// Everything the table can do that is not a betting action.
///
/// The design gives the table's header one icon on the right, so these live behind it rather than
/// in an app bar full of buttons: the invite link, what the variant is, and - for the host - the
/// pause, bot and close controls.
Future<void> showTableMenu(BuildContext context, List<TableMenuEntry> entries) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: KarataColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in entries)
            ListTile(
              leading: KarataIcon(
                entry.icon,
                size: 20,
                color: entry.danger
                    ? KarataColors.orangeLight
                    : KarataColors.ink,
              ),
              title: Text(
                entry.label,
                style: karataText(
                  size: 15,
                  weight: 700,
                  color: entry.danger
                      ? KarataColors.orangeLight
                      : KarataColors.ink,
                ),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                entry.onTap();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
