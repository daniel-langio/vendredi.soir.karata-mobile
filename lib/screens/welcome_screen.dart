import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../debug_backend_config.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

const kDefaultServerUrl =
    'https://preprod-karata-490641885062.southamerica-east1.run.app/poker';

/// When this app is served from the same Spring Boot app it talks to (the
/// intended deployment for the web build - see web-ui/README.md), same-origin
/// requests need no CORS at all, so default to wherever this page itself was
/// loaded from rather than the hardcoded Lambda URL used by the native builds.
String defaultServerUrl() {
  if (kIsWeb) {
    return '${Uri.base.origin}/poker';
  }
  return kDefaultServerUrl;
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

const _customBackend = '__custom__';

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _urlController = TextEditingController(text: defaultServerUrl());
  List<BackendOption> _debugBackends = const [];
  String _selectedBackend = _customBackend;

  @override
  void initState() {
    super.initState();
    _loadDebugBackends();
  }

  Future<void> _loadDebugBackends() async {
    final backends = await DebugBackendConfig.load();
    if (!mounted || backends.isEmpty) return;
    final currentUrl = _urlController.text;
    final matchesAKnownBackend = backends.any((b) => b.url == currentUrl);
    setState(() {
      _debugBackends = backends;
      if (matchesAKnownBackend) _selectedBackend = currentUrl;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _goToRegister() {
    final serverUrl = _urlController.text.trim();
    Navigator.of(context).pushNamed('/register', arguments: {'serverUrl': serverUrl});
  }

  void _goToLogin() {
    final serverUrl = _urlController.text.trim();
    Navigator.of(context).pushNamed('/login', arguments: {'serverUrl': serverUrl});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.casino, size: 72, color: KarataColors.ink),
              const SizedBox(height: 16),
              const Text(
                'Karata',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w300, color: KarataColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                t.welcomeTagline,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: KarataColors.dim, height: 1.45),
              ),
              const Spacer(),
              // Debug-only: which backend to talk to is fixed in a release build (always
              // defaultServerUrl()) - this picker only appears at all when
              // assets/debug_backend_config.json enables it, and never in a non-debug build
              // regardless of the config file. See debug_backend_config.dart.
              if (_debugBackends.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedBackend == _customBackend
                            ? 'Debug backend: custom'
                            : 'Debug backend: ${_debugBackends.firstWhere((b) => b.url == _selectedBackend, orElse: () => _debugBackends.first).name}',
                        style: const TextStyle(color: KarataColors.dim, fontSize: 11.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.dns_outlined, size: 20, color: KarataColors.dim),
                      tooltip: 'Choose a debug backend',
                      onSelected: (url) {
                        setState(() {
                          _selectedBackend = url;
                          if (url != _customBackend) _urlController.text = url;
                        });
                      },
                      itemBuilder: (context) => [
                        for (final b in _debugBackends)
                          PopupMenuItem(value: b.url, child: Text(b.name)),
                        const PopupMenuItem(value: _customBackend, child: Text('Custom URL...')),
                      ],
                    ),
                  ],
                ),
                if (_selectedBackend == _customBackend) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    style: const TextStyle(color: KarataColors.ink, fontSize: 13),
                    decoration: InputDecoration(labelText: t.serverBaseUrl),
                  ),
                ],
                const SizedBox(height: 16),
              ],
              ElevatedButton(onPressed: _goToRegister, child: Text(t.createAccount)),
              const SizedBox(height: 11),
              OutlinedButton(onPressed: _goToLogin, child: Text(t.logIn)),
            ],
          ),
        ),
      ),
    );
  }
}
