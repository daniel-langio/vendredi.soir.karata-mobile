import 'package:flutter/widgets.dart';

/// A tap target that also tells a pointing device it is one.
///
/// [GestureDetector] alone is enough on a phone, where there is no cursor to change. On the web
/// the arrow never turning into a hand makes a perfectly good button read as decoration, so every
/// control in the app goes through this instead - one place to get it right, and nothing to
/// remember at the call sites.
///
/// A null [onTap] disables both halves: no tap, and the cursor left alone rather than promising
/// something that will not happen.
class Clickable extends StatelessWidget {
  const Clickable({
    super.key,
    required this.onTap,
    required this.child,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.behavior = HitTestBehavior.opaque,
    this.cursor = SystemMouseCursors.click,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// For a control that draws a pressed state, as the buttons do when they sink onto their ledge.
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final VoidCallback? onTapCancel;

  final HitTestBehavior behavior;

  /// Overridable for the few controls that want a different one - a text field's beam, say.
  final MouseCursor cursor;

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _enabled ? cursor : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        onTapDown: _enabled ? onTapDown : null,
        onTapUp: _enabled ? onTapUp : null,
        onTapCancel: _enabled ? onTapCancel : null,
        behavior: behavior,
        child: child,
      ),
    );
  }
}
