# Storili Design Document

Audio-first interactive Grimm Brothers fairy tales for children aged 3-5.

## Vision

Children experience classic Grimm tales guided by Capy, a friendly capybara companion. Voice-first interaction with tap fallback. AI-generated storybook art at scene transitions. Inspired by [PocketRealm](https://pocketrealm.app/).

## Core Experience

- Child opens app, picks a story (Hansel & Gretel, Three Little Pigs, etc.)
- Scene illustration appears (classic storybook watercolor style)
- Capy narrates: *"Once upon a time, in a cozy little cottage..."*
- Characters speak with distinct voices (witch, wolf, princess)
- Child can speak anytime - natural conversation, not turn-based
- 4 action cards appear as tap alternative to speaking
- Story follows main plot beats with gentle redirection if child goes off-track
- Session targets ~10 minutes, flexible with save/resume

## Target Audience

| Attribute | Specification |
|-----------|---------------|
| Age | 3-5 years old |
| Reading | Pre-readers (voice-first is essential) |
| Session | Parent nearby, co-play expected |
| Content | Gentle adaptations, no scary parts |
| Vocabulary | Simple, lots of repetition, sound words |

## Interaction Model

### Audio-First, Always Listening

- Child can speak whenever, not just at prompts
- Natural conversation with the story
- Barge-ins welcome - Capy stops immediately and responds
- Mic stays hot during Capy's speech (ElevenLabs handles echo cancellation)
- ElevenLabs agent handles free-form speech

### Voice Input Handling

| Situation | Behavior |
|-----------|----------|
| ASR failure | Gentle re-prompt: "Hmm, I didn't quite catch that!" (up to 2-3 times, then suggest cards) |
| Background noise | After repeated issues, show subtle parent notification suggesting quieter environment |
| Long child speech | After 60s, prompt: "I'm listening! What happens next?" |
| Misheard profanity | Ignore - respond to intent, not misheard word |
| Off-topic adult themes | Gentle redirect: "That's a big question! But right now, the wolf is waiting..." |
| Concerning speech | No special handling - don't make app feel like surveillance |

### 4 Action Cards (Tap Fallback)

- **Visibility**: Hidden during Capy's speech, slide up together when Capy finishes
- **Format**: Text + emoji (e.g., "🌳 Hide behind tree")
- **Content**: 3 AI-suggested actions + "Something else..."
- **4th card**: Opens single-line text input for parent (no gate required)
- **Tap handling**: Card text injected as if child spoke it
- **Haptics**: Light tap feedback on selection
- Cards are helpers, not constraints - voice always works

## Capy - The Companion

| Attribute | Description |
|-----------|-------------|
| Character | Friendly capybara who lives in the fairy tale world |
| Role | Narrator + guide + child's companion |
| Voice | Warm, gentle, preschool teacher energy |
| Behavior | Celebrates choices, reassures if scared, invites participation |
| Catchphrases | "Can you...?", "Look!", "Ooh!", "Don't worry!" |
| Idle behavior | After 30s silence, gently prompts: "What would you like to do?" |
| Name capture | May naturally ask "What's your name, little one?" during story |

## Audio Architecture

### ElevenLabs Integration

Single agent per story with workflow subagent nodes per scene (5 scenes max).

```
┌─────────────────────────────────────────────────────────────────┐
│                     STORY AGENT (One per story)                 │
│                                                                 │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐                │
│  │ Scene 1  │────►│ Scene 2  │────►│ Scene 3  │───► ...        │
│  │ Subagent │     │ Subagent │     │ Subagent │                │
│  │ Node     │     │ Node     │     │ Node     │                │
│  └──────────┘     └──────────┘     └──────────┘                │
│                                                                 │
│  Conversation history persists across all nodes                 │
└─────────────────────────────────────────────────────────────────┘
```

### Agent Custom Tools

The ElevenLabs agent uses client tools to communicate structured data to the app:

| Tool | Purpose |
|------|---------|
| `change_scene` | Signal scene transition, triggers image generation |
| `suggest_actions` | Provide 3 action card suggestions |
| `generate_image` | Request image with dynamic prompt based on child's choices |
| `session_end` | Signal story completion with summary |

### Voice Configuration

- **Capy**: Warm narrator voice (default)
- **Characters**: Distinct voices per character (witch, wolf, children, etc.)
- **Switching**: Inline - agent handles voice changes via prompt instructions

### Connection Management

- **Pre-connect**: Open generic WebSocket connection on home screen before story selection
- **Story binding**: Specify story agent when child taps a story card
- **Connection drop**: Invisible reconnect in background, resume from last stable point
- **Latency indicator**: Visual only (pulsing mic) - no audio filler

### Context Management

Following modern best practices (Anthropic, Google ADK, LangChain):

- **Compiled context per turn** - only current scene + relevant characters
- **RAG for scenarios** - retrieve relevant examples, not all
- **Sliding window history** - compress/summarize older turns
- **Priority system**: scene > scenarios > Capy personality > characters > general knowledge
- **Context errors**: Play along creatively with out-of-context requests

## Story Structure

### No Scripted Branches

Following the Three Little Pigs pattern:

- One main storyline with plot beats
- Agent herds child toward next beat
- Barge-ins handled gracefully, then resume
- Gentle redirection when off-track: *"That's a fun idea! But look, the wolf is going this way..."*

### Story Content Files

Same structure as piglets demo:

```
stories/
├── _shared/
│   ├── capy.txt                 # Shared companion personality
│   └── art_style.txt            # Base art style prompt
│
├── hansel-and-gretel/
│   ├── manifest.json            # Metadata + voice mappings
│   ├── sys_prompt.txt           # Orchestrator for this story
│   ├── story.txt                # General knowledge + scene breakdown
│   ├── scenarios.txt            # 20-30 example inputs → responses
│   ├── characters/
│   │   ├── witch.txt
│   │   ├── gretel.txt
│   │   └── hansel.txt
│   └── scenes/                  # Art prompts only
│       ├── cottage.txt
│       ├── forest.txt
│       └── gingerbread_house.txt
```

### Story.txt Template

```markdown
# [STORY NAME]
# Adapted for ages 3-5 | Audio-first interactive experience

## OVERVIEW
PREMISE: [Child-friendly summary]
PLAYER ROLE: [Who is the child in this story?]
COMPANION: Capy guides them through
TONE: [Cozy, silly, adventurous, etc.]

## CHARACTERS
[For each: name, voice style, personality, role]

## SCENE 1: [SCENE NAME]
LOCATION: [Where are we?]
ATMOSPHERE: [How does it feel?]
ART_PROMPT: [Base art prompt - agent enriches with scene details]

PLOT BEATS:
1. [First thing that happens]
2. [Second thing that happens]
3. [Third thing - leads to next scene]

CAPY MOMENTS:
- [Participation prompts: "Can you...?"]
- [Reassurance phrases if needed]
- [Celebration moments]

KEY DIALOGUE:
[Iconic lines for this scene]

→ NEXT SCENE TRIGGER: [What leads to scene 2]
```

## Image Generation

### Configuration

| Setting | Value |
|---------|-------|
| Service | OpenAI DALL-E 3 (recommended for consistent storybook style) |
| Aspect ratio | Square (1:1) |
| Style | Classic storybook watercolor illustration |
| Consistency | Stylistically similar acceptable (not pixel-perfect) |
| Caching | None - always regenerate fresh images |
| Animation | Ken Burns effect (subtle pan/zoom) on displayed images |

### Prompt Composition

- **Base prompt**: Style + story context from `art_style.txt` and scene files
- **Enrichment**: Agent adds scene-specific details based on child's actual choices
- **Result**: Personalized images reflecting the child's unique playthrough

### Flow

```
Agent calls generate_image tool
        │
        ├──► Capy begins narrating new scene (immediate)
        │
        └──► Image generation starts in parallel (5-10 sec)
                    │
                    ▼
              Image ready → crossfade in with Ken Burns
```

### Fallback

- On failure: Retry silently while keeping previous image visible
- After 2-3 failures: Show pre-made placeholder illustration

## Session Persistence

### Rich AI-Generated Summaries

Not deterministic state flags. AI-generated narrative capturing the child's unique journey.

**What the summary captures:**

| Element | Example |
|---------|---------|
| Child's name | "Emma" (if shared naturally) |
| Play style | "brave helper", "silly", "cautious" |
| Key choices | "whispered instead of shouting" |
| How they chose | "made the witch laugh by pretending" |
| Relationships | "Hansel calls her 'the sneaky one'" |
| Current moment | "about to push the witch" |
| Personality notes | "loves making silly voices" |

### Save Behavior

| Trigger | Action |
|---------|--------|
| Story completion | Generate summary via `session_end` tool |
| Exit (✕ button) | Confirmation dialog, then save summary |
| Time cap reached | Capy says goodbye, save summary |
| App backgrounded | Continue 5-10 seconds, then pause and save |
| Connection lost | Invisible reconnect; if fails, auto-save |

### Resume Experience

- **Story tap**: Auto-resume from where they left off (no prompt)
- **Restart option**: Hidden in settings only

```
App opens
    │
    ▼
Load local summary for story
    │
    ▼
Initialize ElevenLabs agent with:
{
  "resume_summary": "Emma is playing as a brave helper..."
}
    │
    ▼
Agent: "Emma! You're back! Hansel has been waiting
for you - he keeps calling you 'the sneaky one.'"
```

### Local Storage Schema

```json
{
  "device_id": "uuid",
  "last_story": "hansel-and-gretel",
  "daily_playtime_minutes": 15,
  "playtime_date": "2025-12-31",
  "progress": {
    "hansel-and-gretel": {
      "status": "in_progress",
      "summary": "Emma is playing as a brave helper. She chose to whisper a secret plan to Hansel instead of shouting, which was very clever...",
      "updated": "2025-12-31T10:30:00Z"
    }
  }
}
```

## Usage Limits

| Limit | Value |
|-------|-------|
| Daily playtime cap | 30 minutes |
| Cap reset | Daily at midnight (local time) |
| Replays count? | Yes - all playtime counts toward limit |
| Cap reached behavior | Capy: "Time for a break! We'll continue later" → save and exit |

## Technical Architecture

### Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart              # MaterialApp, theme, providers
│   ├── router.dart           # go_router configuration
│   └── theme.dart            # Visual theme (Claymorphism)
│
├── config/
│   └── elevenlabs_config.dart # TTS voice ID, model, timeout
│
├── services/
│   ├── audio_service.dart    # Playback + recording facade
│   ├── elevenlabs_service.dart # Agent + TTS API
│   ├── image_service.dart    # DALL-E 3 generation
│   ├── image_cache.dart      # In-memory image storage
│   └── storage_service.dart
│
├── models/
│   ├── story.dart
│   ├── session.dart
│   └── agent_event.dart
│
├── providers/
│   ├── services.dart         # Service providers
│   ├── story_provider.dart   # Story session state
│   ├── celebration_provider.dart # TTS audio provider
│   └── home_provider.dart    # Story list state
│
├── screens/
│   ├── home_screen.dart
│   ├── story_screen.dart
│   ├── celebration_screen.dart # 3-phase reveal
│   └── settings_screen.dart
│
├── widgets/
│   ├── story_card.dart
│   ├── scene_image.dart
│   ├── action_cards.dart
│   ├── audio_indicator.dart
│   └── full_screen_image_viewer.dart
│
├── utils/
│   ├── bytes_audio_source.dart  # In-memory audio playback
│   └── test_image_generator.dart # Programmatic test images
│
├── screens/debug/
│   └── celebration_debug_launcher.dart # Debug test flow
│
└── assets/
    ├── stories/
    ├── audio/                # Placeholder for jingle
    └── images/               # Placeholder for Capy art

integration_test/
└── celebration_flow_test.dart # Celebration UI integration tests
```

### Data Flow

```
User speaks
    │
    ▼
AudioService (captures mic - always listening)
    │
    ▼
ElevenLabsService (sends via WebSocket)
    │
    ▼
ElevenLabs Agent (processes, generates response)
    │
    ▼
ElevenLabsService (receives events via WebSocket)
    │
    ▼
StoryNotifier (handles events, updates state)
    ├──► AgentAudio → AudioService (plays audio)
    ├──► SuggestedActions → Update UI (show cards)
    ├──► SceneChange + GenerateImage → ImageService (parallel)
    └──► SessionEnded → StorageService (persist) → CelebrationScreen
    │
    ▼
StoryScreen (reacts to state changes)
```

### Core Interfaces

```dart
sealed class AgentEvent {}

class AgentAudio extends AgentEvent {
  final Uint8List audio;
}

class SuggestedActions extends AgentEvent {
  final List<String> actions;  // 3 suggestions
}

class SceneChange extends AgentEvent {
  final String sceneName;
}

class GenerateImage extends AgentEvent {
  final String prompt;  // Agent-enriched prompt
}

class SessionEnded extends AgentEvent {
  final String summary;
}
```

### Packages (12 total)

| Need | Package |
|------|---------|
| State | `flutter_riverpod` |
| Routing | `go_router` |
| Audio Play | `just_audio` |
| Audio Record | `record` |
| WebSocket | `web_socket_channel` |
| HTTP | `http` |
| Storage | `shared_preferences` |
| Images | `cached_network_image` |
| Crash reporting | `firebase_crashlytics` |
| Confetti | `confetti` |
| Env Config | `flutter_dotenv` |
| ElevenLabs Agent | `elevenlabs_agents` |

### Configuration

| Setting | Value |
|---------|-------|
| API key storage | Compiled into app (hardcoded for MVP) |
| Target devices | Recent phones/tablets (last 3-4 years) |
| Orientation | Portrait only (locked) |
| Audio routing | Auto-detect (OS handles device selection) |

## User Experience

### App Launch

1. **Splash screen**: Animated Capy while app initializes
2. **Home screen**: Story cards with animated Capy in header

### Home Screen

```
┌─────────────────────────────────────────┐
│                                    ⚙️   │
│                                         │
│     ┌─────────────────────────────┐     │
│     │   Animated Capy (waving)    │     │
│     └─────────────────────────────┘     │
│                                         │
│  ┌─────────────┐  ┌─────────────┐       │
│  │  Three      │  │  Hansel &   │       │
│  │  Little     │  │  Gretel     │       │
│  │  Pigs       │  │             │       │
│  │ ✨ NEW      │  │ 🔄 CONTINUE │       │
│  └─────────────┘  └─────────────┘       │
│                                         │
└─────────────────────────────────────────┘
```

**Story card states:**
- Never started: Subtle sparkle effect
- In progress: "Continue" badge
- Completed: "Completed" badge

**Connection**: Subtle spinner while pre-connecting to ElevenLabs

### Story Screen Layout

```
┌─────────────────────────────────────────┐
│ ✕                                       │
│                                         │
│         ┌───────────────────┐           │
│         │   Scene Image     │           │
│         │   (Ken Burns)     │           │
│         │   1:1 square      │           │
│         └───────────────────┘           │
│                                         │
│              🎙️ Listening...            │
│                                         │
├─────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │🌳 Hide  │ │🏃 Run   │ │📢 Call  │   │
│  │ behind  │ │  away   │ │  for    │   │
│  │  tree   │ │         │ │  help   │   │
│  └─────────┘ └─────────┘ └─────────┘   │
│           ┌─────────────┐               │
│           │Something else│              │
│           └─────────────┘               │
└─────────────────────────────────────────┘
```

### Screen States

| State | Visual | Audio |
|-------|--------|-------|
| Capy speaking | 🔊 indicator, cards hidden | Voice playing, mic listening |
| Listening | 🎙️ pulsing, cards visible | Mic active |
| Processing | 🎙️ pulsing indicator | Waiting for agent |
| Scene transition | Image crossfade with Ken Burns | Capy narrates |

### Celebration Screen

Shown on story completion. Three-phase reveal sequence:

**Phase 1: Jingle (0-2s)**
- Confetti explosion (confetti package)
- "You did it!" claymorphism card
- Short celebratory jingle audio
- TTS generation starts in background

**Phase 2: Slideshow (variable)**
- Images auto-play with Ken Burns effect (subtle 5% zoom)
- Capy's personalized voice recap plays (ElevenLabs TTS)
- Slide timing synced to audio duration
- Progress dots show current image
- Tap anywhere to skip to gallery

**Phase 3: Gallery (final)**
- Capy celebration header
- Horizontal thumbnail strip (100x100px, 16px gaps)
- Tap thumbnail → full-screen viewer
- Home button (primary, 56px)
- Play Again button (secondary, 56px)

```
Phase 1: Jingle          Phase 2: Slideshow       Phase 3: Gallery
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│  🎉 Confetti 🎉 │      │  🎉 Confetti 🎉 │      │ [Capy] What a   │
│                 │      │                 │      │        story!   │
│  ┌───────────┐  │      │  ┌───────────┐  │      │                 │
│  │ You did   │  │      │  │  Image    │  │      │ [📷][📷][📷]   │
│  │  it!      │  │      │  │(Ken Burns)│  │      │ (tap for full)  │
│  └───────────┘  │      │  └───────────┘  │      │                 │
│                 │      │    ● ○ ○ ○      │      │ [🏠 Home      ] │
│   ⏳ Loading... │      │   (dots)        │      │ [🔄 Play Again] │
└─────────────────┘      └─────────────────┘      └─────────────────┘
```

**Full-Screen Viewer**:
- PageView with swipe navigation
- Close button (top-left, always visible, 56px)
- Swipe down to dismiss
- Thumbnail strip at bottom

**TTS Integration**:
- Uses ElevenLabs TTS API (not conversational agent)
- Lily voice (warm, friendly) via ElevenLabsConfig
- 8-second timeout, silent fallback on failure
- BytesAudioSource plays audio from memory (no temp files)

**Image storage**: Keep in memory via ImageCache, discard after leaving screen.

### Settings Screen

Minimal for MVP:

```
┌─────────────────────────────────────────┐
│ ← Settings                              │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Reset Story Progress           │    │
│  │  Start all stories fresh        │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

### Error Handling

| Error | Experience |
|-------|------------|
| Mic denied | Allow tap-only mode (degraded but functional) |
| Network lost | Invisible reconnect; if fails, save and friendly exit |
| Speech unclear | Gentle re-prompt (2-3x), then suggest tapping cards |
| Image gen fails | Retry silently, show placeholder after 2-3 failures |
| Exit button | Confirmation dialog: "Leave the story?" |

### Offline Behavior

- **Home screen**: Show story selection, pre-connect attempts in background
- **Story start**: If offline, show: "Capy needs internet to talk! Please connect and try again."
- **Mid-story drop**: Invisible reconnect attempt; if fails, save progress and graceful exit

## Branding

| Element | Specification |
|---------|---------------|
| App name | Storili |
| Icon | Capy face |
| Splash | Animated Capy |

## Analytics

Basic anonymous analytics:
- Session length
- Story completion rates
- Crash reports (Firebase Crashlytics)

No personal data collected.

## MVP Scope

### In Scope

- Three Little Pigs (content already exists)
- Capy as companion
- Voice + tap interaction
- On-demand image generation with Ken Burns
- Save/resume with rich summary
- 30-minute daily time cap
- Celebration screen with gallery
- iOS + Android
- Portrait only

### Out of Scope (Future)

- Multiple stories
- Web platform
- Multi-language
- Companion customization
- Voice-only mode
- Child profiles (data model ready, no UI)
- Parent dashboard
- Captions/accessibility

### MVP Phases

```
PHASE 1: Shell
├── Flutter project setup
├── Folder structure
├── Navigation: Home ↔ Story ↔ Settings ↔ Celebration
├── Theme + Branding
├── Animated Capy splash
└── Placeholder UI

PHASE 2: Audio Pipeline
├── AudioService (play + record)
├── Mic permission flow (with tap-only fallback)
├── Test: record → playback locally
└── Streaming chunks

PHASE 3: ElevenLabs
├── ElevenLabsService (WebSocket)
├── Pre-connect on home screen
├── Custom tools: change_scene, suggest_actions, generate_image, session_end
├── AgentEvent parsing
├── StoryNotifier orchestration
├── Barge-in handling
└── Test: speak → hear response

PHASE 4: Full Loop
├── Bundle Three Little Pigs content
├── Load story manifest
├── Complete playthrough
├── Scene transitions
└── Card tap → inject as text

PHASE 5: Images
├── ImageService (DALL-E 3)
├── generate_image tool → trigger generation
├── Ken Burns animation
├── Crossfade transitions
└── Narration masks latency

PHASE 6: Persistence
├── StorageService
├── Save summary on exit/completion
├── Resume with context
├── Daily playtime tracking
├── 30-minute cap with gentle Capy goodbye
└── Personal welcome back

PHASE 7: Celebration ✅ COMPLETE
├── CelebrationScreen with 3-phase reveal
├── Confetti animation (confetti package)
├── Capy voice recap (ElevenLabs TTS API)
├── Ken Burns effect on slideshow images
├── Image gallery with full-screen viewer
├── Swipe navigation + swipe-down dismiss
└── Replay option + Home navigation

    Implementation Notes:
    - 3-phase reveal: jingle (2s) → slideshow+voice → gallery
    - BytesAudioSource: Custom StreamAudioSource for in-memory audio
    - ElevenLabsConfig: Centralized TTS settings (voice ID, model, timeout)
    - celebrationTtsProvider: Riverpod provider with silent fallback
    - FullScreenImageViewer: PageView with swipe gestures
    - 56px touch targets, 16px gaps (child-friendly)
    - Reduced motion support via MediaQuery.disableAnimations

PHASE 8: Polish & Ship
├── Error states
├── Loading indicators
├── Haptic feedback
├── Firebase Crashlytics
├── Settings screen (reset progress)
└── Playtest with kids
```

## Testing

### Automated

- **Unit tests** (177 tests): Services (ElevenLabs, storage, image), providers, models
- **Widget tests**: Action cards, scene image, audio indicator, celebration screen
- **Integration tests**: Celebration flow with programmatic test images

### Debug Test Flow

In debug builds, Settings screen provides celebration testing without completing a story:

```
Settings > Debug > Test Celebration
```

**Routes:**
- `/debug/celebration` - 5 colored images, real TTS
- `/debug/celebration?mock=true` - Silent fallback (no API calls)
- `/debug/celebration?images=N` - Custom image count

**TestImageGenerator** creates colored PNGs at runtime using `dart:ui` Canvas:
- 5 scene colors (red, orange, green, blue, purple)
- Radial gradient overlay for visual interest
- No external asset files required

**CelebrationTestData** provides predetermined summaries for TTS testing.

### Manual (with children)

| Test | Observe |
|------|---------|
| First launch | Can child navigate without help? |
| Voice interaction | Does agent understand child speech? |
| Tap fallback | Do cards work when voice fails? |
| Interruption | Does barge-in feel natural? |
| Resume | Does welcome back feel personal? |
| Session length | Engaged for ~10 min? |
| Time cap | Does gentle exit feel okay? |
| Celebration | Does child enjoy the recap + gallery? |

## Data Model: Future Profile Support

Current storage is device-level, but data model supports future profiles:

```json
{
  "device_id": "uuid",
  "active_profile": null,
  "profiles": [],
  "progress": { }
}
```

When profiles are added, `progress` moves under each profile.

## References

- [ElevenLabs Agents Platform](https://elevenlabs.io/docs/agents-platform/overview)
- [ElevenLabs Workflows](https://elevenlabs.io/docs/agents-platform/customization/agent-workflows)
- [ElevenLabs Prompting Guide](https://elevenlabs.io/docs/agents-platform/best-practices/prompting-guide)
- [Anthropic Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [LangChain Context Engineering](https://blog.langchain.com/context-engineering-for-agents/)
- [PocketRealm](https://pocketrealm.app/) (inspiration)
