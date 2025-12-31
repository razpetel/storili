import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_event.dart';

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
