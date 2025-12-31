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
- Barge-ins welcome - Capy responds naturally and resumes
- ElevenLabs agent handles free-form speech

### 4 Action Cards (Tap Fallback)

- Appear at decision moments as alternative to speaking
- 3 AI-suggested actions relevant to current moment
- 4th card: "Something else..." opens text input for parent
- Cards are helpers, not constraints - voice always works
- Parent can silently guide via the 4th card

## Capy - The Companion

| Attribute | Description |
|-----------|-------------|
| Character | Friendly capybara who lives in the fairy tale world |
| Role | Narrator + guide + child's companion |
| Voice | Warm, gentle, preschool teacher energy |
| Behavior | Celebrates choices, reassures if scared, invites participation |
| Catchphrases | "Can you...?", "Look!", "Ooh!", "Don't worry!" |

## Audio Architecture

### ElevenLabs Integration

Single agent per story with workflow subagent nodes per scene (3-5 scenes max).

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

### Voice Configuration

- **Capy**: Warm narrator voice (default)
- **Characters**: Distinct voices per character (witch, wolf, children, etc.)
- Agent switches voices dynamically based on who's speaking

### Context Management

Following modern best practices (Anthropic, Google ADK, LangChain):

- **Compiled context per turn** - only current scene + relevant characters
- **RAG for scenarios** - retrieve relevant examples, not all
- **Sliding window history** - compress/summarize older turns
- **Priority system**: scene > scenarios > Capy personality > characters > general knowledge

## Story Structure

### No Scripted Branches

Following the Three Little Pigs pattern:

- One main storyline with plot beats
- Agent herds child toward next beat
- Barge-ins handled gracefully, then resume
- Gentle redirection when off-track: *"That's a fun idea! But look, the wolf is going this way..."*

### Story Content Files

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
│   ├── scenarios.txt            # Example inputs → responses
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
ART_PROMPT: [What should the image show?]

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

### On-Demand at Scene Transitions

- Generate when scene transition triggers (not pre-generated)
- 2-4 second latency masked by Capy's narration
- Classic storybook watercolor illustration style
- Consistent style across all stories via shared base prompt

### Flow

```
Scene transition triggered
        │
        ├──► Capy begins narrating new scene (immediate)
        │
        └──► Image generation starts in parallel (2-4 sec)
                    │
                    ▼
              Image ready → crossfade in
```

## Session Persistence

### Rich AI-Generated Summaries

Not deterministic state flags. AI-generated narrative capturing the child's unique journey.

**What the summary captures:**

| Element | Example |
|---------|---------|
| Child's name | "Emma" (if shared) |
| Play style | "brave helper", "silly", "cautious" |
| Key choices | "whispered instead of shouting" |
| How they chose | "made the witch laugh by pretending" |
| Relationships | "Hansel calls her 'the sneaky one'" |
| Current moment | "about to push the witch" |
| Personality notes | "loves making silly voices" |

### Resume Experience

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
  "progress": {
    "hansel-and-gretel": {
      "summary": "Emma is playing as a brave helper. She chose to whisper a secret plan to Hansel instead of shouting, which was very clever...",
      "updated": "2025-12-31T10:30:00Z"
    }
  }
}
```

## Technical Architecture

### Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart              # MaterialApp, theme, providers
│   ├── router.dart           # go_router configuration
│   └── theme.dart            # Visual theme
│
├── services/
│   ├── audio_service.dart    # Playback + recording facade
│   ├── elevenlabs_service.dart
│   ├── image_service.dart
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
│   └── home_provider.dart    # Story list state
│
├── screens/
│   ├── home_screen.dart
│   ├── story_screen.dart
│   └── settings_screen.dart
│
├── widgets/
│   ├── story_card.dart
│   ├── scene_image.dart
│   ├── action_cards.dart
│   └── audio_indicator.dart
│
└── assets/
    └── stories/
```

### Data Flow

```
User speaks
    │
    ▼
AudioService (captures mic)
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
    ├──► SceneChange → ImageService (generate art)
    └──► SessionEnded → StorageService (persist)
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
  final List<String> actions;
}

class SceneChange extends AgentEvent {
  final String sceneName;
  final String artPrompt;
}

class SessionEnded extends AgentEvent {
  final String summary;
}
```

### Packages (8 total)

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

## User Experience

### Story Screen Layout

```
┌─────────────────────────────────────────┐
│ ✕                              🔇  ⚙️   │
│                                         │
│         ┌───────────────────┐           │
│         │   Scene Image     │           │
│         │   (AI generated)  │           │
│         └───────────────────┘           │
│                                         │
│              🎙️ Listening...            │
│                                         │
├─────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │  Hide   │ │  Run    │ │  Call   │   │
│  │ behind  │ │  away   │ │  for    │   │
│  │  tree   │ │         │ │  help   │   │
│  └─────────┘ └─────────┘ └─────────┘   │
│           ┌─────────────┐               │
│           │Something else│              │
│           └─────────────┘               │
└─────────────────────────────────────────┘
```

### States

| State | Visual | Audio |
|-------|--------|-------|
| Capy speaking | 🔊 indicator, cards dimmed | Voice playing |
| Listening | 🎙️ pulsing, cards visible | Mic active |
| Scene transition | Image crossfade | Capy narrates |

### Error Handling

| Error | Experience |
|-------|------------|
| Mic denied | Capy: "I can't hear you! Ask a grown-up to tap here." |
| Network lost | Capy: "Oops, I lost my magic! Let's try again." |
| Speech unclear | Capy: "Hmm, I didn't quite hear that. Can you say it again?" |

## MVP Scope

### In Scope

- Three Little Pigs (content already exists)
- Capy as companion
- Voice + tap interaction
- On-demand image generation
- Save/resume with rich summary
- iOS + Android

### Out of Scope (Future)

- Multiple stories
- Web platform
- Multi-language
- Companion customization
- Voice-only mode

### MVP Phases

```
PHASE 1: Shell (2 days)
├── Flutter project setup
├── Folder structure
├── Navigation: Home ↔ Story ↔ Settings
├── Theme
└── Placeholder UI

PHASE 2: Audio Pipeline (3 days)
├── AudioService (play + record)
├── Mic permission flow
├── Test: record → playback locally
└── Streaming chunks

PHASE 3: ElevenLabs (3 days)
├── ElevenLabsService (WebSocket)
├── AgentEvent parsing
├── StoryNotifier orchestration
└── Test: speak → hear response

PHASE 4: Full Loop (2 days)
├── Bundle Three Little Pigs content
├── Load story manifest
├── Complete playthrough
└── Scene transitions

PHASE 5: Images (2 days)
├── ImageService
├── Scene change → trigger generation
├── Crossfade animation
└── Narration masks latency

PHASE 6: Persistence (2 days)
├── StorageService
├── Save summary on exit
├── Resume with context
└── Personal welcome back

PHASE 7: Polish & Ship (3 days)
├── Error states
├── Loading indicators
├── Parent settings
└── Playtest with kids
```

**Total: ~17 days to shippable MVP**

## Testing

### Automated

- Unit tests: Services (ElevenLabs event parsing, storage)
- Widget tests: Action cards, scene image, audio indicator
- Integration tests: Full story flow with mocked services

### Manual (with children)

| Test | Observe |
|------|---------|
| First launch | Can child navigate without help? |
| Voice interaction | Does agent understand child speech? |
| Tap fallback | Do cards work when voice fails? |
| Interruption | Does barge-in feel natural? |
| Resume | Does welcome back feel personal? |
| Session length | Engaged for ~10 min? |

## References

- [ElevenLabs Agents Platform](https://elevenlabs.io/docs/agents-platform/overview)
- [ElevenLabs Workflows](https://elevenlabs.io/docs/agents-platform/customization/agent-workflows)
- [ElevenLabs Prompting Guide](https://elevenlabs.io/docs/agents-platform/best-practices/prompting-guide)
- [Anthropic Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [LangChain Context Engineering](https://blog.langchain.com/context-engineering-for-agents/)
- [PocketRealm](https://pocketrealm.app/) (inspiration)
