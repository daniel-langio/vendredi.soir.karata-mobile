import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/clickable.dart';
import '../common/karata_card.dart';
import '../common/karata_icon.dart';
import '../common/karata_icons.dart';
import 'admin_column.dart';

/// The grid the three admin lists are built on: an uppercase header, then one row per record,
/// each separated by the same hairline a card uses between its own rows.
///
/// A real [Table] rather than a column of rows, because the whole point of these screens is
/// reading down a column - balances against each other, seat counts against each other - and
/// independently laid-out rows would not line up.
class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortedColumn,
    this.onSort,
  });

  final List<AdminColumn> columns;

  /// One list of cells per record, each the same length as [columns].
  final List<List<Widget>> rows;

  /// Which column the rows are currently ordered by, drawn in gold. Null when the order is the
  /// server's own.
  final int? sortedColumn;

  final ValueChanged<int>? onSort;

  @override
  Widget build(BuildContext context) {
    return KarataCard(
      padding: EdgeInsets.zero,
      child: Table(
        columnWidths: {
          for (var i = 0; i < columns.length; i++) i: columns[i].width,
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              for (var i = 0; i < columns.length; i++) _header(i, columns[i]),
            ],
          ),
          for (final row in rows)
            TableRow(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
              ),
              children: [
                for (var i = 0; i < row.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Align(
                      alignment: columns[i].alignment,
                      child: row[i],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _header(int index, AdminColumn column) {
    final sorted = index == sortedColumn;
    final label = Text(
      column.label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: karataText(
        size: 12,
        weight: column.sortable ? 700 : 600,
        color: sorted ? KarataColors.gold : KarataColors.inkFaint,
        letterSpacing: 0.03,
      ),
    );

    Widget content = label;
    if (column.sortable) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: label),
          const SizedBox(width: 6),
          KarataIcon(
            KarataIcons.sortArrows,
            size: 14,
            color: sorted ? KarataColors.gold : KarataColors.inkFaint,
          ),
        ],
      );
      content = Semantics(
        button: true,
        child: Clickable(
          onTap: onSort == null ? null : () => onSort!(index),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Align(alignment: column.alignment, child: content),
    );
  }
}
