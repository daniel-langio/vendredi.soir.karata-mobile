import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// A centred line of muted copy ending in a gold link - "Already have an account? Log in".
class InlinePrompt extends StatefulWidget {
  const InlinePrompt({
    super.key,
    required this.question,
    required this.linkLabel,
    required this.onPressed,
  });

  final String question;
  final String linkLabel;
  final VoidCallback onPressed;

  @override
  State<InlinePrompt> createState() => _InlinePromptState();
}

class _InlinePromptState extends State<InlinePrompt> {
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer()..onTap = widget.onPressed;
  }

  @override
  void didUpdateWidget(InlinePrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recognizer.onTap = widget.onPressed;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${widget.question} '),
          TextSpan(
            text: widget.linkLabel,
            // Built with karataText rather than copyWith: changing the weight has to move the
            // font's `wght` axis, and copyWith would leave the old axis values in place.
            style: karataText(
              size: 14,
              weight: 700,
              color: KarataColors.gold,
              height: 1.45,
            ),
            recognizer: _recognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: KarataText.subtitle,
    );
  }
}
