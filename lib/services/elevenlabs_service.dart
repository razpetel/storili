import 'dart:async';

import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:flutter/foundation.dart';

import '../models/agent_event.dart';
import 'elevenlabs_tools.dart';
import 'token_provider.dart';

/// Service for managing ElevenLabs Conversational AI sessions.
///
/// Wraps the ConversationClient and provides a stream-based interface
/// for story playback.
class ElevenLabsService extends ChangeNotifier {
  final TokenProvider _tokenProvider;
  ConversationClient? _client;
  final StreamController<AgentEvent> _eventController =
      StreamController<AgentEvent>.broadcast();

  ElevenLabsService({required TokenProvider tokenProvider})
      : _tokenProvider = tokenProvider;

  /// Stream of events from the agent.
  Stream<AgentEvent> get events => _eventController.stream;

  /// Current connection status.
  ElevenLabsConnectionStatus get status => _mapStatus(_client?.status);

  /// Whether the agent is currently speaking.
  bool get isAgentSpeaking => _client?.isSpeaking ?? false;

  /// Whether the microphone is muted.
  bool get isMuted => _client?.isMuted ?? false;

  /// Whether currently connected.
  bool get isConnected => _client?.status == ConversationStatus.connected;

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
        debugPrint('ElevenLabs connected: $conversationId');
        if (!_eventController.isClosed) {
          _eventController.add(
            const ConnectionStatusChanged(ElevenLabsConnectionStatus.connected),
          );
        }
      },
      onDisconnect: (details) {
        debugPrint('ElevenLabs disconnected');
        if (!_eventController.isClosed) {
          _eventController.add(
            const ConnectionStatusChanged(
                ElevenLabsConnectionStatus.disconnected),
          );
        }
      },
      onStatusChange: ({required status}) {
        if (!_eventController.isClosed) {
          _eventController.add(ConnectionStatusChanged(_mapStatus(status)));
        }
      },
      onError: (message, [context]) {
        debugPrint('ElevenLabs error: $message ($context)');
        if (!_eventController.isClosed) {
          _eventController.add(AgentError(message, context));
        }
      },
      onMessage: ({required message, required source}) {
        if (!_eventController.isClosed) {
          if (source == Role.user) {
            _eventController.add(UserTranscript(message));
          } else {
            _eventController.add(AgentResponse(message));
          }
        }
      },
      onModeChange: ({required mode}) {
        if (!_eventController.isClosed) {
          if (mode == ConversationMode.speaking) {
            _eventController.add(const AgentStartedSpeaking());
          } else {
            _eventController.add(const AgentStoppedSpeaking());
          }
        }
      },
      onInterruption: (event) {
        // Barge-in detected - agent will stop speaking
        if (!_eventController.isClosed) {
          _eventController.add(const AgentStoppedSpeaking());
        }
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

  /// Start a story session with a public agent ID (for testing).
  ///
  /// [agentId] - The public agent ID
  Future<void> startWithPublicAgent({
    required String agentId,
    String? childName,
  }) async {
    if (_client == null) {
      initialize();
    }

    final dynamicVariables = <String, String>{};
    if (childName != null) {
      dynamicVariables['child_name'] = childName;
    }

    await _client!.startSession(
      agentId: agentId,
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

  /// Send contextual update (invisible to user, visible to agent).
  void sendContextualUpdate(String context) {
    _client?.sendContextualUpdate(context);
  }

  /// Toggle microphone mute state.
  Future<void> toggleMute() async {
    await _client?.toggleMute();
    notifyListeners();
  }

  /// Set microphone mute state.
  Future<void> setMuted(bool muted) async {
    await _client?.setMicMuted(muted);
    notifyListeners();
  }

  /// Get a conversation token from the backend.
  Future<String> _getConversationToken(String storyId) async {
    return _tokenProvider.getToken(storyId);
  }

  /// Map SDK status to our enum.
  ElevenLabsConnectionStatus _mapStatus(ConversationStatus? status) {
    return switch (status) {
      ConversationStatus.connecting => ElevenLabsConnectionStatus.connecting,
      ConversationStatus.connected => ElevenLabsConnectionStatus.connected,
      ConversationStatus.disconnecting =>
        ElevenLabsConnectionStatus.disconnecting,
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
