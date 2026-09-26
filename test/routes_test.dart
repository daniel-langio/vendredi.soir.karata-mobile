import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/main.dart';
import 'package:poker_client/screens/chip_purchase_screen.dart';
import 'package:poker_client/screens/chip_redemption_screen.dart';
import 'package:poker_client/screens/economy_config_screen.dart';
import 'package:poker_client/screens/economy_screen.dart';
import 'package:poker_client/screens/join_table_screen.dart';
import 'package:poker_client/screens/menu_screen.dart';
import 'package:poker_client/screens/new_table_screen.dart';
import 'package:poker_client/screens/pending_redemptions_screen.dart';
import 'package:poker_client/screens/settings_screen.dart';
import 'package:poker_client/screens/table_screen.dart';

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
