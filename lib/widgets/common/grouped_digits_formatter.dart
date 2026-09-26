import 'package:flutter/services.dart';

import '../../chip_display.dart';

/// Groups an amount field's digits as it is typed, so a buy-in reads "20 000" the way the design
/// draws it rather than "20000".
///
/// The separator is the narrow no-break space [ChipDisplay.groupDigits] already uses for every
/// amount the app *displays*, so a field and the text beside it agree. Callers read the value back
/// with [digitsOf], which is what keeps the grouping purely cosmetic.
class GroupedDigitsFormatter extends TextInputFormatter {
  const GroupedDigitsFormatter();

  /// The digits of [text], with any grouping removed.
  static String digitsOf(String text) => text.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOf(newValue.text);
    if (digits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final grouped = ChipDisplay.groupDigits(int.parse(digits));

    // Keep the caret the same number of *digits* from the end, so inserting a separator ahead of
    // it does not push the caret onto the wrong side of one.
    final digitsAfterCaret = digitsOf(
      newValue.text.substring(
        newValue.selection.end.clamp(0, newValue.text.length),
      ),
    ).length;
    var offset = grouped.length;
    var seen = 0;
    while (offset > 0 && seen < digitsAfterCaret) {
      offset--;
      if (RegExp(r'[0-9]').hasMatch(grouped[offset])) seen++;
    }

    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
