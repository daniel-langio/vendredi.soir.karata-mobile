import 'package:flutter/material.dart';
import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import 'dealer_chip.dart';
import 'last_action_badge.dart';
import 'poker_card.dart';

class SeatWidget extends StatelessWidget {
  final Map<String, dynamic> player;
  final String? activePlayerId;
  final Map<String, dynamic>? revealedHand;

  const SeatWidget({
    super.key,
    required this.player,
    required this.activePlayerId,
    this.revealedHand,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final playerId = player['playerId']?.toString();
    final username = player['username']?.toString() ?? 'Player';
    final chips = ChipDisplay.instance.format(player['chips'] as num?);
    final status = player['status']?.toString() ?? 'ACTIVE';
    final blind = player['blind']?.toString();
    final lastActionRaw = player['lastAction']?.toString();
    final contribution =
        (player['contributionThisRound'] as num?)?.toInt() ?? 0;
    final isActive = activePlayerId != null && activePlayerId == playerId;
    final isFolded = status == 'FOLDED';
    final isAllIn = status == 'ALL_IN';
    final isDealer = player['dealer'] == true;
    final bool isBot = player['isBot'] == true;
    final initial = isBot
        ? 'BOT'
        : (username.isNotEmpty ? username[0].toUpperCase() : '?');
    final holeCards = revealedHand?['holeCards'] as List<dynamic>?;
    final handRank = revealedHand?['handRank'] as String?;

    return Opacity(
      opacity: isFolded ? 0.26 : 1,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // On the clock takes priority over a stale badge from an earlier street - it's a
            // fresh decision point, not a repeat of whatever they last did.
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: TurnBadge(label: t.onTheClock),
              )
            else if (lastActionRaw != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: LastActionBadge(
                  rawAction: lastActionRaw,
                  displayText: formatLastAction(t, lastActionRaw),
                ),
              ),
            SizedBox(
              width: 64,
              height: 46,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isBot
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFF221F28),
                        shape: BoxShape.circle,
                        border: isActive
                            ? Border.all(color: KarataColors.ink, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 18,
                          color: KarataColors.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (isDealer)
                    const Positioned(top: -2, left: -2, child: DealerChip()),
                  if (blind != null || isAllIn)
                    Positioned(
                      top: 0,
                      right: -1,
                      child: Container(
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: isAllIn
                              ? KarataColors.allInBg
                              : const Color(0xFF2E2C34),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isAllIn
                              ? t.allInTag
                              : (blind == 'SMALL' ? t.sb : t.bb),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isAllIn
                                ? KarataColors.allInInk
                                : KarataColors.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              username + (isBot ? ' (BOT)' : ''),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: KarataColors.dim),
            ),
            Text(
              chips,
              style: const TextStyle(
                fontSize: 15,
                color: KarataColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (contribution > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: KarataColors.chipBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$contribution',
                  style: const TextStyle(
                    color: KarataColors.chipInk,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            // Cards flip face-up at each seat that reached a real showdown (won or lost) once
            // the hand concludes - a folded player has no entry here and stays hidden, per usual
            // poker etiquette.
            if (holeCards != null && holeCards.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                // Overlapping mini-card stack, sized for however many hole cards this variant
                // deals (2 for Hold'em, 4 for Omaha) - each card overlaps the previous by 6px.
                width: 3.0 + 30.0 + 24.0 * (holeCards.length - 1),
                height: 42,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < holeCards.length; i++)
                      Positioned(
                        left: 3.0 + i * 24.0,
                        child: PokerCardWidget(
                          cardCode: holeCards[i]?.toString(),
                          width: 30,
                          height: 42,
                          rankFontSize: 12,
                          suitFontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              if (handRank != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    handRank,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: KarataColors.dim,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The API returns lastAction as a pre-formatted English string (e.g. "CALL 20", "SMALL BLIND
/// 10") derived from the domain action itself, not a translation key - re-parse it here rather
/// than changing the API contract just for client-side display purposes.
String formatLastAction(AppLocalizations t, String raw) {
  final parts = raw.split(' ');
  if (parts.isEmpty) return raw;
  final amount = int.tryParse(parts.last) ?? 0;
  switch (parts.first) {
    case 'FOLD':
      return t.fold;
    case 'CHECK':
      return t.check;
    case 'CALL':
      return t.call(ChipDisplay.instance.format(amount));
    case 'BET':
      return t.bet(ChipDisplay.instance.format(amount));
    case 'RAISE':
      return t.raise(ChipDisplay.instance.format(amount));
    case 'SMALL':
      return '${t.sb} ${ChipDisplay.instance.format(amount)}';
    case 'BIG':
      return '${t.bb} ${ChipDisplay.instance.format(amount)}';
    default:
      return raw;
  }
}
