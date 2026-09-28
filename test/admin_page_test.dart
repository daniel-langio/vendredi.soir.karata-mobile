import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karata_ui/widgets/admin/admin_page.dart';
import 'package:karata_ui/widgets/desktop/desktop_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// That an admin screen's own buttons survive both layouts.
///
/// Worth a test of its own because [AdminPage] used to hand [AdminPage.actions] to the wide
/// layout's shell and nowhere else, so the rooms list's "New room" button simply did not exist on
/// a phone - the one screen that can create a room, with no way to create one. Nothing else could
/// catch it: the widget was built and then dropped, so it neither threw nor drew.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget page({required VoidCallback onPressed}) => wrapForTest(
    AdminPage(
      nav: DesktopNav.adminRooms,
      sessionArgs: const {
        'serverUrl': 'https://test.poker/poker',
        'token': 'mock-token',
        'username': 'eli',
      },
      username: 'eli',
      title: 'Rooms',
      subtitle: 'The stake tiers',
      loading: false,
      error: null,
      onRetry: () {},
      actions: [AdminPrimaryAction(label: 'New room', onPressed: onPressed)],
      children: const [Text('a room')],
    ),
  );

  testWidgets('a phone shows the page action, and it works', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(page(onPressed: () => tapped++));
    await tester.pumpAndSettle();

    expect(find.byType(DesktopSidebar), findsNothing);
    expect(find.text('New room'), findsOneWidget);

    await tester.tap(find.text('New room'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });

  testWidgets('a browser-sized window shows it too', (tester) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(page(onPressed: () {}));
    await tester.pumpAndSettle();

    expect(find.byType(DesktopSidebar), findsOneWidget);
    expect(find.text('New room'), findsOneWidget);
  });
}
