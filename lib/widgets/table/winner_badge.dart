import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../common/status_pill.dart';

/// The "Winner" pill that overlaps the bottom edge of a winning hand's cards.
///
/// Pops in rather than simply appearing: scales up past its own size before settling, the one
/// flourish the showdown gets beyond the cards' own glow.
class WinnerBadge extends StatefulWidget {
  const WinnerBadge({super.key, required this.label, this.height = 28});

  final String label;
  final double height;

  @override
  State<WinnerBadge> createState() => _WinnerBadgeState();
}

class _WinnerBadgeState extends State<WinnerBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void initState() {
    super.initState();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 54),
    ]).animate(_controller);

    return ScaleTransition(
      scale: scale,
      child: StatusPill(
        label: widget.label,
        height: widget.height,
        background: KarataColors.gold,
        foreground: KarataColors.onGoldBadge,
        ringColor: KarataColors.goldWash,
        fontSize: widget.height >= 28 ? 15 : 13,
        fontWeight: 800,
      ),
    );
  }
}
