import 'package:flutter/widgets.dart';

import '../../theme/karata_text_styles.dart';

/// The big heading, and the sentence of explanation beneath it, that opens every screen.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KarataText.title),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: KarataText.subtitle),
          ],
        ],
      ),
    );
  }
}
