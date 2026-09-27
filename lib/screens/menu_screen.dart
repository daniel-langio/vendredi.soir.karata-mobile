import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../models/room_summary.dart';
import '../models/table_summary.dart';
import '../session_summary.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/breakpoints.dart';
import '../widgets/common/circle_icon_button.dart';
import '../widgets/common/karata_backdrop.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_icons.dart';
import '../widgets/common/segmented_tabs.dart';
import '../widgets/lobby/lobby_table_card.dart';
import '../widgets/lobby/profile_header.dart';
import '../widgets/lobby/mascot_palette.dart';
import '../widgets/lobby/table_mascot.dart';
import '../widgets/rooms/room_card.dart';
import '../widgets/rooms/room_card_skeleton.dart';
import '../widgets/rooms/room_card_state.dart';
import '../widgets/rooms/room_sit_sheet.dart';
import '../widgets/common/karata_tag.dart';
import '../widgets/rooms/rooms_error_state.dart';
import '../widgets/desktop/desktop_shell.dart';
import '../widgets/desktop/desktop_sidebar.dart';
import '../widgets/desktop/wide_balance_strip.dart';
import '../widgets/desktop/wide_lobby_table_card.dart';
import '../widgets/desktop/wide_room_card.dart';
import '../widgets/wallet/balance_card.dart';

/// Which of the lobby's three lists is on screen.
///
/// Rooms lead, and are where a player who just wants to play should land: picking a stake and
/// being seated is one tap, where a table has to be found first. The two table lists stay behind
/// them for the tables people make themselves.
enum _LobbyTab { rooms, publicTables, myTables }

/// The parts of a room card that its state decides - see `_MenuScreenState._roomView`.
typedef _RoomView = ({
  RoomCardState state,
  String statusLabel,
  KarataTagTone statusTone,
  String footerPrefix,
  String footerAmount,
  String actionLabel,
  VoidCallback? onPressed,
});

class MenuScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const MenuScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final ApiClient _apiClient;
  List<TableSummary> _mine = [];
  List<TableSummary> _public = [];
  bool _loadingTables = true;
  String? _tablesError;
  int? _walletChips;
  int? _atTablesChips;

  List<RoomSummary> _rooms = [];
  bool _loadingRooms = true;
  String? _roomsError;

  /// The tab the player picked, or null while nobody has picked one and [_tab] is choosing.
  _LobbyTab? _chosenTab;

  /// Rooms lead, except when the lobby knows for a fact there are none.
  ///
  /// A player landing on an empty Rooms tab would be looking at nothing to do, when there may
  /// well be a public table one tap away - so an empty room list hands the lobby over to the
  /// tables. A *failed* room load is not an empty lobby and leaves the default alone: the Rooms
  /// tab's own error state is what should be read then, not a silent redirect that makes the
  /// rooms look as though they no longer exist.
  ///
  /// Derived rather than assigned, so the answer stays right when a later refresh finds rooms -
  /// and a player who has picked a tab keeps it either way.
  _LobbyTab get _tab =>
      _chosenTab ??
      (!_loadingRooms && _roomsError == null && _rooms.isEmpty
          ? _LobbyTab.publicTables
          : _LobbyTab.rooms);

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _loadTables();
    _loadRooms();
    _loadWallet();
    ChipDisplay.instance.refreshRateFromServer(_apiClient);
  }

  Future<void> _loadWallet() async {
    try {
      final chips = await _apiClient.getWallet();
      // The wide layout's sidebar prints this too, on every screen.
      SessionSummary.instance.setBalance(chips);
      if (!mounted) return;
      setState(() => _walletChips = chips);
    } catch (_) {
      // Non-critical - the balance card just shows a dash if we can't reach the server.
    }
  }

  /// Both lists come from the server now, not from a device-local record of tables visited: the
  /// server knows every table you host or sit at, so the list survives a reinstall or a new phone.
  Future<void> _loadTables() async {
    setState(() {
      _loadingTables = true;
      _tablesError = null;
    });
    try {
      final results = await Future.wait([
        _apiClient.listMyTables(),
        _apiClient.listPublicTables(),
      ]);
      if (!mounted) return;
      setState(() {
        _mine = results[0].map(TableSummary.fromJson).toList();
        _public = results[1].map(TableSummary.fromJson).toList();
        // What the player already has in front of them elsewhere, which the balance card shows
        // beside the wallet balance. Summed from the tables they are actually seated at, so a
        // table they merely host does not count towards it.
        _atTablesChips = _mine.fold<int>(
          0,
          (total, table) => total + (table.stackOf(widget.username) ?? 0),
        );
        _loadingTables = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tablesError = '$e';
        _loadingTables = false;
      });
    }
  }

  /// The stake tiers, which is the tab the lobby opens on. Kept apart from [_loadTables] so a
  /// room list that loads and a table list that does not can each say so on their own tab.
  Future<void> _loadRooms() async {
    setState(() {
      _loadingRooms = true;
      _roomsError = null;
    });
    try {
      final rooms = await _apiClient.listRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms.map(RoomSummary.fromJson).toList();
        _loadingRooms = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _roomsError = '$e';
        _loadingRooms = false;
      });
    }
  }

  Future<void> _reloadLists() => Future.wait([_loadTables(), _loadRooms()]);

  /// The table this player already occupies in [roomId], if any. `/games/mine` carries each
  /// table's room, so the lobby can send them back to their seat instead of opening a buy-in
  /// sheet for a seat they already hold - which `sit` would have quietly handed back anyway.
  TableSummary? _seatedTableIn(String roomId) {
    for (final table in _mine) {
      if (table.roomId == roomId && table.stackOf(widget.username) != null) {
        return table;
      }
    }
    return null;
  }

  Future<void> _sitInRoom(RoomSummary room) async {
    final t = AppLocalizations.of(context);

    final seat = _seatedTableIn(room.roomId);
    if (seat != null) {
      _openTable(seat.gameId);
      return;
    }

    final choice = await showRoomSitSheet(
      context,
      room: room,
      balanceChips: _walletChips,
    );
    if (!mounted || choice == null) return;

    switch (choice) {
      case AddChipsFirst():
        await _openDeposit();
      case SitDownFor(:final chips):
        await _seatMe(room, chips, t);
    }
  }

  Future<void> _seatMe(RoomSummary room, int chips, AppLocalizations t) async {
    try {
      final gameId = await _apiClient.sitInRoom(
        room.roomId,
        // An absent amount already means the room's default server-side, so only a buy-in the
        // player actually changed is worth sending.
        buyInAmount: chips == room.defaultBuyIn ? null : chips,
      );
      if (!mounted) return;
      _openTable(gameId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.couldNotSitDown(e is ApiException ? e.message : '$e'),
          ),
          backgroundColor: KarataColors.red,
        ),
      );
      // A room that is closed, full or gone says so by disappearing or changing shape in the
      // list, so the refusal and the list never disagree for long.
      _loadRooms();
    }
  }

  Map<String, dynamic> get _sessionArgs => {
    'serverUrl': widget.serverUrl,
    'token': widget.token,
    'username': widget.username,
  };

  Future<void> _openSettings() async {
    await Navigator.of(context).pushNamed('/settings', arguments: _sessionArgs);
  }

  void _openTable(String gameId) {
    Navigator.of(
      context,
    ).pushNamed('/table/$gameId', arguments: _sessionArgs).then((_) {
      _reloadLists();
      _loadWallet();
    });
  }

  Future<void> _createTable() async {
    await Navigator.of(
      context,
    ).pushNamed('/new-table', arguments: _sessionArgs);
    _loadTables();
    _loadWallet();
  }

  Future<void> _joinTable() async {
    await Navigator.of(
      context,
    ).pushNamed('/join-table', arguments: _sessionArgs);
    _loadTables();
    _loadWallet();
  }

  Future<void> _openWallet() async {
    await Navigator.of(context).pushNamed('/economy', arguments: _sessionArgs);
    _loadWallet();
  }

  Future<void> _openDeposit() async {
    await Navigator.of(
      context,
    ).pushNamed('/economy/buy', arguments: _sessionArgs);
    _loadWallet();
  }

  Future<void> _openWithdraw() async {
    await Navigator.of(
      context,
    ).pushNamed('/economy/redeem', arguments: _sessionArgs);
    _loadWallet();
  }

  /// "Good evening, eli" - the wide lobby's heading, which the phone's profile header replaces.
  String _greeting(AppLocalizations t) {
    final hour = DateTime.now().hour;
    if (hour < 12) return t.greetingMorning(widget.username);
    if (hour < 18) return t.greetingAfternoon(widget.username);
    return t.greetingEvening(widget.username);
  }

  /// Artboard 22.
  Widget _wide(AppLocalizations t, ChipDisplaySettings chipSettings) {
    final tables = _tab == _LobbyTab.publicTables ? _public : _mine;

    return DesktopShell(
      current: DesktopNav.lobby,
      sessionArgs: _sessionArgs,
      username: widget.username,
      title: _greeting(t),
      subtitle: t.lobbySubtitle,
      actions: [
        KarataButton(
          label: t.createTable,
          icon: KarataIcons.plus,
          onPressed: _createTable,
          height: 46,
          expand: false,
          horizontalPadding: 20,
          style: KarataButtonStyle.surface,
        ),
        KarataButton(
          label: t.joinWithLink,
          icon: KarataIcons.link,
          onPressed: _joinTable,
          height: 46,
          expand: false,
          horizontalPadding: 20,
          style: KarataButtonStyle.secondary,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WideBalanceStrip(
            balanceLabel: t.balance,
            balance: _walletChips == null
                ? '—'
                : ChipDisplay.amountOnly(chipSettings, _walletChips),
            unit: chipSettings.unitLabel,
            atTablesLabel: t.atTables,
            atTables: _atTablesChips == null
                ? '—'
                : ChipDisplay.amountOnly(chipSettings, _atTablesChips),
            depositLabel: t.deposit,
            withdrawLabel: t.withdraw,
            onDeposit: _openDeposit,
            onWithdraw: _openWithdraw,
            onTap: _openWallet,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              SegmentedTabs(
                labels: [t.roomsTab, t.publicTables, t.yourTables],
                selectedIndex: _tab.index,
                onChanged: (i) =>
                    setState(() => _chosenTab = _LobbyTab.values[i]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _tabHint(t),
                  style: karataText(
                    size: 13,
                    weight: 500,
                    color: KarataColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (_tab == _LobbyTab.rooms)
            _wideRooms(t, chipSettings)
          else if (_loadingTables && _mine.isEmpty && _public.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: KarataColors.gold),
              ),
            )
          else if (_tablesError != null)
            _note(t.couldNotLoadTables(_tablesError!))
          else if (tables.isEmpty)
            _note(
              _tab == _LobbyTab.publicTables ? t.noPublicTables : t.noTablesYet,
            )
          else
            _tableGrid(tables, t, chipSettings),
        ],
      ),
    );
  }

  /// The tables laid out two to a row, on the design's 24px gutter.
  Widget _tableGrid(
    List<TableSummary> tables,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    const columns = 2;
    final rows = <Widget>[];
    for (var i = 0; i < tables.length; i += columns) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var column = 0; column < columns; column++) ...[
              if (column > 0) const SizedBox(width: 24),
              Expanded(
                child: i + column < tables.length
                    ? _wideCard(tables[i + column], t, chips)
                    // The last row of an odd-length list keeps its gutter rather than letting
                    // the single card stretch across both columns.
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          rows[i],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (KarataLayout.isWide(context)) {
      return ValueListenableBuilder<ChipDisplaySettings>(
        valueListenable: ChipDisplay.instance,
        builder: (context, chipSettings, _) => _wide(t, chipSettings),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KarataBackdrop(
        child: SafeArea(
          child: ValueListenableBuilder<ChipDisplaySettings>(
            valueListenable: ChipDisplay.instance,
            builder: (context, chipSettings, _) => RefreshIndicator(
              onRefresh: _reloadLists,
              color: KarataColors.gold,
              backgroundColor: KarataColors.surface,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CircleIconButton(
                        icon: KarataIcons.brightness,
                        iconSize: 22,
                        background: const Color(0x00000000),
                        onPressed: _openSettings,
                        semanticLabel: t.settings,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ProfileHeader(
                      username: widget.username,
                      caption: t.signInHint,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: BalanceCard(
                      radius: 16,
                      balanceLabel: t.balance,
                      balance: _walletChips == null
                          ? '—'
                          : ChipDisplay.amountOnly(chipSettings, _walletChips),
                      unit: chipSettings.unitLabel,
                      atTablesLabel: t.atTables,
                      atTables: _atTablesChips == null
                          ? '—'
                          : ChipDisplay.amountOnly(
                              chipSettings,
                              _atTablesChips,
                            ),
                      depositLabel: t.deposit,
                      withdrawLabel: t.withdraw,
                      onDeposit: _openDeposit,
                      onWithdraw: _openWithdraw,
                      onTap: _openWallet,
                    ),
                  ),
                  const SizedBox(height: 31),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: KarataButton(
                            label: t.createTable,
                            icon: KarataIcons.plus,
                            onPressed: _createTable,
                            height: 50,
                            raised: false,
                            style: KarataButtonStyle.surface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: KarataButton(
                            label: t.joinWithLink,
                            icon: KarataIcons.link,
                            onPressed: _joinTable,
                            height: 50,
                            style: KarataButtonStyle.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    // Three tabs no longer fit a 390px phone, so the row scrolls sideways
                    // rather than shrinking the labels, exactly as the mockup's `overflow-x`
                    // does.
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedTabs(
                        labels: [t.roomsTab, t.publicTables, t.yourTables],
                        selectedIndex: _tab.index,
                        onChanged: (i) =>
                            setState(() => _chosenTab = _LobbyTab.values[i]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _tabHint(t),
                      style: karataText(
                        size: 13,
                        weight: 500,
                        color: KarataColors.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_tab == _LobbyTab.rooms)
                    ..._roomList(t, chipSettings)
                  else
                    ..._tableList(t, chipSettings),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _tableList(AppLocalizations t, ChipDisplaySettings chips) {
    final tables = _tab == _LobbyTab.publicTables ? _public : _mine;

    if (_loadingTables && _mine.isEmpty && _public.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: CircularProgressIndicator(color: KarataColors.gold),
          ),
        ),
      ];
    }

    final rows = <Widget>[];
    if (_tablesError != null) {
      rows.add(_note(t.couldNotLoadTables(_tablesError!)));
    } else if (tables.isEmpty) {
      rows.add(
        _note(
          _tab == _LobbyTab.publicTables ? t.noPublicTables : t.noTablesYet,
        ),
      );
    }

    for (var i = 0; i < tables.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: 16));
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _card(tables[i], t, chips),
        ),
      );
    }
    return rows;
  }

  Widget _card(
    TableSummary table,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    return LobbyTableCard(
      name: table.name,
      statusLabel: t.seatsOpen,
      buyInLabel: table.defaultBuyIn == null
          ? '—'
          : t.buyInOf(ChipDisplay.formatWith(chips, table.defaultBuyIn)),
      playerNames: table.playerNames,
      playerCountLabel: _seatedLabel(table, t),
      actionLabel: _tab == _LobbyTab.publicTables ? t.sitDown : t.open,
      onPressed: () => _openTable(table.gameId),
      decoration: TableMascot.forTable(table.name),
      palette: table.isPublic ? MascotPalette.gold : MascotPalette.silver,
    );
  }

  /// The same table, drawn as the wide grid's landscape tile.
  Widget _wideCard(
    TableSummary table,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    return WideLobbyTableCard(
      name: table.name,
      statusLabel: t.seatsOpen,
      buyInLabel: table.defaultBuyIn == null
          ? '—'
          : t.buyInOf(ChipDisplay.formatWith(chips, table.defaultBuyIn)),
      playerNames: table.playerNames,
      playerCountLabel: _seatedLabel(table, t),
      actionLabel: _tab == _LobbyTab.publicTables ? t.sitDown : t.open,
      onPressed: () => _openTable(table.gameId),
      decoration: TableMascot.forTable(table.name),
      palette: table.isPublic ? MascotPalette.gold : MascotPalette.silver,
    );
  }

  String _tabHint(AppLocalizations t) => switch (_tab) {
    _LobbyTab.rooms => t.roomsHint,
    _LobbyTab.publicTables => t.anyoneCanSitDown,
    _LobbyTab.myTables => t.syncedToYourAccount,
  };

  /// Everything about a room that depends on which of its four states it is in, decided once so
  /// the phone card and the wide row cannot drift apart.
  _RoomView _roomView(
    RoomSummary room,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    final seat = _seatedTableIn(room.roomId);
    if (seat != null) {
      return (
        state: RoomCardState.seated,
        statusLabel: t.roomTagSeated,
        statusTone: KarataTagTone.seated,
        footerPrefix: t.roomYoureInFor,
        footerAmount: ChipDisplay.formatWith(
          chips,
          seat.stackOf(widget.username),
        ),
        actionLabel: t.roomReturnToTable,
        onPressed: () => _openTable(seat.gameId),
      );
    }
    if (room.isFull) {
      return (
        state: RoomCardState.full,
        statusLabel: t.roomTagFull,
        statusTone: KarataTagTone.full,
        footerPrefix: t.roomDefaultBuyIn,
        footerAmount: ChipDisplay.formatWith(chips, room.defaultBuyIn),
        actionLabel: t.roomFull,
        onPressed: null,
      );
    }
    return (
      state: room.quiet ? RoomCardState.quiet : RoomCardState.open,
      statusLabel: room.cashoutEnabled ? t.roomTagCashout : t.roomTagPlayChips,
      statusTone: room.cashoutEnabled
          ? KarataTagTone.cashout
          : KarataTagTone.neutral,
      footerPrefix: t.roomDefaultBuyIn,
      footerAmount: ChipDisplay.formatWith(chips, room.defaultBuyIn),
      actionLabel: t.sitDown,
      onPressed: () => _sitInRoom(room),
    );
  }

  String _blindsLabel(
    RoomSummary room,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) =>
      // Only the big blind carries the unit, so the pair reads "50 / 100 Ar" rather than
      // printing "Ar" twice in six characters.
      t.roomBlinds(
        ChipDisplay.amountOnly(chips, room.smallBlind),
        ChipDisplay.formatWith(chips, room.bigBlind),
      );

  List<Widget> _roomList(AppLocalizations t, ChipDisplaySettings chips) {
    if (_loadingRooms && _rooms.isEmpty) {
      return [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: RoomCardSkeleton(),
          ),
        ],
      ];
    }
    if (_roomsError != null) return [_roomsErrorState(t)];
    if (_rooms.isEmpty) return [_note(t.noRoomsOpen)];

    return [
      for (var i = 0; i < _rooms.length; i++) ...[
        if (i > 0) const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _roomCard(_rooms[i], t, chips),
        ),
      ],
    ];
  }

  Widget _wideRooms(AppLocalizations t, ChipDisplaySettings chips) {
    if (_loadingRooms && _rooms.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoomCardSkeleton(),
          SizedBox(height: 14),
          RoomCardSkeleton(),
          SizedBox(height: 14),
          RoomCardSkeleton(),
        ],
      );
    }
    if (_roomsError != null) return _roomsErrorState(t);
    if (_rooms.isEmpty) return _note(t.noRoomsOpen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _rooms.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _wideRoomCard(_rooms[i], t, chips),
        ],
      ],
    );
  }

  Widget _roomsErrorState(AppLocalizations t) => RoomsErrorState(
    title: t.roomsCouldNotLoad,
    message: t.roomsCheckConnection,
    retryLabel: t.retry,
    onRetry: _loadRooms,
  );

  Widget _roomCard(
    RoomSummary room,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    final view = _roomView(room, t, chips);
    return RoomCard(
      name: room.name,
      blindsLabel: _blindsLabel(room, t, chips),
      variantLabel: t.roomVariant(room.variant),
      statusLabel: view.statusLabel,
      statusTone: view.statusTone,
      state: view.state,
      tableCount: room.tableCount,
      tablesLabel: t.roomTables(room.tableCount),
      playerCount: room.playerCount,
      playersLabel: t.roomPlayers(room.playerCount),
      quietTitle: t.roomBeFirstToSit,
      quietCaption: t.roomNoTablesRunning,
      footerPrefix: view.footerPrefix,
      footerAmount: view.footerAmount,
      actionLabel: view.actionLabel,
      onPressed: view.onPressed,
    );
  }

  Widget _wideRoomCard(
    RoomSummary room,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    final view = _roomView(room, t, chips);
    return WideRoomCard(
      name: room.name,
      blindsLabel: _blindsLabel(room, t, chips),
      variantLabel: t.roomVariant(room.variant),
      statusLabel: view.statusLabel,
      statusTone: view.statusTone,
      state: view.state,
      tableCount: room.tableCount,
      tablesLabel: t.roomTables(room.tableCount),
      playerCount: room.playerCount,
      playersLabel: t.roomPlayers(room.playerCount),
      quietTitle: t.roomBeFirstToSit,
      quietCaption: t.roomNoTablesRunning,
      footerPrefix: view.footerPrefix,
      footerAmount: view.footerAmount,
      actionLabel: view.actionLabel,
      onPressed: view.onPressed,
    );
  }

  String _seatedLabel(TableSummary table, AppLocalizations t) {
    if (table.seated == 0) return t.seatedCountNone;
    if (table.seated == 1) return t.seatedCountOne;
    return t.seatedCount('${table.seated}');
  }

  Widget _note(String message) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: karataText(
        size: 14,
        weight: 500,
        color: KarataColors.inkMuted,
        height: 1.45,
      ),
    ),
  );
}
