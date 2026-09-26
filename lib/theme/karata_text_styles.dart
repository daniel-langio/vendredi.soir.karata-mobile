import 'package:flutter/painting.dart';

import 'karata_colors.dart';

/// The app's single typeface. Declared in pubspec.yaml against the variable TTF in assets/fonts.
const kKarataFont = 'Bricolage Grotesque';

/// Bricolage Grotesque is a *variable* font, and its axis defaults are opsz 96 / wght 800. That
/// matters more than it sounds: a [TextStyle] that only sets `fontWeight` leaves the axes alone,
/// so every unstyled run would render as 96pt ExtraBold regardless of what `fontWeight` says.
/// Weight therefore has to travel as a [FontVariation] on the `wght` axis, which is what
/// [karataText] exists to guarantee.
///
/// The `opsz` axis is set to the font size, mirroring the CSS default of `font-optical-sizing:
/// auto` that the mockups were rendered under - the design's headings are drawn with the display
/// cut of the face and its small print with the text cut, and pinning a single optical size would
/// visibly thicken one end or the other.
TextStyle karataText({
  required double size,
  required int weight,
  Color color = KarataColors.ink,
  double? height,
  double? letterSpacing,
  TextDecoration? decoration,
}) {
  return TextStyle(
    fontFamily: kKarataFont,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing == null ? null : letterSpacing * size,
    color: color,
    decoration: decoration,
    // `fontWeight` is still set so that anything reading the style back (a Material widget picking
    // an icon weight, a golden-file diff) sees the intended weight; `wght` is what actually draws.
    fontWeight: _nearestFontWeight(weight),
    fontVariations: [
      FontVariation('wght', weight.toDouble()),
      FontVariation('opsz', size.clamp(12.0, 96.0)),
      FontVariation('wdth', 100),
    ],
  );
}

FontWeight _nearestFontWeight(int weight) =>
    FontWeight.values[((weight ~/ 100) - 1).clamp(0, 8)];

/// The type roles the V2 mockups actually use. Letter spacing is expressed in `em` (as the design
/// does) and multiplied by the size inside [karataText].
abstract final class KarataText {
  /// The wordmark on the welcome screen.
  static final display = karataText(
    size: 52,
    weight: 800,
    height: 1,
    letterSpacing: -0.03,
  );

  /// The big heading at the top of every screen - "Wallet", "Create account".
  static final title = karataText(
    size: 32,
    weight: 800,
    height: 1.05,
    letterSpacing: -0.02,
  );

  /// The heading inside a card - "Table", "Your buy-in", "House".
  static final sectionTitle = karataText(size: 18, weight: 800);

  /// A table's name on a lobby card.
  static final cardTitle = karataText(size: 24, weight: 800);

  /// The explanatory line under a screen title, and helper copy under a control.
  static final subtitle = karataText(
    size: 14,
    weight: 500,
    color: KarataColors.inkMuted,
    height: 1.45,
  );

  /// Body copy at the same weight as [subtitle] but sized to sit inside a card.
  static final body = karataText(
    size: 15,
    weight: 600,
    color: KarataColors.ink,
  );

  /// The label above a field.
  static final label = karataText(
    size: 13,
    weight: 600,
    color: KarataColors.inkMuted,
  );

  /// Text the user has typed, and the value shown in a read-only field.
  static final input = karataText(
    size: 16,
    weight: 600,
    color: KarataColors.white,
  );

  /// Every button in the app.
  static final button = karataText(size: 16, weight: 700);

  /// A pill, a chip, or a compact button inside a card.
  static final chip = karataText(size: 14, weight: 700);

  /// The quietest tier - the debug line on the welcome screen, captions under a row.
  static final caption = karataText(
    size: 12,
    weight: 500,
    color: KarataColors.inkFaint,
  );

  /// A balance, a pot, a stack - anything that is a number first.
  static final amount = karataText(size: 34, weight: 800, letterSpacing: -0.02);
}
