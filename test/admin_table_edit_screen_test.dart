import 'dart:convert';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:karata_ui/screens/admin/admin_table_edit_screen.dart';
import 'package:karata_ui/widgets/desktop/desktop_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// That the table editor now matches the redesign: Bots instead of a Danger Zone that a real
/// operator could never actually use, a pot/buy-in/seated stats card, and an open-seat row per
/// seat still free.
///
/// GameService.requireInitiator/requireCanClose have no operator bypass, so the pause/resume/close
/// buttons this screen used to offer would 403 for any operator who isn't the table's own host -
/// this is a correctness fix bundled with the redesign, not only a cosmetic one.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Map<String, dynamic> adminTableJson({bool isPublic = true}) => {
    'gameId': 'g1',
    'name': 'Analakely Nights',
    'isPublic': isPublic,
    'status': 'OPEN',
    'seated': 3,
    'capacity': 6,
    'smallBlind': 250,
    'bigBlind': 500,
    'defaultBuyIn': 50000,
    'variant': 'TEXAS_HOLDEM',
    'roomId': null,
    'roomName': null,
    'host': 'eli',
    'createdAt': '2026-01-01T00:00:00Z',
  };

  Map<String, dynamic> gameJson({int pot = 1240}) => {
    'players': [
      {'username': 'Priya', 'chips': 12400},
      {'username': 'Theo', 'chips': 9800},
      {'username': 'Ana', 'chips': 20000},
    ],
    'currentDeal': {'pot': pot},
  };

  http.Client serving({
    bool isPublic = true,
    int pot = 1240,
    void Function(http.Request)? onAddBot,
    void Function(http.Request)? onRemove,
    void Function(http.Request)? onPatch,
  }) => MockClient((request) async {
    if (request.url.path == '/poker/admin/tables' && request.method == 'GET') {
      return http.Response(
        jsonEncode([adminTableJson(isPublic: isPublic)]),
        200,
      );
    }
    if (request.url.path == '/poker/games/g1' && request.method == 'GET') {
      return http.Response(jsonEncode(gameJson(pot: pot)), 200);
    }
    // A 1:1 rate, so an amount in chips prints unchanged in Ar and the assertions below can name
    // the numbers straight out of adminTableJson/gameJson.
    if (request.url.path == '/economy/price') {
      return http.Response(jsonEncode({'arPerChip': 1}), 200);
    }
    if (request.url.path == '/poker/games/g1/bots' &&
        request.method == 'POST') {
      onAddBot?.call(request);
      return http.Response('', 204);
    }
    if (request.url.path.startsWith('/poker/admin/tables/g1/players/') &&
        request.method == 'DELETE') {
      onRemove?.call(request);
      return http.Response('', 204);
    }
    if (request.url.path == '/poker/admin/tables/g1' &&
        request.method == 'PATCH') {
      onPatch?.call(request);
      return http.Response(jsonEncode(adminTableJson(isPublic: isPublic)), 200);
    }
    return http.Response('{}', 404);
  });

  // Everything a test does with the widget - not just the initial load - has to run inside
  // runWithClient's zone, because a later tap (Add bot, Remove, Save) issues its own HTTP call
  // through the same top-level package:http functions. A `then` that runs after pumpAndSettle
  // returns would fire outside the override and hit Flutter's network-blocked default client
  // instead of the mock - silently, since the resulting exception is swallowed by _run's own
  // try/catch.
  Future<void> pump(
    WidgetTester tester,
    http.Client client, [
    Future<void> Function()? then,
    Size size = const Size(800, 3000),
  ]) async {
    // Tall rather than the 800x600 default: the narrow layout now stacks six cards (Table, Bots,
    // the note, Save, Seated players, stats) on top of each other, and ensureVisible's minimal-
    // scroll only ever brings a target flush with whichever edge is nearer - which for a control
    // with as much content below it as above stops short of fully clearing the fold. Kept under
    // 900 wide so KarataLayout.isWide still reads this as the phone layout, unless overridden.
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await http.runWithClient(() async {
      await tester.pumpWidget(
        wrapForTest(
          const AdminTableEditScreen(
            serverUrl: 'https://test.poker/poker',
            token: 'mock-token',
            username: 'ophelia',
            gameId: 'g1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (then != null) await then();
    }, () => client);
  }

  testWidgets('there is no pause, resume or close control any more', (
    tester,
  ) async {
    await pump(tester, serving());

    expect(find.text('Pause table'), findsNothing);
    expect(find.text('Resume table'), findsNothing);
    expect(find.text('Close table'), findsNothing);
    expect(find.text('Danger zone'), findsNothing);
    expect(
      find.textContaining('no operator route', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('a public table offers Add bot, and it calls the endpoint', (
    tester,
  ) async {
    var called = false;
    await pump(tester, serving(onAddBot: (_) => called = true), () async {
      expect(find.text('Bots'), findsOneWidget);
      final button = find.text('Add bot');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    });

    expect(called, isTrue);
  });

  testWidgets('a private table does not offer Add bot', (tester) async {
    await pump(tester, serving(isPublic: false));

    expect(find.text('Bots'), findsNothing);
    expect(find.text('Add a bot'), findsNothing);
    expect(find.text('Add bot'), findsNothing);
  });

  testWidgets('the stats card shows the pot, buy-in and seat count', (
    tester,
  ) async {
    await pump(tester, serving(pot: 1240));

    expect(find.text('Pot size'), findsOneWidget);
    expect(find.text('1 240 Ar'), findsOneWidget);
    expect(find.text('50 000 Ar'), findsOneWidget);
    expect(find.text('3 / 6'), findsOneWidget);
  });

  testWidgets('one open-seat row per free seat, not just when empty', (
    tester,
  ) async {
    // 3 seated of 6 capacity in adminTableJson - 3 free seats.
    await pump(tester, serving());

    expect(find.text('Open seat'), findsNWidgets(3));
  });

  testWidgets('removing a seated player calls the admin endpoint', (
    tester,
  ) async {
    String? removedPath;
    await pump(
      tester,
      serving(onRemove: (r) => removedPath = r.url.path),
      () async {
        final removeButton = find.text('Remove').first;
        await tester.ensureVisible(removeButton);
        await tester.pumpAndSettle();
        await tester.tap(removeButton);
        await tester.pumpAndSettle();
      },
    );

    expect(removedPath, '/poker/admin/tables/g1/players/Priya');
  });

  testWidgets('saving sends the edited name and blinds', (tester) async {
    Map<String, dynamic>? sentBody;
    await pump(
      tester,
      serving(
        onPatch: (r) => sentBody = jsonDecode(r.body) as Map<String, dynamic>,
      ),
      () async {
        await tester.enterText(fieldLabelled('Name'), 'Renamed Table');
        final saveButton = find.text('Save changes');
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      },
    );

    expect(sentBody, isNotNull);
    expect(sentBody!['name'], 'Renamed Table');
  });

  testWidgets('a browser-sized window splits settings from the roster', (
    tester,
  ) async {
    await pump(tester, serving(), null, const Size(1280, 900));

    // Both columns' content is on screen at once - nothing here needs a scroll to check.
    expect(find.byType(DesktopColumns), findsOneWidget);
    expect(find.text('Table'), findsOneWidget);
    expect(find.text('Seated players'), findsOneWidget);
    expect(find.text('Pot size'), findsOneWidget);
  });
}
