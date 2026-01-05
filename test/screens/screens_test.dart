import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/providers/services.dart';
import 'package:storili/screens/home_screen.dart';
import 'package:storili/screens/story_screen.dart';
import 'package:storili/screens/settings_screen.dart';
import 'package:storili/screens/celebration_screen.dart';
import 'package:storili/services/elevenlabs_service.dart';
import 'package:storili/services/image_cache.dart' as image_cache;
import 'package:storili/services/image_service.dart';
import 'package:storili/services/permission_service.dart';

void main() {
  group('Screens', () {
    testWidgets('HomeScreen renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      expect(find.text('Storili'), findsOneWidget);
    });

    testWidgets('StoryScreen renders with storyId', (tester) async {
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
          child: const MaterialApp(home: StoryScreen(storyId: 'test-story')),
        ),
      );
      expect(find.text('Story: test-story'), findsOneWidget);

      await eventController.close();
    });

    testWidgets('SettingsScreen renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('CelebrationScreen renders with storyId', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CelebrationScreen(storyId: 'test-story', summary: 'A great adventure')),
      );
      expect(find.text('Congratulations'), findsOneWidget);
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

  @override
  Future<Uint8List> textToSpeech(String text) async {
    return Uint8List.fromList([]);
  }
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
