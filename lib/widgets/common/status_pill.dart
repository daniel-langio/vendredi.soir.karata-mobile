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
    this.fontSize,
    this.fontWeight,
    this.ringDiameter,
  });

  final String label;
  final Color foreground;
  final Color background;
  final double height;

  /// Defaults to [foreground]; the gold badge draws a paler ring than its text.
  final Color? ringColor;

  /// The wide layout draws this pill smaller than the phone does - an 11px count on a 20px badge
  /// in the sidebar, against 13px on a 26px pill on a lobby card - and sizes the glyph beside it
  /// to match. Both default to the phone's proportions, so a pill that does not ask for them is
  /// drawn exactly as before.
  final double? fontSize;
  final int? fontWeight;
  final double? ringDiameter;

  @override
  Widget build(BuildContext context) {
    final ringSize = ringDiameter ?? height - 8;
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
            style: karataText(
              size: fontSize ?? 13,
              weight: fontWeight ?? 700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
