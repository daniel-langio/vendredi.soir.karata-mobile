import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// One row in either home-screen list. Both `/games/mine` and `/games/public` return the full game
/// representation, which already carries the seated players - so the player count shown here costs
/// no extra field on the API and no second request.
class TableSummary {
  final String gameId;
  final String name;
  final int? defaultBuyIn;
  final int seated;

  const TableSummary({
    required this.gameId,
    required this.name,
    required this.defaultBuyIn,
    required this.seated,
  });

  factory TableSummary.fromJson(Map<String, dynamic> j) => TableSummary(
    gameId: j['gameId'] as String,
    name: j['name'] as String? ?? 'Table',
    defaultBuyIn: (j['defaultBuyIn'] as num?)?.toInt(),
    seated: (j['players'] as List<dynamic>? ?? const []).length,
  );
}

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

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _loadTables();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final chips = await _apiClient.getWallet();
      if (!mounted) return;
      setState(() => _walletChips = chips);
    } catch (_) {
      // Non-critical - the balance badge just stays hidden if we can't reach the server.
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

  Future<void> _openSettings() async {
    await Navigator.of(context).pushNamed('/settings', arguments: _sessionArgs);
  }

  Map<String, dynamic> get _sessionArgs => {
    'serverUrl': widget.serverUrl,
    'token': widget.token,
    'username': widget.username,
  };

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

  Future<void> _openMarketplace() async {
    await Navigator.of(
      context,
    ).pushNamed('/marketplace', arguments: _sessionArgs);
    _loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: t.settings,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: KarataColors.pill,
                    child: Icon(Icons.person, color: KarataColors.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: KarataColors.ink,
                          ),
                        ),
                        Text(
                          t.signInHint,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: KarataColors.dim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_walletChips != null)
                    Tooltip(
                      message: t.walletBalance,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _openMarketplace,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: KarataColors.chipBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.monetization_on_rounded,
                                color: KarataColors.chipInk,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              ValueListenableBuilder<ChipDisplaySettings>(
                                valueListenable: ChipDisplay.instance,
                                builder: (context, chipSettings, _) => Text(
                                  ChipDisplay.formatWith(
                                    chipSettings,
                                    _walletChips,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: KarataColors.chipInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _createTable,
                icon: const Text(
                  '♠',
                  style: TextStyle(color: KarataColors.dim),
                ),
                label: Text(t.createTable),
              ),
              const SizedBox(height: 11),
              OutlinedButton.icon(
                onPressed: _joinTable,
                icon: const Icon(Icons.subdirectory_arrow_right, size: 18),
                label: Text(t.joinWithLink),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _loadingTables && _mine.isEmpty && _public.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadTables,
                        child: ValueListenableBuilder<ChipDisplaySettings>(
                          valueListenable: ChipDisplay.instance,
                          builder: (context, chipSettings, _) => ListView(
                            children: [
                              if (_tablesError != null)
                                _note(t.couldNotLoadTables(_tablesError!)),
                              _sectionHeader(
                                t.yourTables,
                                t.syncedToYourAccount,
                              ),
                              if (_mine.isEmpty && _tablesError == null)
                                _note(t.noTablesYet),
                              ..._mine.map(
                                (table) => _tableTile(table, chipSettings),
                              ),
                              const SizedBox(height: 28),
                              _sectionHeader(
                                t.publicTables,
                                t.anyoneCanSitDown,
                              ),
                              if (_public.isEmpty && _tablesError == null)
                                _note(t.noPublicTables),
                              _publicTableCards(chipSettings),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String hint) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: KarataColors.ink,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hint,
            style: const TextStyle(fontSize: 12.5, color: KarataColors.dim),
          ),
        ),
      ],
    ),
  );

  Widget _note(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: KarataColors.dim),
    ),
  );

  Widget _tableTile(TableSummary table, ChipDisplaySettings chipSettings) {
    final t = AppLocalizations.of(context);
    final String seated;
    if (table.seated == 0) {
      seated = t.seatedCountNone;
    } else if (table.seated == 1) {
      seated = t.seatedCountOne;
    } else {
      seated = t.seatedCount('${table.seated}');
    }
    final details = [
      if (table.defaultBuyIn != null)
        t.buyInOf(ChipDisplay.formatWith(chipSettings, table.defaultBuyIn)),
      seated,
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.circle, size: 7, color: KarataColors.live),
      title: Text(
        table.name,
        style: const TextStyle(color: KarataColors.ink, fontSize: 16.5),
      ),
      subtitle: Text(
        details,
        style: const TextStyle(color: KarataColors.dim, fontSize: 12.5),
      ),
      trailing: TextButton(
        onPressed: () => _openTable(table.gameId),
        child: Text(t.open),
      ),
      onTap: () => _openTable(table.gameId),
    );
  }

  static const _publicTableSuits = ['♠', '♥', '♦', '♣'];

  Widget _publicTableCards(ChipDisplaySettings chipSettings) {
    final cards = <Widget>[];
    for (var i = 0; i < _public.length; i++) {
      if (i > 0) cards.add(const SizedBox(height: 14));
      cards.add(_publicTableCard(_public[i], i, chipSettings));
    }
    return Column(children: cards);
  }

  Widget _publicTableCard(
    TableSummary table,
    int index,
    ChipDisplaySettings chipSettings,
  ) {
    final t = AppLocalizations.of(context);
    final String seated;
    if (table.seated == 0) {
      seated = t.seatedCountNone;
    } else if (table.seated == 1) {
      seated = t.seatedCountOne;
    } else {
      seated = t.seatedCount('${table.seated}');
    }
    final subtitle = [
      if (table.defaultBuyIn != null)
        t.buyInOf(ChipDisplay.formatWith(chipSettings, table.defaultBuyIn)),
      seated,
    ].join(' · ');
    final buyInLabel = table.defaultBuyIn != null
        ? ChipDisplay.formatWith(chipSettings, table.defaultBuyIn)
        : '—';

    return PublicTableCard(
      name: table.name,
      subtitle: subtitle,
      buyInLabel: buyInLabel,
      suit: _publicTableSuits[index % _publicTableSuits.length],
      accent:
          KarataColors
              .publicTableAccents[index % KarataColors.publicTableAccents.length],
      onTap: () => _openTable(table.gameId),
    );
  }
}

/// A public table shown as a large colored card: suit glyph and an "open" affordance up top,
/// name/occupancy and buy-in on the bottom row. Colors cycle across [KarataColors.publicTableAccents]
/// so adjacent cards read as distinct at a glance.
class PublicTableCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String buyInLabel;
  final String suit;
  final Color accent;
  final VoidCallback onTap;

  const PublicTableCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.buyInLabel,
    required this.suit,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      suit,
                      style: const TextStyle(
                        color: KarataColors.cardInk,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.north_east,
                      color: KarataColors.cardInk,
                      size: 15,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: KarataColors.cardInk,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: KarataColors.cardInk.withValues(
                              alpha: 0.62,
                            ),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    buyInLabel,
                    style: TextStyle(
                      color: KarataColors.cardInk,
                      fontSize: buyInLabel.length > 3 ? 26 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
