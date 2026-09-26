import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/css_gradient.dart';
import '../common/karata_button.dart';
import '../common/karata_icons.dart';
import '../common/kente_ribbon.dart';
import '../common/ripple_texture.dart';

/// The teal-shot navy card carrying the player's balance, on both the lobby and the wallet.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.unit,
    required this.balanceLabel,
    required this.atTablesLabel,
    required this.atTables,
    required this.depositLabel,
    required this.withdrawLabel,
    required this.onDeposit,
    required this.onWithdraw,
    this.onTap,
    this.radius = 18,
  });

  /// Already formatted for display - the card lays out digits, it does not convert them.
  final String balance;

  /// The unit printed after the balance at two-thirds its size, or null in chip mode.
  final String? unit;

  final String balanceLabel;
  final String atTablesLabel;
  final String atTables;
  final String depositLabel;
  final String withdrawLabel;
  final VoidCallback? onDeposit;
  final VoidCallback? onWithdraw;

  /// Opens the wallet. The lobby reaches its wallet by tapping the card itself, since the design
  /// gives it no separate link.
  final VoidCallback? onTap;

  /// 16 on the lobby, 18 on the wallet, as the mockups draw them.
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: cssLinearGradient(
              angleDegrees: 160,
              colors: const [KarataColors.backdropTop, Color(0xFF172E3A)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: RippleTexture()),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const KenteRibbon(),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onTap: onTap,
                          behavior: HitTestBehavior.opaque,
                          child: _Figures(
                            balance: balance,
                            unit: unit,
                            balanceLabel: balanceLabel,
                            atTablesLabel: atTablesLabel,
                            atTables: atTables,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: KarataButton(
                                label: depositLabel,
                                icon: KarataIcons.deposit,
                                onPressed: onDeposit,
                                height: 46,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: KarataButton(
                                label: withdrawLabel,
                                icon: KarataIcons.withdraw,
                                onPressed: onWithdraw,
                                height: 46,
                                style: KarataButtonStyle.surface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The balance on the left and what is tied up at tables on the right, baselines aligned.
class _Figures extends StatelessWidget {
  const _Figures({
    required this.balance,
    required this.unit,
    required this.balanceLabel,
    required this.atTablesLabel,
    required this.atTables,
  });

  final String balance;
  final String? unit;
  final String balanceLabel;
  final String atTablesLabel;
  final String atTables;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                balanceLabel,
                style: karataText(
                  size: 13,
                  weight: 600,
                  color: KarataColors.gold,
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  text: balance,
                  children: [
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: karataText(
                          size: 20,
                          weight: 800,
                          color: KarataColors.inkMuted,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: karataText(
                  size: 34,
                  weight: 800,
                  height: 1,
                  letterSpacing: -0.01,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              atTablesLabel,
              style: karataText(
                size: 13,
                weight: 600,
                color: KarataColors.inkMuted,
              ),
            ),
            Text(atTables, style: karataText(size: 18, weight: 800)),
          ],
        ),
      ],
    );
  }
}
