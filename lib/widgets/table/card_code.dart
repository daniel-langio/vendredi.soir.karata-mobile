import 'package:flutter/painting.dart';

import '../../theme/karata_colors.dart';
import '../common/karata_icon.dart';
import '../common/karata_icons.dart';

/// A card as the API sends it: a rank followed by a one-letter suit, such as `As`, `Td`, `9c`.
extension type const CardCode(String code) {
  /// The rank as it is printed on the face. Ten is written "10" rather than "T", which is what
  /// the design draws.
  String get rank {
    final raw = code.substring(0, code.length - 1).toUpperCase();
    return raw == 'T' ? '10' : raw;
  }

  String get suitLetter => code[code.length - 1].toLowerCase();

  KarataIconData get suit => switch (suitLetter) {
    'h' => KarataSuits.heart,
    'd' => KarataSuits.diamond,
    'c' => KarataSuits.club,
    _ => KarataSuits.spade,
  };

  /// The suit's ink on a face-up card.
  Color get color => switch (suitLetter) {
    'h' => KarataColors.red,
    'd' => KarataColors.blue,
    'c' => KarataColors.green,
    _ => KarataColors.surfaceDim,
  };

  /// The same ink, darkened for a card that is out of the hand - the design greys the card itself
  /// and drops its pips to match rather than fading the whole thing out.
  Color get mutedColor => switch (suitLetter) {
    'h' => KarataColors.redDeep,
    'd' => KarataColors.blueDeep,
    'c' => KarataColors.greenDeep,
    _ => const Color(0xFF2A2A3E),
  };

  bool get isValid => code.length >= 2;
}
