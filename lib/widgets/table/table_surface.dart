import 'package:flutter/widgets.dart';

import 'board_row.dart';
import 'chip_glyph.dart';
import 'dealer_button.dart';
import 'fanned_hand.dart';
import 'hand_label.dart';
import 'pot_amount.dart';
import 'seat_data.dart';
import 'seat_layout.dart';
import 'table_felt.dart';
import 'table_metrics.dart';
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
    this.potAmount,
    this.metrics = TableMetrics.phone,
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

  /// The pot in chips, for the chip glyphs the wide layout draws beside the figure. Null leaves
  /// them off, which is also what the phone's metrics do.
  final int? potAmount;

  /// Which of the design's two tables to draw.
  final TableMetrics metrics;

  /// The board's own height, from the card width the row is drawn at.
  double get _boardHeight => metrics.boardCardWidth * 1.385;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = constraints.biggest;
        final feltWidth = [
          area.width * metrics.maxWidthFraction,
          area.height * metrics.maxHeightFraction * metrics.aspect,
        ].reduce((a, b) => a < b ? a : b);
        final feltHeight = feltWidth / metrics.aspect;
        final felt = Rect.fromLTWH(
          (area.width - feltWidth) / 2,
          // Centred in whatever vertical room is left, but never above the seat that sits on the
          // rail over it.
          ((area.height - feltHeight) / 2).clamp(
            area.height * metrics.topFraction,
            area.height,
          ),
          feltWidth,
          feltHeight,
        );
        final positions = SeatLayout.forOpponents(
          opponents.length,
          slots: metrics.ring,
        );
        final boardTop = felt.top + felt.height * metrics.boardTopFraction;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: felt.left,
              top: felt.top,
              child: TableFelt(
                size: felt.size,
                railThickness: metrics.railThickness,
              ),
            ),
            // The board is anchored, not flowed. Everything that comes and goes around it - the
            // outcome banner above, the pot and the hand's name below - is placed relative to it
            // rather than stacked with it, so the cards never shift as those appear. Together
            // with the board keeping all five slots whatever has been dealt, that leaves the
            // centre of the felt still while a hand plays out.
            Positioned(
              left: felt.left,
              top: boardTop,
              width: felt.width,
              child: Center(
                child: BoardRow(
                  cards: board,
                  winningCards: winningCards,
                  cardWidth: metrics.boardCardWidth,
                  gap: metrics.boardGap,
                ),
              ),
            ),
            if (banner != null)
              Positioned(
                left: felt.left,
                width: felt.width,
                bottom: area.height - boardTop + 10,
                child: banner!,
              ),
            // The phone prints the pot under the board; the wide table lifts it above, with the
            // chips it stands for beside the figure. Either way the name of the winning hand
            // stays under the board, where it reads with the cards it describes.
            if (metrics.potChips)
              Positioned(
                left: felt.left,
                top: felt.top + felt.height * metrics.potTopFraction,
                width: felt.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (potAmount != null) ...[
                      ChipStack(amount: potAmount!, size: metrics.chipSize),
                      const SizedBox(height: 3),
                    ],
                    PotAmount(pot),
                  ],
                ),
              ),
            Positioned(
              left: felt.left,
              top: boardTop + _boardHeight + 12,
              width: felt.width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!metrics.potChips) PotAmount(pot),
                  if (handLabel != null) ...[
                    if (!metrics.potChips) const SizedBox(height: 6),
                    HandLabel(handLabel!),
                  ],
                ],
              ),
            ),
            for (var i = 0; i < opponents.length; i++)
              _seat(felt, positions[i], opponents[i]),
            // Drawn after the seats so a bet pushed onto the felt lies over the rail rather than
            // under the seat beside it.
            if (metrics.dealerInboard)
              for (var i = 0; i < opponents.length; i++)
                ..._inboard(felt, positions[i], opponents[i]),
            _hero(felt),
          ],
        );
      },
    );
  }

  /// Where a seat's avatar is centred, in the area's own coordinates.
  Offset _seatCentre(Rect felt, Offset position) => Offset(
    felt.left + felt.width * position.dx,
    felt.top + felt.height * position.dy,
  );

  Widget _seat(Rect felt, Offset position, SeatData seat) {
    final centre = _seatCentre(felt, position);
    return Positioned(
      left: centre.dx - metrics.seatWidth / 2,
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
            width: metrics.seatWidth,
            avatarDiameter: metrics.avatarDiameter,
            nameSize: metrics.seatNameSize,
            stackSize: metrics.seatStackSize,
            cards: seat.revealedCards == null
                ? null
                : FannedHand(
                    cards: seat.revealedCards!,
                    cardWidth: metrics.revealedCardWidth,
                  ),
          ),
          // Parked at the seat's outer corner, clear of the action badge that hangs under the
          // avatar. The wide table puts it on the felt instead - see [_inboard].
          if (seat.isDealer && !metrics.dealerInboard)
            const Positioned(right: 4, top: 0, child: DealerButton()),
        ],
      ),
    );
  }

  /// What the wide table pushes off a seat and onto the felt: the dealer button, and the chips
  /// the seat has bet this street.
  ///
  /// Both slide along the line from the seat to the centre of the felt, which is the direction a
  /// bet actually travels. The button stops short of the chips, so a dealer who has also bet
  /// shows both rather than one on top of the other.
  List<Widget> _inboard(Rect felt, Offset position, SeatData seat) {
    final from = _seatCentre(felt, position);
    final to = felt.center;
    final line = to - from;
    final length = line.distance;
    if (length == 0) return const [];
    // The felt is drawn at whatever size the area allows, so the measured distances scale with
    // it rather than staying at their artboard pixel values on a smaller window.
    final scale = felt.height / 450;
    final unit = line / length;

    Widget at(double distance, Widget child, Size size) {
      final centre = from + unit * (distance * scale).clamp(0.0, length);
      return Positioned(
        left: centre.dx - size.width / 2,
        top: centre.dy - size.height / 2,
        child: child,
      );
    }

    final bet = seat.bet;
    return [
      if (seat.isDealer)
        at(metrics.dealerDistance, const DealerButton(), const Size(22, 22)),
      if (bet != null && bet > 0)
        at(
          metrics.betDistance,
          Opacity(
            opacity: seat.dimmed ? 0.38 : 1,
            child: ChipStack(amount: bet, size: metrics.chipSize),
          ),
          Size(metrics.chipSize * 2 + 3, metrics.chipSize),
        ),
    ];
  }

  Widget _hero(Rect felt) {
    final centre = _seatCentre(felt, metrics.hero);
    final width = heroCards.length * metrics.heroCardWidth;
    return Positioned(
      left: centre.dx - width / 2,
      top: centre.dy - 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (onHeroCardTap == null)
            FannedHand(
              cards: heroCards,
              cardWidth: metrics.heroCardWidth,
              muted: heroDimmed,
            )
          else
            _SelectableHand(
              cards: heroCards,
              cardWidth: metrics.heroCardWidth,
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
    required this.cardWidth,
    required this.selected,
    required this.onTap,
  });

  final List<String?> cards;
  final double cardWidth;
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
                child: FannedHand(
                  cards: [cards[i]],
                  // The design draws a card picked for discard a touch smaller than the rest.
                  cardWidth: cardWidth - 6,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
