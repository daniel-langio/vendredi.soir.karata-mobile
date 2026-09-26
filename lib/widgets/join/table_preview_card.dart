import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/karata_card.dart';

/// The table a pasted link resolved to.
///
/// The join mockup only draws the empty state, so this follows the vocabulary the rest of the V2
/// design establishes for a summary - a ribboned card, the name at card-title size, and the
/// details beneath it as muted body copy.
class TablePreviewCard extends StatelessWidget {
  const TablePreviewCard({
    super.key,
    required this.name,
    required this.details,
    required this.child,
  });

  final String name;
  final String details;

  /// The buy-in field, or nothing when the player is already seated.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return KarataCard(
      ribbon: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.foundIt, style: KarataText.label),
          const SizedBox(height: 6),
          Text(name, style: KarataText.cardTitle),
          const SizedBox(height: 4),
          Text(
            details,
            style: karataText(
              size: 13,
              weight: 500,
              color: KarataColors.inkMuted,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
