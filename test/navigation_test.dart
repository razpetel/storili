import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/app/app.dart';
import 'package:storili/app/router.dart';

void main() {
  group('Navigation', () {
    setUp(() {
      // Reset router to initial location before each test
      AppRouter.router.go('/');
    });

    testWidgets('settings icon navigates to settings', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: StoriliApp()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('back from settings returns to home', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: StoriliApp()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Storili'), findsOneWidget);
    });
  });
}
