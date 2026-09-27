import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';

/// The table itself: a teal felt oval inside a wooden rail.
///
/// Both are ellipses rather than circles - the design gives them separate horizontal and vertical
/// radii (`border-radius: 181px / 250px`), so each is built from an elliptical [BorderRadius]
/// sized to the box rather than [BoxShape.circle], which would round it to whichever side is
/// shorter.
class TableFelt extends StatelessWidget {
  const TableFelt({super.key, required this.size, this.railThickness = 14});

  final Size size;

  /// How far the felt is inset inside the rail, from the mockup's two ovals. 14 on the phone; the
  /// wide table's rail is drawn heavier, at 22.
  final double railThickness;

  static BorderRadius _oval(Size size) =>
      BorderRadius.all(Radius.elliptical(size.width / 2, size.height / 2));

  @override
  Widget build(BuildContext context) {
    final feltSize = Size(
      size.width - railThickness * 2,
      size.height - railThickness * 2,
    );

    return SizedBox.fromSize(
      size: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _oval(size),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6B4630), Color(0xFF3D2517)],
                ),
                // A lit top edge on the rail: `inset 0 2px 0 rgba(255,255,255,0.12)`.
                border: Border.all(color: const Color(0x1FFFFFFF), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x8C000000),
                    blurRadius: 34,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: railThickness,
            top: railThickness,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _oval(feltSize),
                gradient: const RadialGradient(
                  center: Alignment(0, -0.16),
                  radius: 0.72,
                  colors: [
                    KarataColors.feltCenter,
                    KarataColors.feltMid,
                    KarataColors.feltEdge,
                  ],
                  stops: [0, 0.55, 1],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
              child: SizedBox.fromSize(size: feltSize),
            ),
          ),
        ],
      ),
    );
  }
}
