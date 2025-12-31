# ElevenLabs Conversational AI Research Summary

> Research completed for Storili integration - audio-first interactive stories for children.

## Key Findings

### Official Flutter SDK

**Package:** `elevenlabs_agents` v0.3.0 ([pub.dev](https://pub.dev/packages/elevenlabs_agents))

The SDK provides:
- WebRTC-based low-latency audio streaming via LiveKit
- Full-duplex audio (simultaneous speaking/listening)
- Client tools registration for agent-triggered actions
- Comprehensive callbacks for all conversation events
- Built-in barge-in handling (interruptions)

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     ELEVENLABS PLATFORM                         │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Speech Rec   │  │ LLM (Claude) │  │ Voice Synth  │          │
│  │ (ASR)        │  │              │  │ (TTS)        │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                          │                                      │
│                  ┌───────┴───────┐                             │
│                  │ Turn-Taking   │                             │
│                  │ Model         │                             │
│                  └───────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
                           │
                    WebRTC/LiveKit
                           │
┌─────────────────────────────────────────────────────────────────┐
│                     FLUTTER APP                                 │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                 ConversationClient                        │  │
│  │                                                           │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │  │
│  │  │ Audio In    │  │ Callbacks   │  │ Client      │       │  │
│  │  │ (Mic)       │  │ (Events)    │  │ Tools       │       │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Agent Workflows

ElevenLabs supports **workflow subagent nodes** - perfect for Storili's multi-scene stories:

- Each scene can be a subagent node with its own:
  - System prompt
  - Available tools
  - Knowledge base (scene-specific content)
- Transitions between nodes preserve conversation context
- LLM conditions or expressions can trigger transitions

**For Three Little Pigs (5 scenes):**
```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Cottage  │────►│ Straw    │────►│ Stick    │────►│ Brick    │────►│ Celebrate│
│ Scene    │     │ House    │     │ House    │     │ House    │     │          │
└──────────┘     └──────────┘     └──────────┘     └──────────┘     └──────────┘
```

### Client Tools

Client tools execute on the device when the agent calls them. For Storili:

| Tool | Purpose | Wait for Response |
|------|---------|-------------------|
| `change_scene` | Signal scene transition | No |
| `suggest_actions` | Provide 3 action card suggestions | No |
| `generate_image` | Request image with dynamic prompt | No |
| `session_end` | Signal story completion with summary | No |

**Implementation pattern:**
```dart
class ChangeSceneTool implements ClientTool {
  final void Function(String sceneName) onSceneChange;

  ChangeSceneTool(this.onSceneChange);

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    final sceneName = parameters['scene_name'] as String;
    onSceneChange(sceneName);
    return null; // No response needed
  }
}
```

### Connection Flow

1. **Pre-connect on home screen**: Start connection before story selection
2. **Get conversation token**: Backend generates token with agent_id
3. **Start session**: Connect with token + story-specific overrides
4. **Handle events**: Process audio, tools, transcripts via callbacks
5. **End session**: Graceful disconnect with summary

### Audio Handling

The SDK handles all audio internally:
- Microphone capture (requires permissions)
- Audio playback (agent's voice)
- Echo cancellation
- Barge-in detection (interruptions)

**Key properties:**
- `isSpeaking`: Agent is currently speaking
- `isMuted`: Microphone is muted
- `status`: Connection status (connecting, connected, etc.)

### Events/Callbacks

```dart
ConversationCallbacks(
  // Connection lifecycle
  onConnect: ({required conversationId}) { },
  onDisconnect: (details) { },
  onStatusChange: ({required status}) { },
  onError: (message, [context]) { },

  // Transcripts
  onMessage: ({required message, required source}) { },
  onUserTranscript: ({required transcript, required eventId}) { },
  onTentativeAgentResponse: ({required response}) { },

  // Voice activity
  onModeChange: ({required mode}) { },  // listening vs speaking
  onInterruption: (event) { },

  // Tools
  onUnhandledClientToolCall: (toolCall) { },
)
```

### Configuration Overrides

Per-session customization:
```dart
await client.startSession(
  conversationToken: token,
  overrides: ConversationOverrides(
    agent: AgentOverrides(
      firstMessage: 'Hello Emma! Ready to help the piggies?',
      language: 'en',
    ),
  ),
  dynamicVariables: {
    'child_name': 'Emma',
    'resume_summary': 'Emma was playing as a brave helper...',
  },
);
```

## Storili Integration Design

### Dependencies

```yaml
dependencies:
  elevenlabs_agents: ^0.3.0
```

### Platform Setup

**iOS** (`Info.plist`):
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Storili needs your microphone so Capy can hear you!</string>
```

**Android** (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### Backend Requirements

Need a simple backend endpoint to generate conversation tokens:

```
POST /api/conversation-token
Request: { "agent_id": "three-little-pigs", "user_id": "device-123" }
Response: { "token": "eyJ..." }
```

This keeps the API key secure on the server.

### Recommended Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      StoryNotifier                              │
│  (Riverpod StateNotifier - orchestrates story state)            │
│                                                                 │
│  State:                                                         │
│  - currentScene: String                                         │
│  - suggestedActions: List<String>                               │
│  - isAgentSpeaking: bool                                        │
│  - connectionStatus: ConversationStatus                         │
│  - lastImagePrompt: String?                                     │
│  - sessionSummary: String?                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ uses
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ElevenLabsService                            │
│  (Wraps ConversationClient, exposes Stream<AgentEvent>)         │
│                                                                 │
│  Methods:                                                       │
│  - preConnect()                                                 │
│  - startStory(storyId, resumeSummary?)                          │
│  - endSession()                                                 │
│  - sendTextMessage(text)  // for card taps                      │
│                                                                 │
│  Streams:                                                       │
│  - events: Stream<AgentEvent>                                   │
│                                                                 │
│  Properties:                                                    │
│  - isAgentSpeaking: bool                                        │
│  - isMuted: bool                                                │
│  - status: ConversationStatus                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ wraps
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   ConversationClient                            │
│  (From elevenlabs_agents package)                               │
│                                                                 │
│  - Handles WebRTC audio                                         │
│  - Manages client tools                                         │
│  - Provides callbacks                                           │
└─────────────────────────────────────────────────────────────────┘
```

## Agent Setup (ElevenLabs Dashboard)

### Agent Configuration

1. **Create Agent**: "Storili - Three Little Pigs"
2. **LLM**: Claude 3.5 Sonnet (best for function calling)
3. **Voice**: Select warm, child-friendly voice for Capy
4. **System Prompt**: Use `sys_prompt.txt` content

### Client Tools Setup

In ElevenLabs dashboard, create 4 client tools:

**1. change_scene**
- Type: Client
- Parameters: `scene_name` (string)
- Wait for response: No
- Description: "Call when transitioning to a new scene"

**2. suggest_actions**
- Type: Client
- Parameters: `actions` (array of strings, max 3)
- Wait for response: No
- Description: "Provide 3 action suggestions for the child"

**3. generate_image**
- Type: Client
- Parameters: `prompt` (string)
- Wait for response: No
- Description: "Generate an image with the given prompt"

**4. session_end**
- Type: Client
- Parameters: `summary` (string)
- Wait for response: No
- Description: "End the session with a summary of the child's journey"

### Workflow Setup (Optional Enhancement)

For better scene management, create a workflow agent with 5 subagent nodes:
1. Each node has scene-specific system prompt
2. Transitions use LLM conditions ("scene complete")
3. Context preserved across nodes

## Open Questions

1. **Token endpoint**: Need to decide on backend (Firebase Functions, Cloudflare Workers, etc.)
2. **Voice selection**: Need to test voices to find best Capy voice
3. **Character voices**: How to handle voice switching for Wolf, Pigs, etc.?
   - Option A: Single agent with inline voice switching instructions
   - Option B: Multiple voice presets in ElevenLabs
4. **Workflow vs Single Agent**: Start with single agent, migrate to workflow if needed

## References

- [ElevenLabs Agents Overview](https://elevenlabs.io/docs/agents-platform/overview)
- [Agent Workflows](https://elevenlabs.io/docs/agents-platform/customization/agent-workflows)
- [Client Tools](https://elevenlabs.io/docs/agents-platform/customization/tools/client-tools)
- [Flutter SDK](https://pub.dev/packages/elevenlabs_agents)
- [Prompting Guide](https://elevenlabs.io/docs/agents-platform/best-practices/prompting-guide)
