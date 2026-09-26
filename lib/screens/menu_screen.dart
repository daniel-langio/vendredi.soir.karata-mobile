import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../models/table_summary.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/circle_icon_button.dart';
import '../widgets/common/karata_backdrop.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_icons.dart';
import '../widgets/common/segmented_tabs.dart';
import '../widgets/lobby/lobby_table_card.dart';
import '../widgets/lobby/profile_header.dart';
import '../widgets/lobby/mascot_palette.dart';
import '../widgets/lobby/table_mascot.dart';
import '../widgets/wallet/balance_card.dart';

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

  /// Which of the two table lists the tab selector is showing. Public tables lead: they're the
  /// ones a player with no table of their own can actually sit down at.
  bool _showPublic = true;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _loadTables();
    _loadWallet();
    ChipDisplay.instance.refreshRateFromServer(_apiClient);
  }

  Future<void> _loadWallet() async {
    try {
      final chips = await _apiClient.getWallet();
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
      _loadTables();
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KarataBackdrop(
        child: SafeArea(
          child: ValueListenableBuilder<ChipDisplaySettings>(
            valueListenable: ChipDisplay.instance,
            builder: (context, chipSettings, _) => RefreshIndicator(
              onRefresh: _loadTables,
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
                    child: SegmentedTabs(
                      labels: [t.publicTables, t.yourTables],
                      selectedIndex: _showPublic ? 0 : 1,
                      onChanged: (i) => setState(() => _showPublic = i == 0),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _showPublic ? t.anyoneCanSitDown : t.syncedToYourAccount,
                      style: karataText(
                        size: 13,
                        weight: 500,
                        color: KarataColors.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
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
    final tables = _showPublic ? _public : _mine;

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
      rows.add(_note(_showPublic ? t.noPublicTables : t.noTablesYet));
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
    final String seated;
    if (table.seated == 0) {
      seated = t.seatedCountNone;
    } else if (table.seated == 1) {
      seated = t.seatedCountOne;
    } else {
      seated = t.seatedCount('${table.seated}');
    }

    return LobbyTableCard(
      name: table.name,
      statusLabel: t.seatsOpen,
      buyInLabel: table.defaultBuyIn == null
          ? '—'
          : t.buyInOf(ChipDisplay.formatWith(chips, table.defaultBuyIn)),
      playerNames: table.playerNames,
      playerCountLabel: seated,
      actionLabel: _showPublic ? t.sitDown : t.open,
      onPressed: () => _openTable(table.gameId),
      decoration: TableMascot.forTable(table.name),
      palette: table.isPublic ? MascotPalette.gold : MascotPalette.silver,
    );
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
