// Basic smoke test for the Callout app.
//
// Run with: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:call_out/main.dart';

void main() {
  testWidgets('App boots to the main scaffold with bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CalloutApp());
    await tester.pumpAndSettle();

    // Bottom navigation is present with all five tabs.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Create'), findsWidgets);
    expect(find.text('Challenges'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Redeem'), findsWidgets);

    // Switch to Friends and check the demo friends list renders.
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(find.text('Guy'), findsOneWidget);
  });
}
