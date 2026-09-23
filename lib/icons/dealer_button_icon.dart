import 'package:flutter/material.dart';
import '../theme.dart';

/// The "D" dealer-button marker. Purely a pure-Flutter drawing (no image asset), matching
/// [ChipIcon]'s approach.
class DealerButtonIcon extends StatelessWidget {
  final double size;

  const DealerButtonIcon({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: KarataColors.winnerGold,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'D',
        style: TextStyle(
          fontSize: size * 0.55,
          fontWeight: FontWeight.w800,
          color: KarataColors.winnerGoldInk,
          height: 1,
        ),
      ),
    );
  }
}
