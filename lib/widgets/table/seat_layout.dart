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

  /// Where the player's own cards sit - below the table, centred.
  static const hero = Offset(0.5, 0.885);

  /// [count] positions spread evenly around [ring], symmetric about the top.
  ///
  /// Returns the seats in ring order, so the caller is responsible for handing them players in
  /// the order it wants them seated.
  static List<Offset> forOpponents(int count) {
    if (count <= 0) return const [];
    if (count == 1) return const [Offset(0.500, -0.056)];
    final last = ring.length - 1;
    return [
      for (var i = 0; i < count; i++)
        ring[((i * last) / (count - 1)).round().clamp(0, last)],
    ];
  }
}
