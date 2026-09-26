import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import 'karata_icon.dart';

/// A labelled row inside a card: an optional round icon, a title with a line of explanation, and
/// a control on the right - a switch, a dropdown, or a chevron.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.trailing,
    this.onTap,
    this.iconColor = KarataColors.gold,
  });

  final String title;
  final String? description;
  final KarataIconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: KarataColors.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Center(child: KarataIcon(icon!, size: 18, color: iconColor)),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: karataText(size: 15, weight: 700)),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description!,
                  style: karataText(
                    size: 13,
                    weight: 500,
                    color: KarataColors.inkMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );

    // 44px is the design's own minimum for a tappable row, and keeping it on the untapped rows
    // too stops a card's spacing changing depending on whether its rows happen to be links.
    final sized = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: row,
    );
    if (onTap == null) return sized;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: sized,
    );
  }
}
