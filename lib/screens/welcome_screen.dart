import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../debug_backend_config.dart';
import '../l10n/app_localizations.dart';
import '../server_config.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/breakpoints.dart';
import '../widgets/common/karata_backdrop.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_logo.dart';
import '../widgets/common/karata_text_field.dart';
import '../widgets/common/kente_ribbon.dart';
import '../widgets/desktop/auth_split.dart';

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
    Navigator.of(
      context,
    ).pushNamed('/register', arguments: {'serverUrl': serverUrl});
  }

  void _goToLogin() {
    final serverUrl = _urlController.text.trim();
    Navigator.of(
      context,
    ).pushNamed('/login', arguments: {'serverUrl': serverUrl});
  }

  String get _backendLabel {
    if (_selectedBackend == _customBackend) return 'Debug backend: custom';
    final backend = _debugBackends.firstWhere(
      (b) => b.url == _selectedBackend,
      orElse: () => _debugBackends.first,
    );
    return 'Debug backend: ${backend.name}';
  }

  /// The debug backend picker and, when it is set to a custom URL, the field for it.
  ///
  /// Debug-only: which backend to talk to is fixed in a release build (always
  /// defaultServerUrl()) - this only appears at all when assets/debug_backend_config.yml enables
  /// it, and never in a non-debug build regardless of the config file. See
  /// debug_backend_config.dart.
  List<Widget> _backendPicker(AppLocalizations t) {
    if (_debugBackends.isEmpty) return const [];
    return [
      _BackendPicker(
        label: _backendLabel,
        backends: _debugBackends,
        onSelected: (url) => setState(() {
          _selectedBackend = url;
          if (url != _customBackend) _urlController.text = url;
        }),
      ),
      if (_selectedBackend == _customBackend)
        KarataTextField(controller: _urlController, hintText: t.serverBaseUrl),
    ];
  }

  /// The wide layout: the felt panel carries the mark and the tagline, so the column beside it
  /// opens with its own heading and puts the debug line below the buttons rather than above them.
  Widget _wide(AppLocalizations t) {
    return AuthSplitLayout(
      title: t.welcomeBackTitle,
      subtitle: t.welcomeBackSubtitle,
      children: [
        KarataButton(label: t.createAccount, onPressed: _goToRegister),
        KarataButton(
          label: t.logIn,
          onPressed: _goToLogin,
          style: KarataButtonStyle.secondary,
        ),
        ..._backendPicker(t),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (KarataLayout.isWide(context)) return _wide(t);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KarataBackdrop(
        child: Column(
          children: [
            const KenteRibbon(),
            Expanded(
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      // Centred while there is room, scrollable when there is not: the mark and
                      // the tagline together are taller than a short window (a small phone in
                      // landscape, a desktop browser), and this is the one screen with no other
                      // scrolling content to absorb them.
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const KarataLogo(),
                                  const SizedBox(height: 18),
                                  Text('Karata', style: KarataText.display),
                                  const SizedBox(height: 18),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 290,
                                    ),
                                    child: Text(
                                      t.welcomeTagline,
                                      textAlign: TextAlign.center,
                                      // The tagline is the one place the design sizes body copy at
                                      // 16px; karataText keeps the optical-size axis in step with it.
                                      style: karataText(
                                        size: 16,
                                        weight: 500,
                                        color: KarataColors.inkMuted,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Debug-only: which backend to talk to is fixed in a release build
                          // (always defaultServerUrl()) - this picker only appears at all when
                          // assets/debug_backend_config.yml enables it, and never in a non-debug
                          // build regardless of the config file. See debug_backend_config.dart.
                          if (_debugBackends.isNotEmpty) ...[
                            _BackendPicker(
                              label: _backendLabel,
                              backends: _debugBackends,
                              onSelected: (url) => setState(() {
                                _selectedBackend = url;
                                if (url != _customBackend) {
                                  _urlController.text = url;
                                }
                              }),
                            ),
                            if (_selectedBackend == _customBackend) ...[
                              const SizedBox(height: 12),
                              KarataTextField(
                                controller: _urlController,
                                hintText: t.serverBaseUrl,
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                          KarataButton(
                            label: t.createAccount,
                            onPressed: _goToRegister,
                          ),
                          const SizedBox(height: 12),
                          KarataButton(
                            label: t.logIn,
                            onPressed: _goToLogin,
                            style: KarataButtonStyle.secondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The debug backend line, which doubles as the menu that switches backend.
class _BackendPicker extends StatelessWidget {
  const _BackendPicker({
    required this.label,
    required this.backends,
    required this.onSelected,
  });

  final String label;
  final List<BackendOption> backends;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Choose a debug backend',
      onSelected: onSelected,
      color: KarataColors.surface,
      itemBuilder: (context) => [
        for (final b in backends)
          PopupMenuItem(
            value: b.url,
            child: Text(b.name, style: KarataText.body),
          ),
        PopupMenuItem(
          value: _customBackend,
          child: Text('Custom URL...', style: KarataText.body),
        ),
      ],
      child: Text(
        label,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: KarataText.caption,
      ),
    );
  }
}
