// test/screens/celebration_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/screens/celebration_screen.dart';

void main() {
  group('CelebrationScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CelebrationScreen(
              storyId: 'test-story',
              summary: 'Test summary',
            ),
          ),
        ),
      );

      expect(find.byType(CelebrationScreen), findsOneWidget);

      // Dispose timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('shows jingle phase initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CelebrationScreen(
              storyId: 'test-story',
              summary: 'Test summary',
            ),
          ),
        ),
      );

      // Should show "You did it!" text in jingle phase
      expect(find.text('You did it!'), findsOneWidget);

      // Dispose timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });
}
