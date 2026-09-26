import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// The row of equal-width preset buttons under an amount field - "50 BB / 100 BB / 200 BB / Max"
/// on the new-table screen, the quick amounts on the deposit screen.
class ChoiceChipsRow extends StatelessWidget {
  const ChoiceChipsRow({
    super.key,
    required this.labels,
    required this.onSelected,
    this.selectedIndex,
    this.height = 34,
  });

  final List<String> labels;
  final ValueChanged<int> onSelected;

  /// The chip drawn in teal, or null when none of the presets is currently in the field.
  final int? selectedIndex;

  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _Chip(
              label: labels[i],
              selected: i == selectedIndex,
              height: height,
              onPressed: () => onSelected(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.height,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? KarataColors.teal : KarataColors.surfaceRaised,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: karataText(
              size: 13,
              weight: 700,
              color: selected ? KarataColors.white : KarataColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
