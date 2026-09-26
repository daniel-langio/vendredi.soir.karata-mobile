import 'package:flutter/widgets.dart';

import 'card_code.dart';
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
  /// it has not reached; those are dropped rather than drawn, because the design shows a preflop
  /// board as empty felt rather than as five card backs.
  final List<String?> cards;

  /// The subset making up the winning hand, drawn with a gold rim. Everything else greys out once
  /// a winner is known.
  final Set<String> winningCards;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final showdown = winningCards.isNotEmpty;
    final dealt = [for (final c in cards) ?c];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < dealt.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          PlayingCard(
            code: CardCode(dealt[i]),
            width: cardWidth,
            highlighted: winningCards.contains(dealt[i]),
            muted: showdown && !winningCards.contains(dealt[i]),
          ),
        ],
      ],
    );
  }
}
