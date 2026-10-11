import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// The name of the hand on the felt - "Pair of aces", "Two pair" - under the board it describes.
///
/// Rises and fades in the moment it appears: a fresh [HandLabel] always mounts a fresh [State],
/// since the felt only ever builds one once a showdown produces a label and removes it between
/// hands, so there is no need to key it - the entrance plays every time one shows up.
class HandLabel extends StatefulWidget {
  const HandLabel(this.label, {super.key});

  final String label;

  @override
  State<HandLabel> createState() => _HandLabelState();
}

class _HandLabelState extends State<HandLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
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
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - curved.value) * 10),
          child: child,
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: karataText(size: 18, weight: 800, color: KarataColors.gold),
        ),
      ),
    );
  }
}
