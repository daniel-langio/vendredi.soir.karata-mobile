import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import 'karata_text_field.dart';

/// A [KarataTextField] that takes part in a [Form].
///
/// The mockups draw no invalid state - they are all happy-path - so the error is rendered the
/// quietest way that still reads: the field's border turns red and the message sits beneath it in
/// the same small caption size the design uses for field labels.
class KarataFormField extends StatelessWidget {
  const KarataFormField({
    super.key,
    required this.controller,
    this.validator,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.trailing,
    this.suffixText,
    this.autofocus = false,
    this.inputFormatters,
    this.fillColor = KarataColors.surface,
  });

  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final String? suffixText;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  /// See [KarataTextField.fillColor].
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ErrorBorder(
              showError: state.hasError,
              child: KarataTextField(
                controller: controller,
                hintText: hintText,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                autofocus: autofocus,
                trailing: trailing,
                suffixText: suffixText,
                inputFormatters: inputFormatters,
                fillColor: fillColor,
                onChanged: (value) {
                  state.didChange(value);
                  // Clear a stale message as soon as the user starts fixing it, rather than
                  // leaving it up until the next submit.
                  if (state.hasError) state.validate();
                },
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 18, top: 6),
                child: Text(
                  state.errorText!,
                  style: KarataText.label.copyWith(
                    color: KarataColors.orangeLight,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Repaints the field's hairline in red while it is invalid. The border belongs to
/// [KarataTextField], so this overlays a matching one rather than reaching inside it.
class _ErrorBorder extends StatelessWidget {
  const _ErrorBorder({required this.showError, required this.child});

  final bool showError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!showError) return child;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KarataTextField.height / 2),
                border: Border.all(color: KarataColors.orangeLight, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
