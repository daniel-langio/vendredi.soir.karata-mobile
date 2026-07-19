import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/screens/config_screen.dart';

void main() {
  testWidgets('ConfigScreen renders all input fields and the connection button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: ConfigScreen(),
    ));

    // Verify the screen title / header text
    expect(find.text('Poker Client Config'), findsOneWidget);
    expect(find.text('Configure Connection Details'), findsOneWidget);

    // Verify fields exist
    expect(find.byType(TextFormField), findsNWidgets(2)); // URL and Token fields
    expect(find.text('Server Base URL'), findsOneWidget);
    expect(find.text('JWT Auth Token'), findsOneWidget);

    // Verify "Decoded JWT Info" card is present
    expect(find.text('Decoded JWT Info (Realtime)'), findsOneWidget);

    // Verify "Connect to Lobby" button is present
    expect(find.text('Connect to Lobby'), findsOneWidget);
  });
}
