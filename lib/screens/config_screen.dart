import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/jwt_helper.dart';
import 'lobby_screen.dart';
import 'signup_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController(
    text: 'https://62zx5a4vo6n3zjykzu7dx3a4zy0imiwo.lambda-url.eu-west-3.on.aws/poker',
  );
  final _tokenController = TextEditingController();

  String _decodedPlayerId = 'None';
  String _decodedUsername = 'None';

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _tokenController.addListener(_onTokenChanged);
  }

  @override
  void dispose() {
    _tokenController.removeListener(_onTokenChanged);
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    final savedToken = prefs.getString('jwt_token');

    if (savedUrl != null && savedUrl.isNotEmpty) {
      _urlController.text = savedUrl;
    }
    if (savedToken != null && savedToken.isNotEmpty) {
      _tokenController.text = savedToken;
      _onTokenChanged();
    }
  }

  void _onTokenChanged() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _decodedPlayerId = 'None';
        _decodedUsername = 'None';
      });
      return;
    }

    final playerId = JwtHelper.getPlayerId(token);
    final username = JwtHelper.getUsername(token);

    setState(() {
      _decodedPlayerId = playerId ?? 'Invalid / Unknown JWT';
      _decodedUsername = username ?? 'Invalid / Unknown JWT';
    });
  }

  Future<void> _saveAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    await prefs.setString('jwt_token', token);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LobbyScreen(
            baseUrl: url,
            token: token,
            playerId: _decodedPlayerId,
            username: _decodedUsername,
          ),
        ),
      );
    }
  }

  Future<void> _navigateToSignUp() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => SignUpScreen(
          initialServerUrl: _urlController.text.trim(),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      _tokenController.text = result;
      _onTokenChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poker Client Config'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.casino,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 16),
              const Text(
                'Configure Connection Details',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Server Base URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a base URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'JWT Auth Token',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a JWT token';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Decoded JWT Info (Realtime)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const Divider(),
                      Text('Player ID: $_decodedPlayerId'),
                      const SizedBox(height: 4),
                      Text('Username: $_decodedUsername'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveAndProceed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Connect to Lobby',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _navigateToSignUp,
                icon: const Icon(Icons.person_add),
                label: const Text('Sign Up / Register to get API Key'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
