import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/avatar_stack.dart';
import '../common/css_gradient.dart';
import '../common/karata_button.dart';
import '../common/karata_icon.dart';
import '../common/status_pill.dart';
import 'fanned_cards.dart';

/// A table in the lobby list: its name, whether it has room, the buy-in, who is already sitting
/// there, and the button that joins it.
class LobbyTableCard extends StatelessWidget {
  const LobbyTableCard({
    super.key,
    required this.name,
    required this.statusLabel,
    required this.buyInLabel,
    required this.playerNames,
    required this.playerCountLabel,
    required this.actionLabel,
    required this.onPressed,
    required this.decoration,
    this.seatsOpen = true,
  });

  final String name;

  /// "Seats open", or whatever the table's current state is called.
  final String statusLabel;
  final String buyInLabel;
  final List<String> playerNames;
  final String playerCountLabel;
  final String actionLabel;
  final VoidCallback? onPressed;

  /// The two cards fanned into the right edge. Varied per row so a list of tables does not read
  /// as the same picture repeated.
  final ((String, KarataIconData), (String, KarataIconData)) decoration;

  final bool seatsOpen;

  /// The design draws this card at a flat 196px. Its own content only just fits that at the
  /// mockup's font metrics and not at Flutter's, and a longer translation would not fit at all -
  /// so 196 is the floor rather than the height, and the card grows instead of clipping.
  static const minHeight = 196.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: cssLinearGradient(
              angleDegrees: 160,
              colors: const [KarataColors.surface, Color(0xFF16303A)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: 26,
                child: FannedCards(left: decoration.$1, right: decoration.$2),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: minHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 150, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: karataText(
                          size: 23,
                          weight: 800,
                          height: 1.1,
                          letterSpacing: -0.01,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StatusPill(
                        label: statusLabel,
                        foreground: seatsOpen
                            ? KarataColors.tealLight
                            : KarataColors.inkMuted,
                        background: seatsOpen
                            ? const Color(0x291F9D8B)
                            : const Color(0x14FFFFFF),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AvatarStack(names: playerNames),
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 150,
                        child: KarataButton(
                          label: actionLabel,
                          onPressed: onPressed,
                          height: 42,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
