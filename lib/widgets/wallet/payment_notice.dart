import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/dashed_border.dart';
import '../common/karata_icon.dart';
import '../common/karata_icons.dart';

/// The gold panel telling the player exactly what to send and where, with a button that puts the
/// house's number on the clipboard.
///
/// The amount and the number are picked out in white inside the sentence, which is why the copy
/// arrives as three pieces rather than one formatted string - the words around them still come
/// from the translation.
class PaymentNotice extends StatelessWidget {
  const PaymentNotice({
    super.key,
    required this.sentence,
    required this.amount,
    required this.phoneNumber,
    required this.copyLabel,
    required this.onCopy,
  });

  /// The instruction with `{amount}` and `{phone}` still in it.
  final String sentence;

  final String amount;
  final String phoneNumber;
  final String copyLabel;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: const Color(0x59E9C46A),
      background: const Color(0x14E9C46A),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              _spans(),
              style: karataText(
                size: 14,
                weight: 500,
                color: const Color(0xFFF1DCA0),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            _CopyButton(label: copyLabel, onPressed: onCopy),
          ],
        ),
      ),
    );
  }

  /// Splits the sentence on its two placeholders so each value can be drawn in white.
  TextSpan _spans() {
    final bold = karataText(
      size: 14,
      weight: 700,
      color: KarataColors.white,
      height: 1.5,
    );
    final values = {'{amount}': amount, '{phone}': phoneNumber};
    final pattern = RegExp(r'\{amount\}|\{phone\}');

    final children = <InlineSpan>[];
    var index = 0;
    for (final match in pattern.allMatches(sentence)) {
      if (match.start > index) {
        children.add(TextSpan(text: sentence.substring(index, match.start)));
      }
      children.add(TextSpan(text: values[match.group(0)], style: bold));
      index = match.end;
    }
    if (index < sentence.length) {
      children.add(TextSpan(text: sentence.substring(index)));
    }
    return TextSpan(children: children);
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0x2EE9C46A),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const KarataIcon(
                  KarataIcons.copy,
                  size: 16,
                  color: KarataColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: karataText(
                    size: 14,
                    weight: 700,
                    color: KarataColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Puts [text] on the clipboard. Kept beside the notice so both screens copy the same way.
Future<void> copyToClipboard(String text) =>
    Clipboard.setData(ClipboardData(text: text));
