import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/screens/welcome_screen.dart';
import 'test_helpers.dart';

void main() {
  setUp(() {
    // rootBundle caches asset loads (including in-flight Futures) across the whole test
    // process, but the mock platform-channel handler backing it gets torn down between tests -
    // without clearing this, a second test in this file can inherit a Future from a previous
    // test that will now never resolve, silently starving WelcomeScreen's debug-backend load.
    rootBundle.clear();
  });

  testWidgets('WelcomeScreen renders the identity and both entry points',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrapForTest(const WelcomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Karata'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Create account'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Log in'), findsOneWidget);
  });

  testWidgets(
      'the debug backend picker (test runs are debug builds) defaults to the '
      'configured backend and can switch to a custom URL', (WidgetTester tester) async {
    await tester.pumpWidget(wrapForTest(const WelcomeScreen()));
    await tester.pumpAndSettle();

    // assets/debug_backend_config.yml's one entry shares its URL with defaultServerUrl(), so
    // it should be auto-selected - the free-text field stays hidden until "Custom URL..." is
    // explicitly chosen.
    expect(find.textContaining('Debug backend: Cloud Run (karata0)'), findsOneWidget);
    expect(find.text('Server base URL'), findsNothing);

    await tester.tap(find.byIcon(Icons.dns_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom URL...').last);
    await tester.pumpAndSettle();

    expect(find.text('Server base URL'), findsOneWidget);
  });
}
