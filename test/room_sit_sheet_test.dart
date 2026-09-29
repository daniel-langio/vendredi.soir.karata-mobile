import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karata_ui/models/room_summary.dart';
import 'package:karata_ui/widgets/rooms/room_sit_sheet.dart';

import 'test_helpers.dart';

RoomSummary _room({
  bool cashoutEnabled = true,
  bool autoRebuyEnabled = false,
}) => RoomSummary(
  roomId: 'r1',
  name: 'Bronze',
  smallBlind: 50,
  bigBlind: 100,
  defaultBuyIn: 1000,
  variant: 'TEXAS_HOLDEM',
  cashoutEnabled: cashoutEnabled,
  enforceMinimumBuyIn: true,
  autoRebuyEnabled: autoRebuyEnabled,
  maxTables: null,
  tableCount: 1,
  playerCount: 1,
);

Future<void> _openSheet(
  WidgetTester tester, {
  required RoomSummary room,
  required int? balanceChips,
}) async {
  await tester.pumpWidget(
    wrapForTest(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () =>
              showRoomSitSheet(context, room: room, balanceChips: balanceChips),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  // A play-chips room and an auto-rebuy room both hand out their own stake for free
  // server-side, so an empty wallet is not a reason to bar the seat - see GameService.joinGame
  // and DealService.applyAutoRebuys in the backend.
  testWidgets('a play-chips room lets an empty wallet sit down', (
    tester,
  ) async {
    await _openSheet(
      tester,
      room: _room(cashoutEnabled: false),
      balanceChips: 0,
    );

    expect(find.text('Add chips'), findsNothing);
    expect(find.textContaining('Sit down for'), findsOneWidget);
  });

  testWidgets('an auto-rebuy room lets an empty wallet sit down', (
    tester,
  ) async {
    await _openSheet(
      tester,
      room: _room(autoRebuyEnabled: true),
      balanceChips: 0,
    );

    expect(find.text('Add chips'), findsNothing);
    expect(find.textContaining('Sit down for'), findsOneWidget);
  });

  testWidgets('a cashout room without auto-rebuy still requires the wallet', (
    tester,
  ) async {
    await _openSheet(tester, room: _room(), balanceChips: 0);

    expect(find.text('Add chips'), findsOneWidget);
  });
}
