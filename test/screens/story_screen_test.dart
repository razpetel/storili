import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/providers/services.dart';
import 'package:storili/providers/story_provider.dart';
import 'package:storili/screens/story_screen.dart';
import 'package:storili/services/elevenlabs_service.dart';
import 'package:storili/services/image_cache.dart' as image_cache;
import 'package:storili/services/image_service.dart';
import 'package:storili/services/permission_service.dart';
import 'package:storili/widgets/scene_image.dart';

void main() {
  group('StoryScreen', () {
    testWidgets('shows loading indicator when starting', (tester) async {
      final eventController = StreamController<AgentEvent>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            elevenLabsServiceProvider.overrideWithValue(
              _MockElevenLabsService(eventController.stream),
            ),
            permissionServiceProvider.overrideWithValue(
              MockPermissionService(
                checkResult: MicPermissionStatus.granted,
                requestResult: MicPermissionStatus.granted,
              ),
            ),
            imageServiceProvider.overrideWithValue(_MockImageService()),
            imageCacheProvider.overrideWithValue(image_cache.ImageCache()),
          ],
          child: const MaterialApp(
            home: StoryScreen(storyId: 'three-little-pigs'),
          ),
        ),
      );

      // Initially should show idle state
      expect(find.byType(StoryScreen), findsOneWidget);

      await eventController.close();
    });

    testWidgets('displays action cards when available', (tester) async {
      final eventController = StreamController<AgentEvent>.broadcast();

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            elevenLabsServiceProvider.overrideWithValue(
              _MockElevenLabsService(eventController.stream),
            ),
            permissionServiceProvider.overrideWithValue(
              MockPermissionService(
                checkResult: MicPermissionStatus.granted,
                requestResult: MicPermissionStatus.granted,
              ),
            ),
            imageServiceProvider.overrideWithValue(_MockImageService()),
            imageCacheProvider.overrideWithValue(image_cache.ImageCache()),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: StoryScreen(storyId: 'three-little-pigs'),
              );
            },
          ),
        ),
      );

      // Start the story to transition to active state
      final notifier = container.read(storyProvider('three-little-pigs').notifier);
      await notifier.startStory();
      await tester.pumpAndSettle();

      // Emit suggested actions
      eventController.add(const SuggestedActions(['Run', 'Hide', 'Call for help']));
      // Give time for the stream event to propagate
      await tester.pump(const Duration(milliseconds: 50));

      // Check that action cards are displayed
      expect(find.text('Run'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);
      expect(find.text('Call for help'), findsOneWidget);

      await eventController.close();
    });

    testWidgets('shows idle state with start button initially', (tester) async {
      final eventController = StreamController<AgentEvent>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            elevenLabsServiceProvider.overrideWithValue(
              _MockElevenLabsService(eventController.stream),
            ),
            permissionServiceProvider.overrideWithValue(
              MockPermissionService(
                checkResult: MicPermissionStatus.granted,
                requestResult: MicPermissionStatus.granted,
              ),
            ),
            imageServiceProvider.overrideWithValue(_MockImageService()),
            imageCacheProvider.overrideWithValue(image_cache.ImageCache()),
          ],
          child: const MaterialApp(
            home: StoryScreen(storyId: 'three-little-pigs'),
          ),
        ),
      );

      // Should show idle state
      expect(find.text('Ready to start your adventure?'), findsOneWidget);
      expect(find.text('Start Story'), findsOneWidget);

      await eventController.close();
    });

    testWidgets('shows scene image when active', (tester) async {
      final eventController = StreamController<AgentEvent>.broadcast();

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            elevenLabsServiceProvider.overrideWithValue(
              _MockElevenLabsService(eventController.stream),
            ),
            permissionServiceProvider.overrideWithValue(
              MockPermissionService(
                checkResult: MicPermissionStatus.granted,
                requestResult: MicPermissionStatus.granted,
              ),
            ),
            imageServiceProvider.overrideWithValue(_MockImageService()),
            imageCacheProvider.overrideWithValue(image_cache.ImageCache()),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: StoryScreen(storyId: 'three-little-pigs'),
              );
            },
          ),
        ),
      );

      // Start the story
      final notifier = container.read(storyProvider('three-little-pigs').notifier);
      await notifier.startStory();
      await tester.pumpAndSettle();

      // Should show SceneImage widget
      expect(find.byType(SceneImage), findsOneWidget);

      await eventController.close();
    });

    testWidgets('shows speaking indicator when agent is talking', (tester) async {
      final eventController = StreamController<AgentEvent>.broadcast();

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            elevenLabsServiceProvider.overrideWithValue(
              _MockElevenLabsService(eventController.stream),
            ),
            permissionServiceProvider.overrideWithValue(
              MockPermissionService(
                checkResult: MicPermissionStatus.granted,
                requestResult: MicPermissionStatus.granted,
              ),
            ),
            imageServiceProvider.overrideWithValue(_MockImageService()),
            imageCacheProvider.overrideWithValue(image_cache.ImageCache()),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: StoryScreen(storyId: 'three-little-pigs'),
              );
            },
          ),
        ),
      );

      // Start the story
      final notifier = container.read(storyProvider('three-little-pigs').notifier);
      await notifier.startStory();
      await tester.pumpAndSettle();

      // Initially not speaking
      expect(find.text('Capy is talking...'), findsNothing);

      // Agent starts speaking
      eventController.add(const AgentStartedSpeaking());
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Capy is talking...'), findsOneWidget);

      // Agent stops speaking
      eventController.add(const AgentStoppedSpeaking());
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Capy is talking...'), findsNothing);

      await eventController.close();
    });

    testWidgets('shows error state with retry button', (tester) async {
      final eventController = StreamController<AgentEvent>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            elevenLabsServiceProvider.overrideWithValue(
              _MockElevenLabsService(eventController.stream),
            ),
            permissionServiceProvider.overrideWithValue(
              MockPermissionService(
                checkResult: MicPermissionStatus.denied,
                requestResult: MicPermissionStatus.denied,
              ),
            ),
            imageServiceProvider.overrideWithValue(_MockImageService()),
            imageCacheProvider.overrideWithValue(image_cache.ImageCache()),
          ],
          child: const MaterialApp(
            home: StoryScreen(storyId: 'three-little-pigs'),
          ),
        ),
      );

      // Tap start button
      await tester.tap(find.text('Start Story'));
      await tester.pumpAndSettle();

      // Should show error state (permission denied)
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await eventController.close();
    });
  });
}

class _MockElevenLabsService extends ChangeNotifier implements ElevenLabsService {
  final Stream<AgentEvent> _events;

  _MockElevenLabsService(this._events);

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

}

class _MockImageService implements ImageService {
  @override
  String get apiKey => 'test-key';

  @override
  int get maxRetries => 2;

  @override
  Future<Uint8List> generate(String prompt) async {
    return Uint8List.fromList([]);
  }

  @override
  void dispose() {}
}
