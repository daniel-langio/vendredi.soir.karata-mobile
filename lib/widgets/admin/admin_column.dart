import 'package:flutter/widgets.dart';

/// One column of an [AdminDataTable].
///
/// [sortable] is what makes the header a button rather than a label. Which way it is currently
/// sorted, and what sorting actually does, belong to the screen - this only says the column
/// offers it.
class AdminColumn {
  const AdminColumn(
    this.label, {
    this.width = const FlexColumnWidth(),
    this.sortable = false,
    this.alignment = Alignment.centerLeft,
  });

  final String label;
  final TableColumnWidth width;
  final bool sortable;
  final Alignment alignment;
}
