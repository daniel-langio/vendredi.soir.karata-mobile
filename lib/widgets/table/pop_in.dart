import 'package:flutter/material.dart';

/// Scales [child] in from 1.3x down to its natural size whenever [popKey] changes (including on
/// first mount) - the same "just happened" pop already used for last-action badges, reused here
/// for card reveals, the pot amount ticking up, and the winner banner. A constant [popKey] plays
/// the pop exactly once, when this widget is first inserted into the tree.
class PopIn extends StatelessWidget {
  final Object? popKey;
  final Widget child;

  const PopIn({super.key, required this.popKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(popKey),
      tween: Tween(begin: 1.3, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}
