# Phase 5: Images Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add AI-generated storybook illustrations using DALL-E 3, displayed with Ken Burns animation and crossfade transitions.

**Architecture:** ImageService calls DALL-E 3 API, returns bytes stored in ImageCache (outside Riverpod state). StoryNotifier handles GenerateImage events, updates lightweight state references. SceneImage widget displays with Ken Burns animation.

**Tech Stack:** Flutter, http package, DALL-E 3 API, flutter_dotenv for API key

---

## Task 1: Fix Existing Failing Test

**Files:**
- Modify: `test/providers/story_provider_test.dart:276`

**Step 1: Update the test expectation**

The test expects `StorySessionStatus.ending` but behavior was changed to reset to `idle`. Update:

```dart
// Line 276 - change from:
expect(notifier.state.sessionStatus, StorySessionStatus.ending);

// To:
// After endStory completes, status resets to idle for fresh restart
expect(notifier.state.sessionStatus, StorySessionStatus.idle);
```

**Step 2: Run tests to verify fix**

Run: `flutter test test/providers/story_provider_test.dart -v`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add test/providers/story_provider_test.dart
git commit -m "fix: update endStory test to expect idle status"
```

---

## Task 2: Add flutter_dotenv and Create .env

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`
- Create: `.env`
- Modify: `.gitignore`

**Step 1: Add flutter_dotenv to pubspec.yaml**

Add under dependencies:
```yaml
  flutter_dotenv: ^5.1.0
```

Add under flutter > assets:
```yaml
    - .env
```

**Step 2: Run flutter pub get**

Run: `flutter pub get`
Expected: Dependencies resolved

**Step 3: Create .env file with API key**

```
OPENAI_API_KEY=your-api-key-here
```

**Step 4: Add .env to .gitignore**

Add line:
```
.env
```

**Step 5: Update main.dart to load dotenv**

Add import at top:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
```

Update main() function:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: StoriliApp()));
}
```

**Step 6: Run app to verify dotenv loads**

Run: `flutter run -d chrome`
Expected: App starts without errors

**Step 7: Commit**

```bash
git add pubspec.yaml lib/main.dart .gitignore
git commit -m "feat: add flutter_dotenv for API key management"
```

Note: Do NOT commit .env file

---

## Task 3: Create ImageCache

**Files:**
- Create: `lib/services/image_cache.dart`
- Create: `test/services/image_cache_test.dart`

**Step 1: Write failing tests for ImageCache**

Create `test/services/image_cache_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:storili/services/image_cache.dart';

void main() {
  group('ImageCache', () {
    late ImageCache cache;

    setUp(() {
      cache = ImageCache();
    });

    test('store and retrieve image by index', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      cache.store(0, bytes);

      expect(cache.get(0), equals(bytes));
    });

    test('get returns null for missing index', () {
      expect(cache.get(99), isNull);
    });

    test('getAll returns all stored images in order', () {
      final img0 = Uint8List.fromList([1, 2]);
      final img1 = Uint8List.fromList([3, 4]);
      final img2 = Uint8List.fromList([5, 6]);

      cache.store(0, img0);
      cache.store(1, img1);
      cache.store(2, img2);

      final all = cache.getAll();
      expect(all.length, 3);
      expect(all[0], equals(img0));
      expect(all[1], equals(img1));
      expect(all[2], equals(img2));
    });

    test('count returns number of stored images', () {
      expect(cache.count, 0);

      cache.store(0, Uint8List.fromList([1]));
      expect(cache.count, 1);

      cache.store(1, Uint8List.fromList([2]));
      expect(cache.count, 2);
    });

    test('clear removes all images', () {
      cache.store(0, Uint8List.fromList([1]));
      cache.store(1, Uint8List.fromList([2]));

      cache.clear();

      expect(cache.count, 0);
      expect(cache.get(0), isNull);
    });

    test('overwrite existing index', () {
      final original = Uint8List.fromList([1, 2]);
      final updated = Uint8List.fromList([3, 4]);

      cache.store(0, original);
      cache.store(0, updated);

      expect(cache.get(0), equals(updated));
      expect(cache.count, 1);
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/services/image_cache_test.dart -v`
Expected: FAIL - Target of URI doesn't exist

**Step 3: Implement ImageCache**

Create `lib/services/image_cache.dart`:

```dart
import 'dart:typed_data';

/// In-memory cache for generated story images.
///
/// Stores image bytes outside of Riverpod state to avoid
/// copying large binary data on every state update.
class ImageCache {
  final Map<int, Uint8List> _images = {};

  /// Store image bytes at the given index.
  void store(int index, Uint8List bytes) {
    _images[index] = bytes;
  }

  /// Retrieve image bytes at the given index, or null if not found.
  Uint8List? get(int index) => _images[index];

  /// Get all stored images in index order.
  List<Uint8List> getAll() {
    final keys = _images.keys.toList()..sort();
    return keys.map((k) => _images[k]!).toList();
  }

  /// Number of stored images.
  int get count => _images.length;

  /// Clear all stored images.
  void clear() {
    _images.clear();
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/services/image_cache_test.dart -v`
Expected: All 6 tests PASS

**Step 5: Commit**

```bash
git add lib/services/image_cache.dart test/services/image_cache_test.dart
git commit -m "feat: add ImageCache for in-memory image storage"
```

---

## Task 4: Create ImageService

**Files:**
- Create: `lib/services/image_service.dart`
- Create: `test/services/image_service_test.dart`

**Step 1: Write failing tests for ImageService**

Create `test/services/image_service_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:storili/services/image_service.dart';

void main() {
  group('ImageService', () {
    test('generate returns image bytes on success', () async {
      // Mock the OpenAI API response
      final mockClient = MockClient((request) async {
        // Verify request
        expect(request.url.toString(),
            'https://api.openai.com/v1/images/generations');
        expect(request.headers['Authorization'], 'Bearer test-key');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body);
        expect(body['model'], 'dall-e-3');
        expect(body['size'], '1024x1024');
        expect(body['quality'], 'standard');
        expect(body['prompt'], contains('test prompt'));

        // Return mock response with URL
        return http.Response(
          jsonEncode({
            'data': [
              {'url': 'https://example.com/image.png'}
            ]
          }),
          200,
        );
      });

      // Mock the image download
      final imageBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header
      final mockImageClient = MockClient((request) async {
        if (request.url.toString() == 'https://example.com/image.png') {
          return http.Response.bytes(imageBytes, 200);
        }
        return http.Response('Not found', 404);
      });

      final service = ImageService(
        apiKey: 'test-key',
        client: mockClient,
        imageClient: mockImageClient,
      );

      final result = await service.generate('test prompt');

      expect(result, equals(imageBytes));
    });

    test('generate throws on API error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': {'message': 'Invalid API key'}}),
          401,
        );
      });

      final service = ImageService(
        apiKey: 'bad-key',
        client: mockClient,
      );

      expect(
        () => service.generate('test prompt'),
        throwsA(isA<ImageGenerationException>()),
      );
    });

    test('generate retries on failure', () async {
      var attempts = 0;

      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts < 3) {
          return http.Response('Server error', 500);
        }
        return http.Response(
          jsonEncode({
            'data': [{'url': 'https://example.com/image.png'}]
          }),
          200,
        );
      });

      final mockImageClient = MockClient((request) async {
        return http.Response.bytes(Uint8List.fromList([1, 2, 3]), 200);
      });

      final service = ImageService(
        apiKey: 'test-key',
        client: mockClient,
        imageClient: mockImageClient,
        maxRetries: 3,
      );

      final result = await service.generate('test prompt');

      expect(result, isNotNull);
      expect(attempts, 3);
    });

    test('generate throws after max retries', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final service = ImageService(
        apiKey: 'test-key',
        client: mockClient,
        maxRetries: 2,
      );

      expect(
        () => service.generate('test prompt'),
        throwsA(isA<ImageGenerationException>()),
      );
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/services/image_service_test.dart -v`
Expected: FAIL - Target of URI doesn't exist

**Step 3: Implement ImageService**

Create `lib/services/image_service.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Exception thrown when image generation fails.
class ImageGenerationException implements Exception {
  final String message;
  final int? statusCode;

  ImageGenerationException(this.message, [this.statusCode]);

  @override
  String toString() => 'ImageGenerationException: $message (status: $statusCode)';
}

/// Service for generating images via DALL-E 3 API.
class ImageService {
  final String apiKey;
  final http.Client _client;
  final http.Client _imageClient;
  final int maxRetries;

  static const _baseUrl = 'https://api.openai.com/v1/images/generations';

  ImageService({
    required this.apiKey,
    http.Client? client,
    http.Client? imageClient,
    this.maxRetries = 2,
  })  : _client = client ?? http.Client(),
        _imageClient = imageClient ?? http.Client();

  /// Generate an image from the given prompt.
  ///
  /// Returns the image bytes on success.
  /// Throws [ImageGenerationException] on failure after retries.
  Future<Uint8List> generate(String prompt) async {
    Exception? lastError;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final imageUrl = await _callApi(prompt);
        final bytes = await _downloadImage(imageUrl);
        return bytes;
      } on ImageGenerationException catch (e) {
        lastError = e;
        if (attempt < maxRetries) {
          // Exponential backoff: 1s, 2s, 4s...
          await Future.delayed(Duration(seconds: 1 << attempt));
        }
      }
    }

    throw lastError ?? ImageGenerationException('Unknown error');
  }

  Future<String> _callApi(String prompt) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'dall-e-3',
        'prompt': prompt,
        'size': '1024x1024',
        'quality': 'standard',
        'response_format': 'url',
        'n': 1,
      }),
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw ImageGenerationException(error, response.statusCode);
    }

    final data = jsonDecode(response.body);
    return data['data'][0]['url'] as String;
  }

  Future<Uint8List> _downloadImage(String url) async {
    final response = await _imageClient.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw ImageGenerationException(
        'Failed to download image',
        response.statusCode,
      );
    }

    return response.bodyBytes;
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      return data['error']['message'] ?? 'Unknown error';
    } catch (_) {
      return body;
    }
  }

  /// Dispose of HTTP clients.
  void dispose() {
    _client.close();
    _imageClient.close();
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/services/image_service_test.dart -v`
Expected: All 4 tests PASS

**Step 5: Commit**

```bash
git add lib/services/image_service.dart test/services/image_service_test.dart
git commit -m "feat: add ImageService for DALL-E 3 integration"
```

---

## Task 5: Add Service Providers

**Files:**
- Modify: `lib/providers/services.dart`

**Step 1: Add imports and providers**

Add at top of file:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/image_cache.dart';
import '../services/image_service.dart';
```

Add providers at end of file:
```dart
/// Provider for the image cache.
final imageCacheProvider = Provider<ImageCache>((ref) {
  return ImageCache();
});

/// Provider for the image service.
final imageServiceProvider = Provider<ImageService>((ref) {
  final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final service = ImageService(apiKey: apiKey);
  ref.onDispose(() => service.dispose());
  return service;
});
```

**Step 2: Run existing tests to ensure no regressions**

Run: `flutter test`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add lib/providers/services.dart
git commit -m "feat: add imageCacheProvider and imageServiceProvider"
```

---

## Task 6: Update StoryState and Handle GenerateImage Event

**Files:**
- Modify: `lib/providers/story_provider.dart`
- Modify: `test/providers/story_provider_test.dart`

**Step 1: Write failing tests for image handling**

Add to `test/providers/story_provider_test.dart`:

```dart
    test('GenerateImage event triggers image loading state', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: MockElevenLabsService(eventController.stream),
        permission: mockPermission,
        imageService: MockImageService(),
        imageCache: ImageCache(),
      );

      await notifier.startStory();

      // Emit GenerateImage event
      eventController.add(const GenerateImage('test prompt'));
      await Future.microtask(() {});

      expect(notifier.state.isImageLoading, isTrue);
      notifier.dispose();
    });

    test('successful image generation updates state', () async {
      final imageCache = ImageCache();
      final mockImageService = MockImageService(
        generateResult: Uint8List.fromList([1, 2, 3]),
      );

      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: MockElevenLabsService(eventController.stream),
        permission: mockPermission,
        imageService: mockImageService,
        imageCache: imageCache,
      );

      await notifier.startStory();

      eventController.add(const GenerateImage('test prompt'));

      // Wait for async image generation
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isImageLoading, isFalse);
      expect(notifier.state.currentImageIndex, 0);
      expect(notifier.state.imageCount, 1);
      expect(imageCache.get(0), isNotNull);
      notifier.dispose();
    });
```

Also add mock class in test file:
```dart
class MockImageService implements ImageService {
  final Uint8List? generateResult;
  final Exception? generateError;

  MockImageService({this.generateResult, this.generateError});

  @override
  String get apiKey => 'test-key';

  @override
  int get maxRetries => 2;

  @override
  Future<Uint8List> generate(String prompt) async {
    if (generateError != null) throw generateError!;
    return generateResult ?? Uint8List.fromList([]);
  }

  @override
  void dispose() {}
}
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/providers/story_provider_test.dart -v`
Expected: FAIL - missing parameters

**Step 3: Update StoryState to include image fields**

In `lib/providers/story_provider.dart`, update StoryState:

```dart
class StoryState {
  final String storyId;
  final StorySessionStatus sessionStatus;
  final String currentScene;
  final List<String> suggestedActions;
  final bool isAgentSpeaking;
  final ElevenLabsConnectionStatus connectionStatus;
  final String? error;
  final DateTime? lastInteractionTime;
  // New image fields
  final int? currentImageIndex;
  final int imageCount;
  final bool isImageLoading;

  const StoryState({
    required this.storyId,
    this.sessionStatus = StorySessionStatus.idle,
    this.currentScene = 'cottage',
    this.suggestedActions = const [],
    this.isAgentSpeaking = false,
    this.connectionStatus = ElevenLabsConnectionStatus.disconnected,
    this.error,
    this.lastInteractionTime,
    this.currentImageIndex,
    this.imageCount = 0,
    this.isImageLoading = false,
  });

  StoryState copyWith({
    String? storyId,
    StorySessionStatus? sessionStatus,
    String? currentScene,
    List<String>? suggestedActions,
    bool? isAgentSpeaking,
    ElevenLabsConnectionStatus? connectionStatus,
    String? error,
    DateTime? lastInteractionTime,
    bool clearError = false,
    int? currentImageIndex,
    int? imageCount,
    bool? isImageLoading,
  }) {
    return StoryState(
      storyId: storyId ?? this.storyId,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      currentScene: currentScene ?? this.currentScene,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      isAgentSpeaking: isAgentSpeaking ?? this.isAgentSpeaking,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      error: clearError ? null : (error ?? this.error),
      lastInteractionTime: lastInteractionTime ?? this.lastInteractionTime,
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
      imageCount: imageCount ?? this.imageCount,
      isImageLoading: isImageLoading ?? this.isImageLoading,
    );
  }
}
```

**Step 4: Update StoryNotifier to handle GenerateImage**

Update StoryNotifier class:

```dart
class StoryNotifier extends StateNotifier<StoryState> {
  final ElevenLabsService _elevenLabs;
  final PermissionService _permission;
  final ImageService? _imageService;
  final ImageCache? _imageCache;
  StreamSubscription<AgentEvent>? _eventSubscription;

  StoryNotifier({
    required String storyId,
    required ElevenLabsService elevenLabs,
    required PermissionService permission,
    ImageService? imageService,
    ImageCache? imageCache,
  })  : _elevenLabs = elevenLabs,
        _permission = permission,
        _imageService = imageService,
        _imageCache = imageCache,
        super(StoryState(storyId: storyId)) {
    _subscribeToEvents();
  }
```

Update `_handleEvent` for GenerateImage case:

```dart
      case GenerateImage(prompt: final prompt):
        _generateImage(prompt);
```

Add the `_generateImage` method:

```dart
  Future<void> _generateImage(String prompt) async {
    if (_imageService == null || _imageCache == null) return;

    state = state.copyWith(isImageLoading: true);

    try {
      final bytes = await _imageService!.generate(prompt);
      final index = state.imageCount;
      _imageCache!.store(index, bytes);

      state = state.copyWith(
        isImageLoading: false,
        currentImageIndex: index,
        imageCount: index + 1,
      );
    } catch (e) {
      // On failure, just stop loading - keep previous image if any
      state = state.copyWith(isImageLoading: false);
      debugPrint('Image generation failed: $e');
    }
  }
```

Add import at top:
```dart
import '../services/image_cache.dart';
import '../services/image_service.dart';
```

**Step 5: Update storyProvider to include image dependencies**

```dart
final storyProvider = StateNotifierProvider.family<StoryNotifier, StoryState, String>(
  (ref, storyId) {
    final elevenLabs = ref.watch(elevenLabsServiceProvider);
    final permission = ref.watch(permissionServiceProvider);
    final imageService = ref.watch(imageServiceProvider);
    final imageCache = ref.watch(imageCacheProvider);
    return StoryNotifier(
      storyId: storyId,
      elevenLabs: elevenLabs,
      permission: permission,
      imageService: imageService,
      imageCache: imageCache,
    );
  },
);
```

**Step 6: Run tests to verify they pass**

Run: `flutter test test/providers/story_provider_test.dart -v`
Expected: All tests PASS

**Step 7: Commit**

```bash
git add lib/providers/story_provider.dart test/providers/story_provider_test.dart
git commit -m "feat: handle GenerateImage event in StoryNotifier"
```

---

## Task 7: Create SceneImage Widget

**Files:**
- Create: `lib/widgets/scene_image.dart`
- Create: `test/widgets/scene_image_test.dart`

**Step 1: Write failing tests**

Create `test/widgets/scene_image_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/widgets/scene_image.dart';

void main() {
  group('SceneImage', () {
    testWidgets('shows placeholder when imageBytes is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SceneImage(imageBytes: null, isLoading: false),
          ),
        ),
      );

      // Should show placeholder container
      expect(find.byType(SceneImage), findsOneWidget);
      // No Image widget when null
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SceneImage(imageBytes: null, isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays image when imageBytes provided', (tester) async {
      // Create a minimal valid PNG (1x1 transparent pixel)
      final pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SceneImage(imageBytes: pngBytes, isLoading: false),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('has correct aspect ratio (square)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SceneImage(imageBytes: null, isLoading: false),
          ),
        ),
      );

      expect(find.byType(AspectRatio), findsOneWidget);
      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, 1.0);
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/widgets/scene_image_test.dart -v`
Expected: FAIL - Target of URI doesn't exist

**Step 3: Implement SceneImage widget**

Create `lib/widgets/scene_image.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Displays a scene image with Ken Burns animation and crossfade transitions.
class SceneImage extends StatefulWidget {
  final Uint8List? imageBytes;
  final bool isLoading;

  const SceneImage({
    super.key,
    required this.imageBytes,
    required this.isLoading,
  });

  @override
  State<SceneImage> createState() => _SceneImageState();
}

class _SceneImageState extends State<SceneImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05, // 5% zoom
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.imageBytes != null) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SceneImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset animation when image changes
    if (widget.imageBytes != oldWidget.imageBytes) {
      if (widget.imageBytes != null) {
        _controller.forward(from: 0);
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0, // Square
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return Container(
        key: const ValueKey('loading'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.brown.shade100,
              Colors.brown.shade200,
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.imageBytes == null) {
      return Container(
        key: const ValueKey('placeholder'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.brown.shade100,
              Colors.brown.shade200,
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.auto_stories,
            size: 64,
            color: Colors.brown,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      key: ValueKey(widget.imageBytes.hashCode),
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Image.memory(
        widget.imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/widgets/scene_image_test.dart -v`
Expected: All 4 tests PASS

**Step 5: Commit**

```bash
git add lib/widgets/scene_image.dart test/widgets/scene_image_test.dart
git commit -m "feat: add SceneImage widget with Ken Burns animation"
```

---

## Task 8: Integrate SceneImage into StoryScreen

**Files:**
- Modify: `lib/screens/story_screen.dart`

**Step 1: Add import**

```dart
import '../widgets/scene_image.dart';
import '../services/image_cache.dart';
import '../providers/services.dart';
```

**Step 2: Update _buildActiveState to show SceneImage**

Replace the scene indicator Text widget with SceneImage:

```dart
  Widget _buildActiveState(BuildContext context, StoryState state, StoryNotifier notifier, ImageCache imageCache) {
    final imageBytes = state.currentImageIndex != null
        ? imageCache.get(state.currentImageIndex!)
        : null;

    return Column(
      children: [
        // Scene image
        Padding(
          padding: const EdgeInsets.all(16),
          child: SceneImage(
            imageBytes: imageBytes,
            isLoading: state.isImageLoading,
          ),
        ),

        // Speaking indicator
        if (state.isAgentSpeaking)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volume_up, color: Colors.blue),
                SizedBox(width: 8),
                Text('Capy is talking...'),
              ],
            ),
          ),

        const Spacer(),

        // Action cards (existing code)
        ...
      ],
    );
  }
```

**Step 3: Update build method to pass imageCache**

Update the build method to watch imageCache and pass it:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyProvider(storyId));
    final notifier = ref.read(storyProvider(storyId).notifier);
    final imageCache = ref.watch(imageCacheProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Story: $storyId'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showEndDialog(context, notifier),
        ),
      ),
      body: _buildBody(context, state, notifier, imageCache),
    );
  }
```

Update `_buildBody` signature and calls:

```dart
  Widget _buildBody(BuildContext context, StoryState state, StoryNotifier notifier, ImageCache imageCache) {
    switch (state.sessionStatus) {
      case StorySessionStatus.idle:
        return _buildIdleState(notifier);
      case StorySessionStatus.loading:
        return _buildLoadingState();
      case StorySessionStatus.active:
        return _buildActiveState(context, state, notifier, imageCache);
      case StorySessionStatus.ending:
        return _buildLoadingState(message: 'Ending story...');
      case StorySessionStatus.ended:
        return _buildEndedState();
      case StorySessionStatus.error:
        return _buildErrorState(state, notifier);
    }
  }
```

**Step 4: Run all tests**

Run: `flutter test`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/screens/story_screen.dart
git commit -m "feat: integrate SceneImage into StoryScreen"
```

---

## Task 9: End-to-End Test

**Step 1: Run the app on iOS simulator**

Run: `flutter run -d "iPhone 16 Pro"`

**Step 2: Manual test**

1. Launch app
2. Tap story card to start
3. Grant microphone permission
4. Wait for Capy to speak
5. Verify image appears when agent calls generate_image
6. Verify Ken Burns animation (subtle zoom)
7. End story and verify navigation works

**Step 3: Run all tests to confirm nothing broke**

Run: `flutter test`
Expected: All tests PASS

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete Phase 5 - Images implementation"
```

---

## Summary

| Task | Description |
|------|-------------|
| 1 | Fix existing failing test |
| 2 | Add flutter_dotenv and .env |
| 3 | Create ImageCache |
| 4 | Create ImageService |
| 5 | Add service providers |
| 6 | Update StoryState and handle GenerateImage |
| 7 | Create SceneImage widget |
| 8 | Integrate into StoryScreen |
| 9 | End-to-end test |

---

## Post-Implementation Fix: Ken Burns Animation (2026-01-05)

### Issue

The Ken Burns animation was only running for the first image. Subsequent images displayed correctly but without the subtle zoom animation.

### Root Cause

The original `didUpdateWidget` logic didn't reliably detect all image change scenarios, especially when the app was restarted or when widget rebuilds occurred without proper state transitions.

### Solution

Added a fallback check in `build()` to ensure animation is always running when an image is present:

```dart
@override
Widget build(BuildContext context) {
  // Ensure animation is running whenever we have an image
  if (widget.imageBytes != null && !_controller.isAnimating) {
    _controller.repeat(reverse: true);
  }

  return AspectRatio(
    // ...
  );
}
```

Also improved `didUpdateWidget` to properly handle all transitions:

```dart
@override
void didUpdateWidget(SceneImage oldWidget) {
  super.didUpdateWidget(oldWidget);

  final hadImage = oldWidget.imageBytes != null;
  final hasImage = widget.imageBytes != null;

  if (hasImage && !hadImage) {
    // First image arrived
    _controller.stop();
    _controller.reset();
    _controller.repeat(reverse: true);
  } else if (hasImage && hadImage && widget.imageBytes != oldWidget.imageBytes) {
    // Different image - restart animation
    _controller.stop();
    _controller.reset();
    _controller.repeat(reverse: true);
  } else if (!hasImage && hadImage) {
    // Image removed
    _controller.stop();
    _controller.reset();
  }
}
```

### Key Insight

The `build()` fallback is important because:
1. `initState` only runs once when widget is created
2. `didUpdateWidget` might not catch all rebuild scenarios
3. Checking `!_controller.isAnimating` ensures we don't restart unnecessarily
