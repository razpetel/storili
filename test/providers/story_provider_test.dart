import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/providers/story_provider.dart';

void main() {
  group('StorySessionStatus', () {
    test('has all expected values', () {
      expect(StorySessionStatus.values, containsAll([
        StorySessionStatus.idle,
        StorySessionStatus.loading,
        StorySessionStatus.active,
        StorySessionStatus.ending,
        StorySessionStatus.ended,
        StorySessionStatus.error,
      ]));
    });
  });

  group('StoryState', () {
    test('has correct default values', () {
      const state = StoryState(storyId: 'test-story');

      expect(state.storyId, 'test-story');
      expect(state.sessionStatus, StorySessionStatus.idle);
      expect(state.currentScene, 'cottage');
      expect(state.suggestedActions, isEmpty);
      expect(state.isAgentSpeaking, false);
      expect(state.connectionStatus, ElevenLabsConnectionStatus.disconnected);
      expect(state.error, isNull);
      expect(state.lastInteractionTime, isNull);
    });

    test('copyWith creates new instance with updated values', () {
      const original = StoryState(storyId: 'test');
      final updated = original.copyWith(
        sessionStatus: StorySessionStatus.active,
        currentScene: 'straw_house',
        suggestedActions: ['Run', 'Hide'],
        isAgentSpeaking: true,
      );

      // Original unchanged
      expect(original.sessionStatus, StorySessionStatus.idle);
      expect(original.currentScene, 'cottage');

      // Updated has new values
      expect(updated.storyId, 'test'); // Preserved
      expect(updated.sessionStatus, StorySessionStatus.active);
      expect(updated.currentScene, 'straw_house');
      expect(updated.suggestedActions, ['Run', 'Hide']);
      expect(updated.isAgentSpeaking, true);
    });

    test('copyWith can clear error with empty string', () {
      final withError = const StoryState(storyId: 'test').copyWith(
        error: 'Something went wrong',
      );
      expect(withError.error, 'Something went wrong');

      final cleared = withError.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });
  });
}
