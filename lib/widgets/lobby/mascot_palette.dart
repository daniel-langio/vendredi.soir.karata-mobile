import 'package:flutter/painting.dart';

import '../../theme/karata_colors.dart';

/// The metal a table's mascot cards are cut from.
///
/// Gold for a public table, silver for your own - so which list you are looking at reads off the
/// cards themselves, not only off the tab above them.
enum MascotPalette {
  gold(
    bright: KarataColors.goldBright,
    mid: KarataColors.gold,
    deep: KarataColors.goldDeep,
    rim: KarataColors.goldWash,
    ink: KarataColors.onAccent,
    glow: Color(0x59E9C46A),
    halo: Color(0x29E9C46A),
  ),
  silver(
    bright: KarataColors.silverBright,
    mid: KarataColors.silver,
    deep: KarataColors.silverDeep,
    rim: KarataColors.silverBright,
    ink: KarataColors.onSilver,
    glow: Color(0x4DC2C5D4),
    halo: Color(0x1FC2C5D4),
  );

  const MascotPalette({
    required this.bright,
    required this.mid,
    required this.deep,
    required this.rim,
    required this.ink,
    required this.glow,
    required this.halo,
  });

  /// The three stops of the card's face gradient.
  final Color bright;
  final Color mid;
  final Color deep;

  /// The card's border.
  final Color rim;

  /// The rank and suit printed on it.
  final Color ink;

  /// The bloom around the card, and the wider wash behind the pair.
  final Color glow;
  final Color halo;
}
