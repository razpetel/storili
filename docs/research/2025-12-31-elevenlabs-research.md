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

### Authentication: WebRTC vs WebSocket

> **CRITICAL:** The Flutter SDK uses WebRTC (LiveKit), which requires a **conversation token**, NOT a signed URL.

| Connection Type | Endpoint | Response Field | Use Case |
|-----------------|----------|----------------|----------|
| **WebRTC** (Flutter SDK) | `/v1/convai/conversation/token` | `token` (JWT) | Mobile/Flutter apps |
| **WebSocket** | `/v1/convai/conversation/get-signed-url` | `signed_url` | Web apps using raw WebSocket |

**Wrong approach (causes 401 error):**
```typescript
// DON'T use this for Flutter SDK
const response = await fetch(
  `https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=${agentId}`,
  { headers: { 'xi-api-key': apiKey } }
);
const { signed_url } = await response.json();
// Returns: wss://api.elevenlabs.io/v1/convai/conversation?agent_id=...&conversation_signature=...
// SDK tries to use this as LiveKit access_token → 401 "invalid authorization token"
```

**Correct approach:**
```typescript
// USE this for Flutter SDK (WebRTC/LiveKit)
const response = await fetch(
  `https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=${agentId}`,
  { headers: { 'xi-api-key': apiKey } }
);
const { token } = await response.json();
// Returns: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (LiveKit JWT)
```

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

## Agent Setup (API-First)

> **Decision:** We're using the ElevenLabs API to manage agents programmatically rather than the dashboard. See `docs/plans/2026-01-01-elevenlabs-api-agent-config-design.md` for full design.

### Why API-First

- **Version control**: Agent configs in git, code review for prompt changes
- **Reproducible**: Any developer can deploy from the same config
- **Audit trail**: Git history + `.agents.json` tracks what's deployed
- **Future-proof**: Enables CI/CD, staging environments, CMS integration

### Agent Configuration Location

```
backend/agents/
├── types.ts                  # TypeScript types
└── three-little-pigs.ts      # Complete agent config (prompt, tools, voice)
```

### Deployment

```bash
cd backend
npm run agent:deploy three-little-pigs   # Create or update
npm run agent:status                      # Show deployed agents
```

### Client Tools

4 client-side tools registered in both the agent config AND Flutter code:

| Tool | Purpose | Parameters |
|------|---------|------------|
| `change_scene` | Scene transition | `scene_name: string` |
| `suggest_actions` | Show action cards | `actions: string[]` |
| `generate_image` | Generate illustration | `prompt: string` |
| `session_end` | End with summary | `summary: string` |

## Resolved Questions

| Question | Decision |
|----------|----------|
| Token endpoint | Cloudflare Workers using `/v1/convai/conversation/token` (NOT `/get-signed-url`) |
| Voice selection | Voice `b8gbDO0ybjX1VA89pBdX` with tuned TTS settings |
| Character voices | Single agent with inline switching via prompt instructions |
| Workflow vs Single Agent | Single agent for MVP, workflow optional later |
| Dashboard vs API | API-first with TypeScript configs |
| Connection type | WebRTC via LiveKit (Flutter SDK default) |

## End-to-End Testing Results (2026-01-01)

### Verified Working

| Component | Status | Notes |
|-----------|--------|-------|
| Token worker | ✅ | `storili-token-dev.razpetel.workers.dev` returns JWT |
| WebRTC connection | ✅ | `ElevenLabs connected: conv_...` |
| Agent responds | ✅ | First message plays, calls tools |
| `change_scene` tool | ✅ | UI shows "Scene: cottage" |
| Error handling | ✅ | Clean error messages (no type errors) |

### Known Issues Fixed

1. **TypeError with ConnectException** - SDK `onError` callback can pass exception objects instead of strings
   - Fix: Convert to string in callback handler
   - Files: `elevenlabs_service.dart`, `story_provider.dart`

2. **401 "invalid authorization token"** - Using wrong token endpoint
   - Cause: `get-signed-url` returns WebSocket URL, SDK needs LiveKit JWT
   - Fix: Use `/v1/convai/conversation/token` endpoint
   - Files: `backend/src/worker.ts`

### TTS Settings (Tuned)

```typescript
tts: {
  voice_id: 'b8gbDO0ybjX1VA89pBdX',
  model_id: 'eleven_turbo_v2',
  stability: 0.5,
  similarity_boost: 0.65,
  style: 0.8,
  speed: 0.85,
}
```

## References

- [ElevenLabs Agents Overview](https://elevenlabs.io/docs/agents-platform/overview)
- [Agent Workflows](https://elevenlabs.io/docs/agents-platform/customization/agent-workflows)
- [Client Tools](https://elevenlabs.io/docs/agents-platform/customization/tools/client-tools)
- [Flutter SDK](https://pub.dev/packages/elevenlabs_agents)
- [Prompting Guide](https://elevenlabs.io/docs/agents-platform/best-practices/prompting-guide)
