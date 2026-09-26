import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// The pair of pills that switch the lobby between public tables and your own.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 38,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// 38 in the lobby, 40 for the payment providers on the deposit screen.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _Tab(
            label: labels[i],
            selected: i == selectedIndex,
            height: height,
            onPressed: () => onChanged(i),
          ),
        ],
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
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
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? KarataColors.teal : null,
            borderRadius: BorderRadius.circular(height / 2),
            border: selected
                ? null
                : Border.all(color: const Color(0x24FFFFFF), width: 1.5),
          ),
          child: Text(
            label,
            style: karataText(
              size: 15,
              weight: 700,
              color: selected ? KarataColors.white : KarataColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
