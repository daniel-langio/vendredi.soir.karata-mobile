import 'package:flutter/widgets.dart';

/// Karata's mark: two cards fanned, the front one bearing a laterite spade.
///
/// Shipped as an image rather than drawn, because it is the same artwork as the launcher icon and
/// the favicon - one file to change when the brand does, and no chance of the app's own logo
/// drifting from the icon on the home screen.
///
/// The PNG is used rather than the SVG beside it: the SVG would need a rendering package, and at
/// 1024px the raster is sharp at every size this is drawn at.
class KarataLogo extends StatelessWidget {
  const KarataLogo({super.key, this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/karata_mark_1024.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      // The mark is the app's identity; drawing nothing is better than drawing a broken-image
      // glyph if the asset ever fails to resolve.
      errorBuilder: (context, error, stack) => SizedBox.square(dimension: size),
    );
  }
}
