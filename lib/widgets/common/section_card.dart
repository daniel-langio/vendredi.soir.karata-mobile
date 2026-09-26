import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import 'karata_card.dart';

/// A [KarataCard] opened by a heading, and optionally a quiet note on the right of it - "Table",
/// "Your buy-in", "House · Admin".
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.trailingWidget,
    this.ribbon = false,
    this.gap = 16,
  });

  final String title;

  /// The card's rows, separated by [gap].
  final List<Widget> children;

  /// A caption on the heading's right, such as the wallet's "Admin".
  final String? trailing;

  /// A widget in the same slot as [trailing], for the headings that carry a badge instead of a
  /// word. Takes precedence when both are given.
  final Widget? trailingWidget;

  final bool ribbon;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final child in children) {
      rows
        ..add(SizedBox(height: gap))
        ..add(child);
    }

    return KarataCard(
      ribbon: ribbon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: KarataText.sectionTitle)),
              if (trailingWidget != null)
                trailingWidget!
              else if (trailing != null)
                Text(
                  trailing!,
                  style: karataText(
                    size: 12,
                    weight: 600,
                    color: KarataColors.inkFaint,
                  ),
                ),
            ],
          ),
          ...rows,
        ],
      ),
    );
  }
}
