import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';
import '../../models/admin_room.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../../widgets/admin/admin_column.dart';
import '../../widgets/admin/admin_data_table.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/admin/admin_record_card.dart';
import '../../widgets/admin/admin_stat_tile.dart';
import '../../widgets/common/breakpoints.dart';
import '../../widgets/common/karata_icon.dart';
import '../../widgets/common/karata_icons.dart';
import '../../widgets/common/karata_tag.dart';
import '../../widgets/common/karata_text_field.dart';
import '../../widgets/desktop/desktop_sidebar.dart';

/// Which rooms the list is showing. A closed room is invisible everywhere else in the app, so
/// this screen is the only place it can be found and reopened.
enum _RoomFilter { all, active, disabled }

/// Which column the list is ordered by. Buy-in is the default because it is the order the lobby
/// itself puts rooms in, so the admin list reads the same way round as the thing it administers.
enum _RoomSort { name, buyIn, tables, players }

/// The stake tiers, as the house sees them - including the ones it has closed.
class AdminRoomsScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const AdminRoomsScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  late final ApiClient _api;
  List<AdminRoom> _rooms = [];
  bool _loading = true;
  String? _error;
  _RoomFilter _filter = _RoomFilter.all;
  _RoomSort _sort = _RoomSort.buyIn;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _load();
    ChipDisplay.instance.refreshRateFromServer(_api);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _rooms.isEmpty;
      _error = null;
    });
    try {
      final rooms = await _api.listAdminRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms.map(AdminRoom.fromJson).toList();
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

  List<AdminRoom> get _shown {
    final needle = _search.text.trim().toLowerCase();
    final filtered = [
      for (final entry in _rooms)
        if (switch (_filter) {
              _RoomFilter.all => true,
              _RoomFilter.active => !entry.closed,
              _RoomFilter.disabled => entry.closed,
            } &&
            (needle.isEmpty || entry.room.name.toLowerCase().contains(needle)))
          entry,
    ];
    filtered.sort(switch (_sort) {
      _RoomSort.name => (a, b) => a.room.name.compareTo(b.room.name),
      _RoomSort.buyIn => (a, b) => a.room.defaultBuyIn.compareTo(
        b.room.defaultBuyIn,
      ),
      _RoomSort.tables => (a, b) => b.room.tableCount.compareTo(
        a.room.tableCount,
      ),
      _RoomSort.players => (a, b) => b.room.playerCount.compareTo(
        a.room.playerCount,
      ),
    });
    return filtered;
  }

  Future<void> _createRoom() async {
    await Navigator.of(
      context,
    ).pushNamed('/admin/rooms/new', arguments: _sessionArgs);
    _load();
  }

  Future<void> _open(AdminRoom room) async {
    await Navigator.of(
      context,
    ).pushNamed('/admin/rooms/${room.room.roomId}', arguments: _sessionArgs);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<ChipDisplaySettings>(
      valueListenable: ChipDisplay.instance,
      builder: (context, chips, _) => AdminPage(
        nav: DesktopNav.adminRooms,
        sessionArgs: _sessionArgs,
        username: widget.username,
        title: t.adminRooms,
        subtitle: t.adminRoomsSubtitle,
        loading: _loading,
        error: _error,
        onRetry: _load,
        actions: [
          AdminPrimaryAction(label: t.adminNewRoom, onPressed: _createRoom),
        ],
        children: [
          AdminStatRow(tiles: _stats(t)),
          KarataTextField(
            controller: _search,
            hintText: t.adminSearchRooms,
            onChanged: (_) => setState(() {}),
            leading: const KarataIcon(
              KarataIcons.search,
              size: 18,
              color: KarataColors.inkFaint,
            ),
          ),
          AdminFilterRow(
            labels: [t.filterAll, t.filterActive, t.filterDisabled],
            selectedIndex: _filter.index,
            onChanged: (i) => setState(() => _filter = _RoomFilter.values[i]),
          ),
          if (_shown.isEmpty)
            AdminNote(t.adminNoRooms)
          else if (KarataLayout.isWide(context))
            _table(t, chips)
          else
            ..._cards(t, chips),
        ],
      ),
    );
  }

  List<Widget> _stats(AppLocalizations t) {
    final empty = _rooms.where((r) => r.room.quiet).length;
    final full = _rooms.where((r) => r.room.isFull).length;
    final tables = _rooms.fold<int>(0, (n, r) => n + r.room.tableCount);
    final players = _rooms.fold<int>(0, (n, r) => n + r.room.playerCount);
    return [
      AdminStatTile(
        label: t.adminRooms,
        value: '${_rooms.length}',
        caption: t.adminRoomsBreakdown('$empty', '$full'),
      ),
      AdminStatTile(
        label: t.adminTablesRunning,
        value: '$tables',
        caption: t.adminAcrossAllRooms,
      ),
      AdminStatTile(
        label: t.adminPlayersSeated,
        value: '$players',
        caption: t.adminRoomSeatedNow,
      ),
    ];
  }

  Widget _table(AppLocalizations t, ChipDisplaySettings chips) {
    return AdminDataTable(
      columns: [
        AdminColumn(
          t.adminColumnRoom,
          width: const FlexColumnWidth(1.7),
          sortable: true,
        ),
        AdminColumn(t.adminColumnBlinds, width: const FlexColumnWidth(1.8)),
        AdminColumn(
          t.adminColumnBuyIn,
          width: const FlexColumnWidth(1.4),
          sortable: true,
        ),
        AdminColumn(t.roomTagCashout, width: const FlexColumnWidth(1.45)),
        AdminColumn(
          t.adminColumnTables,
          width: const FlexColumnWidth(1.1),
          sortable: true,
          alignment: Alignment.centerRight,
        ),
        AdminColumn(
          t.adminColumnPlayers,
          width: const FlexColumnWidth(1.2),
          sortable: true,
          alignment: Alignment.centerRight,
        ),
        AdminColumn(t.adminColumnStatus, width: const FlexColumnWidth(1.25)),
      ],
      sortedColumn: switch (_sort) {
        _RoomSort.name => 0,
        _RoomSort.buyIn => 2,
        _RoomSort.tables => 4,
        _RoomSort.players => 5,
      },
      onSort: (i) => setState(() {
        _sort = switch (i) {
          0 => _RoomSort.name,
          4 => _RoomSort.tables,
          5 => _RoomSort.players,
          _ => _RoomSort.buyIn,
        };
      }),
      rows: [
        for (final entry in _shown)
          [
            _nameCell(entry, t),
            _muted(
              t.blindsPair(
                ChipDisplay.amountOnly(chips, entry.room.smallBlind),
                ChipDisplay.formatWith(chips, entry.room.bigBlind),
              ),
            ),
            Text(
              ChipDisplay.formatWith(chips, entry.room.defaultBuyIn),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: karataText(
                size: 15,
                weight: 800,
                color: KarataColors.gold,
              ),
            ),
            KarataTag(
              label: entry.room.cashoutEnabled
                  ? t.roomTagCashout
                  : t.roomTagPlayChips,
              tone: entry.room.cashoutEnabled
                  ? KarataTagTone.cashout
                  : KarataTagTone.neutral,
              dense: false,
            ),
            _number('${entry.room.tableCount}'),
            _number('${entry.room.playerCount}'),
            KarataTag(
              label: entry.closed ? t.adminDisabled : t.adminActive,
              tone: entry.closed ? KarataTagTone.full : KarataTagTone.cashout,
              dense: false,
            ),
          ],
      ],
    );
  }

  Widget _nameCell(AdminRoom entry, AppLocalizations t) {
    return GestureDetector(
      onTap: () => _open(entry),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.room.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: karataText(size: 15, weight: 700),
          ),
          const SizedBox(height: 2),
          Text(
            t.roomVariantLong(entry.room.variant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: karataText(
              size: 12,
              weight: 600,
              color: KarataColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _cards(AppLocalizations t, ChipDisplaySettings chips) => [
    for (final entry in _shown)
      AdminRecordCard(
        title: entry.room.name,
        subtitle: t.roomVariantLong(entry.room.variant),
        trailing: KarataTag(
          label: entry.closed ? t.adminDisabled : t.adminActive,
          tone: entry.closed ? KarataTagTone.full : KarataTagTone.cashout,
        ),
        fields: [
          (
            t.adminColumnBlinds,
            t.blindsPair(
              ChipDisplay.amountOnly(chips, entry.room.smallBlind),
              ChipDisplay.formatWith(chips, entry.room.bigBlind),
            ),
          ),
          (
            t.adminColumnBuyIn,
            ChipDisplay.formatWith(chips, entry.room.defaultBuyIn),
          ),
          (t.adminColumnTables, '${entry.room.tableCount}'),
          (t.adminColumnPlayers, '${entry.room.playerCount}'),
        ],
        onPressed: () => _open(entry),
      ),
  ];

  Widget _muted(String text) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: karataText(size: 14, weight: 600, color: KarataColors.inkMuted),
  );

  Widget _number(String text) =>
      Text(text, maxLines: 1, style: karataText(size: 15, weight: 700));
}
