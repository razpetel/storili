import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/providers/services.dart';
import 'package:storili/providers/story_provider.dart';
import 'package:storili/services/elevenlabs_service.dart';
import 'package:storili/services/image_cache.dart';
import 'package:storili/services/image_service.dart';
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
      expect(state.currentImageIndex, isNull);
      expect(state.imageCount, 0);
      expect(state.isImageLoading, false);
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

      // After endStory completes, status resets to idle for fresh restart
      expect(notifier.state.sessionStatus, StorySessionStatus.idle);
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

    test('GenerateImage event triggers image loading state', () async {
      // Use a slow mock that doesn't complete immediately
      final slowMockImageService = SlowMockImageService();
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: MockElevenLabsService(eventController.stream),
        permission: mockPermission,
        imageService: slowMockImageService,
        imageCache: ImageCache(),
      );

      await notifier.startStory();

      eventController.add(const GenerateImage('test prompt'));
      await Future.microtask(() {});

      expect(notifier.state.isImageLoading, isTrue);

      // Complete the slow operation before disposing
      slowMockImageService.completer.complete(Uint8List.fromList([1, 2, 3]));
      await Future.delayed(const Duration(milliseconds: 10));
      notifier.dispose();
    });

    test('successful image generation updates state', () async {
      final imageCache = ImageCache();
      final mockImageService = MockImageService(
        generateResult: Uint8List.fromList([1, 2, 3]),
      );

      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: MockElevenLabsService(eventController.stream),
        permission: mockPermission,
        imageService: mockImageService,
        imageCache: imageCache,
      );

      await notifier.startStory();

      eventController.add(const GenerateImage('test prompt'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isImageLoading, isFalse);
      expect(notifier.state.currentImageIndex, 0);
      expect(notifier.state.imageCount, 1);
      expect(imageCache.get(0), isNotNull);
      notifier.dispose();
    });

    test('failed image generation stops loading but keeps previous state', () async {
      final imageCache = ImageCache();
      final mockImageService = MockImageService(
        generateError: Exception('API error'),
      );

      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: MockElevenLabsService(eventController.stream),
        permission: mockPermission,
        imageService: mockImageService,
        imageCache: imageCache,
      );

      await notifier.startStory();

      eventController.add(const GenerateImage('test prompt'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isImageLoading, isFalse);
      expect(notifier.state.currentImageIndex, isNull);
      expect(notifier.state.imageCount, 0);
      notifier.dispose();
    });

    test('GenerateImage without imageService does nothing', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: MockElevenLabsService(eventController.stream),
        permission: mockPermission,
        // No imageService or imageCache
      );

      await notifier.startStory();

      eventController.add(const GenerateImage('test prompt'));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.isImageLoading, isFalse);
      expect(notifier.state.currentImageIndex, isNull);
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
          imageServiceProvider.overrideWithValue(
            MockImageService(),
          ),
          imageCacheProvider.overrideWithValue(
            ImageCache(),
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

class MockElevenLabsService extends ChangeNotifier implements ElevenLabsService {
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
  bool get isConnected => false;

  @override
  void initialize() {}

  @override
  Future<void> startStory({
    required String storyId,
    String? resumeSummary,
    String? childName,
  }) async {}

  @override
  Future<void> startWithPublicAgent({
    required String agentId,
    String? childName,
  }) async {}

  @override
  Future<void> endSession() async {}

  @override
  void sendMessage(String text) {}

  @override
  void sendContextualUpdate(String context) {}

  @override
  Future<void> toggleMute() async {}

  @override
  Future<void> setMuted(bool muted) async {}

  @override
  Future<Uint8List> textToSpeech(String text) async {
    return Uint8List.fromList([]);
  }
}

class MockImageService implements ImageService {
  final Uint8List? generateResult;
  final Exception? generateError;

  MockImageService({this.generateResult, this.generateError});

  @override
  String get apiKey => 'test-key';

  @override
  int get maxRetries => 2;

  @override
  Future<Uint8List> generate(String prompt) async {
    if (generateError != null) throw generateError!;
    return generateResult ?? Uint8List.fromList([]);
  }

  @override
  void dispose() {}
}

class SlowMockImageService implements ImageService {
  final Completer<Uint8List> completer = Completer<Uint8List>();

  @override
  String get apiKey => 'test-key';

  @override
  int get maxRetries => 2;

  @override
  Future<Uint8List> generate(String prompt) => completer.future;

  @override
  void dispose() {}
}
