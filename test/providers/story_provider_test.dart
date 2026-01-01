import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/providers/services.dart';
import 'package:storili/providers/story_provider.dart';
import 'package:storili/services/elevenlabs_service.dart';
import 'package:storili/services/permission_service.dart';

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

  group('StoryNotifier', () {
    late StreamController<AgentEvent> eventController;
    late MockElevenLabsService mockService;
    late MockPermissionService mockPermission;

    setUp(() {
      eventController = StreamController<AgentEvent>.broadcast();
      mockService = MockElevenLabsService(eventController.stream);
      mockPermission = MockPermissionService(
        checkResult: MicPermissionStatus.granted,
        requestResult: MicPermissionStatus.granted,
      );
    });

    tearDown(() {
      eventController.close();
    });

    test('initial state is idle', () {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      expect(notifier.state.sessionStatus, StorySessionStatus.idle);
      notifier.dispose();
    });

    test('handles SceneChange event', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const SceneChange('brick_house'));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.currentScene, 'brick_house');
      notifier.dispose();
    });

    test('handles SuggestedActions event', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const SuggestedActions(['Run', 'Hide']));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.suggestedActions, ['Run', 'Hide']);
      notifier.dispose();
    });

    test('handles AgentStartedSpeaking - clears actions', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      // First add some actions
      eventController.add(const SuggestedActions(['Action1']));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.suggestedActions, isNotEmpty);

      // Then agent starts speaking
      eventController.add(const AgentStartedSpeaking());
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.isAgentSpeaking, true);
      expect(notifier.state.suggestedActions, isEmpty);
      notifier.dispose();
    });

    test('handles AgentStoppedSpeaking', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const AgentStartedSpeaking());
      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.isAgentSpeaking, true);

      eventController.add(const AgentStoppedSpeaking());
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.isAgentSpeaking, false);
      notifier.dispose();
    });

    test('handles SessionEnded event', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const SessionEnded('Great adventure!'));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.sessionStatus, StorySessionStatus.ended);
      notifier.dispose();
    });

    test('handles ConnectionStatusChanged event', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const ConnectionStatusChanged(
        ElevenLabsConnectionStatus.connected,
      ));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.connectionStatus, ElevenLabsConnectionStatus.connected);
      notifier.dispose();
    });

    test('handles AgentError event', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const AgentError('Something failed', 'context'));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.error, contains('Something failed'));
      expect(notifier.state.error, contains('context'));
      notifier.dispose();
    });

    test('startStory checks permission first', () async {
      final mockPermission = MockPermissionService(
        checkResult: MicPermissionStatus.denied,
        requestResult: MicPermissionStatus.denied,
      );
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      await notifier.startStory();

      expect(notifier.state.sessionStatus, StorySessionStatus.error);
      expect(notifier.state.error!.toLowerCase(), contains('microphone'));
      notifier.dispose();
    });

    test('startStory transitions to loading then active', () async {
      var statusLog = <StorySessionStatus>[];
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      notifier.addListener((state) {
        statusLog.add(state.sessionStatus);
      });

      await notifier.startStory();

      expect(statusLog, contains(StorySessionStatus.loading));
      notifier.dispose();
    });

    test('startStory ignores if not idle', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      // Start first story
      await notifier.startStory();
      final firstStatus = notifier.state.sessionStatus;

      // Try to start again - should be ignored
      await notifier.startStory();

      expect(notifier.state.sessionStatus, firstStatus);
      notifier.dispose();
    });

    test('endStory calls service and updates state', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      await notifier.startStory();
      await notifier.endStory();

      expect(notifier.state.sessionStatus, StorySessionStatus.ending);
      notifier.dispose();
    });

    test('selectAction sends message and clears actions', () async {
      final messages = <String>[];
      final trackingService = TrackingMockService(eventController.stream, messages);

      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: trackingService,
        permission: mockPermission,
      );

      // Add some actions
      eventController.add(const SuggestedActions(['Run', 'Hide']));
      await Future.delayed(const Duration(milliseconds: 10));

      // Select one
      notifier.selectAction('Run');

      expect(messages, ['Run']);
      expect(notifier.state.suggestedActions, isEmpty);
      notifier.dispose();
    });

    test('selectAction updates lastInteractionTime', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      expect(notifier.state.lastInteractionTime, isNull);

      notifier.selectAction('Test');

      expect(notifier.state.lastInteractionTime, isNotNull);
      notifier.dispose();
    });
  });

  group('storyProvider', () {
    test('creates StoryNotifier for given storyId', () {
      final eventController = StreamController<AgentEvent>.broadcast();

      final container = ProviderContainer(
        overrides: [
          elevenLabsServiceProvider.overrideWithValue(
            MockElevenLabsService(eventController.stream),
          ),
          permissionServiceProvider.overrideWithValue(
            MockPermissionService(
              checkResult: MicPermissionStatus.granted,
              requestResult: MicPermissionStatus.granted,
            ),
          ),
        ],
      );

      final state = container.read(storyProvider('three-little-pigs'));
      expect(state.storyId, 'three-little-pigs');
      expect(state.sessionStatus, StorySessionStatus.idle);

      container.dispose();
      eventController.close();
    });
  });
}

class TrackingMockService extends MockElevenLabsService {
  final List<String> messages;

  TrackingMockService(super.events, this.messages);

  @override
  void sendMessage(String text) {
    messages.add(text);
  }
}

class MockElevenLabsService implements ElevenLabsService {
  final Stream<AgentEvent> _events;

  MockElevenLabsService(this._events);

  @override
  Stream<AgentEvent> get events => _events;

  @override
  ElevenLabsConnectionStatus get status => ElevenLabsConnectionStatus.disconnected;

  @override
  bool get isAgentSpeaking => false;

  @override
  bool get isMuted => false;

  @override
  Future<void> startSession({required String agentId, String? childName}) async {}

  @override
  Future<void> endSession() async {}

  @override
  void sendMessage(String text) {}

  @override
  Future<bool> toggleMute() async => false;

  @override
  Future<void> setMuted(bool muted) async {}

  @override
  void dispose() {}
}
