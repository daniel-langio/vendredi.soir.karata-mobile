import 'package:flutter/material.dart';
import 'poker_card.dart';

class BoardRow extends StatelessWidget {
  final List<dynamic> cards;
  const BoardRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    const cardWidth = 64.0;
    const step = 58.0; // cardWidth - 6px overlap, matching the mockup
    final width = cardWidth + step * (cards.length - 1);
    return SizedBox(
      width: width,
      height: 86,
      child: Stack(
        children: [
          for (var i = 0; i < cards.length; i++)
            Positioned(
              left: i * step,
              child: PokerCardWidget(cardCode: cards[i]?.toString()),
            ),
        ],
      ),
    );
  }
}
