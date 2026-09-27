import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_client/screens/menu_screen.dart';
import 'package:poker_client/widgets/common/breakpoints.dart';
import 'package:poker_client/widgets/desktop/desktop_sidebar.dart';
import 'test_helpers.dart';

/// Which of the two layouts a viewport gets, and that a screen actually reaches the wide one.
///
/// Worth a test of its own because the failure it guards against was invisible in every other
/// one: MyApp used to cap the web build at 430px and centre it, while [KarataLayout] reads the
/// window rather than the box it is drawn into - so a browser picked the sidebar layout and then
/// rendered it into a phone-width column. Every other test mounts a screen directly at the
/// default surface, so none of them could see it.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('the breakpoint', () {
    test('a browser window is wide', () {
      expect(KarataLayout.isWideSize(const Size(1280, 860)), isTrue);
    });

    test('a phone is not', () {
      expect(KarataLayout.isWideSize(const Size(412, 915)), isFalse);
    });

    test('a phone held sideways is not, however wide it gets', () {
      // Clears the width floor on its own; the height floor is what holds it back, and is the
      // whole reason there is one.
      expect(KarataLayout.isWideSize(const Size(915, 412)), isFalse);
      expect(KarataLayout.isWideSize(const Size(1280, 412)), isFalse);
    });

    test('the floors themselves are inclusive', () {
      expect(KarataLayout.isWideSize(const Size(900, 600)), isTrue);
      expect(KarataLayout.isWideSize(const Size(899, 600)), isFalse);
      expect(KarataLayout.isWideSize(const Size(900, 599)), isFalse);
    });
  });

  testWidgets('a browser-sized window puts the lobby in the sidebar shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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

    expect(find.byType(DesktopSidebar), findsOneWidget);
  });

  testWidgets('the default surface, being narrow, does not', (tester) async {
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

    expect(find.byType(DesktopSidebar), findsNothing);
  });
}
