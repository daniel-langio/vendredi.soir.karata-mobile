import 'package:flutter/painting.dart';

/// Where the seats sit around the table.
///
/// The positions are the mockup's own, expressed as fractions of the table's box so they hold at
/// any screen size: its five opponent seats land on ring slots 0, 2, 4, 6 and 8 exactly. The four
/// slots between them are interpolated, which is what lets a fuller table spread without the
/// layout being redrawn by hand for every seat count.
///
/// Note that the top slots have a negative y: the seat above the table overlaps its rail rather
/// than sitting inside the felt, exactly as the design draws it.
abstract final class SeatLayout {
  /// The ring, clockwise from the bottom-left.
  static const ring = <Offset>[
    Offset(0.135, 0.720),
    Offset(0.055, 0.430),
    Offset(0.113, 0.128),
    Offset(0.310, -0.030),
    Offset(0.500, -0.056),
    Offset(0.690, -0.030),
    Offset(0.881, 0.128),
    Offset(0.945, 0.430),
    Offset(0.887, 0.720),
  ];

  /// The wide layout's ring, on its landscape felt.
  ///
  /// The wide table is a different shape, not a bigger one - 920x450 against the phone's 362x500 -
  /// so its seats cannot be the phone's fractions. Slots 0, 2, 4, 6 and 8 are exactly where
  /// artboard 03 draws its five players; the four between them are interpolated around the same
  /// ellipse, at the angle halfway between their neighbours and the mean of their distances out.
  /// That is what lets a table of any size spread across it, as [forOpponents] does on the phone.
  static const wideRing = <Offset>[
    Offset(0.109, 0.631),
    Offset(0.027, 0.385),
    Offset(0.109, 0.098),
    Offset(0.268, -0.072),
    Offset(0.500, -0.173),
    Offset(0.732, -0.072),
    Offset(0.891, 0.098),
    Offset(0.973, 0.385),
    Offset(0.891, 0.631),
  ];

  /// Where the player's own cards sit - below the table, centred.
  static const hero = Offset(0.5, 0.885);

  /// The same, on the wide felt.
  static const wideHero = Offset(0.5, 0.929);

  /// [count] positions spread evenly around [slots], symmetric about the top.
  ///
  /// Returns the seats in ring order, so the caller is responsible for handing them players in
  /// the order it wants them seated.
  static List<Offset> forOpponents(int count, {List<Offset> slots = ring}) {
    if (count <= 0) return const [];
    final last = slots.length - 1;
    // One opponent sits opposite you, at the top of the ring.
    if (count == 1) return [slots[last ~/ 2]];
    return [
      for (var i = 0; i < count; i++)
        slots[((i * last) / (count - 1)).round().clamp(0, last)],
    ];
  }
}
