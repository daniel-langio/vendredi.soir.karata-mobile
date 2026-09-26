import 'package:flutter/widgets.dart';

import '../../theme/karata_text_styles.dart';

/// A field with the small muted caption the design puts above it, at the design's 6px gap.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: KarataText.label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
