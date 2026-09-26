import 'package:flutter/material.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import 'karata_icon.dart';
import 'karata_icons.dart';
import 'karata_text_field.dart';

/// The select control, shaped like a [KarataTextField] with a chevron in place of a caret.
class KarataDropdown<T> extends StatelessWidget {
  const KarataDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.fillColor = KarataColors.backdrop,
    this.height = KarataTextField.height,
    this.fontSize = 16,
    this.expand = true,
  });

  final T value;

  /// The options, in the order the design lists them.
  final List<(T, String)> items;

  final ValueChanged<T?>? onChanged;
  final Color fillColor;

  /// 50 as a form field, 40 when it sits at the end of a settings row.
  final double height;

  final double fontSize;

  /// Whether the control fills the width it is given. A form field does; the one at the end of a
  /// settings row sizes to its longest option instead, because that row hands it no width of its
  /// own to fill.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: expand ? double.infinity : null,
      padding: EdgeInsets.only(
        left: height >= KarataTextField.height ? 18 : 14,
        right: height >= KarataTextField.height ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: KarataColors.line, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          onChanged: onChanged,
          isExpanded: expand,
          isDense: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: KarataColors.surfaceRaised,
          style: karataText(
            size: fontSize,
            weight: 600,
            color: KarataColors.white,
          ),
          icon: KarataIcon(
            KarataIcons.chevronDown,
            size: fontSize >= 16 ? 18 : 16,
            color: KarataColors.inkMuted,
          ),
          items: [
            for (final (item, label) in items)
              DropdownMenuItem(value: item, child: Text(label)),
          ],
        ),
      ),
    );
  }
}
