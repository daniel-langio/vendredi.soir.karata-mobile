import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A card turning from its back to its face.
///
/// [t] runs 0 (face-down, showing [back]) to 1 (face-up, showing [front]); the back is mirrored
/// back upright so it never reads backwards while it is still turning.
class CardFlip extends StatelessWidget {
  const CardFlip({
    super.key,
    required this.t,
    required this.front,
    required this.back,
  });

  final double t;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    final angle = (1 - t) * math.pi;
    final showingFront = angle < math.pi / 2;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(angle),
      child: showingFront
          ? front
          : Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: back,
            ),
    );
  }
}
