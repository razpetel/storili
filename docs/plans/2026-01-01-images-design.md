# Phase 5: Images - Design Document

## Goal

Add AI-generated storybook illustrations using DALL-E 3, displayed with Ken Burns animation and crossfade transitions.

## Architecture

```
GenerateImage event (from ElevenLabs agent)
       │
       ▼
 StoryNotifier sets isImageLoading: true
       │
       ▼
 ImageService.generate(prompt)  ──► runs parallel to Capy speaking
       │
       ▼
 DALL-E 3 API (1024x1024, standard quality)
       │
       ▼
 Download image bytes
       │
       ▼
 ImageCache stores bytes (outside Riverpod state)
       │
       ▼
 StoryNotifier updates currentImageIndex, imageCount
       │
       ▼
 SceneImage widget displays with Ken Burns + crossfade
```

## Key Decisions

### Image Storage: In-Memory Only (MVP)

- Images kept in `ImageCache` during session
- Gallery works for single-session completions
- On resume: agent generates fresh image, no gallery history
- Disk persistence deferred to Phase 6

### State Design: Lightweight References

**Bad (bytes in state):**
```dart
class StoryState {
  final Uint8List? currentImage;      // Megabytes copied on every update
  final List<Uint8List> sessionImages;
}
```

**Good (references only):**
```dart
class ImageCache {
  final Map<int, Uint8List> _images = {};

  void store(int index, Uint8List bytes);
  Uint8List? get(int index);
  List<Uint8List> getAll();
  void clear();
}

class StoryState {
  final int? currentImageIndex;  // Lightweight
  final int imageCount;
  final bool isImageLoading;
}
```

### API Key: Environment Variable

- Store in `.env` file (gitignored)
- Load via `flutter_dotenv` package
- Pass via `--dart-define` for CI builds

### Error Handling

| Scenario | Behavior |
|----------|----------|
| API failure | 2 retries with exponential backoff |
| All retries fail | Show placeholder asset, log error |
| First scene fails | Show placeholder (no "previous image" to fall back to) |
| Network timeout | 30 second timeout, then retry logic |

### Ken Burns Animation

- Subtle zoom: 100% → 105% over 10 seconds
- Direction: zoom in (not out)
- Loops continuously while image displayed
- Resets on new image

### Crossfade Transition

- Duration: 500ms
- Easing: ease-in-out
- Old image fades out while new fades in

## Files

| File | Action | Purpose |
|------|--------|---------|
| `.env` | Create | Store OPENAI_API_KEY (gitignored) |
| `pubspec.yaml` | Modify | Add flutter_dotenv |
| `lib/main.dart` | Modify | Load dotenv on startup |
| `lib/services/image_service.dart` | Create | DALL-E 3 API calls |
| `lib/services/image_cache.dart` | Create | In-memory image storage |
| `lib/widgets/scene_image.dart` | Create | Ken Burns + crossfade display |
| `lib/providers/services.dart` | Modify | Add imageServiceProvider, imageCacheProvider |
| `lib/providers/story_provider.dart` | Modify | Handle GenerateImage event, add image state fields |
| `lib/screens/story_screen.dart` | Modify | Replace scene text with SceneImage widget |
| `assets/images/placeholder.png` | Create | Fallback illustration |

## API Details

**Endpoint:** `POST https://api.openai.com/v1/images/generations`

**Request:**
```json
{
  "model": "dall-e-3",
  "prompt": "...",
  "size": "1024x1024",
  "quality": "standard",
  "response_format": "url",
  "n": 1
}
```

**Cost:** ~$0.04 per image (standard quality)

## Testing

- Unit tests: ImageService (mock HTTP), ImageCache
- Widget tests: SceneImage animation states
- Integration: GenerateImage event → image displayed

## Out of Scope (Phase 6+)

- Disk persistence for resume
- Gallery on resume
- Image compression
- Preloading next scene
