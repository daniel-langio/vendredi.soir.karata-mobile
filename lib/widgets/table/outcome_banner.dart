import 'package:flutter/material.dart';
import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import 'pop_in.dart';

class OutcomeBanner extends StatelessWidget {
  final Map<String, dynamic> outcome;
  final String myUsername;
  const OutcomeBanner({
    super.key,
    required this.outcome,
    required this.myUsername,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final winners = outcome['winners'] as List<dynamic>? ?? [];
    if (winners.isEmpty) return const SizedBox();
    final names = winners
        .map(
          (w) => w['username'] == myUsername ? t.you : w['username'].toString(),
        )
        .join(' & ');
    final total = winners.fold<int>(
      0,
      (sum, w) => sum + ((w['amount'] as num?)?.toInt() ?? 0),
    );
    final rank = (winners.first as Map<String, dynamic>)['handRank'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // This widget only exists in the tree once a hand reaches showdown, so a constant popKey
        // is enough - it pops in exactly once per showdown, on first mount, and won't replay on
        // the polling rebuilds that follow while the same outcome is still showing.
        PopIn(
          popKey: 'winner-pill',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: KarataColors.winnerGold,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              t.winnerTag,
              style: const TextStyle(
                color: KarataColors.winnerGoldInk,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.won(names, ChipDisplay.instance.format(total)),
          style: const TextStyle(
            color: KarataColors.ink,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (rank != null) ...[
          const SizedBox(height: 4),
          Text(
            rank,
            style: const TextStyle(color: KarataColors.dim, fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}
