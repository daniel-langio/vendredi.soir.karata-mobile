import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';
import '../../models/admin_player.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../../widgets/admin/admin_column.dart';
import '../../widgets/admin/admin_data_table.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/admin/admin_record_card.dart';
import '../../widgets/admin/admin_stat_tile.dart';
import '../../widgets/common/avatar.dart';
import '../../widgets/common/breakpoints.dart';
import '../../widgets/common/karata_tag.dart';
import '../../widgets/desktop/desktop_sidebar.dart';

enum _PlayerFilter { all, humans, bots, suspended }

/// Which column the list is ordered by. Sorting is the client's, not the server's: the whole list
/// is already here, and a round trip to reorder rows already on screen would be a slower answer
/// to a question the operator can ask again a second later.
enum _PlayerSort { name, balance, joined }

/// Every account the house has, and where each one is sitting.
class AdminPlayersScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const AdminPlayersScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<AdminPlayersScreen> createState() => _AdminPlayersScreenState();
}

class _AdminPlayersScreenState extends State<AdminPlayersScreen> {
  late final ApiClient _api;
  List<AdminPlayer> _players = [];
  bool _loading = true;
  String? _error;
  _PlayerFilter _filter = _PlayerFilter.all;
  _PlayerSort _sort = _PlayerSort.name;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _load();
    ChipDisplay.instance.refreshRateFromServer(_api);
  }

  Future<void> _load() async {
    setState(() {
      _loading = _players.isEmpty;
      _error = null;
    });
    try {
      final players = await _api.listAdminPlayers();
      if (!mounted) return;
      setState(() {
        _players = players.map(AdminPlayer.fromJson).toList();
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

  List<AdminPlayer> get _shown {
    final filtered = switch (_filter) {
      _PlayerFilter.all => _players,
      _PlayerFilter.humans => _players.where((p) => !p.bot).toList(),
      _PlayerFilter.bots => _players.where((p) => p.bot).toList(),
      _PlayerFilter.suspended => _players.where((p) => p.suspended).toList(),
    };
    final ordered = [...filtered];
    switch (_sort) {
      case _PlayerSort.name:
        ordered.sort((a, b) => a.username.compareTo(b.username));
      case _PlayerSort.balance:
        ordered.sort((a, b) => b.balance.compareTo(a.balance));
      case _PlayerSort.joined:
        // Accounts with no recorded join date sort last rather than being treated as the oldest,
        // which is what a null read as zero would do.
        ordered.sort((a, b) {
          if (a.joinedAt == null) return b.joinedAt == null ? 0 : 1;
          if (b.joinedAt == null) return -1;
          return b.joinedAt!.compareTo(a.joinedAt!);
        });
    }
    return ordered;
  }

  Future<void> _open(AdminPlayer player) async {
    await Navigator.of(context).pushNamed(
      '/admin/players/${Uri.encodeComponent(player.username)}',
      arguments: _sessionArgs,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<ChipDisplaySettings>(
      valueListenable: ChipDisplay.instance,
      builder: (context, chips, _) => AdminPage(
        nav: DesktopNav.adminPlayers,
        sessionArgs: _sessionArgs,
        username: widget.username,
        title: t.adminPlayers,
        subtitle: t.adminAccountsShown(
          '${_shown.length}',
          '${_players.length}',
        ),
        loading: _loading,
        error: _error,
        onRetry: _load,
        children: [
          AdminStatRow(tiles: _stats(t)),
          AdminFilterRow(
            labels: [
              t.filterAll,
              t.adminPlayers,
              t.filterBots,
              t.filterSuspended,
            ],
            selectedIndex: _filter.index,
            onChanged: (i) => setState(() => _filter = _PlayerFilter.values[i]),
          ),
          if (_shown.isEmpty)
            AdminNote(t.adminNoPlayers)
          else if (KarataLayout.isWide(context))
            _table(context, t, chips)
          else
            ..._cards(context, t, chips),
        ],
      ),
    );
  }

  List<Widget> _stats(AppLocalizations t) {
    final humans = _players.where((p) => !p.bot).toList();
    final bots = _players.where((p) => p.bot).toList();
    final seated = _players.where((p) => p.seated).length;
    return [
      AdminStatTile(
        label: t.adminColumnSeated,
        value: '$seated / ${_players.length}',
        caption: t.adminPlayersAtATable,
      ),
      AdminStatTile(
        label: t.adminPlayers,
        value: '${humans.where((p) => p.seated).length} / ${humans.length}',
        caption: t.adminHumanAccountsSeated,
      ),
      AdminStatTile(
        label: t.filterBots,
        value: '${bots.where((p) => p.seated).length} / ${bots.length}',
        caption: t.adminBotAccountsSeated,
      ),
    ];
  }

  Widget _table(
    BuildContext context,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    return AdminDataTable(
      columns: [
        AdminColumn(
          t.adminColumnPlayer,
          width: const FlexColumnWidth(2.4),
          sortable: true,
        ),
        AdminColumn(
          t.adminColumnBalance,
          width: const FlexColumnWidth(1.3),
          sortable: true,
          alignment: Alignment.centerRight,
        ),
        AdminColumn(t.adminColumnStatus, width: const FlexColumnWidth(1.1)),
        AdminColumn(
          t.adminColumnJoined,
          width: const FlexColumnWidth(1.3),
          sortable: true,
        ),
        AdminColumn(t.adminColumnAtTable, width: const FlexColumnWidth(1.6)),
      ],
      sortedColumn: switch (_sort) {
        _PlayerSort.name => 0,
        _PlayerSort.balance => 1,
        _PlayerSort.joined => 3,
      },
      onSort: (i) => setState(() {
        _sort = switch (i) {
          1 => _PlayerSort.balance,
          3 => _PlayerSort.joined,
          _ => _PlayerSort.name,
        };
      }),
      rows: [
        for (final player in _shown)
          [
            _identity(player, t),
            Text(
              ChipDisplay.formatWith(chips, player.balance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: karataText(size: 15, weight: 700),
            ),
            KarataTag(
              label: player.suspended ? t.adminSuspended : t.adminActive,
              tone: player.suspended
                  ? KarataTagTone.full
                  : KarataTagTone.cashout,
              dense: false,
            ),
            _muted(_joined(context, t, player)),
            _muted(player.atTableName ?? t.adminNotSeated),
          ],
      ],
    );
  }

  Widget _identity(AdminPlayer player, AppLocalizations t) {
    return GestureDetector(
      onTap: () => _open(player),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Avatar(name: player.username, diameter: 30),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              player.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: karataText(size: 15, weight: 700),
            ),
          ),
          if (player.bot) ...[
            const SizedBox(width: 8),
            KarataTag(label: t.adminBot),
          ],
        ],
      ),
    );
  }

  List<Widget> _cards(
    BuildContext context,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) => [
    for (final player in _shown)
      AdminRecordCard(
        title: player.username,
        subtitle: player.bot ? t.adminBot : '',
        trailing: KarataTag(
          label: player.suspended ? t.adminSuspended : t.adminActive,
          tone: player.suspended ? KarataTagTone.full : KarataTagTone.cashout,
        ),
        fields: [
          (t.adminColumnBalance, ChipDisplay.formatWith(chips, player.balance)),
          (t.adminColumnJoined, _joined(context, t, player)),
          (t.adminColumnAtTable, player.atTableName ?? t.adminNotSeated),
        ],
        onPressed: () => _open(player),
      ),
  ];

  /// The server does not know when an account registered if it predates the column, so the date
  /// is a dash rather than a guess.
  String _joined(BuildContext context, AppLocalizations t, AdminPlayer player) {
    final joined = player.joinedAt;
    if (joined == null) return t.adminUnknownDate;
    return MaterialLocalizations.of(context).formatShortDate(joined.toLocal());
  }

  Widget _muted(String text) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: karataText(size: 14, weight: 600, color: KarataColors.inkMuted),
  );
}
