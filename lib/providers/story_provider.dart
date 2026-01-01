import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_event.dart';
import '../services/elevenlabs_service.dart';
import '../services/permission_service.dart';
import 'services.dart';

/// Session status for story playback.
enum StorySessionStatus {
  idle,
  loading,
  active,
  ending,
  ended,
  error,
}

/// Immutable state for story playback.
class StoryState {
  final String storyId;
  final StorySessionStatus sessionStatus;
  final String currentScene;
  final List<String> suggestedActions;
  final bool isAgentSpeaking;
  final ElevenLabsConnectionStatus connectionStatus;
  final String? error;
  final DateTime? lastInteractionTime;

  const StoryState({
    required this.storyId,
    this.sessionStatus = StorySessionStatus.idle,
    this.currentScene = 'cottage',
    this.suggestedActions = const [],
    this.isAgentSpeaking = false,
    this.connectionStatus = ElevenLabsConnectionStatus.disconnected,
    this.error,
    this.lastInteractionTime,
  });

  StoryState copyWith({
    String? storyId,
    StorySessionStatus? sessionStatus,
    String? currentScene,
    List<String>? suggestedActions,
    bool? isAgentSpeaking,
    ElevenLabsConnectionStatus? connectionStatus,
    String? error,
    DateTime? lastInteractionTime,
    bool clearError = false,
  }) {
    return StoryState(
      storyId: storyId ?? this.storyId,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      currentScene: currentScene ?? this.currentScene,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      isAgentSpeaking: isAgentSpeaking ?? this.isAgentSpeaking,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      error: clearError ? null : (error ?? this.error),
      lastInteractionTime: lastInteractionTime ?? this.lastInteractionTime,
    );
  }
}

/// Manages story playback state and orchestrates services.
class StoryNotifier extends StateNotifier<StoryState> {
  final ElevenLabsService _elevenLabs;
  final PermissionService _permission;
  StreamSubscription<AgentEvent>? _eventSubscription;

  StoryNotifier({
    required String storyId,
    required ElevenLabsService elevenLabs,
    required PermissionService permission,
  })  : _elevenLabs = elevenLabs,
        _permission = permission,
        super(StoryState(storyId: storyId)) {
    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    _eventSubscription = _elevenLabs.events.listen(_handleEvent);
  }

  void _handleEvent(AgentEvent event) {
    switch (event) {
      case SceneChange(sceneName: final scene):
        state = state.copyWith(currentScene: scene);

      case SuggestedActions(actions: final actions):
        state = state.copyWith(suggestedActions: actions);

      case GenerateImage():
        // TODO: Defer to Phase 3
        break;

      case SessionEnded():
        state = state.copyWith(sessionStatus: StorySessionStatus.ended);

      case AgentStartedSpeaking():
        state = state.copyWith(
          isAgentSpeaking: true,
          suggestedActions: [],
        );

      case AgentStoppedSpeaking():
        state = state.copyWith(isAgentSpeaking: false);

      case UserTranscript():
        // Could log for debugging
        break;

      case AgentResponse():
        // Could log for debugging
        break;

      case ConnectionStatusChanged(status: final status):
        state = state.copyWith(connectionStatus: status);

      case AgentError(message: final msg, context: final ctx):
        state = state.copyWith(
          error: '$msg${ctx != null ? ': $ctx' : ''}',
        );
    }
  }

  /// Start the story session.
  Future<void> startStory() async {
    // Guard: only start from idle
    if (state.sessionStatus != StorySessionStatus.idle) {
      return;
    }

    state = state.copyWith(
      sessionStatus: StorySessionStatus.loading,
      clearError: true,
    );

    // Check permission
    final permStatus = await _permission.checkMicrophone();
    if (permStatus != MicPermissionStatus.granted) {
      // Try requesting
      final requestStatus = await _permission.requestMicrophone();
      if (requestStatus != MicPermissionStatus.granted) {
        state = state.copyWith(
          sessionStatus: StorySessionStatus.error,
          error: 'Microphone permission required. Please enable in Settings.',
        );
        return;
      }
    }

    try {
      await _elevenLabs.startStory(storyId: state.storyId);
      state = state.copyWith(
        sessionStatus: StorySessionStatus.active,
        lastInteractionTime: DateTime.now(),
      );
    } catch (e, stackTrace) {
      // Convert any exception type to string safely
      String errorMessage;
      try {
        errorMessage = e.toString();
      } catch (_) {
        errorMessage = 'Unknown error occurred';
      }
      debugPrint('Story start error: $errorMessage\n$stackTrace');
      state = state.copyWith(
        sessionStatus: StorySessionStatus.error,
        error: errorMessage,
      );
    }
  }

  /// End the story session.
  Future<void> endStory() async {
    state = state.copyWith(sessionStatus: StorySessionStatus.ending);
    await _elevenLabs.endSession();
  }

  /// Called when child taps an action card.
  void selectAction(String action) {
    _elevenLabs.sendMessage(action);
    state = state.copyWith(
      suggestedActions: [],
      lastInteractionTime: DateTime.now(),
    );
  }

  /// Called when parent types custom message.
  void sendCustomMessage(String message) {
    _elevenLabs.sendMessage(message);
    state = state.copyWith(lastInteractionTime: DateTime.now());
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for story state, parameterized by story ID.
final storyProvider = StateNotifierProvider.family<StoryNotifier, StoryState, String>(
  (ref, storyId) {
    final elevenLabs = ref.watch(elevenLabsServiceProvider);
    final permission = ref.watch(permissionServiceProvider);
    return StoryNotifier(
      storyId: storyId,
      elevenLabs: elevenLabs,
      permission: permission,
    );
  },
);
