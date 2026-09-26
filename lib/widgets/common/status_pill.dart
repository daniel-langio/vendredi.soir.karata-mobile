import 'package:flutter/widgets.dart';

import '../../theme/karata_text_styles.dart';
import 'dashed_ring.dart';

/// A small rounded tag with a dashed chip glyph in front of its label - "Seats open" on a table
/// card, the outstanding count on the pending-payouts row.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.height = 26,
    this.ringColor,
  });

  final String label;
  final Color foreground;
  final Color background;
  final double height;

  /// Defaults to [foreground]; the gold badge draws a paler ring than its text.
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final ringSize = height - 8;
    return Container(
      height: height,
      padding: EdgeInsets.only(left: (height - ringSize) / 2, right: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DashedRing(diameter: ringSize, color: ringColor ?? foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: karataText(size: 13, weight: 700, color: foreground),
          ),
        ],
      ),
    );
  }
}
