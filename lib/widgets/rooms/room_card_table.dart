import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import 'room_card_chip.dart';

/// The felt-and-wood table filling a populated room card's background - not a decorative accent
/// but the card's actual background, the way the live table itself is drawn: a large circle
/// anchored just off the card's bottom-right corner, its far edge visible curving up past the
/// top-left, with two chip stacks resting on the felt.
///
/// Every layer is positioned with `right`/`bottom` rather than `left`/`top`, at the offsets the
/// design draws for its 358x218 card, so the crop stays anchored to the corner it was drawn
/// against however wide the card ends up - full phone width in the list, a fixed tile in the
/// desktop grid.
///
/// Left out entirely for a [RoomCardState.quiet] room - see `RoomQuietWell` - so an empty room
/// reads as quiet rather than borrowing a busy room's imagery.
class RoomCardTable extends StatelessWidget {
  const RoomCardTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            const _Ellipse(
              right: -426,
              bottom: -408,
              width: 836,
              height: 380,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x66000000), Color(0x00000000)],
                  stops: [0, 0.7],
                ),
              ),
            ),
            const _Ellipse(
              right: -360,
              bottom: -370,
              width: 760,
              height: 760,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6B4630), Color(0xFF3D2517)],
                ),
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0x14FFFFFF), width: 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
            const _Ellipse(
              right: -340,
              bottom: -350,
              width: 720,
              height: 720,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.3, -0.4),
                  radius: 0.75,
                  colors: [
                    KarataColors.feltCenter,
                    KarataColors.feltMid,
                    KarataColors.feltEdge,
                  ],
                  stops: [0, 0.55, 1],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
            ),
            const _Ellipse(
              right: -336,
              bottom: -346,
              width: 712,
              height: 712,
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0x1EFFFFFF), width: 1),
                ),
              ),
            ),
            const _Ellipse(
              right: 5,
              bottom: 131,
              width: 304,
              height: 198,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF)],
                  stops: [0, 0.7],
                ),
              ),
            ),
            // A stack of 5, peeking in from the top-right edge, in the gap between the header and
            // the occupancy row.
            for (var i = 0; i < 5; i++)
              Positioned(
                right: 17 - 4.0 * i,
                bottom: 159 - 4.0 * i,
                child: const RoomCardChip(size: 22),
              ),
            // A smaller stack of 3, low on the left edge.
            for (var i = 0; i < 3; i++)
              Positioned(
                right: 345 - 3.0 * i,
                bottom: 5 - 3.0 * i,
                child: const RoomCardChip(size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

/// One of the table's circles or ellipses, sized and positioned from the card's bottom-right
/// corner rather than [BoxShape.circle], which cannot draw the two non-round ellipses (the
/// grounding shadow and the overhead highlight).
class _Ellipse extends StatelessWidget {
  const _Ellipse({
    required this.right,
    required this.bottom,
    required this.width,
    required this.height,
    required this.decoration,
  });

  final double right;
  final double bottom;
  final double width;
  final double height;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: decoration.copyWith(
          borderRadius: BorderRadius.all(
            Radius.elliptical(width / 2, height / 2),
          ),
        ),
      ),
    );
  }
}
