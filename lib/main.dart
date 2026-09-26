import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'chip_display.dart';
import 'locale_controller.dart';
import 'sound_settings.dart';
import 'url_strategy_stub.dart'
    if (dart.library.js_interop) 'url_strategy_web.dart';
import 'screens/welcome_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/new_table_screen.dart';
import 'screens/join_table_screen.dart';
import 'screens/table_screen.dart';
import 'screens/economy_screen.dart';
import 'screens/chip_purchase_screen.dart';
import 'screens/chip_redemption_screen.dart';
import 'screens/economy_config_screen.dart';
import 'screens/pending_redemptions_screen.dart';
import 'theme/karata_colors.dart';
import 'theme/karata_theme.dart';

void main() {
  configureUrlStrategy();
  LocaleController.instance.load();
  SoundSettings.instance.load();
  ChipDisplay.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.instance,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Karata',
          debugShowCheckedModeBanner: false,
          theme: karataTheme(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          onGenerateRoute: karataOnGenerateRoute,
          // This UI is drawn as a phone screen. On a wide browser window it just looked like that
          // same phone layout stretched edge to edge, so cap it and centre it there; a native
          // build is already phone-shaped and wants the full window.
          //
          // Every screen is phone-width for now, the table included: the V2 design has a separate
          // desktop layout for each screen, which is a pass of its own.
          builder: kIsWeb
              ? (context, child) => ColoredBox(
                  color: KarataColors.backdrop,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: child,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

/// Session data a screen needs, either handed down via route arguments during
/// normal in-app navigation, or reloaded from shared_preferences when the
/// route is entered directly (a deep link, a browser refresh, or the app
/// being killed and restarted on this route).
class _Session {
  final String serverUrl;
  final String token;
  final String username;
  const _Session({
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  static _Session? fromArguments(Object? arguments) {
    if (arguments is! Map) return null;
    final serverUrl = arguments['serverUrl'];
    final token = arguments['token'];
    final username = arguments['username'];
    if (serverUrl is! String || token is! String || username is! String) {
      return null;
    }
    return _Session(serverUrl: serverUrl, token: token, username: username);
  }
}

/// Resolves every route name the app pushes.
///
/// Public so a test can assert that the names screens actually push are names this recognises -
/// a mistyped one is silently inert at runtime, which is how the lobby's deposit and withdraw
/// buttons once did nothing at all.
Route<dynamic>? karataOnGenerateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '/');
  final segments = uri.pathSegments;
  final session = _Session.fromArguments(settings.arguments);

  Widget page;
  if (segments.isEmpty) {
    page = const RootScreen();
  } else if (segments.length == 1 &&
      (segments[0] == 'register' || segments[0] == 'signup')) {
    final args = settings.arguments as Map?;
    final serverUrl = (args?['serverUrl'] as String?) ?? defaultServerUrl();
    final redirectTarget = uri.queryParameters['redirect'];
    page = _AuthScreenGate(
      redirectTarget: redirectTarget,
      buildForm: (context) => RegisterScreen(
        serverUrl: serverUrl,
        promoCode: uri.queryParameters['promocode'],
        redirectTarget: redirectTarget,
      ),
    );
  } else if (segments.length == 1 && segments[0] == 'login') {
    final args = settings.arguments as Map?;
    final serverUrl = (args?['serverUrl'] as String?) ?? defaultServerUrl();
    final redirectTarget = uri.queryParameters['redirect'];
    page = _AuthScreenGate(
      redirectTarget: redirectTarget,
      buildForm: (context) =>
          LoginScreen(serverUrl: serverUrl, redirectTarget: redirectTarget),
    );
  } else if (segments.length == 1 && segments[0] == 'menu') {
    page = session == null
        ? _RequireSession(routeName: settings.name ?? uri.path)
        : MenuScreen(
            serverUrl: session.serverUrl,
            token: session.token,
            username: session.username,
          );
  } else if (segments.length == 1 && segments[0] == 'settings') {
    page = session == null
        ? _RequireSession(routeName: settings.name ?? uri.path)
        : SettingsScreen(
            serverUrl: session.serverUrl,
            token: session.token,
            username: session.username,
          );
  } else if (segments.length == 1 && segments[0] == 'new-table') {
    page = session == null
        ? _RequireSession(routeName: settings.name ?? uri.path)
        : NewTableScreen(
            serverUrl: session.serverUrl,
            token: session.token,
            username: session.username,
          );
  } else if (segments.length == 1 && segments[0] == 'join-table') {
    page = session == null
        ? _RequireSession(routeName: settings.name ?? uri.path)
        : JoinTableScreen(
            serverUrl: session.serverUrl,
            token: session.token,
            username: session.username,
          );
  } else if (segments.length == 1 && segments[0] == 'economy') {
    page = session == null
        ? _RequireSession(routeName: settings.name ?? uri.path)
        : EconomyScreen(
            serverUrl: session.serverUrl,
            token: session.token,
            username: session.username,
          );
  } else if (segments.length == 2 &&
      segments[0] == 'economy' &&
      segments[1] == 'buy') {
    page = session == null
        ? _RequireSession(routeName: settings.name ?? uri.path)
        : ChipPurchaseScreen(
            serverUrl: session.serverUrl,
            token: session.token,
            username: session.username,
          );
  } else if (segments.length == 2 &&
      segments[0] == 'economy' &&
      segments[1] == 'redeem') {
    page = session == null
        ? _RequireSession(routeName: settings.name ?? uri.path)
        : ChipRedemptionScreen(
            serverUrl: session.serverUrl,
            token: session.token,
            username: session.username,
          );
  } else if (segments.length == 2 &&
      segments[0] == 'economy' &&
      segments[1] == 'config') {
    page = session == null
        ? _RequireSession(routeName: settings.name ?? uri.path)
        : EconomyConfigScreen(
            serverUrl: session.serverUrl,
            token: session.token,
            username: session.username,
          );
  } else if (segments.length == 2 &&
      segments[0] == 'economy' &&
      segments[1] == 'pending') {
    page = session == null
        ? _RequireSession(routeName: settings.name ?? uri.path)
        : PendingRedemptionsScreen(
            serverUrl: session.serverUrl,
            token: session.token,
            username: session.username,
          );
  } else if (segments.length == 2 && segments[0] == 'table') {
    final gameId = segments[1];
    page = session == null
        ? _RequireSession(routeName: settings.name ?? uri.path)
        : TableScreen(
            serverUrl: session.serverUrl,
            token: session.token,
            username: session.username,
            gameId: gameId,
          );
  } else {
    page = const RootScreen();
  }

  return MaterialPageRoute(settings: settings, builder: (context) => page);
}

/// Loads a saved session before entering a route that needs one, reached directly (a deep link,
/// a browser refresh, or the app restarting on that route) rather than via in-app navigation,
/// where the session would already be in the route's arguments. Falls through to /login,
/// carrying [routeName] as `redirect`, when no session is found - so authenticating lands the
/// caller back where they were headed instead of always on /menu.
class _RequireSession extends StatefulWidget {
  final String routeName;
  const _RequireSession({required this.routeName});

  @override
  State<_RequireSession> createState() => _RequireSessionState();
}

class _RequireSessionState extends State<_RequireSession> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url');
    final token = prefs.getString('jwt_token');
    final username = prefs.getString('username');
    if (!mounted) return;

    if (serverUrl != null &&
        serverUrl.isNotEmpty &&
        token != null &&
        token.isNotEmpty &&
        username != null) {
      Navigator.of(context).pushReplacementNamed(
        widget.routeName,
        arguments: {
          'serverUrl': serverUrl,
          'token': token,
          'username': username,
        },
      );
    } else {
      final redirect = Uri.encodeQueryComponent(widget.routeName);
      Navigator.of(context).pushReplacementNamed('/login?redirect=$redirect');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Guards /login and /register /signup: a saved session already existing means there is nothing
/// to log into, so skip straight to [redirectTarget] (or /menu) instead of showing the form.
class _AuthScreenGate extends StatefulWidget {
  final String? redirectTarget;
  final WidgetBuilder buildForm;
  const _AuthScreenGate({required this.buildForm, this.redirectTarget});

  @override
  State<_AuthScreenGate> createState() => _AuthScreenGateState();
}

class _AuthScreenGateState extends State<_AuthScreenGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url');
    final token = prefs.getString('jwt_token');
    final username = prefs.getString('username');
    if (!mounted) return;

    if (serverUrl != null &&
        serverUrl.isNotEmpty &&
        token != null &&
        token.isNotEmpty &&
        username != null) {
      Navigator.of(context).pushReplacementNamed(
        widget.redirectTarget ?? '/menu',
        arguments: {
          'serverUrl': serverUrl,
          'token': token,
          'username': username,
        },
      );
    } else {
      setState(() => _checked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.buildForm(context);
  }
}

/// Decides whether a saved session exists before the user sees anything.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _hasSession = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url');
    final token = prefs.getString('jwt_token');
    final username = prefs.getString('username');

    if (!mounted) return;

    if (serverUrl != null &&
        serverUrl.isNotEmpty &&
        token != null &&
        token.isNotEmpty &&
        username != null) {
      setState(() => _hasSession = true);
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/menu',
        (route) => false,
        arguments: {
          'serverUrl': serverUrl,
          'token': token,
          'username': username,
        },
      );
    } else {
      setState(() => _checked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSession || !_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const WelcomeScreen();
  }
}
