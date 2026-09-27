import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_client/models/room_summary.dart';
import 'package:poker_client/screens/menu_screen.dart';
import 'package:poker_client/widgets/common/karata_button.dart';
import 'package:poker_client/widgets/rooms/room_card.dart';
import 'package:poker_client/widgets/rooms/room_card_state.dart';
import 'package:poker_client/widgets/rooms/room_full_pill.dart';
import 'package:poker_client/widgets/rooms/room_quiet_well.dart';
import 'package:poker_client/widgets/rooms/room_stats_well.dart';
import 'package:poker_client/widgets/rooms/room_tag.dart';
import 'test_helpers.dart';

/// A room card with everything but [state] and its labels held fixed, so a test names only the
/// thing it is about.
Widget roomCard({
  required RoomCardState state,
  String statusLabel = 'Cashout',
  RoomTagTone statusTone = RoomTagTone.cashout,
  String footerPrefix = 'Default buy-in',
  String actionLabel = 'Sit down',
  int tableCount = 3,
  int playerCount = 14,
  VoidCallback? onPressed,
}) => wrapForTest(
  Align(
    child: RoomCard(
      name: 'Bronze',
      blindsLabel: 'Blinds 50 / 100 Ar',
      variantLabel: "Hold'em",
      statusLabel: statusLabel,
      statusTone: statusTone,
      state: state,
      tableCount: tableCount,
      tablesLabel: 'tables',
      playerCount: playerCount,
      playersLabel: 'players',
      quietTitle: 'Be the first to sit',
      quietCaption: '0 tables running yet',
      footerPrefix: footerPrefix,
      footerAmount: '5 000 Ar',
      actionLabel: actionLabel,
      onPressed: onPressed,
    ),
  ),
);

/// A server that answers the lobby's three list endpoints and nothing else, so a test can say
/// what the lobby was told rather than only what it does when it is told nothing.
http.Client _lobbyServing({
  required List<Object> rooms,
  List<Object> publicTables = const [],
}) => MockClient((request) async {
  final body = switch (request.url.path) {
    '/poker/rooms' => rooms,
    '/poker/games/public' => publicTables,
    '/poker/games/mine' => const [],
    _ => null,
  };
  if (body == null) return http.Response('{}', 404);
  return http.Response(
    jsonEncode(body),
    200,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
});

Future<void> _pumpLobby(WidgetTester tester, http.Client client) async {
  await http.runWithClient(() async {
    await tester.pumpWidget(
      wrapForTest(
        const MenuScreen(
          serverUrl: 'https://test.poker/poker',
          token: 'mock-token',
          username: 'eli',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }, () => client);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RoomSummary', () {
    RoomSummary room({
      int? maxTables,
      int tableCount = 0,
      int playerCount = 0,
    }) => RoomSummary.fromJson({
      'roomId': 'r1',
      'name': 'Bronze',
      'blinds': {'small': 50, 'big': 100},
      'defaultBuyIn': 5000,
      'variant': 'TEXAS_HOLDEM',
      'cashoutEnabled': true,
      'enforceMinimumBuyIn': true,
      'autoRebuyEnabled': false,
      'maxTables': maxTables,
      'tableCount': tableCount,
      'playerCount': playerCount,
    });

    test('an uncapped room is never full, however busy it gets', () {
      expect(room(tableCount: 40, playerCount: 240).isFull, isFalse);
    });

    test('a capped room with seats left is still sittable', () {
      // Four tables allowed and four running, but 20 of the 24 seats taken - the server will put
      // the next player in one of the four that are free rather than refusing them.
      expect(
        room(maxTables: 4, tableCount: 4, playerCount: 20).isFull,
        isFalse,
      );
    });

    test('a capped room with every seat taken is full', () {
      expect(room(maxTables: 4, tableCount: 4, playerCount: 24).isFull, isTrue);
    });

    test('an unenforced minimum lets any positive buy-in through', () {
      final relaxed = RoomSummary.fromJson({
        'roomId': 'r1',
        'name': 'Bronze',
        'blinds': {'small': 50, 'big': 100},
        'defaultBuyIn': 5000,
        'enforceMinimumBuyIn': false,
        'tableCount': 0,
        'playerCount': 0,
      });
      expect(relaxed.minimumBuyIn, 1);
      expect(room().minimumBuyIn, 5000);
    });
  });

  group('RoomCard', () {
    testWidgets('a busy room offers a seat and counts what is there', (
      tester,
    ) async {
      await tester.pumpWidget(
        roomCard(state: RoomCardState.open, onPressed: () {}),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RoomStatsWell), findsOneWidget);
      expect(find.byType(RoomQuietWell), findsNothing);
      expect(find.widgetWithText(KarataButton, 'Sit down'), findsOneWidget);
    });

    testWidgets('a quiet room invites rather than printing two zeroes', (
      tester,
    ) async {
      await tester.pumpWidget(
        roomCard(
          state: RoomCardState.quiet,
          tableCount: 0,
          playerCount: 0,
          onPressed: () {},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RoomQuietWell), findsOneWidget);
      expect(find.text('Be the first to sit'), findsOneWidget);
      // Still sittable: an empty room is the normal state of a new one, not a broken one.
      expect(find.widgetWithText(KarataButton, 'Sit down'), findsOneWidget);
    });

    testWidgets('a room you are already in sends you back to your seat', (
      tester,
    ) async {
      await tester.pumpWidget(
        roomCard(
          state: RoomCardState.seated,
          statusLabel: 'Seated',
          statusTone: RoomTagTone.seated,
          footerPrefix: 'You’re in for',
          actionLabel: 'Return to your table',
          onPressed: () {},
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(KarataButton, 'Return to your table'),
        findsOneWidget,
      );
      expect(find.text('Seated'), findsOneWidget);
    });

    testWidgets('a full room shows a state, not a button that does nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        roomCard(
          state: RoomCardState.full,
          statusLabel: 'Full',
          statusTone: RoomTagTone.full,
          actionLabel: 'Room full',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RoomFullPill), findsOneWidget);
      expect(find.byType(KarataButton), findsNothing);
    });
  });

  // Every request answered with a 400 by the test binding, so this is the unreachable-server
  // path. The Rooms tab must say so: an empty room list would be indistinguishable from a lobby
  // where every room genuinely has nobody in it, which is a state that really happens here.
  testWidgets('the lobby opens on Rooms and reports a failed load', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        const MenuScreen(
          serverUrl: 'https://test.poker/poker',
          token: 'mock-token',
          username: 'eli',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Pick your stake — we’ll seat you at the best open table.'),
      findsOneWidget,
    );
    expect(find.text('Couldn’t load rooms'), findsOneWidget);
    expect(find.widgetWithText(KarataButton, 'Retry'), findsOneWidget);
    expect(
      find.text('No rooms are open right now.'),
      findsNothing,
      reason: 'a failed load must not be reported as an empty lobby',
    );
  });

  group('which tab the lobby opens on', () {
    final aRoom = {
      'roomId': 'r1',
      'name': 'Bronze',
      'blinds': {'small': 50, 'big': 100},
      'defaultBuyIn': 5000,
      'tableCount': 3,
      'playerCount': 14,
    };

    testWidgets('Rooms, when there are rooms', (tester) async {
      await _pumpLobby(tester, _lobbyServing(rooms: [aRoom]));
      expect(find.text('Bronze'), findsOneWidget);
      expect(find.text('Anyone can sit down'), findsNothing);
    });

    testWidgets('Public tables, when the room list comes back empty', (
      tester,
    ) async {
      await _pumpLobby(tester, _lobbyServing(rooms: const []));
      // An empty Rooms tab is nothing to do; the tables are one tap away and might not be.
      expect(find.text('Anyone can sit down'), findsOneWidget);
      expect(find.text('No rooms are open right now.'), findsNothing);
    });

    testWidgets('Rooms still, so its error can be read, when the load failed', (
      tester,
    ) async {
      await _pumpLobby(
        tester,
        MockClient((_) async => http.Response('{}', 500)),
      );
      expect(find.text('Couldn’t load rooms'), findsOneWidget);
    });

    testWidgets('whatever the player picked, empty room list or not', (
      tester,
    ) async {
      await _pumpLobby(tester, _lobbyServing(rooms: const []));
      await tester.tap(find.text('Rooms'));
      await tester.pumpAndSettle();
      expect(find.text('No rooms are open right now.'), findsOneWidget);
    });
  });
}
