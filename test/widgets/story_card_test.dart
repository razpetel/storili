import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/story_info.dart';
import 'package:storili/widgets/story_card.dart';

void main() {
  const testStory = StoryInfo(
    id: 'test-story',
    title: 'Test Story Title',
    primaryColor: Color(0xFFF5E6D3),
    secondaryColor: Color(0xFF8B7355),
  );

  group('StoryCard', () {
    testWidgets('displays story title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCard(
              story: testStory,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Story Title'), findsOneWidget);
    });

    testWidgets('displays play icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCard(
              story: testStory,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCard(
              story: testStory,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StoryCard));
      expect(tapped, isTrue);
    });
  });
}
