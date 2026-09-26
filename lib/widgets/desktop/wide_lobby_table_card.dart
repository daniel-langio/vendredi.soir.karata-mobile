import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/avatar_stack.dart';
import '../common/css_gradient.dart';
import '../common/karata_button.dart';
import '../common/karata_icon.dart';
import '../common/kente_ribbon.dart';
import '../common/status_pill.dart';
import '../lobby/mascot_card_face.dart';
import '../lobby/mascot_palette.dart';

/// A table in the wide lobby's grid.
///
/// The same information as the phone's [LobbyTableCard], turned on its side: a flat 230px tile
/// with the table's details down the left, its two mascot cards lying flat against the right, and
/// the join button pinned to the bottom corner. Two of these sit side by side in the grid, which
/// is why it is drawn wide and short rather than tall.
class WideLobbyTableCard extends StatelessWidget {
  const WideLobbyTableCard({
    super.key,
    required this.name,
    required this.statusLabel,
    required this.buyInLabel,
    required this.playerNames,
    required this.playerCountLabel,
    required this.actionLabel,
    required this.onPressed,
    required this.decoration,
    required this.palette,
    this.seatsOpen = true,
  });

  final String name;
  final String statusLabel;
  final String buyInLabel;
  final List<String> playerNames;
  final String playerCountLabel;
  final String actionLabel;
  final VoidCallback? onPressed;

  /// The two cards lying against the right edge, varied per table so a grid of them does not read
  /// as the same picture repeated.
  final ((String, KarataIconData), (String, KarataIconData)) decoration;

  /// Gold for a public table, silver for your own.
  final MascotPalette palette;

  final bool seatsOpen;

  static const height = 230.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: cssLinearGradient(
              angleDegrees: 160,
              colors: const [KarataColors.surface, Color(0xFF16303A)],
            ),
          ),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: KenteRibbon(height: 5),
                ),
                Positioned(
                  right: -10,
                  top: 20,
                  child: IgnorePointer(
                    child: Container(
                      width: 220,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0.2, 0),
                          radius: 0.65,
                          colors: [palette.halo, palette.halo.withAlpha(0)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 36,
                  child: SizedBox(
                    width: 190,
                    height: 170,
                    child: Stack(
                      children: [
                        // Laid flat rather than fanned: the phone tilts its pair, the wide tile
                        // simply overlaps them.
                        Positioned(
                          left: 10,
                          top: 10,
                          child: _card(decoration.$1),
                        ),
                        Positioned(
                          left: 82,
                          top: 4,
                          child: _card(decoration.$2),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 26,
                  right: 190,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: karataText(size: 26, weight: 800, height: 1.1),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusPill(
                          label: statusLabel,
                          // Solid teal here, against the phone's teal wash.
                          foreground: seatsOpen
                              ? KarataColors.onTeal
                              : KarataColors.inkMuted,
                          background: seatsOpen
                              ? KarataColors.teal
                              : const Color(0x14FFFFFF),
                          ringColor: seatsOpen
                              ? KarataColors.tealPale
                              : KarataColors.inkMuted,
                          ringDiameter: 20,
                          fontWeight: 800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        buyInLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: karataText(
                          size: 14,
                          weight: 600,
                          color: KarataColors.gold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          AvatarStack(names: playerNames, diameter: 28),
                          if (playerNames.isNotEmpty) const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              playerCountLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: karataText(
                                size: 13,
                                weight: 500,
                                color: KarataColors.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 24,
                  bottom: 20,
                  child: KarataButton(
                    label: actionLabel,
                    onPressed: onPressed,
                    height: 44,
                    expand: false,
                    // `padding: 0 32px` - wider than the 14px a hugging pill takes by default.
                    horizontalPadding: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card((String, KarataIconData) card) => MascotCardFace(
    rank: card.$1,
    suit: card.$2,
    palette: palette,
    width: 92,
    height: 128,
    radius: 11,
    rankSize: 24,
    cornerSuitSize: 15,
    pipSize: 46,
    cornerInset: const Offset(7, 7),
    centrePip: true,
  );
}
