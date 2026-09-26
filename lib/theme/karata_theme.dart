import 'package:flutter/material.dart';

import 'karata_colors.dart';
import 'karata_text_styles.dart';

/// The Material theme Karata hands to [MaterialApp].
///
/// Most of the V2 design is drawn by the widgets in `lib/widgets/common/` rather than by Material,
/// because the mockups specify shapes Material has no slot for - a button with a hard ledge under
/// it, a field with a 25px radius and a hairline border. What is set here is the part Material
/// still owns: the page colour, the text selection, the dialogs and snack bars, and the default
/// text style everything inherits.
ThemeData karataTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: kKarataFont,
  );

  return base.copyWith(
    scaffoldBackgroundColor: KarataColors.backdrop,
    canvasColor: KarataColors.backdrop,
    colorScheme: const ColorScheme.dark(
      surface: KarataColors.surface,
      surfaceContainerHighest: KarataColors.surfaceRaised,
      primary: KarataColors.orange,
      onPrimary: KarataColors.white,
      secondary: KarataColors.gold,
      onSecondary: KarataColors.onAccent,
      tertiary: KarataColors.teal,
      error: KarataColors.red,
      onSurface: KarataColors.ink,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: kKarataFont,
      bodyColor: KarataColors.ink,
      displayColor: KarataColors.ink,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: KarataColors.gold,
      selectionColor: Color(0x55E9C46A),
      selectionHandleColor: KarataColors.gold,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: KarataColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titleTextStyle: KarataText.sectionTitle,
      contentTextStyle: KarataText.subtitle,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: KarataColors.surfaceRaised,
      contentTextStyle: KarataText.body,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: KarataColors.gold,
    ),
    dividerColor: const Color(0x12FFFFFF),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
