import 'package:flutter/material.dart';
import '../../theme.dart';

/// The rounded, gradient-green table surface behind the opponent seats, board and hero's hole
/// cards. Purely a background decoration - meant to sit behind that content in a [Stack], not to
/// lay it out.
class TableFelt extends StatelessWidget {
  const TableFelt({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [KarataColors.feltCenter, KarataColors.feltEdge],
        ),
        borderRadius: BorderRadius.circular(140),
        border: Border.all(color: KarataColors.feltRing, width: 1.5),
      ),
    );
  }
}
