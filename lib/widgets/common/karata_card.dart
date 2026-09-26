import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import 'kente_ribbon.dart';

/// The rounded navy panel that holds nearly every group of controls in the app.
class KarataCard extends StatelessWidget {
  const KarataCard({
    super.key,
    required this.child,
    this.ribbon = false,
    this.padding = const EdgeInsets.all(18),
    this.color = KarataColors.surface,
    this.gradient,
  });

  final Widget child;

  /// Whether the kente stripe runs along the card's top edge.
  final bool ribbon;

  final EdgeInsets padding;
  final Color color;
  final Gradient? gradient;

  static const radius = 18.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: gradient == null ? color : null,
            gradient: gradient,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ribbon) const KenteRibbon(),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// The hairline the design uses to separate two rows inside a card.
class CardDivider extends StatelessWidget {
  const CardDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: Color(0x12FFFFFF), child: SizedBox(height: 1));
}
