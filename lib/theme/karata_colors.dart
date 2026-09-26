import 'package:flutter/painting.dart';

/// Every colour in the Karata V2 design, named once.
///
/// The names are the design's own vocabulary rather than Material's, because the mockups do not
/// map onto a Material colour scheme: there is no "primary container", there is an orange action
/// button, a gold accent, a teal affirmative and a navy field. Keeping the design's names means a
/// value in a mockup can be found here by searching for its hex.
abstract final class KarataColors {
  // Page --------------------------------------------------------------------
  /// Top of the page's radial gradient, at 50% -10%.
  static const backdropTop = Color(0xFF23234A);

  /// The gradient's body, and the flat background wherever there is no gradient.
  static const backdrop = Color(0xFF14142A);

  /// A notch darker than [backdrop], for wells sunk into a card.
  static const backdropDeep = Color(0xFF0E0E20);

  // Surfaces ----------------------------------------------------------------
  /// Cards, inputs, and the circular icon buttons in the header.
  static const surface = Color(0xFF1E1E3A);

  /// Raised pieces sitting on top of [surface] - unselected chips, sliders, list wells.
  static const surfaceRaised = Color(0xFF29294D);

  /// The felt-side panels on the table screen.
  static const surfaceDim = Color(0xFF1C1C2E);

  // Text --------------------------------------------------------------------
  /// Headings and anything that has to read at a glance.
  static const ink = Color(0xFFF2F0F7);

  /// Body copy, field labels, and the subtitles under a screen title.
  static const inkMuted = Color(0xFFA9A8C6);

  /// The quietest tier - helper lines, captions, disabled chip text.
  static const inkFaint = Color(0xFF8A89A8);

  /// Text on top of the gold accent.
  static const onAccent = Color(0xFF5E3F00);

  /// The darker ink used on a small gold badge, where [onAccent] would not carry enough contrast
  /// at 12px.
  static const onGoldBadge = Color(0xFF3D2A00);

  static const white = Color(0xFFFFFFFF);

  // Accents -----------------------------------------------------------------
  /// The gold that carries Karata's brand - balances, links, the winner pill.
  static const gold = Color(0xFFE9C46A);
  static const goldBright = Color(0xFFFBE7A1);
  static const goldDeep = Color(0xFFC99A2E);
  static const goldWash = Color(0xFFFFF2C4);

  /// The primary action colour, with the hard drop shadow that gives buttons their lift.
  static const orange = Color(0xFFC4502A);
  static const orangeShadow = Color(0xFF7E2F15);
  static const orangeLight = Color(0xFFFF8A73);

  /// Affirmative - selected chips, "seats open", the check action.
  static const teal = Color(0xFF1F9D8B);
  static const tealDeep = Color(0xFF0F5C55);
  static const tealLight = Color(0xFF5FD4C0);

  /// "Your turn", and the blue diamond/club suits.
  static const blue = Color(0xFF2F6FD0);
  static const blueDeep = Color(0xFF2B4F86);

  /// Destructive - log out, fold, negative deltas.
  static const red = Color(0xFFD6453A);
  static const redDeep = Color(0xFF8E3A33);

  /// Positive money movement.
  static const green = Color(0xFF2E8F58);
  static const greenDeep = Color(0xFF2D5E42);

  /// The silver a private table's mascot cards are cut from, against the gold of a public one.
  static const silverBright = Color(0xFFF4F5FA);
  static const silver = Color(0xFFC2C5D4);
  static const silverDeep = Color(0xFF8E91A6);

  /// Ink on a silver face, matching what [onAccent] is to gold.
  static const onSilver = Color(0xFF3A3D52);

  // Playing cards -----------------------------------------------------------
  static const cardFace = Color(0xFFFBFAF7);
  static const cardBackTop = Color(0xFFFBE7A1);
  static const cardMuted = Color(0xFFA3A2B6);

  // Lines -------------------------------------------------------------------
  /// The hairline on a field or an outlined button.
  static const line = Color(0x1AFFFFFF);

  /// The brighter hairline used where a border has to carry an edge on its own.
  static const lineStrong = Color(0x2EFFFFFF);

  // Felt --------------------------------------------------------------------
  static const feltCenter = Color(0xFF178A7B);
  static const feltMid = Color(0xFF0F6A5F);
  static const feltEdge = Color(0xFF0B4E47);
}
