import 'package:flutter/material.dart';
import 'seat.dart';

/// Lays opponent seats out around the felt like a real table, filling this fixed order as more
/// opponents join: top-left, top-middle, top-right, left-middle, right-middle, bottom-left,
/// bottom-right. The hero's own seat isn't part of this - it's the separate hand row anchored at
/// bottom-center, alongside these on the same felt.
class TableSeats extends StatelessWidget {
  final List<Map<String, dynamic>> opponents;
  final String? activePlayerId;
  final Map<String, Map<String, dynamic>> revealedHands;

  const TableSeats({
    super.key,
    required this.opponents,
    required this.activePlayerId,
    required this.revealedHands,
  });

  // Inset from the felt's actual corners so seats clear TableFelt's heavy corner rounding rather
  // than sitting on top of the curve.
  static const _slots = [
    Alignment(-0.72, -0.92), // top-left
    Alignment(0.0, -1.0), // top-middle
    Alignment(0.72, -0.92), // top-right
    Alignment(-0.88, -0.05), // left-middle
    Alignment(0.88, -0.05), // right-middle
    Alignment(-0.72, 0.68), // bottom-left
    Alignment(0.72, 0.68), // bottom-right
  ];

  @override
  Widget build(BuildContext context) {
    final seatCount = opponents.length < _slots.length
        ? opponents.length
        : _slots.length;
    return Stack(
      // As a plain (non-Positioned) child of the outer content Stack, this Stack would otherwise
      // only get loose constraints; forcing it to expand is what makes each Align's fractional
      // position resolve against the whole felt area rather than shrinking to fit its seats.
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < seatCount; i++)
          Align(
            alignment: _slots[i],
            child: SeatWidget(
              player: opponents[i],
              activePlayerId: activePlayerId,
              revealedHand: revealedHands[opponents[i]['playerId']?.toString()],
            ),
          ),
      ],
    );
  }
}
