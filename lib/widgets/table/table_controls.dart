import 'package:flutter/material.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/karata_icons.dart';
import 'bet_sizer_row.dart';
import 'round_icon_button.dart';
import 'table_action_bar.dart';

/// Everything below the felt: the pot, the two round buttons flanking it, the bet sizer, and the
/// action buttons.
class TableControls extends StatelessWidget {
  const TableControls({
    super.key,
    this.centreLabel,
    required this.actions,
    required this.actionsEnabled,
    required this.onHandStrength,
    required this.onEmote,
    required this.handStrengthLabel,
    required this.emoteLabel,
    this.sizer,
    this.message,
    required this.status,
  });

  /// What sits between the two round buttons. The pot lives on the felt, under the board it
  /// belongs to, so this slot carries something about the player instead.
  final String? centreLabel;

  final List<TableAction> actions;
  final bool actionsEnabled;
  final VoidCallback? onHandStrength;
  final VoidCallback? onEmote;
  final String handStrengthLabel;
  final String emoteLabel;

  /// The pot-fraction row, or null when there is nothing to size (a spectator, a closed table).
  final BetSizerRow? sizer;

  /// Shown in place of the buttons - "Waiting for the draw", "Table closed".
  final String? message;

  /// Whose turn it is and how long they have left - and, being the one line that is always on
  /// screen here, the natural home for anything else the table needs to say.
  final Widget status;

  /// The height the tallest arrangement needs - round buttons, clock, sizer and three actions.
  ///
  /// Reserved whatever is actually showing, because this block sits under the felt and the felt
  /// is sized from the space left over: letting it shrink for a one-button state would move the
  /// table itself every time the hand changed phase.
  static const reservedHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: reservedHeight),
      child: Align(alignment: Alignment.bottomCenter, child: _content(context)),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            RoundIconButton(
              icon: KarataIcons.betBars,
              onPressed: onHandStrength,
              semanticLabel: handStrengthLabel,
            ),
            Expanded(
              child: Text(
                centreLabel ?? '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: karataText(
                  size: 18,
                  weight: 800,
                  color: KarataColors.white,
                ),
              ),
            ),
            RoundIconButton(
              icon: KarataIcons.emote,
              iconSize: 18,
              onPressed: onEmote,
              semanticLabel: emoteLabel,
            ),
          ],
        ),
        const SizedBox(height: 10),
        status,
        const SizedBox(height: 10),
        if (message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: karataText(
                size: 13,
                weight: 600,
                color: KarataColors.inkMuted,
              ),
            ),
          )
        else ...[
          if (sizer != null) ...[
            Opacity(opacity: actionsEnabled ? 1 : 0.4, child: sizer!),
            const SizedBox(height: 10),
          ],
          TableActionBar(actions: actions, enabled: actionsEnabled),
        ],
      ],
    );
  }
}
