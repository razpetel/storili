import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/screens/home_screen.dart';
import 'package:storili/widgets/capy_welcome.dart';
import 'package:storili/widgets/story_card.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('displays CapyWelcome', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.byType(CapyWelcome), findsOneWidget);
    });

    testWidgets('displays StoryCard for Three Little Pigs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.byType(StoryCard), findsOneWidget);
      expect(find.text('The Three Little Pigs'), findsOneWidget);
    });

    testWidgets('displays settings button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
