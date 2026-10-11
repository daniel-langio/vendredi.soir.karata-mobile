import 'package:flutter/painting.dart';

import 'seat_layout.dart';

/// Everything the table is drawn at, which the two layouts disagree about.
///
/// The V2 set draws the table twice, and not as the same picture at two sizes: the phone's felt
/// is a portrait 362x500 oval with the pot printed under the board, and the wide one is a
/// landscape 920x450 with the pot - and its chips - above it. Gathering the differences here
/// keeps [TableSurface] one widget with one set of rules rather than two that drift apart.
class TableMetrics {
  const TableMetrics({
    required this.aspect,
    required this.ring,
    required this.hero,
    required this.railThickness,
    required this.seatWidth,
    required this.avatarDiameter,
    required this.seatNameSize,
    required this.seatStackSize,
    required this.boardCardWidth,
    required this.boardGap,
    required this.heroCardWidth,
    required this.revealedCardWidth,
    required this.maxWidthFraction,
    required this.maxHeightFraction,
    required this.topFraction,
    required this.boardTopFraction,
    required this.potTopFraction,
    required this.potChips,
    required this.dealerInboard,
    required this.dealerDistance,
    required this.betDistance,
    required this.chipSize,
  });

  /// The felt's width over its height, held fixed rather than stretched to the area: a table that
  /// grows taller than it is wide stops reading as a poker table.
  final double aspect;

  /// The seat slots, as fractions of the felt's box.
  final List<Offset> ring;
  final Offset hero;

  /// How far the felt is inset inside its wooden rail.
  final double railThickness;

  final double seatWidth;
  final double avatarDiameter;
  final double seatNameSize;
  final double seatStackSize;

  final double boardCardWidth;
  final double boardGap;
  final double heroCardWidth;

  /// A hand revealed at showdown, drawn in place of a seat's avatar.
  final double revealedCardWidth;

  /// How much of the area the felt may take, leaving room for the seats on its rail.
  final double maxWidthFraction;
  final double maxHeightFraction;

  /// Where the top of the felt sits once its height is known - the seat above it overlaps the
  /// rail, so it cannot start at the very top of the area.
  final double topFraction;

  /// Where the board and the pot sit down the felt.
  final double boardTopFraction;
  final double potTopFraction;

  /// Whether the pot is drawn as chips beside its figure. Only the wide mockups do.
  final bool potChips;

  /// Whether the dealer button and a seat's bet chips are pushed in off the seat, toward the
  /// centre of the felt, rather than pinned to the seat's own corner.
  final bool dealerInboard;

  /// How far along that line each lands, in the felt's own units. Measured rather than
  /// proportional: both have to clear the name and stack hanging under the avatar, which is a
  /// fixed height however far the seat happens to be from the middle of the table.
  final double dealerDistance;
  final double betDistance;

  final double chipSize;

  /// The phone, from artboard 04.
  static const phone = TableMetrics(
    aspect: 362 / 500,
    ring: SeatLayout.ring,
    hero: SeatLayout.hero,
    railThickness: 14,
    seatWidth: 110,
    avatarDiameter: 56,
    seatNameSize: 12,
    seatStackSize: 13,
    boardCardWidth: 52,
    boardGap: 5,
    heroCardWidth: 58,
    revealedCardWidth: 48,
    maxWidthFraction: 0.928,
    maxHeightFraction: 0.80,
    topFraction: 0.18,
    boardTopFraction: 0.31,
    // Unused while potChips is false; the pot is placed under the board instead.
    potTopFraction: 0,
    potChips: false,
    dealerInboard: false,
    // Unused while dealerInboard is false.
    dealerDistance: 0,
    betDistance: 0,
    chipSize: 22,
  );

  /// The wide layout, from artboard 03's 1100x880 canvas: a 920x450 rail at (90, 130), the pot
  /// block at y=262 and the board at y=326.
  static const wide = TableMetrics(
    aspect: 920 / 450,
    ring: SeatLayout.wideRing,
    hero: SeatLayout.wideHero,
    railThickness: 22,
    seatWidth: 130,
    avatarDiameter: 78,
    seatNameSize: 15,
    seatStackSize: 17,
    boardCardWidth: 62,
    boardGap: 8,
    heroCardWidth: 66,
    revealedCardWidth: 56,
    // Fractions of the area the surface is actually given, which is the canvas less the top bar
    // above it and the action bar below: roughly y=52 to y=730 of artboard 03's 880.
    maxWidthFraction: 920 / 1092,
    maxHeightFraction: 450 / 678,
    topFraction: (130 - 52) / 678,
    boardTopFraction: (326 - 130) / 450,
    potTopFraction: (262 - 130) / 450,
    potChips: true,
    dealerInboard: true,
    // Artboard 03's own two: a button just off the lower-left seat, and a bet a little further
    // in from the upper-left one.
    dealerDistance: 105,
    betDistance: 145,
    chipSize: 22,
  );
}
