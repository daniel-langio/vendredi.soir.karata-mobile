import 'dart:async';
import 'package:flutter/material.dart';
import '../api/api_client.dart';

class GameScreen extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String gameId;
  final String playerId;
  final String username;

  const GameScreen({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.gameId,
    required this.playerId,
    required this.username,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final ApiClient _apiClient;
  StreamSubscription? _eventSub;

  Map<String, dynamic>? _gameState;
  List<dynamic> _myCards = [];
  final List<String> _logs = [];

  bool _isLoading = false;
  bool _showMyHand = true;

  // Slider/Bet state
  double _actionAmount = 100.0;
  String? _selectedActionType; // 'BET' or 'RAISE'

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.baseUrl, token: widget.token);
    _logs.add('Joining table...');
    _refreshAll();
    _subscribeToEvents();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final game = await _apiClient.getGame(widget.gameId);
      final dealId = game['currentDealId']?.toString();

      List<dynamic> cards = [];
      if (dealId != null) {
        try {
          final handData = await _apiClient.getMyHand(dealId);
          cards = handData['cards'] as List<dynamic>? ?? [];
        } catch (e) {
          // It's possible that hand is not yet dealt or inaccessible
        }
      }

      if (mounted) {
        setState(() {
          _gameState = game;
          _myCards = cards;
        });
      }
    } catch (e) {
      _addLog('Refresh failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToEvents() {
    _eventSub = _apiClient.streamEvents(widget.gameId).listen(
      (event) {
        if (!mounted) return;
        final type = event['type']?.toString() ?? 'UNKNOWN';
        final payload = event['payload'] as Map<String, dynamic>? ?? {};

        String logMsg = '[$type]';
        if (type == 'PLAYER_JOINED') {
          logMsg = 'Player ${payload['username'] ?? 'unknown'} joined';
        } else if (type == 'DEAL_STARTED') {
          logMsg = 'Deal started! ID: ${payload['dealId']?.toString().substring(0, 8)}...';
        } else if (type == 'PHASE_CHANGED') {
          logMsg = 'Phase changed to ${payload['phase']}';
        } else if (type == 'ACTION_TAKEN') {
          logMsg = '${payload['username'] ?? 'Player'} action: ${payload['actionType']} ${payload['amount'] ?? ''}';
        } else if (type == 'SHOWDOWN') {
          logMsg = 'Showdown! Cards are revealed';
        } else if (type == 'POT_AWARDED') {
          logMsg = 'Pot of ${payload['amount']} awarded to ${payload['username'] ?? 'winner'}!';
        } else if (type == 'ERROR') {
          logMsg = 'SSE Network Connection error: ${payload['message']}';
        }

        _addLog(logMsg);
        _refreshAll();
      },
      onError: (err) {
        _addLog('Event stream error: $err');
      },
    );
  }

  void _addLog(String msg) {
    if (mounted) {
      setState(() {
        _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)} - $msg');
      });
    }
  }

  Future<void> _submitAction(String actionType, {int? amount}) async {
    final dealId = _gameState?['currentDealId']?.toString();
    if (dealId == null) {
      _showSnackBar('No active deal ID to play on.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Create deadline: 30 seconds from now in ISO 8601 UTC
      final timeout = DateTime.now().add(const Duration(seconds: 30)).toUtc().toIso8601String();
      await _apiClient.takeAction(
        dealId: dealId,
        actionType: actionType,
        amount: amount,
        timeoutLimit: timeout,
      );
      _showSnackBar('Action $actionType accepted!');
      setState(() {
        _selectedActionType = null;
      });
      await _refreshAll();
    } catch (e) {
      _showSnackBar('Failed to perform action: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameName = _gameState?['name'] ?? 'Loading...';
    final currentDeal = _gameState?['currentDeal'] as Map<String, dynamic>?;
    final phase = currentDeal?['phase']?.toString() ?? 'NO DEAL';
    final pot = currentDeal?['pot']?.toString() ?? '0';
    final communityCards = currentDeal?['communityCards'] as List<dynamic>? ?? [null, null, null, null, null];
    final players = _gameState?['players'] as List<dynamic>? ?? [];
    final activePlayerId = currentDeal?['activePlayerId']?.toString();

    // Check if it's user's turn
    final isMyTurn = activePlayerId != null && activePlayerId == widget.playerId;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(gameName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Manual Refresh',
          ),
        ],
      ),
      body: _gameState == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Poker Table Area (Green Felt)
                    Expanded(
                      flex: 5,
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.brown.shade800, width: 8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Felt details / layout
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Pot & Phase
                                Text(
                                  'POT: $pot CHIPS',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    phase,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Community Cards (5 slots)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: communityCards.map((card) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: PokerCardWidget(
                                        cardCode: card?.toString(),
                                        isFaceDown: card == null,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),

                            // Active action badge if any
                            if (isMyTurn)
                              Positioned(
                                top: 12,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black38, blurRadius: 4),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, size: 16, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'YOUR TURN TO ACT!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Players Horizontal List
                    SizedBox(
                      height: 95,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemCount: players.length,
                        itemBuilder: (context, idx) {
                          final p = players[idx];
                          final pId = p['playerId']?.toString();
                          final pName = p['username']?.toString() ?? 'Player';
                          final chips = p['chips']?.toString() ?? '0';
                          final isActive = activePlayerId != null && activePlayerId == pId;
                          final isMe = pId == widget.playerId;

                          return Container(
                            width: 110,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.deepPurple.shade900 : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? Colors.amber.shade600
                                    : (isMe ? Colors.deepPurple.shade300 : Colors.transparent),
                                width: isActive ? 3 : 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isMe ? '$pName (You)' : pName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.circle, size: 10, color: Colors.amber),
                                    const SizedBox(width: 3),
                                    Text(
                                      chips,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isActive) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ACTING',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Your Private Hand section
                    Container(
                      color: const Color(0xFF212121),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        children: [
                          const Text(
                            'MY HAND:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_myCards.isEmpty)
                            const Text(
                              'Waiting for deal...',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            )
                          else
                            ..._myCards.map((card) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: PokerCardWidget(
                                  cardCode: card?.toString(),
                                  isFaceDown: !_showMyHand,
                                  width: 40,
                                  height: 56,
                                ),
                              );
                            }),
                          const Spacer(),
                          if (_myCards.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _showMyHand = !_showMyHand);
                              },
                              icon: Icon(_showMyHand ? Icons.visibility_off : Icons.visibility, size: 18),
                              label: Text(_showMyHand ? 'Hide' : 'Show', style: const TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(foregroundColor: Colors.deepPurple.shade300),
                            ),
                        ],
                      ),
                    ),

                    // Actions Panel or Slider
                    _buildActionsOrSlider(isMyTurn),

                    // Event Log at Bottom
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: Colors.black,
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.history, size: 14, color: Colors.white70),
                                SizedBox(width: 4),
                                Text(
                                  'GAME LOG (SSE REAL-TIME)',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _logs.length,
                                itemBuilder: (context, idx) {
                                  return Text(
                                    _logs[idx],
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildActionsOrSlider(bool isMyTurn) {
    if (!isMyTurn) {
      return Container(
        color: const Color(0xFF121212),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(
          child: Text(
            'WAITING FOR OTHER PLAYERS...',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
        ),
      );
    }

    if (_selectedActionType != null) {
      // Show Bet / Raise Slider & Confirm
      return Container(
        color: const Color(0xFF121212),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_selectedActionType AMOUNT: ${_actionAmount.round()}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedActionType = null);
                  },
                  child: const Text('Back', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _actionAmount,
                    min: 10,
                    max: 1000,
                    divisions: 99,
                    activeColor: Colors.amber,
                    onChanged: (val) {
                      setState(() => _actionAmount = val);
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submitAction(
                      _selectedActionType!,
                      amount: _actionAmount.round(),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                    child: Text('CONFIRM $_selectedActionType'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default action choices
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionBtn('FOLD', Colors.redAccent, () => _submitAction('FOLD')),
          _actionBtn('CHECK', Colors.blueAccent, () => _submitAction('CHECK')),
          _actionBtn('CALL', Colors.green, () => _submitAction('CALL')),
          _actionBtn('BET', Colors.amber.shade700, () {
            setState(() {
              _selectedActionType = 'BET';
              _actionAmount = 20.0; // Default bet
            });
          }),
          _actionBtn('RAISE', Colors.purpleAccent, () {
            setState(() {
              _selectedActionType = 'RAISE';
              _actionAmount = 50.0; // Default raise
            });
          }),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class PokerCardWidget extends StatelessWidget {
  final String? cardCode;
  final bool isFaceDown;
  final double width;
  final double height;

  const PokerCardWidget({
    super.key,
    this.cardCode,
    this.isFaceDown = false,
    this.width = 50,
    this.height = 70,
  });

  @override
  Widget build(BuildContext context) {
    if (isFaceDown || cardCode == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 2))],
        ),
        child: const Center(
          child: Icon(
            Icons.help_outline,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }

    final code = cardCode!;
    if (code.length < 2) return const SizedBox();

    final suitChar = code[code.length - 1].toLowerCase();
    final rank = code.substring(0, code.length - 1).toUpperCase();

    String suitSymbol = '';
    Color suitColor = Colors.black;

    switch (suitChar) {
      case 'c':
        suitSymbol = '♣';
        suitColor = Colors.black;
        break;
      case 'd':
        suitSymbol = '♦';
        suitColor = Colors.red;
        break;
      case 'h':
        suitSymbol = '♥';
        suitColor = Colors.red;
        break;
      case 's':
        suitSymbol = '♠';
        suitColor = Colors.black;
        break;
      default:
        suitSymbol = '?';
        suitColor = Colors.grey;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank,
                  style: TextStyle(
                    color: suitColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                Text(
                  suitSymbol,
                  style: TextStyle(
                    color: suitColor,
                    fontSize: 12,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Text(
              suitSymbol,
              style: TextStyle(
                color: suitColor.withValues(alpha: 0.15),
                fontSize: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
