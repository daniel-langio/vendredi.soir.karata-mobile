import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// The rounded navy input used by every form in the app: 50px tall, fully rounded, hairline
/// border, 18px of leading padding.
class KarataTextField extends StatelessWidget {
  const KarataTextField({
    super.key,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.trailing,
    this.suffixText,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.fillColor = KarataColors.surface,
  });

  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;

  /// A button pinned inside the right edge, such as the password reveal eye.
  final Widget? trailing;

  /// A static unit shown at the right edge, such as the "Ar" on an amount field.
  final String? suffixText;

  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;

  /// The field's own background. Defaults to the card colour, which is what a field sitting
  /// directly on the page wants; a field *inside* a card drops to [KarataColors.backdrop] so it
  /// still reads as a well rather than blending into the panel around it.
  final Color fillColor;

  static const double height = 50;

  @override
  Widget build(BuildContext context) {
    // The trailing button is 44px wide and sits 3px from the edge, so the text has to stop short
    // of it; a plain suffix only needs its own width plus the usual gutter.
    final trailingInset = trailing != null ? 60.0 : 18.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: KarataColors.line, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              enabled: enabled,
              autofocus: autofocus,
              textAlign: textAlign,
              inputFormatters: inputFormatters,
              style: KarataText.input,
              cursorColor: KarataColors.gold,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: hintText,
                hintStyle: KarataText.input.copyWith(
                  color: KarataColors.inkFaint,
                ),
                contentPadding: EdgeInsets.only(
                  left: 18,
                  right: suffixText != null ? 8 : trailingInset,
                ),
              ),
            ),
          ),
          if (suffixText != null)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Text(
                suffixText!,
                style: karataText(
                  size: 15,
                  weight: 600,
                  color: KarataColors.inkFaint,
                ),
              ),
            ),
          if (trailing != null)
            Padding(padding: const EdgeInsets.only(right: 3), child: trailing),
        ],
      ),
    );
  }
}
