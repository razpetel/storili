# Phase 2: Audio Pipeline Design

> ElevenLabs Conversational AI integration for Storili.

## Overview

**Goal:** Connect Flutter app to ElevenLabs Conversational AI, enabling voice-driven interactive storytelling.

**Architecture:** Hybrid approach - testable abstractions for core components, pragmatic simplicity elsewhere.

**Tech Stack:**
- `elevenlabs_agents: ^0.3.0` - Official Flutter SDK
- `http: ^1.2.0` - Token fetching
- `permission_handler: ^11.3.0` - Microphone permissions
- Cloudflare Workers - Token endpoint

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Story Screen                                     │
│  (watches StoryNotifier state)                                          │
└─────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       StoryNotifier                                     │
│  (StateNotifier - orchestrates session, processes events)               │
│                                                                         │
│  State: scene, actions, isAgentSpeaking, connectionStatus, error        │
└─────────────────────────────────────────────────────────────────────────┘
          │                   │                    │
          ▼                   ▼                    ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ ElevenLabsService│ │ PermissionService│ │ (SessionRepo)    │
│ Stream<AgentEvent│ │ requestMic()     │ │ Phase 3          │
│ startSession()   │ │ checkMic()       │ │                  │
│ endSession()     │ │ openSettings()   │ │                  │
└──────────────────┘ └──────────────────┘ └──────────────────┘
          │
          ▼
┌──────────────────┐
│ TokenProvider    │
│ (Cloudflare)     │
└──────────────────┘
```

## File Structure

```
lib/
├── config/
│   └── app_config.dart           # Environment configuration
├── models/
│   ├── agent_event.dart          # Sealed event class hierarchy
│   └── token_exception.dart      # Typed token errors
├── services/
│   ├── elevenlabs_service.dart   # SDK wrapper, emits Stream<AgentEvent>
│   ├── elevenlabs_tools.dart     # 4 client tools
│   ├── token_provider.dart       # Abstract + CloudflareTokenProvider
│   └── permission_service.dart   # Abstract + PermissionServiceImpl
├── providers/
│   ├── services.dart             # Service providers
│   └── story_provider.dart       # StoryNotifier + StoryState
backend/
├── worker.ts                     # Cloudflare Worker
├── wrangler.toml                 # Cloudflare config
└── package.json
```

## Component Specifications

### 1. AgentEvent (Sealed Class)

```dart
sealed class AgentEvent {
  const AgentEvent();
}

class SceneChange extends AgentEvent {
  final String sceneName;
  const SceneChange(this.sceneName);
}

class SuggestedActions extends AgentEvent {
  final List<String> actions;
  const SuggestedActions(this.actions);
}

class GenerateImage extends AgentEvent {
  final String prompt;
  const GenerateImage(this.prompt);
}

class SessionEnded extends AgentEvent {
  final String summary;
  const SessionEnded(this.summary);
}

class AgentStartedSpeaking extends AgentEvent {
  const AgentStartedSpeaking();
}

class AgentStoppedSpeaking extends AgentEvent {
  const AgentStoppedSpeaking();
}

class UserTranscript extends AgentEvent {
  final String transcript;
  const UserTranscript(this.transcript);
}

class AgentResponse extends AgentEvent {
  final String text;
  const AgentResponse(this.text);
}

class ConnectionStatusChanged extends AgentEvent {
  final ElevenLabsConnectionStatus status;
  const ConnectionStatusChanged(this.status);
}

class AgentError extends AgentEvent {
  final String message;
  final String? context;
  const AgentError(this.message, [this.context]);
}

enum ElevenLabsConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
}
```

### 2. TokenProvider

```dart
abstract class TokenProvider {
  /// Throws [TokenException] on failure
  Future<String> getToken(String agentId);
}

class TokenException implements Exception {
  final String message;
  final TokenErrorType type;
  const TokenException(this.message, this.type);
}

enum TokenErrorType {
  network,
  invalidAgent,
  serverError,
  rateLimited,
}

class CloudflareTokenProvider implements TokenProvider {
  final http.Client _client;
  final Uri _baseUrl;
  final Duration _timeout;

  CloudflareTokenProvider({
    required Uri baseUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl,
       _client = client ?? http.Client(),
       _timeout = timeout;

  @override
  Future<String> getToken(String agentId) async {
    // Implementation with proper error handling
  }
}
```

### 3. PermissionService

```dart
enum MicPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

abstract class PermissionService {
  Future<MicPermissionStatus> requestMicrophone();
  Future<MicPermissionStatus> checkMicrophone();
  Future<void> openSettings();
}

class PermissionServiceImpl implements PermissionService {
  // Implementation using permission_handler package
}
```

### 4. Client Tools

Four tools registered with ElevenLabs SDK:

| Tool | Parameters | Action |
|------|------------|--------|
| `change_scene` | `scene_name: string` | Emit SceneChange event |
| `suggest_actions` | `actions: string[]` | Emit SuggestedActions (max 3) |
| `generate_image` | `prompt: string` | Emit GenerateImage event |
| `session_end` | `summary: string` | Emit SessionEnded event |

All tools validate parameters and silently ignore malformed calls (log error, don't crash).

### 5. ElevenLabsService

```dart
class ElevenLabsService {
  final TokenProvider _tokenProvider;
  ConversationClient? _client;
  final StreamController<AgentEvent> _eventController;

  Stream<AgentEvent> get events => _eventController.stream;
  ElevenLabsConnectionStatus get status => ...;
  bool get isAgentSpeaking => _client?.isSpeaking ?? false;
  bool get isMuted => _client?.isMuted ?? false;

  Future<void> startSession({
    required String agentId,
    String? childName,
  }) async {
    // Guard: reject if already connected
    // Get token with timeout
    // Connect with timeout
  }

  Future<void> endSession() async { ... }
  void sendMessage(String text) { ... }
  Future<bool> toggleMute() async { ... } // Returns new state
  Future<void> setMuted(bool muted) async { ... }
}
```

### 6. StoryState & StoryNotifier

```dart
class StoryState {
  final String storyId;
  final StorySessionStatus sessionStatus; // idle, loading, active, ending, ended, error
  final String currentScene;
  final List<String> suggestedActions;
  final bool isAgentSpeaking;
  final ElevenLabsConnectionStatus connectionStatus;
  final String? error;
  final DateTime? lastInteractionTime; // For idle detection
}

enum StorySessionStatus {
  idle,
  loading,
  active,
  ending,
  ended,
  error,
}

class StoryNotifier extends StateNotifier<StoryState> {
  // Handles: permission check, token fetch, session management
  // Implements: idle timeout (5min + 30s), max session (45min)
  // Processes: all AgentEvent types
}
```

## Session Lifecycle

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. USER TAPS "START STORY"                                              │
│    Guard: if sessionStatus != idle, ignore tap                          │
│    Set sessionStatus = loading                                          │
│    Show: CircularProgressIndicator + "Getting ready..."                 │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 2. PERMISSION CHECK                                                     │
│    PermissionService.checkMicrophone()                                  │
│    ├─ granted → continue                                                │
│    ├─ denied → requestMicrophone() with inline Capy message             │
│    │   "I need to hear your voice! Please tap Allow."                   │
│    └─ permanentlyDenied → show Settings dialog                          │
│        "Capy needs microphone access. Tap Settings to enable."          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 3. GET TOKEN (10s timeout)                                              │
│    TokenProvider.getToken(agentId)                                      │
│    ├─ success → continue                                                │
│    └─ TokenException → "Oops! I couldn't connect. Let's try again!"     │
│        + [Try Again] button                                             │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 4. CONNECT (15s timeout)                                                │
│    ElevenLabsService.startSession()                                     │
│    ├─ success → sessionStatus = active, navigate to story screen        │
│    └─ failure → "Oops! I couldn't connect. Let's try again!"            │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 5. ACTIVE SESSION                                                       │
│                                                                         │
│    Events:                                                              │
│    AgentStartedSpeaking  → fade action cards to 50% opacity             │
│    AgentStoppedSpeaking  → restore action cards to 100%                 │
│    SuggestedActions      → show up to 3 tappable cards                  │
│    SceneChange           → update currentScene                          │
│    GenerateImage         → (defer to Phase 3)                           │
│    AgentError            → show toast, log error                        │
│                                                                         │
│    Timers:                                                              │
│    - Idle: 5min no interaction → prompt, +30s → end                     │
│    - Max: 45min hard cap → end gracefully                               │
│                                                                         │
│    User actions:                                                        │
│    - Tap action card → sendMessage(action)                              │
│    - Tap mute → toggleMute()                                            │
│    - Tap X → confirm dialog → endSession()                              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 6. SESSION END                                                          │
│                                                                         │
│    Natural end (agent calls session_end):                               │
│    → SessionEnded event with summary                                    │
│    → sessionStatus = ended                                              │
│    → Navigate to CelebrationScreen                                      │
│                                                                         │
│    Parent end (X button):                                               │
│    → endSession()                                                       │
│    → Navigate to HomeScreen (no celebration)                            │
│                                                                         │
│    Timeout end (idle or max):                                           │
│    → Agent: "I'll wait here for next time. Bye!"                        │
│    → endSession()                                                       │
│    → Navigate to HomeScreen                                             │
└─────────────────────────────────────────────────────────────────────────┘
```

## Background & Interruption Handling

```
App → background:
  - setMuted(true) immediately
  - Start 30s timer
  - If foregrounded within 30s → setMuted(false), continue
  - If 30s expires → endSession()

Phone call / audio interruption:
  - Treat same as background
  - Mute, 30s grace, end if longer

App killed by OS:
  - Session dies (acceptable for MVP)
  - Resume feature in Phase 3
```

## Cloudflare Worker

```typescript
interface Env {
  ELEVENLABS_API_KEY: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    try {
      const { agent_id } = await request.json() as { agent_id?: string };

      if (!agent_id || typeof agent_id !== 'string') {
        return new Response('Missing agent_id', { status: 400 });
      }

      // Allowlist validation
      const allowedAgents = ['three-little-pigs'];
      if (!allowedAgents.includes(agent_id)) {
        return new Response('Invalid agent_id', { status: 400 });
      }

      const response = await fetch(
        `https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=${agent_id}`,
        { headers: { 'xi-api-key': env.ELEVENLABS_API_KEY } }
      );

      if (!response.ok) {
        console.error(`ElevenLabs API error: ${response.status}`);
        return new Response('Token generation failed', { status: 502 });
      }

      const { signed_url } = await response.json() as { signed_url: string };

      return new Response(
        JSON.stringify({ token: signed_url }),
        { headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    } catch (error) {
      console.error('Worker error:', error);
      return new Response('Internal error', { status: 500 });
    }
  },
};
```

## Platform Configuration

### iOS (ios/Runner/Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Storili needs your microphone so Capy can hear your voice!</string>
```

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

## Testing Strategy

### Unit Tests
- TokenProvider: mock http.Client, test success/error paths
- PermissionService: mock permission_handler, test all status mappings
- Client tools: test event emission, parameter validation
- StoryNotifier: test event handling, state transitions

### Integration Tests
- Full session flow with mocked ElevenLabsService
- Permission denied → settings flow
- Timeout handling
- Idle detection

### Manual Testing
- Real device with ElevenLabs agent
- Background/foreground transitions
- Network interruption

## Deferred to Phase 3+

| Feature | Phase | Reason |
|---------|-------|--------|
| Session resume | 3 | Needs persistence layer |
| Progress save on drop | 3 | Needs persistence layer |
| Image generation | 3 | Separate service |
| Capy loading animation | 4 | Needs art assets |
| VoiceOver accessibility | 4 | Polish phase |
| Localization | 4+ | English-only MVP |

## Dependencies to Add

```yaml
dependencies:
  elevenlabs_agents: ^0.3.0
  http: ^1.2.0
  permission_handler: ^11.3.0
```

## Configuration

```dart
class AppConfig {
  static const tokenEndpoint = String.fromEnvironment(
    'TOKEN_ENDPOINT',
    defaultValue: 'https://storili-token-dev.YOUR_SUBDOMAIN.workers.dev',
  );

  static const maxSessionDuration = Duration(minutes: 45);
  static const idleWarningDuration = Duration(minutes: 5);
  static const idleGracePeriod = Duration(seconds: 30);
  static const backgroundGracePeriod = Duration(seconds: 30);
  static const tokenTimeout = Duration(seconds: 10);
  static const connectTimeout = Duration(seconds: 15);
}
```
