import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import 'karata_icon.dart';

/// How a Karata button is painted. The design has exactly three.
enum KarataButtonStyle {
  /// Orange, with a hard 3px ledge underneath - the one action a screen wants you to take.
  primary,

  /// Transparent with a hairline border, for the alternative next to a [primary].
  secondary,

  /// Filled navy on its own darker ledge, for actions that sit inside a card rather than at the
  /// foot of a screen.
  surface,

  /// Outlined in warm red, for the one action on a row that undoes something.
  danger,
}

/// The colours that distinguish one [KarataButtonStyle] from another: the face, the ledge beneath
/// it, and the lit top edge the design draws as an inset shadow.
extension on KarataButtonStyle {
  Color? get fill => switch (this) {
    KarataButtonStyle.primary => KarataColors.orange,
    KarataButtonStyle.secondary || KarataButtonStyle.danger => null,
    KarataButtonStyle.surface => KarataColors.surfaceRaised,
  };

  Color? get ledge => switch (this) {
    KarataButtonStyle.primary => KarataColors.orangeShadow,
    KarataButtonStyle.secondary || KarataButtonStyle.danger => null,
    KarataButtonStyle.surface => KarataColors.backdropDeep,
  };

  /// `inset 0 1px 0 rgba(255,255,255,X)` - stronger on the orange face than the navy one.
  Color? get topEdge => switch (this) {
    KarataButtonStyle.primary => const Color(0x47FFFFFF),
    KarataButtonStyle.secondary || KarataButtonStyle.danger => null,
    KarataButtonStyle.surface => const Color(0x14FFFFFF),
  };

  /// The hairline on the two styles that have no fill of their own.
  Color? get border => switch (this) {
    KarataButtonStyle.secondary => KarataColors.lineStrong,
    KarataButtonStyle.danger => const Color(0x73FF8A73),
    _ => null,
  };

  Color get foreground => switch (this) {
    KarataButtonStyle.primary => KarataColors.white,
    KarataButtonStyle.danger => KarataColors.orangeLight,
    _ => KarataColors.ink,
  };
}

/// The pill button used across every screen: 54px tall, fully rounded, label centred with an
/// optional leading icon.
///
/// The primary style's `box-shadow: 0 3px 0 #7e2f15` reads as a physical ledge, so pressing it
/// sinks the button onto that ledge rather than fading it - the mockups are static and do not
/// specify a pressed state, and sinking is the only reading of a 3px lip that stays consistent
/// with it.
class KarataButton extends StatefulWidget {
  const KarataButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = KarataButtonStyle.primary,
    this.icon,
    this.height = 54,
    this.expand = true,
    this.raised = true,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final KarataButtonStyle style;
  final KarataIconData? icon;
  final double height;

  /// Whether the button stretches to its parent's width, as it does at the foot of a screen.
  final bool expand;

  /// The label's size. 16 everywhere except the compact row actions inside a card, which the
  /// design drops to 13.
  final double fontSize;

  /// Whether the button sits on its darker ledge. The lobby's own action row is drawn flat, with
  /// only the lit top edge, so that the two buttons beside it read as one band.
  final bool raised;

  @override
  State<KarataButton> createState() => _KarataButtonState();
}

class _KarataButtonState extends State<KarataButton> {
  bool _down = false;

  static const _ledge = 3.0;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final ledge = widget.raised ? widget.style.ledge : null;
    final sunk = _down && _enabled && ledge != null;
    final foreground = widget.style.foreground;

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          KarataIcon(widget.icon!, size: 20, color: foreground),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: karataText(
              size: widget.fontSize,
              weight: 700,
              color: foreground,
            ),
          ),
        ),
      ],
    );

    // A full-width button centres its label in the space it already has; one that hugs its
    // label needs the design's own 14px of breathing room, or the pill closes to a circle around
    // a short word like "Cancel". Padded inside the clip so the lit top edge still spans the
    // whole button.
    if (!widget.expand) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: content,
      );
    }

    return Opacity(
      opacity: _enabled ? 1 : 0.45,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: _enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // Reserve the ledge so a sinking button does not shift the rest of the column.
          padding: EdgeInsets.only(
            top: sunk ? _ledge : 0,
            bottom: sunk ? 0 : (ledge != null ? _ledge : 0),
          ),
          child: Container(
            height: widget.height,
            width: widget.expand ? double.infinity : null,
            decoration: BoxDecoration(
              color: widget.style.fill,
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: widget.style.border == null
                  ? null
                  : Border.all(color: widget.style.border!, width: 1.5),
              boxShadow: ledge != null && !sunk
                  ? [BoxShadow(color: ledge, offset: const Offset(0, _ledge))]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: Stack(
                children: [
                  Center(child: content),
                  if (widget.style.topEdge case final edge?)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 1,
                      child: ColoredBox(color: edge),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
