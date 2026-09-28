import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';
import '../../models/admin_table.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../../widgets/admin/admin_column.dart';
import '../../widgets/admin/admin_data_table.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/admin/admin_record_card.dart';
import '../../widgets/common/breakpoints.dart';
import '../../widgets/common/karata_tag.dart';
import '../../widgets/desktop/desktop_sidebar.dart';

enum _TableFilter { all, open, full, paused }

/// Every table running right now - including the private ones the lobby never shows an operator.
///
/// No pot column, unlike the mockup: a pot is only knowable by replaying a deal, and this list
/// would replay every game on the server each time it is opened.
class AdminTablesScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const AdminTablesScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<AdminTablesScreen> createState() => _AdminTablesScreenState();
}

class _AdminTablesScreenState extends State<AdminTablesScreen> {
  late final ApiClient _api;
  List<AdminTable> _tables = [];
  bool _loading = true;
  String? _error;
  _TableFilter _filter = _TableFilter.all;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _load();
    ChipDisplay.instance.refreshRateFromServer(_api);
  }

  Future<void> _load() async {
    setState(() {
      _loading = _tables.isEmpty;
      _error = null;
    });
    try {
      final tables = await _api.listAdminTables();
      if (!mounted) return;
      setState(() {
        _tables = tables.map(AdminTable.fromJson).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : '$e';
        _loading = false;
      });
    }
  }

  Map<String, dynamic> get _sessionArgs => {
    'serverUrl': widget.serverUrl,
    'token': widget.token,
    'username': widget.username,
  };

  List<AdminTable> get _shown => switch (_filter) {
    _TableFilter.all => _tables,
    _TableFilter.open => _tables.where((x) => x.status == 'OPEN').toList(),
    _TableFilter.full => _tables.where((x) => x.status == 'FULL').toList(),
    _TableFilter.paused => _tables.where((x) => x.paused).toList(),
  };

  Future<void> _open(AdminTable table) async {
    await Navigator.of(
      context,
    ).pushNamed('/admin/tables/${table.gameId}', arguments: _sessionArgs);
    _load();
  }

  String _statusLabel(AdminTable table, AppLocalizations t) =>
      switch (table.status) {
        'FULL' => t.adminStatusFull,
        'PAUSED' => t.adminStatusPaused,
        'DORMANT' => t.adminStatusDormant,
        _ => t.adminStatusOpen,
      };

  KarataTagTone _statusTone(AdminTable table) => switch (table.status) {
    'FULL' => KarataTagTone.full,
    'PAUSED' || 'DORMANT' => KarataTagTone.seated,
    _ => KarataTagTone.cashout,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final full = _tables.where((x) => x.status == 'FULL').length;
    return ValueListenableBuilder<ChipDisplaySettings>(
      valueListenable: ChipDisplay.instance,
      builder: (context, chips, _) => AdminPage(
        nav: DesktopNav.adminTables,
        sessionArgs: _sessionArgs,
        username: widget.username,
        title: t.adminTables,
        subtitle: t.adminTableCount('${_tables.length}', '$full'),
        loading: _loading,
        error: _error,
        onRetry: _load,
        children: [
          AdminFilterRow(
            labels: [t.filterAll, t.filterOpen, t.filterFull, t.filterPaused],
            selectedIndex: _filter.index,
            onChanged: (i) => setState(() => _filter = _TableFilter.values[i]),
          ),
          if (_shown.isEmpty)
            AdminNote(t.adminNoTables)
          else if (KarataLayout.isWide(context))
            _table(t, chips)
          else
            ..._cards(t, chips),
        ],
      ),
    );
  }

  Widget _table(AppLocalizations t, ChipDisplaySettings chips) {
    return AdminDataTable(
      columns: [
        AdminColumn(t.adminColumnTable, width: const FlexColumnWidth(2.6)),
        AdminColumn(t.adminColumnStatus, width: const FlexColumnWidth(1.1)),
        AdminColumn(
          t.adminColumnSeated,
          width: const FlexColumnWidth(0.9),
          alignment: Alignment.centerRight,
        ),
        AdminColumn(t.adminColumnBlinds, width: const FlexColumnWidth(1.5)),
        AdminColumn(t.adminColumnBuyIn, width: const FlexColumnWidth(1.3)),
      ],
      rows: [
        for (final table in _shown)
          [
            _nameCell(table, t),
            KarataTag(
              label: _statusLabel(table, t),
              tone: _statusTone(table),
              dense: false,
            ),
            Text(
              '${table.seated} / ${table.capacity}',
              maxLines: 1,
              style: karataText(size: 15, weight: 700),
            ),
            _muted(
              table.smallBlind == null || table.bigBlind == null
                  ? '—'
                  : t.blindsPair(
                      ChipDisplay.amountOnly(chips, table.smallBlind),
                      ChipDisplay.formatWith(chips, table.bigBlind),
                    ),
            ),
            Text(
              table.defaultBuyIn == null
                  ? '—'
                  : ChipDisplay.formatWith(chips, table.defaultBuyIn),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: karataText(
                size: 15,
                weight: 800,
                color: table.defaultBuyIn == null
                    ? KarataColors.inkFaint
                    : KarataColors.gold,
              ),
            ),
          ],
      ],
    );
  }

  Widget _nameCell(AdminTable table, AppLocalizations t) {
    return GestureDetector(
      onTap: () => _open(table),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              table.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: karataText(size: 15, weight: 700),
            ),
          ),
          const SizedBox(width: 8),
          KarataTag(
            label:
                table.roomName ??
                (table.isPublic ? t.adminPublic : t.adminPrivate),
            tone: table.belongsToRoom
                ? KarataTagTone.seated
                : KarataTagTone.neutral,
          ),
        ],
      ),
    );
  }

  List<Widget> _cards(AppLocalizations t, ChipDisplaySettings chips) => [
    for (final table in _shown)
      AdminRecordCard(
        title: table.name,
        subtitle:
            table.roomName ?? (table.isPublic ? t.adminPublic : t.adminPrivate),
        trailing: KarataTag(
          label: _statusLabel(table, t),
          tone: _statusTone(table),
        ),
        fields: [
          (t.adminColumnSeated, '${table.seated} / ${table.capacity}'),
          (
            t.adminColumnBuyIn,
            table.defaultBuyIn == null
                ? '—'
                : ChipDisplay.formatWith(chips, table.defaultBuyIn),
          ),
        ],
        onPressed: () => _open(table),
      ),
  ];

  Widget _muted(String text) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: karataText(size: 14, weight: 600, color: KarataColors.inkMuted),
  );
}
