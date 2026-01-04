# ElevenLabsService Design for Storili

> Service interface design for integrating ElevenLabs Conversational AI into Storili.

## Overview

The `ElevenLabsService` wraps the `elevenlabs_agents` SDK and provides a clean interface for story playback. It converts SDK callbacks into a stream of `AgentEvent` objects that the `StoryNotifier` can process.

## File Structure

```
lib/
├── services/
│   └── elevenlabs_service.dart
├── models/
│   └── agent_event.dart
└── providers/
    └── story_provider.dart  (uses ElevenLabsService)
```

## AgentEvent Model

```dart
// lib/models/agent_event.dart

import 'dart:typed_data';

/// Events emitted by the ElevenLabs agent during a story session.
sealed class AgentEvent {
  const AgentEvent();
}

/// Scene transition requested by the agent.
class SceneChange extends AgentEvent {
  final String sceneName;
  const SceneChange(this.sceneName);
}

/// Action suggestions for the child to choose from.
class SuggestedActions extends AgentEvent {
  final List<String> actions;
  const SuggestedActions(this.actions);
}

/// Image generation requested with enriched prompt.
class GenerateImage extends AgentEvent {
  final String prompt;
  const GenerateImage(this.prompt);
}

/// Story session ended with summary.
class SessionEnded extends AgentEvent {
  final String summary;
  const SessionEnded(this.summary);
}

/// Agent started speaking (hide action cards).
class AgentStartedSpeaking extends AgentEvent {
  const AgentStartedSpeaking();
}

/// Agent stopped speaking (show action cards).
class AgentStoppedSpeaking extends AgentEvent {
  const AgentStoppedSpeaking();
}

/// User transcript received.
class UserTranscript extends AgentEvent {
  final String transcript;
  const UserTranscript(this.transcript);
}

/// Agent response text received.
class AgentResponse extends AgentEvent {
  final String text;
  const AgentResponse(this.text);
}

/// Connection status changed.
class ConnectionStatusChanged extends AgentEvent {
  final ElevenLabsConnectionStatus status;
  const ConnectionStatusChanged(this.status);
}

/// Error occurred.
class AgentError extends AgentEvent {
  final String message;
  final String? context;
  const AgentError(this.message, [this.context]);
}

/// Connection status enum (mirrors SDK).
enum ElevenLabsConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
}
```

## Client Tools

```dart
// lib/services/elevenlabs_tools.dart

import 'dart:async';
import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import '../models/agent_event.dart';

/// Tool: change_scene
/// Called by agent to transition to a new scene.
class ChangeSceneTool implements ClientTool {
  final StreamController<AgentEvent> _eventController;

  ChangeSceneTool(this._eventController);

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    final sceneName = parameters['scene_name'] as String? ?? '';
    _eventController.add(SceneChange(sceneName));
    return null;
  }
}

/// Tool: suggest_actions
/// Called by agent to provide action card suggestions.
class SuggestActionsTool implements ClientTool {
  final StreamController<AgentEvent> _eventController;

  SuggestActionsTool(this._eventController);

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    final actionsRaw = parameters['actions'];
    final actions = (actionsRaw as List<dynamic>?)
        ?.map((e) => e.toString())
        .take(3)
        .toList() ?? [];
    _eventController.add(SuggestedActions(actions));
    return null;
  }
}

/// Tool: generate_image
/// Called by agent to request image generation.
class GenerateImageTool implements ClientTool {
  final StreamController<AgentEvent> _eventController;

  GenerateImageTool(this._eventController);

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    final prompt = parameters['prompt'] as String? ?? '';
    _eventController.add(GenerateImage(prompt));
    return null;
  }
}

/// Tool: session_end
/// Called by agent when story is complete.
class SessionEndTool implements ClientTool {
  final StreamController<AgentEvent> _eventController;

  SessionEndTool(this._eventController);

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    final summary = parameters['summary'] as String? ?? '';
    _eventController.add(SessionEnded(summary));
    return null;
  }
}
```

## ElevenLabsService

```dart
// lib/services/elevenlabs_service.dart

import 'dart:async';
import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:flutter/foundation.dart';
import '../models/agent_event.dart';
import 'elevenlabs_tools.dart';

/// Service for managing ElevenLabs Conversational AI sessions.
///
/// Wraps the ConversationClient and provides a stream-based interface
/// for story playback.
class ElevenLabsService extends ChangeNotifier {
  ConversationClient? _client;
  final StreamController<AgentEvent> _eventController =
      StreamController<AgentEvent>.broadcast();

  /// Stream of events from the agent.
  Stream<AgentEvent> get events => _eventController.stream;

  /// Current connection status.
  ElevenLabsConnectionStatus get status => _mapStatus(_client?.status);

  /// Whether the agent is currently speaking.
  bool get isAgentSpeaking => _client?.isSpeaking ?? false;

  /// Whether the microphone is muted.
  bool get isMuted => _client?.isMuted ?? false;

  /// Initialize the service and create the conversation client.
  void initialize() {
    _client = ConversationClient(
      clientTools: {
        'change_scene': ChangeSceneTool(_eventController),
        'suggest_actions': SuggestActionsTool(_eventController),
        'generate_image': GenerateImageTool(_eventController),
        'session_end': SessionEndTool(_eventController),
      },
      callbacks: _createCallbacks(),
    );

    _client!.addListener(_onClientChanged);
  }

  /// Callbacks for conversation events.
  ConversationCallbacks _createCallbacks() {
    return ConversationCallbacks(
      onConnect: ({required conversationId}) {
        _eventController.add(
          const ConnectionStatusChanged(ElevenLabsConnectionStatus.connected),
        );
      },
      onDisconnect: (details) {
        _eventController.add(
          const ConnectionStatusChanged(ElevenLabsConnectionStatus.disconnected),
        );
      },
      onStatusChange: ({required status}) {
        _eventController.add(ConnectionStatusChanged(_mapStatus(status)));
      },
      onError: (message, [context]) {
        _eventController.add(AgentError(message, context));
      },
      onMessage: ({required message, required source}) {
        if (source == Role.user) {
          _eventController.add(UserTranscript(message));
        } else {
          _eventController.add(AgentResponse(message));
        }
      },
      onModeChange: ({required mode}) {
        if (mode == ConversationMode.speaking) {
          _eventController.add(const AgentStartedSpeaking());
        } else {
          _eventController.add(const AgentStoppedSpeaking());
        }
      },
      onInterruption: (event) {
        // Barge-in detected - agent will stop speaking
        _eventController.add(const AgentStoppedSpeaking());
      },
      onUnhandledClientToolCall: (toolCall) {
        debugPrint('Unhandled tool call: ${toolCall.toolName}');
      },
    );
  }

  void _onClientChanged() {
    notifyListeners();
  }

  /// Start a story session.
  ///
  /// [storyId] - The story to play (e.g., 'three-little-pigs')
  /// [resumeSummary] - Optional summary for resuming a previous session
  /// [childName] - Optional child's name for personalization
  Future<void> startStory({
    required String storyId,
    String? resumeSummary,
    String? childName,
  }) async {
    if (_client == null) {
      initialize();
    }

    // Get conversation token from backend
    final token = await _getConversationToken(storyId);

    // Build dynamic variables for personalization
    final dynamicVariables = <String, String>{};
    if (childName != null) {
      dynamicVariables['child_name'] = childName;
    }
    if (resumeSummary != null) {
      dynamicVariables['resume_summary'] = resumeSummary;
    }

    // Start the session
    await _client!.startSession(
      conversationToken: token,
      overrides: ConversationOverrides(
        agent: AgentOverrides(
          firstMessage: resumeSummary != null
              ? null // Agent will use resume context
              : 'Hello! Ready for a story adventure?',
        ),
      ),
      dynamicVariables: dynamicVariables,
    );
  }

  /// End the current session.
  Future<void> endSession() async {
    await _client?.endSession();
  }

  /// Send a text message to the agent (used for card taps).
  void sendMessage(String text) {
    _client?.sendUserMessage(text);
  }

  /// Toggle microphone mute state.
  Future<void> toggleMute() async {
    await _client?.toggleMute();
  }

  /// Set microphone mute state.
  Future<void> setMuted(bool muted) async {
    await _client?.setMicMuted(muted);
  }

  /// Get a conversation token from the backend.
  Future<String> _getConversationToken(String storyId) async {
    // TODO: Implement actual backend call
    // For now, throw unimplemented
    throw UnimplementedError(
      'Backend endpoint for conversation tokens not yet implemented. '
      'Need to call POST /api/conversation-token with agent_id.',
    );
  }

  /// Map SDK status to our enum.
  ElevenLabsConnectionStatus _mapStatus(ConversationStatus? status) {
    return switch (status) {
      ConversationStatus.connecting => ElevenLabsConnectionStatus.connecting,
      ConversationStatus.connected => ElevenLabsConnectionStatus.connected,
      ConversationStatus.disconnecting => ElevenLabsConnectionStatus.disconnecting,
      _ => ElevenLabsConnectionStatus.disconnected,
    };
  }

  @override
  void dispose() {
    _client?.removeListener(_onClientChanged);
    _client?.dispose();
    _eventController.close();
    super.dispose();
  }
}
```

## Riverpod Provider

```dart
// lib/providers/services.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/elevenlabs_service.dart';

/// Provider for the ElevenLabs service.
final elevenLabsServiceProvider = Provider<ElevenLabsService>((ref) {
  final service = ElevenLabsService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});
```

## Usage in StoryNotifier

```dart
// lib/providers/story_provider.dart (partial)

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_event.dart';
import '../services/elevenlabs_service.dart';
import '../services/image_service.dart';
import 'services.dart';

class StoryState {
  final String storyId;
  final String currentScene;
  final List<String> suggestedActions;
  final bool isAgentSpeaking;
  final ElevenLabsConnectionStatus connectionStatus;
  final String? currentImageUrl;
  final String? sessionSummary;
  final bool isLoading;
  final String? error;

  const StoryState({
    required this.storyId,
    this.currentScene = 'cottage',
    this.suggestedActions = const [],
    this.isAgentSpeaking = false,
    this.connectionStatus = ElevenLabsConnectionStatus.disconnected,
    this.currentImageUrl,
    this.sessionSummary,
    this.isLoading = false,
    this.error,
  });

  StoryState copyWith({
    String? storyId,
    String? currentScene,
    List<String>? suggestedActions,
    bool? isAgentSpeaking,
    ElevenLabsConnectionStatus? connectionStatus,
    String? currentImageUrl,
    String? sessionSummary,
    bool? isLoading,
    String? error,
  }) {
    return StoryState(
      storyId: storyId ?? this.storyId,
      currentScene: currentScene ?? this.currentScene,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      isAgentSpeaking: isAgentSpeaking ?? this.isAgentSpeaking,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      currentImageUrl: currentImageUrl ?? this.currentImageUrl,
      sessionSummary: sessionSummary ?? this.sessionSummary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class StoryNotifier extends StateNotifier<StoryState> {
  final ElevenLabsService _elevenLabs;
  // final ImageService _imageService; // TODO: Add when implementing
  StreamSubscription<AgentEvent>? _eventSubscription;

  StoryNotifier(this._elevenLabs, String storyId)
      : super(StoryState(storyId: storyId)) {
    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    _eventSubscription = _elevenLabs.events.listen(_handleEvent);
  }

  void _handleEvent(AgentEvent event) {
    switch (event) {
      case SceneChange(sceneName: final scene):
        state = state.copyWith(currentScene: scene);
        // TODO: Trigger image generation for new scene

      case SuggestedActions(actions: final actions):
        state = state.copyWith(suggestedActions: actions);

      case GenerateImage(prompt: final prompt):
        _generateImage(prompt);

      case SessionEnded(summary: final summary):
        state = state.copyWith(sessionSummary: summary);
        // TODO: Navigate to celebration screen

      case AgentStartedSpeaking():
        state = state.copyWith(
          isAgentSpeaking: true,
          suggestedActions: [], // Hide cards while speaking
        );

      case AgentStoppedSpeaking():
        state = state.copyWith(isAgentSpeaking: false);

      case ConnectionStatusChanged(status: final status):
        state = state.copyWith(connectionStatus: status);

      case AgentError(message: final msg, context: final ctx):
        state = state.copyWith(error: '$msg${ctx != null ? ': $ctx' : ''}');

      case UserTranscript() || AgentResponse():
        // Could log these for debugging
        break;
    }
  }

  Future<void> startStory({String? resumeSummary}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _elevenLabs.startStory(
        storyId: state.storyId,
        resumeSummary: resumeSummary,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> endStory() async {
    await _elevenLabs.endSession();
  }

  /// Called when child taps an action card.
  void selectAction(String action) {
    _elevenLabs.sendMessage(action);
    state = state.copyWith(suggestedActions: []); // Clear cards
  }

  /// Called when parent types custom message via "Something else..." card.
  void sendCustomMessage(String message) {
    _elevenLabs.sendMessage(message);
  }

  Future<void> _generateImage(String prompt) async {
    // TODO: Call ImageService.generateImage(prompt)
    // state = state.copyWith(currentImageUrl: url);
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for story state.
final storyProvider =
    StateNotifierProvider.family<StoryNotifier, StoryState, String>(
  (ref, storyId) {
    final elevenLabs = ref.watch(elevenLabsServiceProvider);
    return StoryNotifier(elevenLabs, storyId);
  },
);
```

## Backend Token Endpoint

The app needs a backend to generate conversation tokens. Options:

### Option 1: Firebase Cloud Functions

```typescript
// functions/src/index.ts
import * as functions from 'firebase-functions';
import fetch from 'node-fetch';

const ELEVENLABS_API_KEY = functions.config().elevenlabs.api_key;

export const getConversationToken = functions.https.onCall(async (data) => {
  const { agentId, userId } = data;

  const response = await fetch(
    `https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=${agentId}`,
    {
      headers: {
        'xi-api-key': ELEVENLABS_API_KEY,
      },
    }
  );

  const result = await response.json();
  return { token: result.signed_url };
});
```

### Option 2: Simple Express Server

```typescript
// server/index.ts
import express from 'express';

const app = express();
const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY;

app.post('/api/conversation-token', async (req, res) => {
  const { agent_id } = req.body;

  const response = await fetch(
    `https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=${agent_id}`,
    {
      headers: { 'xi-api-key': ELEVENLABS_API_KEY },
    }
  );

  const { signed_url } = await response.json();
  res.json({ token: signed_url });
});
```

## Testing Strategy

### Unit Tests

```dart
// test/services/elevenlabs_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/services/elevenlabs_tools.dart';

void main() {
  group('ChangeSceneTool', () {
    test('emits SceneChange event with scene name', () async {
      final controller = StreamController<AgentEvent>.broadcast();
      final tool = ChangeSceneTool(controller);

      final events = <AgentEvent>[];
      controller.stream.listen(events.add);

      await tool.execute({'scene_name': 'straw_house'});

      expect(events, hasLength(1));
      expect(events.first, isA<SceneChange>());
      expect((events.first as SceneChange).sceneName, 'straw_house');

      await controller.close();
    });
  });

  group('SuggestActionsTool', () {
    test('emits SuggestedActions with up to 3 actions', () async {
      final controller = StreamController<AgentEvent>.broadcast();
      final tool = SuggestActionsTool(controller);

      final events = <AgentEvent>[];
      controller.stream.listen(events.add);

      await tool.execute({
        'actions': ['Hide', 'Run', 'Call for help', 'Extra action']
      });

      expect(events, hasLength(1));
      expect(events.first, isA<SuggestedActions>());
      final actions = (events.first as SuggestedActions).actions;
      expect(actions, hasLength(3)); // Max 3
      expect(actions, ['Hide', 'Run', 'Call for help']);

      await controller.close();
    });
  });
}
```

### Integration Tests (with Mocked SDK)

```dart
// test/integration/story_flow_test.dart

// Mock ConversationClient and test full story flow
// Verify events trigger correct state changes
```

## Next Steps for Implementation

1. **Add dependencies** to `pubspec.yaml`:
   ```yaml
   elevenlabs_agents: ^0.3.0
   ```

2. **Create files**:
   - `lib/models/agent_event.dart`
   - `lib/services/elevenlabs_tools.dart`
   - `lib/services/elevenlabs_service.dart`
   - `lib/providers/services.dart`
   - Update `lib/providers/story_provider.dart`

3. **Platform setup**:
   - Add microphone permissions (iOS Info.plist, Android Manifest)
   - Set minimum SDK versions

4. **Backend**:
   - Choose platform (Firebase, Cloudflare, etc.)
   - Implement token endpoint
   - Update `_getConversationToken()` in service

5. **ElevenLabs Dashboard**:
   - Create agent for Three Little Pigs
   - Configure client tools (change_scene, etc.)
   - Set up system prompt and knowledge base

6. **Testing**:
   - Write unit tests for tools
   - Write integration tests with mocked SDK
   - Test on physical devices (iOS + Android)

---

## Important Update (2026-01-05)

**Client tools via API:** When deploying agents via the ElevenLabs API (not dashboard), client tools must be placed in `conversation_config.agent.prompt.tools[]` with `type: "client"`. See `docs/research/2026-01-05-elevenlabs-client-tools-fix.md` for the correct JSON schema format.

**LLM recommendation:** Use `gpt-4o-mini` for reliable tool calling. The `glm-45-air-fp8` model caused immediate disconnects.
