import 'package:flutter/widgets.dart';

import 'card_code.dart';
import 'empty_card_slot.dart';
import 'playing_card.dart';

/// The community cards, laid out in a row at the centre of the felt.
class BoardRow extends StatelessWidget {
  const BoardRow({
    super.key,
    required this.cards,
    this.winningCards = const {},
    this.cardWidth = 52,
  });

  /// One entry per board slot. The API sends a fixed-size array padded with nulls for the streets
  /// it has not reached, and those are drawn as empty slots - the design shows a preflop board as
  /// five dashed outlines, which is also what keeps the row from changing width as cards land.
  final List<String?> cards;

  /// The subset making up the winning hand, drawn with a gold rim. Everything else greys out once
  /// a winner is known.
  final Set<String> winningCards;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final showdown = winningCards.isNotEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          if (cards[i] case final card?)
            PlayingCard(
              code: CardCode(card),
              width: cardWidth,
              highlighted: winningCards.contains(card),
              muted: showdown && !winningCards.contains(card),
            )
          else
            EmptyCardSlot(width: cardWidth),
        ],
      ],
    );
  }
}
