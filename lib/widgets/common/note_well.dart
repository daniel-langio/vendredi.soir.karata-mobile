import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// A sunken strip inside a card carrying one short, gold-lettered fact - the worked example under
/// the "show chips as money" switch.
class NoteWell extends StatelessWidget {
  const NoteWell({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KarataColors.backdrop,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: karataText(size: 13, weight: 600, color: KarataColors.gold),
      ),
    );
  }
}
