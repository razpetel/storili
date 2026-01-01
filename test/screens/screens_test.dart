import 'dart:async';
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
        const MaterialApp(home: CelebrationScreen(storyId: 'test-story')),
      );
      expect(find.text('Congratulations'), findsOneWidget);
    });
  });
}

class _MockElevenLabsService implements ElevenLabsService {
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
