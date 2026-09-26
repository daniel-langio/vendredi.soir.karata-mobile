import 'package:flutter/widgets.dart';

/// Which of the design's two layouts a viewport gets.
///
/// The V2 mockups are drawn twice: once on a 390x844 phone, and once on a 1280x860 desktop canvas
/// whose screens carry a permanent 248px sidebar instead of a back button. [isWide] is the line
/// between them.
///
/// The width floor is the narrowest the desktop drawings can honestly be held to - the sidebar is
/// 248px and the content beside it is laid out as two columns on a 48px gutter, which stops
/// reading as two columns much below this. The height floor is what keeps a phone held sideways
/// (844x390) on the phone layout: it clears the width test easily, but the desktop screens are
/// vertical stacks of 18px-padded cards that would have nowhere to go in 390px of height.
abstract final class KarataLayout {
  static const wideWidth = 900.0;
  static const wideHeight = 600.0;

  static bool isWide(BuildContext context) =>
      isWideSize(MediaQuery.sizeOf(context));

  static bool isWideSize(Size size) =>
      size.width >= wideWidth && size.height >= wideHeight;
}
