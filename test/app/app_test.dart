import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/app/app.dart';

void main() {
  group('StoriliApp', () {
    testWidgets('renders MaterialApp with router', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: StoriliApp()),
      );
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('shows HomeScreen at start', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: StoriliApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Storili'), findsOneWidget);
    });
  });
}
