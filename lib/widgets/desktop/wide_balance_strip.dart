import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/css_gradient.dart';
import '../common/karata_button.dart';
import '../common/karata_icons.dart';
import '../common/kente_ribbon.dart';
import '../common/ripple_texture.dart';

/// The balance, laid out as a band rather than a card.
///
/// Same teal-shot navy and same figures as the phone's [BalanceCard]; the wide drawing just has
/// the room to put the balance, what is tied up at tables and the two actions all on one line,
/// with a hairline between the two figures.
class WideBalanceStrip extends StatelessWidget {
  const WideBalanceStrip({
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
  });

  /// Already formatted for display - the strip lays out digits, it does not convert them.
  final String balance;
  final String? unit;
  final String balanceLabel;
  final String atTablesLabel;
  final String atTables;
  final String depositLabel;
  final String withdrawLabel;
  final VoidCallback? onDeposit;
  final VoidCallback? onWithdraw;

  /// Opens the wallet. The lobby reaches its wallet by tapping the figures, as it does on a phone.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 22,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: onTap,
                            behavior: HitTestBehavior.opaque,
                            child: _Figure(
                              label: balanceLabel,
                              labelColor: KarataColors.gold,
                              value: balance,
                              unit: unit,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 28),
                          // `align-self: stretch` on a 1px rule, which is what the IntrinsicHeight
                          // above is here to give it.
                          const ColoredBox(
                            color: Color(0x1FFFFFFF),
                            child: SizedBox(width: 1, height: double.infinity),
                          ),
                          const SizedBox(width: 28),
                          _Figure(
                            label: atTablesLabel,
                            labelColor: KarataColors.inkMuted,
                            value: atTables,
                            size: 24,
                          ),
                          const Spacer(),
                          const SizedBox(width: 28),
                          KarataButton(
                            label: depositLabel,
                            icon: KarataIcons.deposit,
                            onPressed: onDeposit,
                            height: 46,
                            expand: false,
                          ),
                          const SizedBox(width: 10),
                          KarataButton(
                            label: withdrawLabel,
                            icon: KarataIcons.withdraw,
                            onPressed: onWithdraw,
                            height: 46,
                            expand: false,
                            style: KarataButtonStyle.surface,
                          ),
                        ],
                      ),
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

/// A caption over a number, with the unit set smaller beside it.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.labelColor,
    required this.value,
    required this.size,
    this.unit,
  });

  final String label;
  final Color labelColor;
  final String value;
  final String? unit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: karataText(size: 13, weight: 600, color: labelColor),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: value,
            children: [
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: karataText(
                    size: 22,
                    weight: 800,
                    color: KarataColors.inkMuted,
                  ),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: karataText(size: size, weight: 800, height: 1),
        ),
      ],
    );
  }
}
