import 'package:flutter/material.dart';
import '../../icons/chip_icon.dart';
import '../../theme.dart';

/// A small decorative chip-stack shown above the pot amount - reuses the app's existing
/// white/green/red palette (`card`, `live`, `red`) rather than inventing new denominations, and
/// isn't meant to literally represent how the pot is made up.
class PotChips extends StatelessWidget {
  const PotChips({super.key});

  @override
  Widget build(BuildContext context) {
    const size = 16.0;
    const overlap = 9.0;
    return SizedBox(
      width: size + overlap * 2,
      height: size,
      child: const Stack(
        children: [
          Positioned(left: 0, child: ChipIcon(size: size, color: KarataColors.red)),
          Positioned(
            left: overlap,
            child: ChipIcon(size: size, color: KarataColors.live),
          ),
          Positioned(
            left: overlap * 2,
            child: ChipIcon(size: size, color: KarataColors.card),
          ),
        ],
      ),
    );
  }
}
