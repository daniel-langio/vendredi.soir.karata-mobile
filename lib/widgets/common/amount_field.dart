import 'package:flutter/material.dart';

import '../../chip_display.dart';
import '../../theme/karata_colors.dart';
import 'grouped_digits_formatter.dart';
import 'karata_text_field.dart';

/// A money field: numeric, grouped as it is typed, and carrying its unit at the right edge.
///
/// Every amount in the app is entered in whatever unit the player reads the rest of it in, so the
/// conversion to and from chips lives here rather than in each screen. [entryText] seeds a field
/// and [chipsFrom] reads it back; going through the pair is what keeps the grouping cosmetic.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.display,
    this.onChanged,
    this.fillColor = KarataColors.surface,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ChipDisplaySettings display;
  final ValueChanged<String>? onChanged;
  final Color fillColor;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  /// How [chips] should appear in a field, in the player's own unit.
  static String entryText(ChipDisplaySettings display, int chips) {
    final entry = display.entryFromChips(chips);
    // Chip counts are shown ungrouped, matching how they read everywhere else in the app.
    return display.inMoney ? ChipDisplay.groupDigits(entry) : '$entry';
  }

  /// The chips a field's contents stand for, or null if it does not hold a usable number.
  static int? chipsFrom(ChipDisplaySettings display, String text) {
    final digits = GroupedDigitsFormatter.digitsOf(text);
    if (digits.isEmpty) return null;
    return display.chipsFromEntry(int.parse(digits));
  }

  @override
  Widget build(BuildContext context) {
    return KarataTextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: display.inMoney
          ? const [GroupedDigitsFormatter()]
          : const [],
      suffixText: display.unitLabel,
      fillColor: fillColor,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      enabled: enabled,
    );
  }
}
