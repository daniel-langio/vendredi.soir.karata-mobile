import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_client/screens/auth_redirect.dart';
import 'package:poker_client/screens/chip_purchase_screen.dart';
import 'package:poker_client/screens/chip_redemption_screen.dart';
import 'package:poker_client/screens/economy_config_screen.dart';
import 'package:poker_client/screens/economy_screen.dart';
import 'package:poker_client/screens/join_table_screen.dart';
import 'package:poker_client/screens/menu_screen.dart';
import 'package:poker_client/screens/new_table_screen.dart';
import 'package:poker_client/screens/login_screen.dart';
import 'package:poker_client/screens/pending_redemptions_screen.dart';
import 'package:poker_client/screens/settings_screen.dart';
import 'package:poker_client/screens/table_screen.dart';
import 'test_helpers.dart';

/// Every route name a screen pushes, and the screen it is meant to reach.
///
/// An unrecognised name does not throw and does not return null - it falls through to
/// [RootScreen], which resumes the session and lands the player back on the lobby. Pushed from
/// the lobby, that looks exactly like a button doing nothing, which is how deposit and withdraw
/// shipped pointing at "/chips/buy" and "/chips/redeem" while the routes were "/economy/buy" and
/// "/economy/redeem". Asserting the *screen*, not merely that something resolved, is what makes
/// that visible.
const _routes = <String, Type>{
  '/menu': MenuScreen,
  '/new-table': NewTableScreen,
  '/join-table': JoinTableScreen,
  '/settings': SettingsScreen,
  '/economy': EconomyScreen,
  '/economy/buy': ChipPurchaseScreen,
  '/economy/redeem': ChipRedemptionScreen,
  '/economy/config': EconomyConfigScreen,
  '/economy/pending': PendingRedemptionsScreen,
  '/onboarding/deposit': ChipPurchaseScreen,
  '/table/7f3c1e5a-4b2d-4c8e-9a10-6d5b2f8e1c44': TableScreen,
};

/// What in-app navigation always passes, so the route builds its screen rather than the
/// session-loading gate a deep link would get.
const _session = {
  'serverUrl': 'https://test.poker/poker',
  'token': 'mock-token',
  'username': 'eli',
};

void main() {
  testWidgets('every route the app pushes reaches its own screen', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    _routes.forEach((name, screen) {
      final route = karataOnGenerateRoute(
        RouteSettings(name: name, arguments: _session),
      );
      expect(route, isA<MaterialPageRoute<dynamic>>(), reason: name);
      // The builders here only call a screen's constructor, so this never touches the context.
      final page = (route! as MaterialPageRoute<dynamic>).builder(context);
      expect(
        page.runtimeType,
        screen,
        reason: '"$name" should reach $screen, not ${page.runtimeType}',
      );
    });
  });

  testWidgets('a redirect survives the route it was carried on', (
    tester,
  ) async {
    // _RequireSession sends anyone without a session to /login carrying where they were headed,
    // so that authenticating lands them there rather than on the lobby.
    SharedPreferences.setMockInitialValues({});
    const target = '/table/7f3c1e5a-4b2d-4c8e-9a10-6d5b2f8e1c44';
    final encoded = Uri.encodeQueryComponent(target);

    await tester.pumpWidget(wrapRoutedForTest('/login?redirect=$encoded'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<LoginScreen>(find.byType(LoginScreen)).redirectTarget,
      target,
      reason: 'logging in would land on the lobby instead of the table',
    );
  });

  group('switching between the two auth forms', () {
    test('carries the redirect across', () {
      expect(
        authRouteWithRedirect('/register', '/economy/buy'),
        '/register?redirect=%2Feconomy%2Fbuy',
      );
    });

    test('and the route it builds is one the app recognises', () {
      // The encoding has to survive the round trip, or the redirect silently becomes a 404 that
      // falls through to the lobby.
      final built = authRouteWithRedirect('/login', '/table/abc-123');
      final parsed = Uri.parse(built);
      expect(parsed.path, '/login');
      expect(parsed.queryParameters['redirect'], '/table/abc-123');
    });

    test('leaves a plain form alone when there is nowhere to go back to', () {
      expect(authRouteWithRedirect('/login', null), '/login');
      expect(authRouteWithRedirect('/login', ''), '/login');
    });
  });

  testWidgets('a name nothing recognises falls back to the root screen', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final route = karataOnGenerateRoute(
      const RouteSettings(name: '/chips/buy', arguments: _session),
    );
    final page = (route! as MaterialPageRoute<dynamic>).builder(context);
    expect(page, isA<RootScreen>());
  });
}
