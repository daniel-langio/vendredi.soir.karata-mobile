import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import 'game_screen.dart';
import 'config_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String playerId;
  final String username;

  const LobbyScreen({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.playerId,
    required this.username,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late final ApiClient _apiClient;
  final _joinGameController = TextEditingController();
  final _newGameNameController = TextEditingController(text: 'Friday Night Poker');
  final _smallBlindController = TextEditingController(text: '10');
  final _bigBlindController = TextEditingController(text: '20');
  final _buyInController = TextEditingController(text: '1000');

  List<String> _savedGameIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.baseUrl, token: widget.token);
    _loadSavedGames();
  }

  @override
  void dispose() {
    _joinGameController.dispose();
    _newGameNameController.dispose();
    _smallBlindController.dispose();
    _bigBlindController.dispose();
    _buyInController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedGames() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedGameIds = prefs.getStringList('saved_games_list') ?? [];
    });
  }

  Future<void> _saveGameId(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_games_list') ?? [];
    if (!list.contains(gameId)) {
      list.insert(0, gameId);
      await prefs.setStringList('saved_games_list', list);
      setState(() {
        _savedGameIds = list;
      });
    }
  }

  Future<void> _deleteSavedGameId(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_games_list') ?? [];
    list.remove(gameId);
    await prefs.setStringList('saved_games_list', list);
    setState(() {
      _savedGameIds = list;
    });
  }

  Future<void> _handleCreateGame() async {
    final name = _newGameNameController.text.trim();
    final sbStr = _smallBlindController.text.trim();
    final bbStr = _bigBlindController.text.trim();

    if (name.isEmpty || sbStr.isEmpty || bbStr.isEmpty) {
      _showErrorSnackBar('Please fill in all new game fields');
      return;
    }

    final sb = int.tryParse(sbStr);
    final bb = int.tryParse(bbStr);

    if (sb == null || bb == null || sb <= 0 || bb <= 0) {
      _showErrorSnackBar('Blinds must be positive integers');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final gameMap = await _apiClient.createGame(name, sb, bb);
      final gameId = gameMap['gameId']?.toString();
      if (gameId == null) {
        throw Exception('Server did not return a game ID');
      }

      await _saveGameId(gameId);
      _showSuccessSnackBar('Game Table "$name" created successfully!');
      _joinGameController.text = gameId;
    } catch (e) {
      _showErrorSnackBar('Failed to create game: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleJoinGame(String gameId, {bool skipBuyInCheck = false}) async {
    final cleanId = gameId.trim();
    if (cleanId.isEmpty) {
      _showErrorSnackBar('Please enter or select a valid Game ID');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Fetch game details to verify it exists and inspect current players
      final gameMap = await _apiClient.getGame(cleanId);
      final players = gameMap['players'] as List<dynamic>? ?? [];
      
      // Check if user is already registered in the game
      final isRegistered = players.any((p) => p['playerId'] == widget.playerId);

      if (!isRegistered && !skipBuyInCheck) {
        // If not registered, prompt for buy-in amount before fully entering
        setState(() => _isLoading = false);
        _promptBuyIn(cleanId);
        return;
      }

      await _saveGameId(cleanId);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GameScreen(
              baseUrl: widget.baseUrl,
              token: widget.token,
              gameId: cleanId,
              playerId: widget.playerId,
              username: widget.username,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to join game: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _promptBuyIn(String gameId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buy-In to Game'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('You are not registered in this game. Enter your buy-in chip amount to register and join:'),
              const SizedBox(height: 16),
              TextField(
                controller: _buyInController,
                decoration: const InputDecoration(
                  labelText: 'Buy-In Chips',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final buyInAmountStr = _buyInController.text.trim();
                final buyInAmount = int.tryParse(buyInAmountStr);
                if (buyInAmount == null || buyInAmount <= 0) {
                  _showErrorSnackBar('Please enter a valid buy-in amount');
                  return;
                }
                Navigator.of(context).pop();

                setState(() => _isLoading = true);
                try {
                  await _apiClient.buyIn(gameId, buyInAmount);
                  _showSuccessSnackBar('Registered successfully with $buyInAmount chips!');
                  _handleJoinGame(gameId, skipBuyInCheck: true);
                } catch (e) {
                  _showErrorSnackBar('Buy-in failed: $e');
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Register & Join'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _disconnect() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ConfigScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poker Table Lobby'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _disconnect,
            tooltip: 'Config Screen',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Info Header
                Card(
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${widget.username}!',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${widget.playerId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Join Existing Game
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Join Game Table',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _joinGameController,
                          decoration: const InputDecoration(
                            labelText: 'Game UUID',
                            border: OutlineInputBorder(),
                            hintText: 'e.g. 550e8400-e29b-41d4-a716-446655440000',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _handleJoinGame(_joinGameController.text),
                          icon: const Icon(Icons.login),
                          label: const Text('Join Game'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Create New Game
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Create New Game Table',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _newGameNameController,
                          decoration: const InputDecoration(
                            labelText: 'Table Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _smallBlindController,
                                decoration: const InputDecoration(
                                  labelText: 'Small Blind',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _bigBlindController,
                                decoration: const InputDecoration(
                                  labelText: 'Big Blind',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _handleCreateGame,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Create Table'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Saved Games List
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'Saved/Recent Game Tables',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                if (_savedGameIds.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No saved games. Create or join a table to display it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _savedGameIds.length,
                    itemBuilder: (context, index) {
                      final gameId = _savedGameIds[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.gamepad, color: Colors.deepPurple),
                          title: Text(
                            gameId,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                onPressed: () => _handleJoinGame(gameId),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                onPressed: () => _deleteSavedGameId(gameId),
                              ),
                            ],
                          ),
                          onTap: () => _handleJoinGame(gameId),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
