import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/screens/home_screen.dart';
import 'package:storili/screens/story_screen.dart';
import 'package:storili/screens/settings_screen.dart';
import 'package:storili/screens/celebration_screen.dart';

void main() {
  group('Screens', () {
    testWidgets('HomeScreen renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      expect(find.text('Storili'), findsOneWidget);
    });

    testWidgets('StoryScreen renders with storyId', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StoryScreen(storyId: 'test-story')),
      );
      expect(find.text('test-story'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('CelebrationScreen renders with storyId', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CelebrationScreen(storyId: 'test-story')),
      );
      expect(find.text('Congratulations'), findsOneWidget);
    });
  });
}
