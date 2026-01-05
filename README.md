# Storili

Audio-first interactive fairy tales for children aged 3-5, featuring Capy the capybara companion.

## Overview

Children experience classic Grimm tales through natural voice conversation. Capy narrates and guides while children speak freely or tap action cards. AI-generated storybook illustrations appear at scene transitions with Ken Burns animation.

## Features

- **Voice-First Interaction**: Natural conversation, always-listening (not turn-based)
- **Tap Fallback**: 4 action cards appear when Capy finishes speaking
- **AI-Generated Art**: DALL-E 3 storybook illustrations at scene transitions
- **Session Persistence**: Rich AI-generated summaries capture the child's journey
- **Celebration Screen**: Confetti, personalized voice recap, and image gallery

## Tech Stack

- **Framework**: Flutter (iOS & Android)
- **State Management**: Riverpod
- **Routing**: go_router
- **Voice AI**: ElevenLabs Agents (conversational) + TTS API (celebration recap)
- **Image Generation**: OpenAI DALL-E 3
- **Audio Playback**: just_audio
- **Animations**: confetti package, Ken Burns effect

## Project Structure

```
lib/
├── app/           # App shell, router, theme
├── config/        # Configuration (ElevenLabs settings)
├── models/        # Data models (AgentEvent, Story)
├── providers/     # Riverpod providers
├── screens/       # HomeScreen, StoryScreen, CelebrationScreen, Settings
├── services/      # ElevenLabs, Image, Storage services
├── utils/         # Utilities (BytesAudioSource)
└── widgets/       # Reusable UI components
```

## Setup

1. Copy `.env.example` to `.env` and add your API keys:
   ```
   OPENAI_API_KEY=your_key
   ELEVENLABS_API_KEY=your_key
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run:
   ```bash
   flutter run
   ```

## Development

### Running Tests
```bash
flutter test
```

### Worktree Development
Feature branches use git worktrees for isolation:
```bash
git worktree add .worktrees/feature-name -b feature/feature-name
```

## MVP Phases

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Shell (navigation, theme, splash) | Complete |
| 2 | Audio Pipeline (mic, playback) | Complete |
| 3 | ElevenLabs Integration | Complete |
| 4 | Full Story Loop | Complete |
| 5 | Image Generation (DALL-E 3) | Complete |
| 6 | Persistence (save/resume) | In Progress |
| 7 | Celebration Screen | Complete |
| 8 | Polish & Ship | Pending |

## Documentation

- [Design Document](docs/plans/2025-12-31-storili-design.md)
- [Phase 7 Celebration Design](docs/plans/2026-01-05-phase7-celebration-design.md)

## License

Private - All rights reserved
