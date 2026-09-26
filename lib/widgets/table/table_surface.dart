import 'package:flutter/widgets.dart';

import 'board_row.dart';
import 'dealer_button.dart';
import 'fanned_hand.dart';
import 'hand_label.dart';
import 'pot_amount.dart';
import 'seat_data.dart';
import 'seat_layout.dart';
import 'table_felt.dart';
import 'table_seat.dart';

/// The felt and everything sitting on it: the seats around the rail, the board and pot at the
/// centre, and the player's own cards below.
///
/// Presentation only - it takes formatted strings and already-resolved seat state, which is what
/// lets the table screen keep its game logic and hand this a plain description of the hand.
class TableSurface extends StatelessWidget {
  const TableSurface({
    super.key,
    required this.opponents,
    required this.board,
    required this.pot,
    required this.heroCards,
    this.winningCards = const {},
    this.handLabel,
    this.heroDimmed = false,
    this.heroIsDealer = false,
    this.onHeroCardTap,
    this.selectedHeroCards = const {},
    this.banner,
  });

  final List<SeatData> opponents;
  final List<String?> board;

  /// Already formatted. Sits under the board, where the chips it counts actually are.
  final String pot;

  final List<String?> heroCards;
  final Set<String> winningCards;
  final String? handLabel;
  final bool heroDimmed;
  final bool heroIsDealer;

  /// Draw games let the player pick cards to discard.
  final ValueChanged<int>? onHeroCardTap;
  final Set<int> selectedHeroCards;

  /// The outcome announcement, shown over the board.
  final Widget? banner;

  /// The table's own proportions, from the mockup's 362x500 felt. Held fixed rather than
  /// stretched to the area, because a table that grows taller than it is wide stops reading as a
  /// poker table and leaves a lake of empty felt under the board.
  static const _aspect = 362 / 500;

  /// How much of the area the felt may take, leaving room for the seats that sit on its rail.
  static const _maxWidthFraction = 0.928;
  static const _maxHeightFraction = 0.80;

  /// Where the top of the felt sits once its height is known - the seat above it overlaps the
  /// rail, so it cannot start at the very top of the area.
  static const _topFraction = 0.18;

  static const _seatWidth = 110.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = constraints.biggest;
        final feltWidth = [
          area.width * _maxWidthFraction,
          area.height * _maxHeightFraction * _aspect,
        ].reduce((a, b) => a < b ? a : b);
        final feltHeight = feltWidth / _aspect;
        final felt = Rect.fromLTWH(
          (area.width - feltWidth) / 2,
          // Centred in whatever vertical room is left, but never above the seat that sits on the
          // rail over it.
          ((area.height - feltHeight) / 2).clamp(
            area.height * _topFraction,
            area.height,
          ),
          feltWidth,
          feltHeight,
        );
        final positions = SeatLayout.forOpponents(opponents.length);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: felt.left,
              top: felt.top,
              child: TableFelt(size: felt.size),
            ),
            // The board and the pot, a little above the felt's centre so they clear the hero's
            // cards below.
            Positioned(
              left: felt.left,
              top: felt.top + felt.height * 0.31,
              width: felt.width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (banner != null) ...[banner!, const SizedBox(height: 10)],
                  BoardRow(cards: board, winningCards: winningCards),
                  const SizedBox(height: 12),
                  PotAmount(pot),
                  if (handLabel != null) ...[
                    const SizedBox(height: 6),
                    HandLabel(handLabel!),
                  ],
                ],
              ),
            ),
            for (var i = 0; i < opponents.length; i++)
              _seat(felt, positions[i], opponents[i]),
            _hero(felt),
          ],
        );
      },
    );
  }

  Widget _seat(Rect felt, Offset position, SeatData seat) {
    final centre = Offset(
      felt.left + felt.width * position.dx,
      felt.top + felt.height * position.dy,
    );
    return Positioned(
      left: centre.dx - _seatWidth / 2,
      top: centre.dy - 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TableSeat(
            username: seat.username,
            stack: seat.stack,
            action: seat.action,
            actionLabel: seat.actionLabel,
            dimmed: seat.dimmed,
            width: _seatWidth,
            cards: seat.revealedCards == null
                ? null
                : FannedHand(cards: seat.revealedCards!, cardWidth: 48),
          ),
          // Parked at the seat's outer corner, clear of the action badge that hangs under the
          // avatar.
          if (seat.isDealer)
            const Positioned(right: 4, top: 0, child: DealerButton()),
        ],
      ),
    );
  }

  Widget _hero(Rect felt) {
    final centre = Offset(
      felt.left + felt.width * SeatLayout.hero.dx,
      felt.top + felt.height * SeatLayout.hero.dy,
    );
    final width = heroCards.length * 58.0;
    return Positioned(
      left: centre.dx - width / 2,
      top: centre.dy - 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (onHeroCardTap == null)
            FannedHand(cards: heroCards, muted: heroDimmed)
          else
            _SelectableHand(
              cards: heroCards,
              selected: selectedHeroCards,
              onTap: onHeroCardTap!,
            ),
          if (heroIsDealer)
            const Positioned(right: -26, top: 30, child: DealerButton()),
        ],
      ),
    );
  }
}

/// The player's own hand while a draw is in progress: tapping a card marks it for discard.
class _SelectableHand extends StatelessWidget {
  const _SelectableHand({
    required this.cards,
    required this.selected,
    required this.onTap,
  });

  final List<String?> cards;
  final Set<int> selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cards.length; i++)
          GestureDetector(
            onTap: () => onTap(i),
            child: Opacity(
              opacity: selected.contains(i) ? 0.45 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FannedHand(cards: [cards[i]], cardWidth: 52),
              ),
            ),
          ),
      ],
    );
  }
}
