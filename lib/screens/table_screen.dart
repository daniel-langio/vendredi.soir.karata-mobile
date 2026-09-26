import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_client.dart';
import '../chip_display.dart';
import '../game_sounds.dart';
import '../l10n/app_localizations.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/karata_backdrop.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_card.dart';
import '../widgets/common/amount_field.dart';
import '../widgets/common/karata_icons.dart';
import '../widgets/table/bet_sizer_row.dart';
import '../widgets/table/last_action_label.dart';
import '../widgets/table/outcome_banner.dart';
import '../widgets/table/seat_action_badge.dart';
import '../widgets/table/seat_data.dart';
import '../widgets/table/table_action_bar.dart';
import '../widgets/table/table_controls.dart';
import '../widgets/table/table_menu_sheet.dart';
import '../widgets/table/table_surface.dart';
import '../widgets/table/table_top_bar.dart';
import '../widgets/table/variant_info_dialog.dart';

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
  late final ApiClient _apiClient;
  Timer? _pollTimer;
  Timer? _tickTimer;

  Map<String, dynamic>? _game;
  List<dynamic> _myCards = [];
  bool _isLoading = false;

  /// What the bet/raise box currently holds. The V2 design keeps the sizer on screen rather than
  /// behind a toggle, so this is always live rather than only while a panel is open.
  int _sizerAmount = 0;
  final _sizerController = TextEditingController();

  // Five-Card Draw: indices into _myCards the player has tapped to mark for discard.
  final Set<int> _selectedDiscardIndices = {};

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
  }

  void _onChipDisplayChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    ChipDisplay.instance.removeListener(_onChipDisplayChanged);
    _sizerController.dispose();
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
      // A failed poll is left to the next tick. The V2 header has no room for a connection
      // indicator, so there is nothing to report here - the table simply keeps showing the last
      // state it managed to fetch.
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
    // The field takes the same unit the player reads the rest of the table in - chips normally,
    // Ariary once "show chips as money" is on - rather than silently asking for chips under a
    // money-flavoured UI. The API only ever speaks chips, so a money entry is converted back below
    // at the very rate every other amount on screen is rendered with.
    final display = ChipDisplay.instance.value;
    final defaultBuyIn = (_game?['defaultBuyIn'] as num?)?.toInt() ?? 200;
    final buyInController = TextEditingController(
      text: '${display.entryFromChips(defaultBuyIn)}',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.sitDown),
        content: TextField(
          controller: buyInController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: t.amount),
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

    final entered = int.tryParse(buyInController.text.trim());
    final buyIn = entered == null ? null : display.chipsFromEntry(entered);
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
                ? const Icon(Icons.check, color: KarataColors.teal)
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

  /// The server refuses every deal and action while a table is paused. Without this the refusal
  /// surfaces as a bare error snackbar, reading as a bug rather than as the host having
  /// deliberately stopped play.
  Widget _pausedBanner(AppLocalizations t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: KarataCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        _isHost ? t.tablePausedHost : t.tablePaused,
        textAlign: TextAlign.center,
        style: karataText(size: 13, weight: 600, color: KarataColors.gold),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return const Scaffold(
        backgroundColor: KarataColors.backdrop,
        body: Center(
          child: CircularProgressIndicator(color: KarataColors.gold),
        ),
      );
    }

    final t = AppLocalizations.of(context);
    final gameName = _game?['name'] as String? ?? '';

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      body: KarataBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                child: Column(
                  children: [
                    TableTopBar(
                      title: _isClosed
                          ? '$gameName (${t.closedSuffix})'
                          : gameName,
                      leaveLabel: t.leaveTable,
                      settingsLabel: t.settings,
                      onLeave: () {
                        _sounds.click();
                        _leaveTable();
                      },
                      onSettings: _showTableMenu,
                    ),
                    if (_isPaused && !_isClosed)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _pausedBanner(t),
                      ),
                    Expanded(child: _surface(t)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _controls(t),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const ColoredBox(
                  color: Color(0x73000000),
                  child: Center(
                    child: CircularProgressIndicator(color: KarataColors.gold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Going back has to give up the seat for real, not just pop the route - the server still has
    // you in the hand otherwise. Intercepting here covers the top bar's arrow, the system back
    // button and the predictive-back gesture at once, and reuses the same confirmation the Leave
    // table menu item shows. Only worth asking of someone who actually holds a seat though: a
    // spectator, or anyone at a closed table, has nothing to give up and just leaves.
    return PopScope(
      canPop: _isClosed || !_isPlaying,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _leaveTable();
      },
      child: scaffold,
    );
  }

  /// The felt and everything on it, assembled from the current deal.
  Widget _surface(AppLocalizations t) {
    final deal = _currentDeal;
    final outcome = deal?['outcome'] as Map<String, dynamic>?;
    final revealedHands = <String, Map<String, dynamic>>{
      for (final rh in (outcome?['revealedHands'] as List<dynamic>? ?? []))
        (rh as Map<String, dynamic>)['playerId'].toString(): rh,
    };
    final winningCards = <String>{
      for (final c in (outcome?['winningCards'] as List<dynamic>? ?? []))
        c.toString(),
    };

    return TableSurface(
      opponents: [
        for (final p in _players)
          if (p['username'] != widget.username)
            _seatFor(p as Map<String, dynamic>, t, revealedHands),
      ],
      board:
          (deal?['communityCards'] as List<dynamic>? ??
                  const [null, null, null, null, null])
              .map((c) => c?.toString())
              .toList(),
      winningCards: winningCards,
      pot: ChipDisplay.instance.format(deal?['pot'] as num?),
      handLabel: _handRank(outcome),
      heroCards: _myCards.map((c) => c?.toString()).toList(),
      heroDimmed: _you?['status'] == 'FOLDED',
      heroIsDealer: _you?['dealer'] == true,
      selectedHeroCards: _selectedDiscardIndices,
      onHeroCardTap: _phase == 'DRAW' && _isMyTurn ? _toggleDiscard : null,
      banner: outcome == null
          ? null
          : OutcomeBanner(outcome: outcome, myUsername: widget.username),
    );
  }

  /// One opponent, with whatever they last did resolved into a badge.
  SeatData _seatFor(
    Map<String, dynamic> player,
    AppLocalizations t,
    Map<String, Map<String, dynamic>> revealedHands,
  ) {
    final playerId = player['playerId']?.toString();
    final status = player['status']?.toString();
    final folded = status == 'FOLDED';
    final isActive = playerId != null && playerId == _activePlayerId;
    final revealed = revealedHands[playerId];
    final lastAction = player['lastAction']?.toString();

    final (action, label) = switch (true) {
      _ when revealed?['winner'] == true => (SeatAction.winner, t.winner),
      _ when folded => (SeatAction.folded, t.fold),
      _ when isActive => (SeatAction.turn, t.yourTurnBadge),
      _ when status == 'ALL_IN' => (SeatAction.allIn, t.allIn),
      _ when lastAction != null => (
        _actionKind(lastAction),
        formatLastAction(t, lastAction),
      ),
      _ => (null, null),
    };

    return SeatData(
      username: player['username']?.toString() ?? '',
      stack: ChipDisplay.instance.format(player['chips'] as num?),
      action: action,
      actionLabel: label,
      dimmed: folded,
      isDealer: player['dealer'] == true,
      // `holeCards`, not `cards`: the showdown payload names the two cards a player turned over
      // separately from the community cards they were read against.
      revealedCards: revealed == null
          ? null
          : (revealed['holeCards'] as List<dynamic>? ?? [])
                .map((c) => c?.toString())
                .toList(),
    );
  }

  SeatAction _actionKind(String rawAction) {
    final type = rawAction.split(' ').first.toUpperCase();
    return switch (type) {
      'CHECK' => SeatAction.checked,
      'CALL' => SeatAction.called,
      'BET' || 'RAISE' => SeatAction.bet,
      'FOLD' => SeatAction.folded,
      'ALL_IN' => SeatAction.allIn,
      _ => SeatAction.waiting,
    };
  }

  /// The name of the winning hand - "Pair of aces" - which the payload hangs off the winner
  /// rather than off the outcome itself.
  String? _handRank(Map<String, dynamic>? outcome) {
    final winners = outcome?['winners'] as List<dynamic>? ?? const [];
    if (winners.isEmpty) return null;
    return (winners.first as Map<String, dynamic>)['handRank']?.toString();
  }

  /// The pot line, the two round buttons, the sizer and the action buttons.
  Widget _controls(AppLocalizations t) {
    final common = (
      centreLabel: _myStack,
      handStrengthLabel: t.handStrength,
      emoteLabel: t.sendReaction,
    );

    if (_isClosed) {
      return TableControls(
        actions: const [],
        actionsEnabled: false,
        message: t.tableClosed,
        onHandStrength: null,
        onEmote: null,
        centreLabel: common.centreLabel,
        handStrengthLabel: common.handStrengthLabel,
        emoteLabel: common.emoteLabel,
      );
    }

    // A spectator - never bought in, or left earlier - always gets a way to sit down, whatever
    // the hand's phase. Joining mid-hand only takes effect for the *next* hand (see _sitDown).
    if (!_isPlaying) {
      final handInProgress = _dealId.isNotEmpty && _phase != 'SHOWDOWN';
      return TableControls(
        actionsEnabled: !_isLoading,
        actions: [
          (
            label: t.sitDown,
            onPressed: _isLoading ? null : _sitDown,
            style: KarataButtonStyle.primary,
          ),
        ],
        message: handInProgress ? null : null,
        onHandStrength: null,
        onEmote: null,
        centreLabel: common.centreLabel,
        handStrengthLabel: common.handStrengthLabel,
        emoteLabel: common.emoteLabel,
      );
    }

    if (_dealId.isEmpty || _phase == 'SHOWDOWN') {
      return TableControls(
        actionsEnabled: true,
        actions: [
          (
            label: _dealId.isEmpty ? t.startTheHand : t.nextHand,
            onPressed: () {
              _sounds.click();
              _startHand();
            },
            style: KarataButtonStyle.primary,
          ),
        ],
        onHandStrength: _openVariantInfo,
        onEmote: null,
        centreLabel: common.centreLabel,
        handStrengthLabel: common.handStrengthLabel,
        emoteLabel: common.emoteLabel,
      );
    }

    if (_phase == 'DRAW') {
      return TableControls(
        actionsEnabled: _isMyTurn,
        message: _isMyTurn ? null : t.waitingForDraw,
        actions: [
          (
            label: _selectedDiscardIndices.isEmpty
                ? t.standPat
                : t.drawCards(_selectedDiscardIndices.length),
            onPressed: _submitDraw,
            style: KarataButtonStyle.primary,
          ),
        ],
        onHandStrength: _openVariantInfo,
        onEmote: null,
        centreLabel: common.centreLabel,
        handStrengthLabel: common.handStrengthLabel,
        emoteLabel: common.emoteLabel,
      );
    }

    return TableControls(
      actionsEnabled: _isMyTurn,
      actions: _bettingActions(t),
      sizer: _betSizer(t),
      onHandStrength: _openVariantInfo,
      onEmote: null,
      centreLabel: common.centreLabel,
      handStrengthLabel: common.handStrengthLabel,
      emoteLabel: common.emoteLabel,
    );
  }

  /// What the player has in front of them at this table.
  ///
  /// Read from the seated player rather than from `game.you`, which carries what they may do
  /// this turn (call amount, raise bounds) rather than what they hold.
  String? get _myStack {
    final me =
        _players.firstWhere(
              (p) => p['username'] == widget.username,
              orElse: () => null,
            )
            as Map<String, dynamic>?;
    final chips = me?['chips'] as num?;
    return chips == null ? null : ChipDisplay.instance.format(chips);
  }

  int get _minRaise => (_you?['minRaise'] as num?)?.toInt() ?? 20;

  int get _maxRaise => (_you?['maxRaise'] as num?)?.toInt() ?? 0;

  int get _callAmount => (_you?['callAmount'] as num?)?.toInt() ?? 0;

  /// BET on an unopened round, RAISE once someone has put chips in.
  String get _raiseType =>
      ((_currentDeal?['currentRoundBet'] as num?)?.toInt() ?? 0) == 0
      ? 'BET'
      : 'RAISE';

  List<TableAction> _bettingActions(AppLocalizations t) {
    final callAmount = _callAmount;
    final minRaise = _minRaise;
    final maxRaise = _maxRaise;

    // callAmount arrives already capped to this player's stack, so a short stack facing more than
    // it owns calls all-in for less rather than being left with folding as its only legal move
    // (the part it can't cover goes to a side pot it isn't eligible for). Saying "all in" makes
    // that plain, since the amount alone doesn't tell you it's everything you have.
    final allInCall = callAmount > 0 && callAmount >= maxRaise;
    final callLabel = callAmount == 0
        ? t.check
        : '${allInCall ? t.allIn : t.callVerb} ${ChipDisplay.instance.format(callAmount)}';

    final raiseAmount = _sizerAmount == 0 ? minRaise : _sizerAmount;
    final raiseLabel =
        '${_raiseType == 'BET' ? t.betVerb : t.raiseVerb} '
        '${ChipDisplay.instance.format(raiseAmount)}';

    // Mirrors a real backend rejection (TexasHoldemRules.isActionLegal): a raise or bet has to
    // meet the table's minimum, which a short stack sometimes can't - disable it rather than
    // letting the request fail server-side.
    final canCall = callAmount == 0 || maxRaise >= callAmount;
    final canRaise = maxRaise > 0 && maxRaise >= minRaise;

    return [
      (
        label: t.fold,
        onPressed: () {
          _sounds.click();
          _submitAction('FOLD');
        },
        style: KarataButtonStyle.secondary,
      ),
      (
        label: callLabel,
        onPressed: canCall
            ? () {
                _sounds.click();
                callAmount == 0
                    ? _submitAction('CHECK')
                    : _submitAction('CALL', amount: callAmount);
              }
            : null,
        style: KarataButtonStyle.surface,
      ),
      (
        label: raiseLabel,
        onPressed: canRaise
            ? () {
                _sounds.click();
                _submitAction(_raiseType, amount: raiseAmount);
              }
            : null,
        style: KarataButtonStyle.primary,
      ),
    ];
  }

  /// The pot fractions, and the box holding what a bet would actually be.
  BetSizerRow _betSizer(AppLocalizations t) {
    final pot = (_currentDeal?['pot'] as num?)?.toInt() ?? 0;
    // A short stack can have fewer chips than the table's minimum raise (e.g. an all-in for
    // less); guard against that so bounds never invert.
    final maxRaise = _maxRaise;
    final minRaise = _minRaise <= maxRaise ? _minRaise : maxRaise;
    int clamp(int v) =>
        maxRaise <= minRaise ? minRaise : v.clamp(minRaise, maxRaise);

    final fractions = <(String, int)>[
      (t.oneThirdPot, clamp(pot ~/ 3)),
      (t.halfPot, clamp(pot ~/ 2)),
      (t.threeQuartersPot, clamp(pot * 3 ~/ 4)),
      (t.pot, clamp(pot)),
      (t.allIn, maxRaise),
    ];

    // The box shows what the button beside it says, in the player's own unit - a "Raise 2 400 Ar"
    // button over a box reading "24" would look like two different numbers.
    final current = _sizerAmount == 0 ? minRaise : _sizerAmount;
    final display = ChipDisplay.instance.value;
    final text = AmountField.entryText(display, current);
    if (_sizerController.text != text) {
      _sizerController.text = text;
    }

    return BetSizerRow(
      labels: [for (final f in fractions) f.$1],
      selectedIndex: fractions.indexWhere((f) => f.$2 == current) == -1
          ? null
          : fractions.indexWhere((f) => f.$2 == current),
      onSelected: (i) {
        _sounds.click();
        setState(() => _sizerAmount = fractions[i].$2);
      },
      amountController: _sizerController,
      amountLabel: t.betAmount,
      enabled: _isMyTurn,
      onAmountChanged: (value) {
        final entered = AmountField.chipsFrom(display, value);
        if (entered != null) setState(() => _sizerAmount = clamp(entered));
      },
    );
  }

  /// Everything the table can do that is not a betting action, behind the header's settings
  /// button - the design gives the table one icon there, and these are what it opens.
  /// Opens the table's menu. The entries are assembled here because which of them apply depends
  /// on the table's state and on whether this player hosts it.
  void _showTableMenu() {
    _sounds.click();
    final t = AppLocalizations.of(context);
    showTableMenu(context, [
      (
        icon: KarataIcons.externalLink,
        label: t.copyInvite,
        onTap: _copyInvite,
        danger: false,
      ),
      (
        icon: KarataIcons.globe,
        label: t.gameVariant,
        onTap: _openVariantInfo,
        danger: false,
      ),
      if (_isHost && !_isClosed)
        (
          icon: KarataIcons.clock,
          label: _isPaused ? t.resumeTable : t.pauseTable,
          onTap: () => _setPaused(!_isPaused),
          danger: false,
        ),
      if (_isHost && !_isClosed)
        (
          icon: KarataIcons.plus,
          label: t.addBot,
          onTap: _addBot,
          danger: false,
        ),
      if (_canClose)
        (
          icon: KarataIcons.logout,
          label: t.closeTable,
          onTap: _closeTable,
          danger: true,
        ),
    ]);
  }

  void _openVariantInfo() =>
      showVariantInfo(context, _game?['variant'] as String? ?? 'TEXAS_HOLDEM');
}
