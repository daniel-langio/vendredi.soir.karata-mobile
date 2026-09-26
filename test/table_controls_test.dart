import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/widgets/common/karata_button.dart';
import 'package:poker_client/widgets/table/bet_sizer_row.dart';
import 'package:poker_client/widgets/table/table_controls.dart';
import 'package:poker_client/widgets/table/turn_status_bar.dart';
import 'test_helpers.dart';

/// The controls sit under the felt, and the felt is sized from whatever space is left over - so
/// anything that changes this block's height moves the whole table. The countdown appearing when
/// the clock reaches you, and vanishing the moment you act, did exactly that: the status line is
/// now always present and only changes what it says.
void main() {
  Widget controls({
    Widget status = const TurnStatusBar(),
    BetSizerRow? sizer,
    String? message,
    bool singleAction = false,
  }) {
    return wrapForTest(
      Scaffold(
        body: Column(
          children: [
            const Spacer(),
            TableControls(
              centreLabel: '18 800 Ar',
              handStrengthLabel: 'Hand strength',
              emoteLabel: 'React',
              onHandStrength: () {},
              onEmote: () {},
              actionsEnabled: true,
              message: message,
              status: status,
              sizer: sizer,
              actions: singleAction
                  ? const [
                      (
                        label: 'Next hand',
                        onPressed: null,
                        style: KarataButtonStyle.primary,
                      ),
                    ]
                  : const [
                      (
                        label: 'Fold',
                        onPressed: null,
                        style: KarataButtonStyle.secondary,
                      ),
                      (
                        label: 'Check',
                        onPressed: null,
                        style: KarataButtonStyle.surface,
                      ),
                      (
                        label: 'Bet',
                        onPressed: null,
                        style: KarataButtonStyle.primary,
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  BetSizerRow sizerRow() => BetSizerRow(
    labels: const ['1/3', '1/2', '3/4', 'Pot', 'All-in'],
    onSelected: (_) {},
    amountController: TextEditingController(text: '2 400'),
    amountLabel: 'Bet amount',
  );

  Future<double> heightOf(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pump();
    return tester.getSize(find.byType(TableControls)).height;
  }

  testWidgets('the countdown filling in does not change the block height', (
    tester,
  ) async {
    final idle = await heightOf(tester, controls(sizer: sizerRow()));
    final onTheClock = await heightOf(
      tester,
      controls(
        sizer: sizerRow(),
        status: const TurnStatusBar(
          isYours: true,
          label: 'Your turn - 42s left',
          remaining: Duration(seconds: 42),
          fraction: 0.35,
        ),
      ),
    );
    final waiting = await heightOf(
      tester,
      controls(
        sizer: sizerRow(),
        status: const TurnStatusBar(label: 'Waiting on hanta', fraction: 0.6),
      ),
    );

    expect(
      onTheClock,
      idle,
      reason: 'the table would shift every time the clock reached you',
    );
    expect(waiting, idle);
  });

  testWidgets('every arrangement reserves the same height', (tester) async {
    // The sizer row vanishing at showdown, and three action buttons collapsing to one, are the
    // other two things that used to resize this block and take the felt with them.
    final betting = await heightOf(tester, controls(sizer: sizerRow()));
    final noSizer = await heightOf(tester, controls());
    final oneButton = await heightOf(tester, controls(singleAction: true));
    final waiting = await heightOf(
      tester,
      controls(message: 'Waiting for the draw'),
    );

    for (final height in [betting, noSizer, oneButton, waiting]) {
      expect(height, TableControls.reservedHeight);
    }
  });
}
