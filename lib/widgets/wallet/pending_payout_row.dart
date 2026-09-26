import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/dashed_ring.dart';
import '../common/karata_button.dart';
import '../common/karata_icon.dart';
import '../common/karata_icons.dart';

/// One payout the house still owes: how much, to which number, through which provider, and the
/// button that refunds it instead.
class PendingPayoutRow extends StatelessWidget {
  const PendingPayoutRow({
    super.key,
    required this.amount,
    required this.phoneNumber,
    required this.provider,
    required this.reference,
    required this.cancelLabel,
    required this.onCancel,
  });

  final String amount;
  final String phoneNumber;
  final String provider;
  final String reference;
  final String cancelLabel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 40,
          child: Stack(
            alignment: Alignment.center,
            children: const [
              DashedRing(diameter: 40, color: Color(0x80E9C46A)),
              KarataIcon(
                KarataIcons.externalLink,
                size: 18,
                color: KarataColors.gold,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(amount, style: karataText(size: 20, weight: 800)),
              const SizedBox(height: 3),
              Text(
                phoneNumber,
                style: karataText(
                  size: 13,
                  weight: 500,
                  color: KarataColors.inkMuted,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  _ProviderTag(provider),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: karataText(
                        size: 12,
                        weight: 500,
                        color: KarataColors.inkFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        KarataButton(
          label: cancelLabel,
          onPressed: onCancel,
          style: KarataButtonStyle.danger,
          height: 36,
          fontSize: 13,
          expand: false,
        ),
      ],
    );
  }
}

/// The small slug naming the mobile-money operator a payout goes through.
class _ProviderTag extends StatelessWidget {
  const _ProviderTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: KarataColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: karataText(size: 11, weight: 700)),
    );
  }
}
