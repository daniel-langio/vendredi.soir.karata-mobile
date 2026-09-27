import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/karata_button.dart';

/// One payout the house still owes, as the wide layout lists it.
typedef PendingPayout = ({
  String amount,
  String phoneNumber,
  String provider,
  String reference,
  VoidCallback onCancel,
});

/// The payouts still owed, as a table.
///
/// The phone stacks each payout into a row of its own because four fields will not fit across
/// 390px; artboard 28 has the width to put them in columns with a header over them, which is what
/// an operator working through a list of them actually wants.
class WidePendingTable extends StatelessWidget {
  const WidePendingTable({
    super.key,
    required this.columnLabels,
    required this.rows,
    required this.cancelLabel,
  });

  /// Amount, phone, provider, reference. The action column's header is blank, as it is drawn.
  final List<String> columnLabels;

  final List<PendingPayout> rows;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: KarataColors.surface,
        child: Table(
          // The reference takes up the slack; everything else is as wide as it needs to be.
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: IntrinsicColumnWidth(),
            2: IntrinsicColumnWidth(),
            3: FlexColumnWidth(),
            4: IntrinsicColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                for (final label in columnLabels) _Header(label),
                const _Header('', alignRight: true),
              ],
            ),
            for (final row in rows)
              TableRow(
                children: [
                  _Cell(
                    child: Text(
                      row.amount,
                      style: karataText(size: 18, weight: 800),
                    ),
                  ),
                  _Cell(
                    child: Text(
                      row.phoneNumber,
                      style: karataText(
                        size: 14,
                        weight: 500,
                        color: KarataColors.inkMuted,
                      ),
                    ),
                  ),
                  _Cell(child: _ProviderTag(row.provider)),
                  _Cell(
                    child: Text(
                      row.reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: karataText(
                        size: 13,
                        weight: 500,
                        color: KarataColors.inkFaint,
                      ),
                    ),
                  ),
                  _Cell(
                    alignRight: true,
                    child: KarataButton(
                      label: cancelLabel,
                      onPressed: row.onCancel,
                      style: KarataButtonStyle.danger,
                      height: 36,
                      fontSize: 13,
                      expand: false,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label, {this.alignRight = false});

  final String label;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: karataText(
            size: 12,
            weight: 600,
            color: KarataColors.inkFaint,
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.child, this.alignRight = false});

  final Widget child;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

/// The small slug naming the mobile-money operator a payout goes through. Slightly larger than
/// the phone's, as the wide drawing sets it.
class _ProviderTag extends StatelessWidget {
  const _ProviderTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: KarataColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: karataText(size: 12, weight: 700)),
    );
  }
}
