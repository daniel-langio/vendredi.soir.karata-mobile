import 'package:flutter/widgets.dart';

import '../common/karata_button.dart';

/// One of the three buttons along the bottom of the table.
typedef TableAction = ({
  String label,
  VoidCallback? onPressed,
  KarataButtonStyle style,
});

/// Fold, check/call, and bet/raise - the row the hand is actually played from.
///
/// Dimmed rather than removed when it is not your turn, so the table does not reflow every time
/// the action moves and you can still read what your options will be.
class TableActionBar extends StatelessWidget {
  const TableActionBar({super.key, required this.actions, this.enabled = true});

  final List<TableAction> actions;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Row(
        children: [
          for (final action in actions) ...[
            if (action != actions.first) const SizedBox(width: 8),
            Expanded(
              child: KarataButton(
                label: action.label,
                onPressed: enabled ? action.onPressed : null,
                style: action.style,
                height: 46,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
