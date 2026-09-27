import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/clickable.dart';
import '../common/karata_card.dart';
import '../common/karata_icon.dart';
import '../common/karata_icons.dart';

/// One record of an admin list, on a phone.
///
/// The mockups draw these screens at desktop width only, where a grid is the right shape for
/// comparing a column of balances. A phone has no such column to read down, so the same record
/// becomes a card: what it is on top, its figures as labelled pairs underneath.
class AdminRecordCard extends StatelessWidget {
  const AdminRecordCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.onPressed,
    this.trailing,
  });

  final String title;
  final String subtitle;

  /// Label / value pairs, laid out two to a row.
  final List<(String, String)> fields;

  /// A tag or badge beside the title - a table's status, a suspended account.
  final Widget? trailing;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onTap: onPressed,
      child: KarataCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: karataText(size: 17, weight: 800),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: karataText(
                            size: 12,
                            weight: 600,
                            color: KarataColors.inkFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
                if (onPressed != null) ...[
                  const SizedBox(width: 6),
                  const KarataIcon(
                    KarataIcons.chevronRight,
                    size: 18,
                    color: KarataColors.inkFaint,
                  ),
                ],
              ],
            ),
            if (fields.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (var i = 0; i < fields.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _field(fields[i])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: i + 1 < fields.length
                          ? _field(fields[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _field((String, String) field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          field.$1.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: karataText(
            size: 11,
            weight: 600,
            color: KarataColors.inkFaint,
            letterSpacing: 0.03,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          field.$2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: karataText(size: 14, weight: 700),
        ),
      ],
    );
  }
}
