import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/story_info.dart';

void main() {
  group('StoryInfo', () {
    test('can be instantiated', () {
      const story = StoryInfo(
        id: 'test-story',
        title: 'Test Story',
        primaryColor: Color(0xFFFFFFFF),
        secondaryColor: Color(0xFF000000),
      );

      expect(story.id, 'test-story');
      expect(story.title, 'Test Story');
    });
  });

  group('availableStories', () {
    test('contains three-little-pigs', () {
      expect(availableStories.length, 1);
      expect(availableStories.first.id, 'three-little-pigs');
    });

    test('three-little-pigs has correct title', () {
      final pigs = availableStories.first;
      expect(pigs.title, 'The Three Little Pigs');
    });
  });
}
