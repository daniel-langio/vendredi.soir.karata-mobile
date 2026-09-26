import 'package:flutter/material.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// The row of pot fractions above the action buttons, with the bet amount at its end.
class BetSizerRow extends StatelessWidget {
  const BetSizerRow({
    super.key,
    required this.labels,
    required this.onSelected,
    required this.amountController,
    required this.amountLabel,
    this.selectedIndex,
    this.onAmountChanged,
    this.enabled = true,
  });

  /// "1/3", "1/2", "3/4", "Pot", "All-in" - already localised.
  final List<String> labels;
  final ValueChanged<int> onSelected;

  final TextEditingController amountController;

  /// Read out to screen readers; the design hides it visually.
  final String amountLabel;

  final int? selectedIndex;
  final ValueChanged<String>? onAmountChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _Fraction(
              label: labels[i],
              selected: i == selectedIndex,
              onPressed: enabled ? () => onSelected(i) : null,
            ),
          ),
        ],
        const SizedBox(width: 4),
        _AmountBox(
          controller: amountController,
          label: amountLabel,
          onChanged: onAmountChanged,
          enabled: enabled,
        ),
      ],
    );
  }
}

class _Fraction extends StatelessWidget {
  const _Fraction({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? KarataColors.teal : KarataColors.surfaceRaised,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            maxLines: 1,
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

/// The 48x32 box the bet amount is typed into.
class _AmountBox extends StatelessWidget {
  const _AmountBox({
    required this.controller,
    required this.label,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      textField: true,
      child: Container(
        // The design draws this at 48px around a chip count like "68"; in money mode the same
        // bet reads "2 400", so it takes the width it needs rather than clipping the figure.
        constraints: const BoxConstraints(minWidth: 56),
        height: 32,
        decoration: BoxDecoration(
          color: KarataColors.backdrop,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KarataColors.lineStrong, width: 1.5),
        ),
        child: IntrinsicWidth(
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: onChanged,
            cursorColor: KarataColors.gold,
            style: karataText(size: 16, weight: 800, color: KarataColors.white),
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
      ),
    );
  }
}
