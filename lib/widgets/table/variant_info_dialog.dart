import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Explains how the table's variant is dealt - which is the only place in the app that says so,
/// and the one thing a player joining an unfamiliar game needs before they act.
void showVariantInfo(BuildContext context, String variant) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final t = AppLocalizations.of(context);
      final title = switch (variant) {
        'OMAHA' => t.variantTitleOmaha,
        'FIVE_CARD_DRAW' => t.variantTitleFiveCardDraw,
        _ => t.variantTitle,
      };
      final holeCardsText = switch (variant) {
        'OMAHA' => t.variantHoleCardsOmaha,
        'FIVE_CARD_DRAW' => t.variantHoleCardsFiveCardDraw,
        _ => t.variantHoleCards,
      };
      final boardText = variant == 'FIVE_CARD_DRAW'
          ? t.variantDrawPhase
          : t.variantBoard;
      final rankingText = switch (variant) {
        'OMAHA' => t.variantRankingOmaha,
        'FIVE_CARD_DRAW' => t.variantRankingFiveCardDraw,
        _ => t.variantRanking,
      };
      Widget bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '•  $text',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
      );
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              bullet(holeCardsText),
              bullet(boardText),
              bullet(t.variantBetting),
              bullet(rankingText),
              const SizedBox(height: 8),
              Text(
                t.variantSimplificationsHeading,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              bullet(t.variantNoSidePots),
              bullet(t.variantSimplifiedMinRaise),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.close),
          ),
        ],
      );
    },
  );
}
