# Phase 7: Celebration Screen - Design Document

**Date:** 2026-01-05
**Status:** Approved
**Author:** Claude + User collaboration

## Overview

Implement the celebration screen shown when a child completes a story. Features confetti animation, personalized Capy voice recap via ElevenLabs TTS, auto-playing image slideshow, and gallery with full-screen viewer.

## Decisions

| Decision | Choice |
|----------|--------|
| TTS fallback | Silent slideshow (no pre-recorded clips) |
| Confetti package | `confetti: ^0.7.0` |
| Slideshow sync | Fixed interval based on voice duration |
| Gallery interaction | Thumbnails with tap-to-enlarge |
| Image viewer zoom | Deferred to post-MVP |
| State management | StatefulWidget + Riverpod ref.listen |
| Audio bytes playback | BytesAudioSource (no temp files) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CELEBRATION SCREEN                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Phase 1: JINGLE (0-2s)                                     │
│  ├── Confetti burst (warm palette)                          │
│  ├── "You did it!" card (claymorphism)                      │
│  ├── Local jingle plays                                     │
│  ├── TTS request fires in background                        │
│  └── If TTS slow: show subtle loader after jingle           │
│                                                             │
│  Phase 2: SLIDESHOW (2s - voice end)                        │
│  ├── Images auto-advance (dynamic interval from duration)   │
│  ├── Ken Burns effect per image                             │
│  ├── Confetti continues (lighter)                           │
│  ├── Capy voice plays (or silent if TTS failed)             │
│  ├── Tap to skip → Phase 3                                  │
│  └── Skip button if voice outlasts images                   │
│                                                             │
│  Phase 3: GALLERY (final)                                   │
│  ├── Capy celebrating (120x120)                             │
│  ├── "What a story!" header                                 │
│  ├── Horizontal thumbnail strip (100x100, tappable)         │
│  ├── Home button (primary)                                  │
│  ├── Play Again button (secondary)                          │
│  └── Tap thumbnail → Full-screen viewer                     │
│                                                             │
│  Full-Screen Viewer (overlay)                               │
│  ├── Close button: top-left, 56x56, always visible          │
│  ├── PageView for swipe navigation                          │
│  ├── Swipe-down to dismiss (scale + fade feedback)          │
│  ├── Mini thumbnail strip at bottom                         │
│  └── Hero animation from/to gallery thumbnail               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase Details

### Phase 1: Jingle

**Duration:** ~2 seconds (jingle length)

**Visual:**
```
┌─────────────────────────────────────────┐
│  🎊        CONFETTI FALLING        🎊   │
│                                         │
│         ┌───────────────────┐           │
│         │   "You did it!"   │           │
│         │   (Fredoka 32px)  │           │
│         └───────────────────┘           │
│            claymorphism card            │
│                                         │
│         [loader if TTS slow]            │
└─────────────────────────────────────────┘
```

**Audio:** Local jingle asset plays immediately.

**Background:** TTS request fires on mount, provider handles timeout (8s).

### Phase 2: Slideshow

**Duration:** Voice duration, or 3.5s × image count if silent

**Visual:**
```
┌─────────────────────────────────────────┐
│  (lighter confetti continues)           │
│                                         │
│         ┌───────────────────┐           │
│         │   Current Image   │           │
│         │   (Ken Burns)     │           │
│         │   1:1, 24px radius│           │
│         └───────────────────┘           │
│                                         │
│            ● ○ ○ ○ ○                    │
│         (12px progress dots)            │
│                                         │
│   [Skip button if voice > slides]       │
└─────────────────────────────────────────┘
```

**Slide interval:** `max(2s, voiceDuration / imageCount)`

**Interaction:** Tap anywhere skips to Phase 3.

### Phase 3: Gallery

**Visual:**
```
┌─────────────────────────────────────────┐
│                                         │
│      ┌────────────┐                     │
│      │   Capy     │  "What a story!"    │
│      │  120x120   │  (Fredoka 28px)     │
│      └────────────┘                     │
│                                         │
│  ┌───────┐  ┌───────┐  ┌───────┐       │
│  │100x100│  │100x100│  │100x100│  →    │
│  └───────┘  └───────┘  └───────┘       │
│     16px gap, horizontal scroll         │
│                                         │
│     ┌────────────────────────┐          │
│     │   Home (icon)    56px  │          │
│     └────────────────────────┘          │
│              16px gap                   │
│     ┌────────────────────────┐          │
│     │   Play Again (icon)    │          │
│     └────────────────────────┘          │
└─────────────────────────────────────────┘
```

**Button order:** Home first (safer), Play Again second (intentional).

**Thumbnail tap:** Opens full-screen viewer.

---

## Full-Screen Image Viewer

**Layout:**
```
┌─────────────────────────────────────────┐
│  ┌──────┐                               │
│  │  ✕   │ top-left, always visible      │
│  └──────┘ 56x56, SafeArea aware         │
│                                         │
│    ┌───────────────────────────────┐    │
│    │                               │    │
│    │      Image (fit: contain)     │    │
│    │      Hero animation           │    │
│    │                               │    │
│    └───────────────────────────────┘    │
│                                         │
│              ← swipe →                  │
│                                         │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│  │    │ │ ██ │ │    │ │    │ │    │   │
│  └────┘ └────┘ └────┘ └────┘ └────┘   │
│   Mini thumbnail strip (48px)           │
└─────────────────────────────────────────┘
```

**Gestures:**

| Gesture | Action |
|---------|--------|
| Tap ✕ | Close viewer |
| Swipe left/right | Navigate images |
| Swipe down (velocity > 800) | Dismiss with scale+fade |
| Tap thumbnail | Jump to that image |

**Edge cases:**
- Single image: No thumbnail strip, no swipe
- Hero animation only for initial image

---

## Error Handling

### TTS Failures

| Failure | Detection | Fallback |
|---------|-----------|----------|
| Timeout (>8s) | Future.timeout | Silent slideshow |
| API error | catch block | Silent slideshow |
| Empty summary | summary.trim().isEmpty | Skip TTS entirely |
| Network lost | catch block | Silent slideshow |

### Voice Duration Extremes

| Case | Handling |
|------|----------|
| Very short (<4s) | Minimum 2s per slide |
| Very long (>30s) | Show skip button after last slide |

### Image Failures

```dart
Image.memory(
  imageBytes,
  errorBuilder: (_, __, ___) => Container(
    color: AppColors.primary,
    child: Icon(Icons.image_not_supported),
  ),
)
```

### Reduced Motion

```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;

if (reduceMotion) {
  // Static images (no Ken Burns)
  // No confetti (show celebration_stars.png)
  // Instant transitions
  // Voice still plays
}
```

---

## Technical Implementation

### Widget Structure

```dart
CelebrationScreen (ConsumerStatefulWidget)
├── TickerProviderStateMixin (multiple animations)
├── WidgetsBindingObserver (lifecycle)
│
├── Controllers:
│   ├── ConfettiController
│   ├── AnimationController _kenBurnsController
│   ├── AudioPlayer _jinglePlayer
│   └── AudioPlayer _voicePlayer
│
├── State:
│   ├── CelebrationPhase _phase
│   ├── int _currentSlide
│   ├── bool _jingleComplete
│   ├── bool _ttsComplete
│   ├── Uint8List? _ttsAudioBytes
│   └── bool _waitingForTts
│
└── Build:
    ├── ConfettiWidget (layer)
    └── AnimatedSwitcher
        ├── _JingleView
        ├── _SlideshowView
        └── _GalleryView
```

### State Machine

```dart
enum CelebrationPhase { jingle, slideshow, gallery }

void _onJingleComplete() {
  _jingleComplete = true;
  _tryTransition();
}

void _onTtsComplete(Uint8List? audioBytes) {
  _ttsComplete = true;
  _ttsAudioBytes = audioBytes;
  _tryTransition();
}

void _tryTransition() {
  if (!_jingleComplete) return;
  if (!_ttsComplete) {
    setState(() => _waitingForTts = true);
    return;
  }
  if (_phase != CelebrationPhase.jingle) return;

  _transitionToSlideshow(_ttsAudioBytes);
}
```

### BytesAudioSource

```dart
class BytesAudioSource extends StreamAudioSource {
  final Uint8List bytes;
  BytesAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
```

### TTS Provider

```dart
final celebrationTtsProvider = FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, summary) async {
    if (summary.trim().isEmpty) return null;

    try {
      final elevenLabs = ref.read(elevenLabsServiceProvider);
      return await elevenLabs
          .textToSpeech(summary)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('TTS failed: $e');
      return null;
    }
  },
);
```

### ElevenLabs TTS Method

```dart
// Add to ElevenLabsService

Future<Uint8List> textToSpeech(String text) async {
  final response = await http.post(
    Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/${ElevenLabsConfig.capyVoiceId}'),
    headers: {
      'xi-api-key': _apiKey,
      'Content-Type': 'application/json',
      'Accept': 'audio/mpeg',
    },
    body: jsonEncode({
      'text': text,
      'model_id': 'eleven_turbo_v2_5',
      'voice_settings': ElevenLabsConfig.capyVoiceSettings,
    }),
  );

  if (response.statusCode != 200) {
    throw ElevenLabsException('TTS failed: ${response.statusCode}');
  }

  return response.bodyBytes;
}
```

---

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `lib/screens/celebration_screen.dart` | Rewrite | Full implementation |
| `lib/widgets/full_screen_image_viewer.dart` | Create | Image viewer overlay |
| `lib/utils/bytes_audio_source.dart` | Create | just_audio byte source |
| `lib/config/elevenlabs_config.dart` | Create | Shared voice ID/settings |
| `lib/services/elevenlabs_service.dart` | Modify | Add textToSpeech() |
| `lib/providers/celebration_provider.dart` | Create | TTS FutureProvider |
| `lib/app/router.dart` | Modify | Pass summary to celebration |
| `pubspec.yaml` | Modify | Add confetti package |

---

## Assets Required

| Asset | Path | Spec |
|-------|------|------|
| Celebration jingle | `assets/audio/celebration_jingle.mp3` | ~2s, xylophone/bells, fade out |
| Capy celebrating | `assets/images/capy_celebrate.png` | 240x240 @2x |
| Static celebration | `assets/images/celebration_stars.png` | 400x400 @2x, reduced motion |

---

## Accessibility

| Element | Handling |
|---------|----------|
| Confetti | `ExcludeSemantics` (decorative) |
| Images | Semantic label: "Story image N of M" |
| Phase changes | `SemanticsService.announce()` |
| Reduced motion | Skip Ken Burns, static confetti graphic |
| Close button | Semantic label: "Close image viewer" |

---

## UX Guidelines (Children 3-5)

| Guideline | Implementation |
|-----------|----------------|
| Touch targets | Minimum 56px height for buttons |
| Thumbnail size | 100x100px (larger for small fingers) |
| Touch spacing | 16px gap between elements |
| No hidden UI | Close button always visible |
| Haptic feedback | On page change, on dismiss |
| No emoji icons | Use SVG icons from Lucide |

---

## Testing Focus

| Component | Tests |
|-----------|-------|
| State machine | Phase transitions, race conditions |
| TTS provider | Timeout, failure, empty summary |
| BytesAudioSource | Audio playback from bytes |
| Full-screen viewer | Navigation, dismiss gestures |
| Reduced motion | Respects MediaQuery setting |
| Edge cases | 0 images, 1 image, long voice |

---

## Debug & Testing Infrastructure

### Test Image Generator

Utility for generating colored PNG images programmatically without external assets:

```dart
class TestImageGenerator {
  static const List<Color> sceneColors = [
    Color(0xFFE57373), // Red - "The cottage"
    Color(0xFFFFB74D), // Orange - "The forest path"
    Color(0xFF81C784), // Green - "The meadow"
    Color(0xFF64B5F6), // Blue - "The river"
    Color(0xFFBA68C8), // Purple - "The castle"
  ];

  static Future<List<int>> generateColoredImage(
    Color color, {int size = 512}
  ) async {
    // Uses dart:ui Canvas to draw solid color + gradient overlay
    // Returns PNG bytes via picture.toImage() + toByteData()
  }
}
```

**Key insight:** Using `dart:ui` Canvas avoids need for asset files during testing. Images are generated at runtime with visual interest (radial gradient overlay, corner indicator circle).

### Debug Test Flow

Access via Settings screen (debug builds only):

| Route | Configuration |
|-------|---------------|
| `/debug/celebration` | 5 images, real TTS |
| `/debug/celebration?mock=true` | 5 images, silent fallback |
| `/debug/celebration?images=3` | 3 images, real TTS |

**CelebrationDebugLauncher** workflow:
1. Clears ImageCache
2. Generates N colored test images (parallel progress indicator)
3. Populates ImageCache with indices
4. Navigates to `/celebration/test-story` with predetermined summary

```dart
// Predetermined test data
class CelebrationTestData {
  static const String storyId = 'three-little-pigs-test';
  static const String summary = '''
What an amazing adventure! You helped the three little pigs build their houses.
You were so brave when you told the big bad wolf to go away!
The wolf huffed and puffed, but together we outsmarted him.
Great job, little storyteller!''';
  static const String shortSummary = 'Great job finishing the story!';
}
```

### Integration Tests

Location: `integration_test/celebration_flow_test.dart`

| Test | Purpose |
|------|---------|
| Debug launcher navigation | Verifies setup and route transition |
| Confetti animation display | Ensures celebration UI renders |
| Image gallery after slideshow | Phase transition timing |
| Replay button functionality | Restart behavior |

**Key insight:** Integration tests use `UncontrolledProviderScope` with pre-populated `ImageCache` to bypass actual image generation. Tests exercise the full UI flow with mock data.

---

## Implementation Learnings

### Memory Leak Prevention

Stream subscriptions must be stored and cancelled:

```dart
// BAD - memory leak
_voicePlayer.playerStateStream.listen((state) { ... });

// GOOD - tracked and cancelled
StreamSubscription<PlayerState>? _voicePlayerSubscription;

_voicePlayerSubscription = _voicePlayer.playerStateStream.listen((state) { ... });

@override
void dispose() {
  _voicePlayerSubscription?.cancel();
  super.dispose();
}
```

### Deprecation Migration

Flutter 3.7+ deprecates `Color.withOpacity()`:

```dart
// Deprecated - precision loss warning
color.withOpacity(0.9)

// Preferred - explicit alpha
color.withValues(alpha: 0.9)
```

### Provider Family Pattern

`FutureProvider.autoDispose.family` enables dynamic parameter passing with cleanup:

```dart
final celebrationTtsProvider = FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, summary) async {
    // Each unique summary gets its own provider instance
    // autoDispose cleans up when no longer used
  },
);

// Usage
ref.listen(
  celebrationTtsProvider(summary),
  (previous, next) {
    next.whenData((audioBytes) => ...);
  },
);
```

---

## Deferred to Post-MVP

- Pinch-to-zoom in image viewer (gesture complexity)
- Landscape mode for wider images
- Double-tap to zoom
- Image sharing functionality
