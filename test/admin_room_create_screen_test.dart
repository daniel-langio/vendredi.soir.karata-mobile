import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:karata_ui/screens/admin/admin_room_create_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// That the room-create form actually carries the room settings a room can be stamped from - not
/// just cashout, which is all it used to expose - through to the request it sends.
///
/// Deliberately does not cover "make this table public": a room has no such setting (it is a
/// stake tier players sit down at directly, never itself listed as a public table), and this
/// screen must go on not offering it.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'flipping enforce-minimum-buy-in and auto-rebuy sends them, off cashout too',
    (tester) async {
      Map<String, dynamic>? sentBody;
      final client = MockClient((request) async {
        if (request.url.path == '/poker/rooms' && request.method == 'POST') {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 201);
        }
        // The screen also refreshes the chip-display rate on open; failing that is silent.
        return http.Response('{}', 404);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(
          wrapForTest(
            const AdminRoomCreateScreen(
              serverUrl: 'https://test.poker/poker',
              token: 'mock-token',
              username: 'ophelia',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(fieldLabelled('Name'), 'High rollers');
        await tester.enterText(fieldLabelled('Small blind'), '50');
        await tester.enterText(fieldLabelled('Big blind'), '100');
        await tester.enterText(fieldLabelled('Default buy-in'), '5000');

        // Every switch starts at the room's own default (cashout on, minimum buy-in enforced,
        // auto-rebuy off) - flip every one of them, so the request below can only be right if
        // each switch is actually wired to its own field rather than to another's. The form is
        // taller than the test surface, so each has to be scrolled into view before it can be hit.
        for (final label in [
          'Cashout enabled',
          'Enforce minimum buy-in',
          'Auto-rebuy busted players',
        ]) {
          final s = switchLabelled(label);
          await tester.ensureVisible(s);
          await tester.pumpAndSettle();
          await tester.tap(s);
        }
        await tester.pumpAndSettle();

        final createButton = find.text('Create room');
        await tester.ensureVisible(createButton);
        await tester.pumpAndSettle();
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      }, () => client);

      expect(sentBody, isNotNull, reason: 'POST /poker/rooms was never sent');
      expect(sentBody!['cashoutEnabled'], isFalse);
      expect(sentBody!['enforceMinimumBuyIn'], isFalse);
      expect(sentBody!['autoRebuyEnabled'], isTrue);
    },
  );

  testWidgets('the defaults match a fresh room before anything is touched', (
    tester,
  ) async {
    Map<String, dynamic>? sentBody;
    final client = MockClient((request) async {
      if (request.url.path == '/poker/rooms' && request.method == 'POST') {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{}', 201);
      }
      return http.Response('{}', 404);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(
        wrapForTest(
          const AdminRoomCreateScreen(
            serverUrl: 'https://test.poker/poker',
            token: 'mock-token',
            username: 'ophelia',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(fieldLabelled('Name'), 'Bronze');
      await tester.enterText(fieldLabelled('Small blind'), '10');
      await tester.enterText(fieldLabelled('Big blind'), '20');
      await tester.enterText(fieldLabelled('Default buy-in'), '2000');
      final createButton = find.text('Create room');
      await tester.ensureVisible(createButton);
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();
    }, () => client);

    expect(sentBody!['cashoutEnabled'], isTrue);
    expect(sentBody!['enforceMinimumBuyIn'], isTrue);
    expect(sentBody!['autoRebuyEnabled'], isFalse);
    expect(sentBody!['maxTables'], isNull);
  });
}
