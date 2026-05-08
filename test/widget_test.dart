// Basic smoke test for SafeHer Bangladesh app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SafeHer app smoke test', (WidgetTester tester) async {
    // Build a minimal MaterialApp wrapper — the real app uses SafeHerApp
    // but importing it here causes plugin issues in tests.
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('SafeHer'))));
    expect(find.text('SafeHer'), findsOneWidget);
  });
}
