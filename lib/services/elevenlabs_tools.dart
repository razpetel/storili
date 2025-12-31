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
  /// Maximum number of action suggestions to display.
  static const int maxActions = 3;

  final StreamController<AgentEvent> _eventController;

  SuggestActionsTool(this._eventController);

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    final actionsRaw = parameters['actions'];
    final actions = (actionsRaw is List)
        ? actionsRaw.map((e) => e.toString()).take(maxActions).toList()
        : <String>[];
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
