import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_client.dart';
import '../chip_display.dart';
import '../game_sounds.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../wide_layout.dart';
import '../widgets/table/act_button.dart';
import '../widgets/table/board_row.dart';
import '../widgets/table/chat_dock_panel.dart';
import '../widgets/table/dealer_chip.dart';
import '../widgets/table/last_action_badge.dart';
import '../widgets/table/outcome_banner.dart';
import '../widgets/table/poker_card.dart';
import '../widgets/table/pop_in.dart';
import '../widgets/table/pot_chips.dart';
import '../widgets/table/seat.dart';
import '../widgets/table/table_felt.dart';
import '../widgets/table/table_seats.dart';

class TableScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;
  final String gameId;

  const TableScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
    required this.gameId,
  });

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  // Below this body width, render the original single-column phone layout; at or above it, add
  // the docked chat panel alongside a wider table (see WideLayout for how web reaches this width).
  static const _wideBreakpoint = 700.0;

  late final ApiClient _apiClient;
  Timer? _pollTimer;
  Timer? _tickTimer;

  Map<String, dynamic>? _game;
  List<dynamic> _myCards = [];
  bool _isLoading = false;
  bool _isStale = false;
  DateTime? _lastUpdated;

  String? _selectedActionType; // 'BET' or 'RAISE' while the sizer is open
  int _sizerAmount = 0;

  // Five-Card Draw: indices into _myCards the player has tapped to mark for discard.
  final Set<int> _selectedDiscardIndices = {};

  // Purely cosmetic bookkeeping for the turn countdown's progress bar - the deadline itself
  // (_turnDeadline) is always the server's authoritative value; this just remembers when we
  // first observed the current turn so the bar has a start point to animate from.
  String? _turnWindowKey;
  DateTime? _turnWindowStart;

  final GameSounds _sounds = GameSounds();

  // Previous-frame values, used to turn a polled snapshot into "something just happened" events
  // worth a sound - the API reports state, not transitions.
  int _previousPot = 0;
  String? _previousPhase;
  Map<String, dynamic>? _previousOutcome;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _refresh(showSpinner: true);
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    _sounds.prepare();
    // Every chip amount on this screen is formatted through ChipDisplay, so a change made in
    // settings has to repaint the table.
    ChipDisplay.instance.addListener(_onChipDisplayChanged);
    // Only this screen wants more than the app's default phone-width cap on web - see
    // WideLayout's doc comment.
    WideLayout.instance.value = true;
  }

  void _onChipDisplayChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    ChipDisplay.instance.removeListener(_onChipDisplayChanged);
    WideLayout.instance.value = false;
    unawaited(_sounds.dispose());
    super.dispose();
  }

  Map<String, dynamic>? get _currentDeal =>
      _game?['currentDeal'] as Map<String, dynamic>?;
  String get _dealId => _game?['currentDealId']?.toString() ?? '';
  String get _phase => _currentDeal?['phase']?.toString() ?? '';
  String? get _activePlayerId => _currentDeal?['activePlayerId']?.toString();
  Map<String, dynamic>? get _you => _game?['you'] as Map<String, dynamic>?;
  List<dynamic> get _players => _game?['players'] as List<dynamic>? ?? [];
  bool get _isClosed => _game?['closed'] == true;
  bool get _isPaused => _game?['paused'] == true;

  /// Pausing, resuming and closing are the host's alone (see GameService.requireInitiator /
  /// requireCanClose) - hiding them from everyone else keeps the menu honest rather than offering
  /// actions the server will refuse.
  bool get _isHost => _game?['initiatorUsername'] == widget.username;

  /// Mirrors GameService.requireCanClose: the host, or the last player still seated at a table
  /// whose host has walked away. Public tables are nobody's to close.
  bool get _canClose =>
      _game?['isPublic'] != true &&
      (_isHost || (_isPlaying && _players.length == 1));
  bool get _isMyTurn {
    final me = _players.firstWhere(
      (p) => p['username'] == widget.username,
      orElse: () => null,
    );
    return me != null &&
        _activePlayerId != null &&
        _activePlayerId == me['playerId']?.toString();
  }

  /// Whether the current user is a seated player of this game (has bought in at some point and
  /// hasn't since fully dropped out) rather than just watching - e.g. someone who opened an
  /// invite link without ever sitting down, or who left mid-hand and that hand has since ended.
  bool get _isPlaying => _players.any((p) => p['username'] == widget.username);

  /// The server's authoritative deadline for whoever's on the clock to act - see
  /// DealService.enforceTurnTimeout on the backend, which auto-folds past this point.
  DateTime? get _turnDeadline {
    final raw = _currentDeal?['turnDeadline'] as String?;
    return raw != null ? DateTime.parse(raw) : null;
  }

  Future<void> _refresh({bool showSpinner = false}) async {
    if (showSpinner && mounted) setState(() => _isLoading = true);
    try {
      final game = await _apiClient.getGame(widget.gameId);
      final dealId = game['currentDealId']?.toString();

      List<dynamic> cards = _myCards;
      if (dealId != null) {
        try {
          final handData = await _apiClient.getMyHand(dealId);
          cards = handData['cards'] as List<dynamic>? ?? [];
        } catch (_) {
          // Hand not accessible yet (e.g. between hands) - keep the last known cards.
        }
      } else {
        cards = [];
      }

      if (!mounted) return;
      setState(() {
        _game = game;
        _myCards = cards;
        _isStale = false;
        _lastUpdated = DateTime.now();
      });

      final previousPot = _previousPot;
      final previousPhase = _previousPhase;
      final previousOutcome = _previousOutcome;

      final deal = game['currentDeal'] as Map<String, dynamic>?;
      final currentPot = (deal?['pot'] as num?)?.toInt() ?? 0;
      final currentPhase = deal?['phase']?.toString();
      final currentOutcome = deal?['outcome'] as Map<String, dynamic>?;
      _previousPot = currentPot;
      _previousPhase = currentPhase;
      _previousOutcome = currentOutcome;

      if (currentPhase != null &&
          currentPhase != previousPhase &&
          _isDealingPhase(currentPhase)) {
        _sounds.deal();
      }
      if (currentPot > previousPot) {
        _sounds.chips();
      }
      if (currentOutcome != null && previousOutcome == null) {
        _isUserWinner(currentOutcome, widget.username)
            ? _sounds.chips()
            : _sounds.click();
      }
    } catch (_) {
      if (mounted) setState(() => _isStale = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isDealingPhase(String phase) {
    return phase == 'FLOP' || phase == 'TURN' || phase == 'RIVER';
  }

  bool _isUserWinner(Map<String, dynamic> outcome, String username) {
    final winners = outcome['winners'] as List<dynamic>? ?? [];
    return winners.any((w) => w['username'] == username);
  }

  Future<void> _startHand() async {
    setState(() {
      _isLoading = true;
      _selectedDiscardIndices.clear();
    });
    try {
      final game = await _apiClient.startDeal(widget.gameId);
      if (mounted) setState(() => _game = game);
      await _refresh();
    } catch (e) {
      _showError((t) => t.couldNotStartHand('$e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Reuses the buyIn call the join-by-link flow already relies on. Joining mid-hand doesn't seat
  /// the player into the hand already in progress - the backend only deals in whoever was already
  /// seated when the hand started - so this is safe to offer at any point, not just at showdown.
  Future<void> _sitDown() async {
    final t = AppLocalizations.of(context);
    final buyInController = TextEditingController(
      text: '${_game?['defaultBuyIn'] ?? 200}',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.sitDown),
        content: TextField(
          controller: buyInController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: t.chips),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.sitDown),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final buyIn = int.tryParse(buyInController.text.trim());
    if (buyIn == null || buyIn <= 0) {
      _showError((t) => t.enterValidBuyIn);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiClient.buyIn(widget.gameId, buyIn);
      await _refresh();
    } catch (e) {
      _showError((t) => t.couldNotSitDown('$e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAction(String actionType, {int? amount}) async {
    if (_dealId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _apiClient.takeAction(
        dealId: _dealId,
        actionType: actionType,
        amount: amount,
      );
      setState(() => _selectedActionType = null);
      await _refresh();
    } catch (e) {
      _showError((t) => t.actionFailed(actionType, '$e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleDiscard(int index) {
    setState(() {
      if (_selectedDiscardIndices.contains(index)) {
        _selectedDiscardIndices.remove(index);
      } else {
        _selectedDiscardIndices.add(index);
      }
    });
  }

  Future<void> _submitDraw() async {
    if (_dealId.isEmpty) return;
    final discard = _selectedDiscardIndices
        .map((i) => _myCards[i].toString())
        .toList();
    setState(() => _isLoading = true);
    try {
      await _apiClient.takeAction(
        dealId: _dealId,
        actionType: 'DRAW',
        discard: discard,
      );
      setState(() => _selectedDiscardIndices.clear());
      await _refresh();
    } catch (e) {
      _showError((t) => t.actionFailed('DRAW', '$e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String Function(AppLocalizations) message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message(AppLocalizations.of(context))),
        backgroundColor: KarataColors.red,
      ),
    );
  }

  Future<void> _copyInvite() async {
    // On web this is a real clickable link (the app has proper per-page paths - see
    // main.dart's routing); a native build has no meaningful "origin" to build one from,
    // so it falls back to the bare table ID, which the join-table screen also accepts.
    final invite = kIsWeb
        ? '${Uri.base.origin}/table/${widget.gameId}'
        : widget.gameId;
    await Clipboard.setData(ClipboardData(text: invite));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).inviteCopied)),
    );
  }

  Future<void> _closeTable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final t = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(t.closeTableTitle),
          content: Text(t.closeTableContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                t.closeTable,
                style: const TextStyle(color: KarataColors.red),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiClient.closeTable(widget.gameId);
      await _refresh();
    } catch (e) {
      _showError((t) => t.couldNotCloseTable('$e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveTable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final t = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(t.leaveTableTitle),
          content: Text(t.leaveTableContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                t.leaveTable,
                style: const TextStyle(color: KarataColors.red),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiClient.leaveTable(widget.gameId);
      if (!mounted) return;
      // Clears the whole stack rather than just replacing this screen - normally reached via
      // Menu pushing this table on top of itself, so a plain replace would leave that earlier
      // Menu instance underneath and show as a stray back button.
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/menu',
        (route) => false,
        arguments: {
          'serverUrl': widget.serverUrl,
          'token': widget.token,
          'username': widget.username,
        },
      );
    } catch (e) {
      _showError((t) => t.couldNotLeaveTable('$e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setPaused(bool paused) async {
    setState(() => _isLoading = true);
    try {
      if (paused) {
        await _apiClient.pauseTable(widget.gameId);
      } else {
        await _apiClient.resumeTable(widget.gameId);
      }
      await _refresh();
    } catch (e) {
      _showError((t) => t.couldNotPauseTable('$e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addBot() async {
    String? selected; // null = let the server choose
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final t = AppLocalizations.of(context);
          Widget option(String? value, String label) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            trailing: selected == value
                ? const Icon(Icons.check, color: KarataColors.live)
                : null,
            onTap: () => setDialogState(() => selected = value),
          );
          return AlertDialog(
            title: Text(t.addBotTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                option(null, t.botStrategyServerChoice),
                option('CAUTIOUS', t.botStrategyCautious),
                option('BALANCED', t.botStrategyBalanced),
                option('AGGRESSIVE', t.botStrategyAggressive),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(t.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(t.addBot),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiClient.addBot(widget.gameId, strategy: selected);
      await _refresh();
    } catch (e) {
      _showError((t) => t.couldNotAddBot('$e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _pausedBanner(AppLocalizations t) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: KarataColors.pill,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.pause_circle_outline,
          size: 18,
          color: KarataColors.ink,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.tablePaused,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KarataColors.ink,
                ),
              ),
              Text(
                t.tablePausedExplainer,
                style: const TextStyle(fontSize: 11.5, color: KarataColors.dim),
              ),
            ],
          ),
        ),
        if (_isHost)
          TextButton(
            onPressed: _isLoading ? null : () => _setPaused(false),
            child: Text(t.resumeTable),
          ),
      ],
    ),
  );

  void _showVariantInfo() {
    final variant = _game?['variant'] as String? ?? 'TEXAS_HOLDEM';
    showDialog<void>(
      context: context,
      builder: (context) {
        final t = AppLocalizations.of(context);
        final title = switch (variant) {
          'OMAHA' => t.variantTitleOmaha,
          'FIVE_CARD_DRAW' => t.variantTitleFiveCardDraw,
          _ => t.variantTitle,
        };
        final holeCardsText = switch (variant) {
          'OMAHA' => t.variantHoleCardsOmaha,
          'FIVE_CARD_DRAW' => t.variantHoleCardsFiveCardDraw,
          _ => t.variantHoleCards,
        };
        final boardText = variant == 'FIVE_CARD_DRAW'
            ? t.variantDrawPhase
            : t.variantBoard;
        final rankingText = switch (variant) {
          'OMAHA' => t.variantRankingOmaha,
          'FIVE_CARD_DRAW' => t.variantRankingFiveCardDraw,
          _ => t.variantRanking,
        };
        Widget bullet(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '•  $text',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        );
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                bullet(holeCardsText),
                bullet(boardText),
                bullet(t.variantBetting),
                bullet(rankingText),
                const SizedBox(height: 8),
                Text(
                  t.variantSimplificationsHeading,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                bullet(t.variantNoSidePots),
                bullet(t.variantNoButtonRotation),
                bullet(t.variantSimplifiedMinRaise),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.close),
            ),
          ],
        );
      },
    );
  }

  void _toggleSizer(String type) {
    if (_selectedActionType == type) {
      setState(() => _selectedActionType = null);
      return;
    }
    final you = _you;
    final minRaise = (you?['minRaise'] as num?)?.toInt() ?? 20;
    setState(() {
      _selectedActionType = type;
      _sizerAmount = minRaise;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final t = AppLocalizations.of(context);
    final gameName = _game?['name'] as String? ?? '';
    final pot = ChipDisplay.instance.format(_currentDeal?['pot'] as num?);
    final communityCards =
        _currentDeal?['communityCards'] as List<dynamic>? ??
        [null, null, null, null, null];
    final outcome = _currentDeal?['outcome'] as Map<String, dynamic>?;
    final revealedHands = <String, Map<String, dynamic>>{
      for (final rh in (outcome?['revealedHands'] as List<dynamic>? ?? []))
        (rh as Map<String, dynamic>)['playerId'].toString(): rh,
    };

    return Scaffold(
      backgroundColor: KarataColors.bg,
      appBar: AppBar(
        title: Text(
          _isClosed ? '$gameName (${t.closedSuffix})' : gameName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: KarataColors.dim,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            tooltip: t.gameVariant,
            onPressed: () {
              _sounds.click();
              _showVariantInfo();
            },
          ),
          IconButton(
            icon: const Icon(Icons.ios_share, size: 20),
            tooltip: t.copyInvite,
            onPressed: () {
              _sounds.click();
              _copyInvite();
            },
          ),
          if (!_isClosed)
            PopupMenuButton<void>(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () {
                    _sounds.click();
                    _leaveTable();
                  },
                  child: Text(t.leaveTable),
                ),
                if (_isHost)
                  PopupMenuItem(
                    onTap: () {
                      _sounds.click();
                      _setPaused(!_isPaused);
                    },
                    child: Text(_isPaused ? t.resumeTable : t.pauseTable),
                  ),
                if (_isHost)
                  PopupMenuItem(
                    onTap: () {
                      _sounds.click();
                      _addBot();
                    },
                    child: Text(t.addBot),
                  ),
                if (_canClose)
                  PopupMenuItem(
                    onTap: () {
                      _sounds.click();
                      _closeTable();
                    },
                    child: Text(
                      t.closeTable,
                      style: const TextStyle(color: KarataColors.red),
                    ),
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: _isStale ? KarataColors.stale : KarataColors.live,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _liveStatusLabel(),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: KarataColors.dim,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;
          final tableContent = Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The server refuses every deal and action while a table is paused. Without this
                // the refusal surfaces as a bare error snackbar, reading as a bug rather than as
                // the host having deliberately stopped play.
                if (_isPaused && !_isClosed) _pausedBanner(t),
                // The felt is a pure background decoration sized to this Expanded region. Seats,
                // board and the hero's own cards all share one Stack over it now, positioned by
                // Align rather than flowed top-to-bottom, so opponents can sit anywhere around the
                // felt instead of only along a single top row.
                Expanded(
                  child: Stack(
                    children: [
                      const Positioned.fill(child: TableFelt()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 10,
                        ),
                        child: Stack(
                          children: [
                            TableSeats(
                              opponents: _players
                                  .where(
                                    (p) => p['username'] != widget.username,
                                  )
                                  .cast<Map<String, dynamic>>()
                                  .toList(),
                              activePlayerId: _activePlayerId,
                              revealedHands: revealedHands,
                            ),
                            // A little below dead-center so it clears the top-row seats and isn't
                            // squeezed against them.
                            Align(
                              alignment: const Alignment(0, 0.2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  BoardRow(cards: communityCards),
                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const PotChips(),
                                          const SizedBox(width: 6),
                                          Text(
                                            t.pot,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: KarataColors.dim,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Pops on every genuine pot change (raw amount, not the
                                      // formatted string, so a money-display toggle in settings
                                      // doesn't trigger a pop of its own).
                                      PopIn(
                                        popKey: _currentDeal?['pot'],
                                        child: Text(
                                          pot,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            color: KarataColors.ink,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (outcome != null) ...[
                                    const SizedBox(height: 14),
                                    OutcomeBanner(
                                      outcome: outcome,
                                      myUsername: widget.username,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: _buildHandRow(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(height: 18, child: _buildTurnLine()),
                const SizedBox(height: 10),
                if (_selectedActionType != null) ...[
                  _buildSizer(),
                  const SizedBox(height: 11),
                ],
                _buildActionArea(),
                const SizedBox(height: 14),
                _buildSelfStatus(),
              ],
            ),
          );

          return Stack(
            children: [
              if (isWide)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: tableContent),
                        const SizedBox(width: 16),
                        const SizedBox(width: 300, child: ChatDockPanel()),
                      ],
                    ),
                  ),
                )
              else
                tableContent,
              if (_isLoading)
                Container(
                  color: Colors.black45,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  String _liveStatusLabel() {
    final t = AppLocalizations.of(context);
    if (!_isStale) {
      return t.live;
    }
    final last = _lastUpdated;
    if (last == null) {
      return t.reconnecting;
    }
    final secs = DateTime.now().difference(last).inSeconds;
    return t.lastUpdateAgo(secs);
  }

  Widget _buildTurnLine() {
    if (_isClosed || _dealId.isEmpty || _phase == 'SHOWDOWN') {
      return const SizedBox();
    }
    final t = AppLocalizations.of(context);

    if (_isMyTurn && _turnDeadline != null) {
      final deadline = _turnDeadline!;
      final key = '$_dealId:$_phase:$_activePlayerId';
      if (_turnWindowKey != key) {
        _turnWindowKey = key;
        _turnWindowStart = DateTime.now();
      }
      final remaining = deadline.difference(DateTime.now()).inSeconds;
      final secs = remaining > 0 ? remaining : 0;
      final totalMs = deadline.difference(_turnWindowStart!).inMilliseconds;
      final elapsedMs = DateTime.now()
          .difference(_turnWindowStart!)
          .inMilliseconds;
      final fraction = totalMs > 0
          ? (elapsedMs / totalMs).clamp(0.0, 1.0)
          : 1.0;

      return Row(
        children: [
          _ClockBar(fraction: fraction),
          const SizedBox(width: 8),
          Text(
            t.yourTurnLeft(secs),
            style: const TextStyle(fontSize: 13, color: KarataColors.dim),
          ),
        ],
      );
    }

    final active = _players.firstWhere(
      (p) => p['playerId']?.toString() == _activePlayerId,
      orElse: () => null,
    );
    if (active == null) return const SizedBox();
    return Text(
      t.waitingOn(active['username']?.toString() ?? ''),
      style: const TextStyle(fontSize: 13, color: KarataColors.dim),
    );
  }

  Widget _buildActionArea() {
    final t = AppLocalizations.of(context);
    if (_isClosed) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: Center(
          child: Text(
            t.tableClosed,
            style: const TextStyle(
              color: KarataColors.dim,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
        ),
      );
    }

    if (!_isPlaying) {
      // A spectator - never bought in, or left earlier - always gets a way to sit down, whatever
      // the hand's phase. Joining mid-hand only takes effect for the *next* hand (see _sitDown),
      // so say so whenever one is actually in progress rather than leaving it unexplained.
      final handInProgress = _dealId.isNotEmpty && _phase != 'SHOWDOWN';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (handInProgress) ...[
            Text(
              t.willJoinNextHand,
              textAlign: TextAlign.center,
              style: const TextStyle(color: KarataColors.dim, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
          ],
          ElevatedButton(
            onPressed: _isLoading ? null : _sitDown,
            child: Text(t.sitDown),
          ),
        ],
      );
    }

    if (_dealId.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _sounds.click();
            _startHand();
          },
          child: Text(t.startTheHand),
        ),
      );
    }

    if (_phase == 'SHOWDOWN') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(onPressed: _startHand, child: Text(t.nextHand)),
      );
    }

    if (_phase == 'DRAW') {
      if (!_isMyTurn) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: Center(
            child: Text(
              t.waitingForDraw,
              style: const TextStyle(color: KarataColors.dim, fontSize: 13),
            ),
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitDraw,
          child: Text(
            _selectedDiscardIndices.isEmpty
                ? t.standPat
                : t.drawCards(_selectedDiscardIndices.length),
          ),
        ),
      );
    }

    final mine = _isMyTurn;
    final you = _you;
    final callAmount = (you?['callAmount'] as num?)?.toInt() ?? 0;
    final minRaise = (you?['minRaise'] as num?)?.toInt() ?? 20;
    final maxRaise = (you?['maxRaise'] as num?)?.toInt() ?? 0;
    final currentRoundBet =
        (_currentDeal?['currentRoundBet'] as num?)?.toInt() ?? 0;
    final raiseType = currentRoundBet == 0 ? 'BET' : 'RAISE';
    final sizerOpen = _selectedActionType == raiseType;
    final raiseAmount = sizerOpen ? _sizerAmount : minRaise;
    final callLabel = callAmount == 0
        ? t.check
        : t.call(ChipDisplay.instance.format(callAmount));
    final raiseLabel = currentRoundBet == 0
        ? t.bet(ChipDisplay.instance.format(raiseAmount))
        : t.raise(ChipDisplay.instance.format(raiseAmount));
    // Both mirror real backend rejections (TexasHoldemRules.isActionLegal) - a call needs enough
    // chips to cover it in full (no side-pot/all-in-for-less support yet), and a raise/bet must
    // meet the table's minimum, which a short stack sometimes can't - gray those out instead of
    // letting the request fail server-side.
    final canCall = callAmount == 0 || maxRaise >= callAmount;
    final canRaise = maxRaise > 0 && maxRaise >= minRaise;

    return Row(
      children: [
        Expanded(
          child: ActButton(
            label: t.fold,
            enabled: mine,
            onPressed: () {
              _sounds.click();
              _submitAction('FOLD');
            },
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: ActButton(
            label: callLabel,
            enabled: mine && canCall,
            solid: mine,
            onPressed: () {
              _sounds.click();
              callAmount == 0
                  ? _submitAction('CHECK')
                  : _submitAction('CALL', amount: callAmount);
            },
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: ActButton(
            label: raiseLabel,
            enabled: mine && canRaise,
            onPressed: () {
              _sounds.click();
              sizerOpen
                  ? _submitAction(raiseType, amount: _sizerAmount)
                  : _submitAction(raiseType, amount: minRaise);
            },
          ),
        ),
        const SizedBox(width: 9),
        BumpButton(
          on: sizerOpen,
          enabled: mine && canRaise,
          onPressed: () {
            _sounds.click();
            _toggleSizer(raiseType);
          },
        ),
      ],
    );
  }

  Widget _buildSizer() {
    final you = _you;
    final rawMinRaise = (you?['minRaise'] as num?)?.toInt() ?? 20;
    final rawMaxRaise = (you?['maxRaise'] as num?)?.toInt() ?? rawMinRaise;
    // A short stack can have fewer chips than the table's minimum raise (e.g. an all-in for
    // less); guard against that so bounds never invert (min > max would crash Slider/clamp).
    final minRaise = rawMinRaise <= rawMaxRaise ? rawMinRaise : rawMaxRaise;
    final maxRaise = rawMaxRaise;
    final pot = (_currentDeal?['pot'] as num?)?.toInt() ?? 0;

    int clampAmount(int v) => v.clamp(minRaise, maxRaise);
    final t = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: KarataColors.pillLine),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                ChipDisplay.instance.format(_sizerAmount),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: KarataColors.ink,
                ),
              ),
              Text(
                t.minAllIn(
                  ChipDisplay.instance.format(minRaise),
                  ChipDisplay.instance.format(maxRaise),
                ),
                style: const TextStyle(fontSize: 11.5, color: KarataColors.dim),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: KarataColors.ink,
              inactiveTrackColor: const Color(0xFF26242B),
              thumbColor: KarataColors.ink,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: clampAmount(_sizerAmount).toDouble(),
              min: minRaise.toDouble(),
              max: maxRaise > minRaise
                  ? maxRaise.toDouble()
                  : minRaise.toDouble() + 1,
              onChanged: (v) => setState(() => _sizerAmount = v.round()),
            ),
          ),
          Row(
            children: [
              _quickBtn(t.oneThirdPot, false, () {
                _sounds.click();
                setState(() => _sizerAmount = clampAmount(pot ~/ 3));
              }),
              _quickBtn(t.halfPot, false, () {
                _sounds.click();
                setState(() => _sizerAmount = clampAmount(pot ~/ 2));
              }),
              _quickBtn(t.threeQuartersPot, false, () {
                _sounds.click();
                setState(() => _sizerAmount = clampAmount(pot * 3 ~/ 4));
              }),
              _quickBtn(t.pot, false, () {
                _sounds.click();
                setState(() => _sizerAmount = clampAmount(pot));
              }),
              _quickBtn(t.allIn, _sizerAmount == maxRaise, () {
                _sounds.click();
                setState(() => _sizerAmount = maxRaise);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickBtn(String label, bool on, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(34),
            side: const BorderSide(color: KarataColors.pillLine),
            backgroundColor: on ? KarataColors.pill : null,
            foregroundColor: on ? KarataColors.ink : KarataColors.dim,
          ),
          child: Text(label, style: const TextStyle(fontSize: 12.5)),
        ),
      ),
    );
  }

  Widget _buildSelfStatus() {
    final t = AppLocalizations.of(context);
    final playing = _isPlaying;
    final me =
        _players.firstWhere(
              (p) => p['username'] == widget.username,
              orElse: () => null,
            )
            as Map<String, dynamic>?;
    final myChipsAmount = me?['chips'] as num?;
    final myChips = myChipsAmount == null
        ? null
        : ChipDisplay.instance.format(myChipsAmount);
    final myLastActionRaw = me?['lastAction']?.toString();
    final myLastAction = myLastActionRaw != null
        ? formatLastAction(t, myLastActionRaw)
        : null;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: playing ? KarataColors.chipBg : const Color(0xFF2E2C34),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            playing ? t.playing : t.spectating,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: playing ? KarataColors.chipInk : KarataColors.dim,
            ),
          ),
        ),
        if (myChips != null) ...[
          const SizedBox(width: 10),
          Text(
            myChips,
            style: const TextStyle(
              fontSize: 13,
              color: KarataColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const Spacer(),
        if (myLastAction != null)
          LastActionBadge(
            rawAction: myLastActionRaw!,
            displayText: myLastAction,
          ),
      ],
    );
  }

  Widget _buildHandRow() {
    final t = AppLocalizations.of(context);
    final canSelectDiscards = _phase == 'DRAW' && _isMyTurn;
    final isDealer = _you?['blind']?.toString() == 'SMALL';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canSelectDiscards) ...[
          Text(
            t.tapCardsToDiscard,
            style: const TextStyle(fontSize: 12, color: KarataColors.dim),
          ),
          const SizedBox(height: 6),
        ],
        if (isDealer || _isMyTurn)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                if (isDealer) ...[
                  const DealerChip(),
                  const SizedBox(width: 8),
                ],
                if (_isMyTurn) TurnBadge(label: t.onTheClock),
              ],
            ),
          ),
        SizedBox(
          height: 132,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _myCards.isEmpty
                    ? Row(
                        children: const [
                          _MutedHoleCard(),
                          SizedBox(width: 0),
                          _MutedHoleCard(),
                        ],
                      )
                    : Stack(
                        children: [
                          for (var i = 0; i < _myCards.length; i++)
                            Positioned(
                              left: i * 76.0,
                              child: GestureDetector(
                                onTap: canSelectDiscards
                                    ? () => _toggleDiscard(i)
                                    : null,
                                child: Opacity(
                                  opacity:
                                      canSelectDiscards &&
                                          _selectedDiscardIndices.contains(i)
                                      ? 0.35
                                      : 1.0,
                                  // Pops this hole card in the moment it's dealt (its code goes
                                  // from unset to a real value); stays put after that.
                                  child: PopIn(
                                    popKey: _myCards[i]?.toString(),
                                    child: PokerCardWidget(
                                      cardCode: _myCards[i]?.toString(),
                                      width: 92,
                                      height: 124,
                                      rankFontSize: 34,
                                      suitFontSize: 26,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              // _MadeHandBox (below) is hidden here per product decision - hand-strength
              // evaluation isn't implemented yet, so it only ever showed a "coming soon"
              // placeholder. Kept in code, not deleted, for when real evaluation lands.
            ],
          ),
        ),
      ],
    );
  }
}

class _ClockBar extends StatelessWidget {
  final double fraction;
  const _ClockBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 30,
        height: 3,
        child: Stack(
          children: [
            Container(color: const Color(0xFF26242B)),
            FractionallySizedBox(
              widthFactor: 1 - fraction,
              child: Container(color: KarataColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

// Not currently shown (see the comment at its old call site in _buildHandRow) - kept rather than
// deleted for when real hand-strength evaluation lands.
// ignore: unused_element
class _MadeHandBox extends StatelessWidget {
  const _MadeHandBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 124,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: KarataColors.pillLine),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        AppLocalizations.of(context).handStrengthAvailableSoon,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, color: KarataColors.dim),
      ),
    );
  }
}

class _MutedHoleCard extends StatelessWidget {
  const _MutedHoleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 124,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF201E25)),
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}

