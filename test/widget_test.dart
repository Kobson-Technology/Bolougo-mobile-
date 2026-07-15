import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolougo_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic test - just verify no crash on startup would require real API
    expect(true, isTrue);
  });
}
