/// Events emitted by the ElevenLabs agent during a story session.
sealed class AgentEvent {
  const AgentEvent();
}

/// Scene transition requested by the agent.
class SceneChange extends AgentEvent {
  final String sceneName;
  const SceneChange(this.sceneName);

  @override
  String toString() => 'SceneChange($sceneName)';
}

/// Action suggestions for the child to choose from.
class SuggestedActions extends AgentEvent {
  final List<String> actions;
  const SuggestedActions(this.actions);

  @override
  String toString() => 'SuggestedActions($actions)';
}

/// Image generation requested with enriched prompt.
class GenerateImage extends AgentEvent {
  final String prompt;
  const GenerateImage(this.prompt);

  @override
  String toString() => 'GenerateImage($prompt)';
}

/// Story session ended with summary.
class SessionEnded extends AgentEvent {
  final String summary;
  const SessionEnded(this.summary);

  @override
  String toString() => 'SessionEnded($summary)';
}

/// Agent started speaking (hide action cards).
class AgentStartedSpeaking extends AgentEvent {
  const AgentStartedSpeaking();

  @override
  String toString() => 'AgentStartedSpeaking()';
}

/// Agent stopped speaking (show action cards).
class AgentStoppedSpeaking extends AgentEvent {
  const AgentStoppedSpeaking();

  @override
  String toString() => 'AgentStoppedSpeaking()';
}

/// User transcript received.
class UserTranscript extends AgentEvent {
  final String transcript;
  const UserTranscript(this.transcript);

  @override
  String toString() => 'UserTranscript($transcript)';
}

/// Agent response text received.
class AgentResponse extends AgentEvent {
  final String text;
  const AgentResponse(this.text);

  @override
  String toString() => 'AgentResponse($text)';
}

/// Connection status changed.
class ConnectionStatusChanged extends AgentEvent {
  final ElevenLabsConnectionStatus status;
  const ConnectionStatusChanged(this.status);

  @override
  String toString() => 'ConnectionStatusChanged($status)';
}

/// Error occurred.
class AgentError extends AgentEvent {
  final String message;
  final String? context;
  const AgentError(this.message, [this.context]);

  @override
  String toString() =>
      'AgentError($message${context != null ? ', $context' : ''})';
}

/// Connection status enum (mirrors SDK).
enum ElevenLabsConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
}
