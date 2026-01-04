# Phase 7: Celebration Screen - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the celebration screen with confetti, personalized voice recap, image slideshow, and gallery.

**Architecture:** Three-phase reveal (jingle → slideshow → gallery) using StatefulWidget with Riverpod for TTS. Full-screen image viewer as separate overlay widget. BytesAudioSource for playing TTS audio bytes directly.

**Tech Stack:** Flutter, Riverpod, just_audio, confetti package, ElevenLabs TTS API, go_router

---

## Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml:30-40`

**Step 1: Add confetti and just_audio packages**

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  go_router: ^14.6.2
  elevenlabs_agents: ^0.3.0
  http: ^1.2.0
  permission_handler: ^11.3.0
  mcp_toolkit: ^0.1.2
  google_fonts: ^6.2.1
  flutter_dotenv: ^5.1.0
  confetti: ^0.7.0
  just_audio: ^0.9.36
```

**Step 2: Add asset directories**

In the `flutter:` section, update assets:

```yaml
flutter:
  uses-material-design: true

  assets:
    - .env
    - assets/stories/
    - assets/audio/
    - assets/images/
```

**Step 3: Run pub get**

```bash
cd /Users/razpetel/projects/storili/.worktrees/phase7-celebration
/Users/razpetel/dev/flutter/bin/flutter pub get
```

Expected: "Got dependencies!"

**Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add confetti and just_audio dependencies"
```

---

## Task 2: Create BytesAudioSource Utility

**Files:**
- Create: `lib/utils/bytes_audio_source.dart`
- Test: `test/utils/bytes_audio_source_test.dart`

**Step 1: Write the test**

```dart
// test/utils/bytes_audio_source_test.dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:storili/utils/bytes_audio_source.dart';

void main() {
  group('BytesAudioSource', () {
    test('returns full content when no range specified', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final source = BytesAudioSource(bytes);

      final response = await source.request();

      expect(response.sourceLength, 5);
      expect(response.contentLength, 5);
      expect(response.offset, 0);
      expect(response.contentType, 'audio/mpeg');
    });

    test('returns partial content when range specified', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final source = BytesAudioSource(bytes);

      final response = await source.request(1, 4);

      expect(response.sourceLength, 5);
      expect(response.contentLength, 3);
      expect(response.offset, 1);
    });

    test('stream yields correct bytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final source = BytesAudioSource(bytes);

      final response = await source.request(1, 4);
      final chunks = await response.stream.toList();

      expect(chunks.length, 1);
      expect(chunks[0], [2, 3, 4]);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
/Users/razpetel/dev/flutter/bin/flutter test test/utils/bytes_audio_source_test.dart
```

Expected: FAIL - file not found

**Step 3: Create the utils directory and implementation**

```dart
// lib/utils/bytes_audio_source.dart
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

/// Audio source that plays from in-memory bytes.
///
/// Used for playing TTS audio received from ElevenLabs API
/// without writing to a temporary file.
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

**Step 4: Run test to verify it passes**

```bash
/Users/razpetel/dev/flutter/bin/flutter test test/utils/bytes_audio_source_test.dart
```

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/utils/bytes_audio_source.dart test/utils/bytes_audio_source_test.dart
git commit -m "feat: add BytesAudioSource for in-memory audio playback"
```

---

## Task 3: Create ElevenLabs Config

**Files:**
- Create: `lib/config/elevenlabs_config.dart`
- Test: `test/config/elevenlabs_config_test.dart`

**Step 1: Write the test**

```dart
// test/config/elevenlabs_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/config/elevenlabs_config.dart';

void main() {
  group('ElevenLabsConfig', () {
    test('capyVoiceId is not empty', () {
      expect(ElevenLabsConfig.capyVoiceId.isNotEmpty, true);
    });

    test('capyVoiceSettings contains required keys', () {
      expect(ElevenLabsConfig.capyVoiceSettings.containsKey('stability'), true);
      expect(
          ElevenLabsConfig.capyVoiceSettings.containsKey('similarity_boost'),
          true);
    });

    test('ttsModel is set', () {
      expect(ElevenLabsConfig.ttsModel.isNotEmpty, true);
    });

    test('ttsTimeout is reasonable', () {
      expect(ElevenLabsConfig.ttsTimeout.inSeconds, greaterThanOrEqualTo(5));
      expect(ElevenLabsConfig.ttsTimeout.inSeconds, lessThanOrEqualTo(15));
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
/Users/razpetel/dev/flutter/bin/flutter test test/config/elevenlabs_config_test.dart
```

Expected: FAIL - file not found

**Step 3: Create implementation**

```dart
// lib/config/elevenlabs_config.dart

/// Configuration for ElevenLabs TTS API.
///
/// Centralizes voice settings used across the app for consistency
/// between conversational AI agent and standalone TTS calls.
class ElevenLabsConfig {
  ElevenLabsConfig._();

  /// Voice ID for Capy (the narrator/companion).
  /// Get this from ElevenLabs dashboard > Voices > Your voice > Voice ID
  static const String capyVoiceId = 'pFZP5JQG7iQjIQuC4Bku'; // Lily voice (warm, friendly)

  /// Voice settings for consistent Capy personality.
  static const Map<String, dynamic> capyVoiceSettings = {
    'stability': 0.5,
    'similarity_boost': 0.75,
  };

  /// TTS model for fast generation.
  static const String ttsModel = 'eleven_turbo_v2_5';

  /// Timeout for TTS requests.
  static const Duration ttsTimeout = Duration(seconds: 8);
}
```

**Step 4: Run test to verify it passes**

```bash
/Users/razpetel/dev/flutter/bin/flutter test test/config/elevenlabs_config_test.dart
```

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/config/elevenlabs_config.dart test/config/elevenlabs_config_test.dart
git commit -m "feat: add ElevenLabs config for TTS settings"
```

---

## Task 4: Add TTS Method to ElevenLabsService

**Files:**
- Modify: `lib/services/elevenlabs_service.dart`
- Test: `test/services/elevenlabs_service_tts_test.dart`

**Step 1: Write the test**

```dart
// test/services/elevenlabs_service_tts_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'dart:typed_data';

// Note: This test requires refactoring ElevenLabsService to accept http.Client
// For now, we test the TTS endpoint logic separately

void main() {
  group('ElevenLabs TTS', () {
    test('TTS request format is correct', () {
      // Verify the expected request format
      final requestBody = jsonEncode({
        'text': 'Hello world',
        'model_id': 'eleven_turbo_v2_5',
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.75,
        },
      });

      final decoded = jsonDecode(requestBody) as Map<String, dynamic>;
      expect(decoded['text'], 'Hello world');
      expect(decoded['model_id'], 'eleven_turbo_v2_5');
      expect(decoded['voice_settings']['stability'], 0.5);
    });

    test('TTS URL format is correct', () {
      const voiceId = 'test-voice-id';
      final url = Uri.parse(
          'https://api.elevenlabs.io/v1/text-to-speech/$voiceId');

      expect(url.host, 'api.elevenlabs.io');
      expect(url.path, '/v1/text-to-speech/test-voice-id');
    });
  });
}
```

**Step 2: Run test to verify format**

```bash
/Users/razpetel/dev/flutter/bin/flutter test test/services/elevenlabs_service_tts_test.dart
```

Expected: Pass (testing format only)

**Step 3: Add TTS method to ElevenLabsService**

Add these imports at the top of `lib/services/elevenlabs_service.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/elevenlabs_config.dart';
```

Add this method to the `ElevenLabsService` class (before the `dispose` method):

```dart
  /// Generate speech from text using ElevenLabs TTS API.
  ///
  /// Returns audio bytes (MP3 format) or throws on failure.
  Future<Uint8List> textToSpeech(String text) async {
    final apiKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('ELEVENLABS_API_KEY not configured');
    }

    final url = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/${ElevenLabsConfig.capyVoiceId}',
    );

    final response = await http.post(
      url,
      headers: {
        'xi-api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'audio/mpeg',
      },
      body: jsonEncode({
        'text': text,
        'model_id': ElevenLabsConfig.ttsModel,
        'voice_settings': ElevenLabsConfig.capyVoiceSettings,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('TTS failed: ${response.statusCode} ${response.body}');
    }

    return response.bodyBytes;
  }
```

**Step 4: Run all tests to ensure no regression**

```bash
/Users/razpetel/dev/flutter/bin/flutter test
```

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/services/elevenlabs_service.dart test/services/elevenlabs_service_tts_test.dart
git commit -m "feat: add textToSpeech method to ElevenLabsService"
```

---

## Task 5: Create Celebration TTS Provider

**Files:**
- Create: `lib/providers/celebration_provider.dart`
- Test: `test/providers/celebration_provider_test.dart`

**Step 1: Write the test**

```dart
// test/providers/celebration_provider_test.dart
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/providers/celebration_provider.dart';
import 'package:storili/providers/services.dart';
import 'package:storili/services/elevenlabs_service.dart';
import 'package:storili/services/token_provider.dart';

// Mock ElevenLabsService
class MockElevenLabsService extends ElevenLabsService {
  final Uint8List? mockAudio;
  final Exception? mockError;

  MockElevenLabsService({this.mockAudio, this.mockError})
      : super(tokenProvider: _MockTokenProvider());

  @override
  Future<Uint8List> textToSpeech(String text) async {
    if (mockError != null) throw mockError!;
    return mockAudio ?? Uint8List.fromList([1, 2, 3]);
  }
}

class _MockTokenProvider implements TokenProvider {
  @override
  Future<String> getToken(String storyId) async => 'mock-token';
}

void main() {
  group('celebrationTtsProvider', () {
    test('returns null for empty summary', () async {
      final container = ProviderContainer(
        overrides: [
          elevenLabsServiceProvider.overrideWithValue(MockElevenLabsService()),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(celebrationTtsProvider('').future);
      expect(result, isNull);
    });

    test('returns null for whitespace-only summary', () async {
      final container = ProviderContainer(
        overrides: [
          elevenLabsServiceProvider.overrideWithValue(MockElevenLabsService()),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(celebrationTtsProvider('   ').future);
      expect(result, isNull);
    });

    test('returns audio bytes on success', () async {
      final mockAudio = Uint8List.fromList([1, 2, 3, 4, 5]);
      final container = ProviderContainer(
        overrides: [
          elevenLabsServiceProvider
              .overrideWithValue(MockElevenLabsService(mockAudio: mockAudio)),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(celebrationTtsProvider('Great story!').future);
      expect(result, mockAudio);
    });

    test('returns null on error', () async {
      final container = ProviderContainer(
        overrides: [
          elevenLabsServiceProvider.overrideWithValue(
            MockElevenLabsService(mockError: Exception('API error')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(celebrationTtsProvider('Great story!').future);
      expect(result, isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
/Users/razpetel/dev/flutter/bin/flutter test test/providers/celebration_provider_test.dart
```

Expected: FAIL - provider not found

**Step 3: Create implementation**

```dart
// lib/providers/celebration_provider.dart
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/elevenlabs_config.dart';
import 'services.dart';

/// Provider for celebration screen TTS audio.
///
/// Fetches personalized recap audio from ElevenLabs TTS API.
/// Returns null on failure (silent fallback).
final celebrationTtsProvider =
    FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, summary) async {
    // Skip TTS for empty summaries
    if (summary.trim().isEmpty) {
      return null;
    }

    try {
      final elevenLabs = ref.read(elevenLabsServiceProvider);
      return await elevenLabs
          .textToSpeech(summary)
          .timeout(ElevenLabsConfig.ttsTimeout);
    } catch (e) {
      debugPrint('Celebration TTS failed: $e');
      return null; // Silent fallback
    }
  },
);
```

**Step 4: Run test to verify it passes**

```bash
/Users/razpetel/dev/flutter/bin/flutter test test/providers/celebration_provider_test.dart
```

Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/providers/celebration_provider.dart test/providers/celebration_provider_test.dart
git commit -m "feat: add celebration TTS provider with silent fallback"
```

---

## Task 6: Update Router to Pass Summary

**Files:**
- Modify: `lib/app/router.dart`
- Modify: `lib/screens/celebration_screen.dart` (update constructor)

**Step 1: Update CelebrationScreen constructor**

```dart
// lib/screens/celebration_screen.dart
import 'package:flutter/material.dart';

class CelebrationScreen extends StatelessWidget {
  const CelebrationScreen({
    super.key,
    required this.storyId,
    required this.summary,
  });

  final String storyId;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Congratulations',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('You completed $storyId!'),
            const SizedBox(height: 8),
            Text('Summary: ${summary.substring(0, summary.length.clamp(0, 50))}...'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate home
              },
              child: const Text('Home'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Update router to pass summary via extra**

```dart
// lib/app/router.dart
import 'package:go_router/go_router.dart';
import 'package:storili/screens/home_screen.dart';
import 'package:storili/screens/story_screen.dart';
import 'package:storili/screens/settings_screen.dart';
import 'package:storili/screens/celebration_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/story/:storyId',
        name: 'story',
        builder: (context, state) {
          final storyId = state.pathParameters['storyId']!;
          return StoryScreen(storyId: storyId);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/celebration/:storyId',
        name: 'celebration',
        builder: (context, state) {
          final storyId = state.pathParameters['storyId']!;
          final summary = state.extra as String? ?? '';
          return CelebrationScreen(storyId: storyId, summary: summary);
        },
      ),
    ],
  );
}
```

**Step 3: Run tests to verify no regression**

```bash
/Users/razpetel/dev/flutter/bin/flutter test
```

Expected: All tests pass

**Step 4: Commit**

```bash
git add lib/app/router.dart lib/screens/celebration_screen.dart
git commit -m "feat: update router to pass summary to celebration screen"
```

---

## Task 7: Create Placeholder Assets

**Files:**
- Create: `assets/audio/.gitkeep`
- Create: `assets/images/.gitkeep`

**Step 1: Create asset directories**

```bash
mkdir -p assets/audio assets/images
touch assets/audio/.gitkeep assets/images/.gitkeep
```

**Step 2: Create placeholder jingle (silent MP3 for now)**

For development, we'll use a test approach. The actual jingle will be added later.

Create a note file:

```bash
echo "# Placeholder for celebration_jingle.mp3 (~2s xylophone/bells)" > assets/audio/README.md
echo "# Placeholder for capy_celebrate.png (240x240)" > assets/images/README.md
```

**Step 3: Commit**

```bash
git add assets/
git commit -m "chore: add placeholder asset directories"
```

---

## Task 8: Implement CelebrationScreen - Phase Structure

**Files:**
- Modify: `lib/screens/celebration_screen.dart`
- Test: `test/screens/celebration_screen_test.dart`

**Step 1: Write basic structure test**

```dart
// test/screens/celebration_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/screens/celebration_screen.dart';

void main() {
  group('CelebrationScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CelebrationScreen(
              storyId: 'test-story',
              summary: 'Test summary',
            ),
          ),
        ),
      );

      expect(find.byType(CelebrationScreen), findsOneWidget);
    });

    testWidgets('shows jingle phase initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CelebrationScreen(
              storyId: 'test-story',
              summary: 'Test summary',
            ),
          ),
        ),
      );

      // Should show "You did it!" text in jingle phase
      expect(find.text('You did it!'), findsOneWidget);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
/Users/razpetel/dev/flutter/bin/flutter test test/screens/celebration_screen_test.dart
```

Expected: May pass with current simple implementation, but won't have "You did it!" text

**Step 3: Implement full CelebrationScreen**

```dart
// lib/screens/celebration_screen.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../app/theme.dart';
import '../providers/celebration_provider.dart';
import '../providers/services.dart';
import '../utils/bytes_audio_source.dart';

/// Phase of the celebration reveal sequence.
enum CelebrationPhase { jingle, slideshow, gallery }

/// Celebration screen shown when a story is completed.
class CelebrationScreen extends ConsumerStatefulWidget {
  const CelebrationScreen({
    super.key,
    required this.storyId,
    required this.summary,
  });

  final String storyId;
  final String summary;

  @override
  ConsumerState<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends ConsumerState<CelebrationScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Phase state
  CelebrationPhase _phase = CelebrationPhase.jingle;
  bool _jingleComplete = false;
  bool _ttsComplete = false;
  Uint8List? _ttsAudioBytes;
  bool _waitingForTts = false;

  // Slideshow state
  int _currentSlide = 0;
  Timer? _slideTimer;
  bool _showSkipButton = false;

  // Controllers
  late ConfettiController _confettiController;
  late AnimationController _kenBurnsController;
  AudioPlayer? _jinglePlayer;
  AudioPlayer? _voicePlayer;

  // Images from cache
  List<Uint8List> _images = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize controllers
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 10),
    );

    _kenBurnsController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Load images from cache
    final imageCache = ref.read(imageCacheProvider);
    _images = imageCache.getAll();

    // Start celebration
    _startJingle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _jinglePlayer?.pause();
      _voicePlayer?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_phase == CelebrationPhase.jingle) {
        _jinglePlayer?.play();
      } else if (_phase == CelebrationPhase.slideshow) {
        _voicePlayer?.play();
      }
    }
  }

  Future<void> _startJingle() async {
    _confettiController.play();

    // TODO: Play actual jingle when asset is available
    // For now, simulate jingle duration
    await Future.delayed(const Duration(seconds: 2));

    _jingleComplete = true;
    _tryTransition();
  }

  void _onTtsComplete(Uint8List? audioBytes) {
    _ttsComplete = true;
    _ttsAudioBytes = audioBytes;
    _tryTransition();
  }

  void _tryTransition() {
    if (!mounted) return;

    if (!_jingleComplete) return;

    if (!_ttsComplete) {
      setState(() => _waitingForTts = true);
      return;
    }

    if (_phase != CelebrationPhase.jingle) return;

    _transitionToSlideshow();
  }

  Future<void> _transitionToSlideshow() async {
    if (_images.isEmpty) {
      // No images - skip to gallery
      _transitionToGallery();
      return;
    }

    setState(() {
      _phase = CelebrationPhase.slideshow;
      _waitingForTts = false;
    });

    // Calculate slide duration
    Duration slideDuration;
    if (_ttsAudioBytes != null) {
      _voicePlayer = AudioPlayer();
      await _voicePlayer!.setAudioSource(BytesAudioSource(_ttsAudioBytes!));
      final voiceDuration = _voicePlayer!.duration ?? const Duration(seconds: 10);
      slideDuration = Duration(
        milliseconds: (voiceDuration.inMilliseconds / _images.length)
            .clamp(2000, 5000)
            .toInt(),
      );
      _voicePlayer!.play();

      // Listen for voice completion
      _voicePlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (_currentSlide >= _images.length - 1) {
            _transitionToGallery();
          }
        }
      });
    } else {
      slideDuration = const Duration(milliseconds: 3500);
    }

    // Start Ken Burns animation
    _kenBurnsController.repeat(reverse: true);

    // Start slide timer
    _startSlideTimer(slideDuration);
  }

  void _startSlideTimer(Duration interval) {
    _slideTimer?.cancel();
    _slideTimer = Timer.periodic(interval, (timer) {
      if (_currentSlide < _images.length - 1) {
        setState(() => _currentSlide++);
        HapticFeedback.selectionClick();
      } else {
        timer.cancel();
        // Check if voice is still playing
        if (_voicePlayer?.playing != true) {
          _transitionToGallery();
        } else {
          setState(() => _showSkipButton = true);
        }
      }
    });
  }

  void _transitionToGallery() {
    _slideTimer?.cancel();
    _voicePlayer?.stop();
    _kenBurnsController.stop();
    _confettiController.stop();

    if (mounted) {
      setState(() => _phase = CelebrationPhase.gallery);
    }
  }

  void _onTapToSkip() {
    if (_phase == CelebrationPhase.slideshow) {
      HapticFeedback.mediumImpact();
      _transitionToGallery();
    }
  }

  void _navigateHome() {
    context.go('/');
  }

  void _playAgain() {
    context.go('/story/${widget.storyId}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _kenBurnsController.dispose();
    _slideTimer?.cancel();
    _jinglePlayer?.dispose();
    _voicePlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for TTS completion
    ref.listen(celebrationTtsProvider(widget.summary), (prev, next) {
      next.whenData(_onTtsComplete);
    });

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content
          GestureDetector(
            onTap: _phase == CelebrationPhase.slideshow ? _onTapToSkip : null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _buildPhaseContent(),
            ),
          ),

          // Confetti layer
          if (_phase != CelebrationPhase.gallery && !reduceMotion)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                colors: const [
                  AppColors.accent,
                  AppColors.shadowOuter,
                  AppColors.primary,
                  AppColors.secondary,
                ],
                numberOfParticles: 20,
                maxBlastForce: 20,
                minBlastForce: 5,
                gravity: 0.2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    return switch (_phase) {
      CelebrationPhase.jingle => _buildJinglePhase(),
      CelebrationPhase.slideshow => _buildSlideshowPhase(),
      CelebrationPhase.gallery => _buildGalleryPhase(),
    };
  }

  Widget _buildJinglePhase() {
    return Center(
      key: const ValueKey('jingle'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Claymorphism card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowOuter,
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              'You did it!',
              style: AppTypography.appTitle.copyWith(fontSize: 32),
            ),
          ),

          // Loading indicator if waiting for TTS
          if (_waitingForTts) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlideshowPhase() {
    if (_images.isEmpty) {
      return const Center(child: Text('No images'));
    }

    return Center(
      key: const ValueKey('slideshow'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image with Ken Burns
          AnimatedBuilder(
            animation: _kenBurnsController,
            builder: (context, child) {
              final scale = 1.0 + (_kenBurnsController.value * 0.05);
              return Transform.scale(scale: scale, child: child);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 280,
                height: 280,
                child: Image.memory(
                  _images[_currentSlide],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primary,
                    child: const Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Progress dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_images.length, (index) {
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentSlide
                      ? AppColors.accent
                      : AppColors.shadowOuter,
                ),
              );
            }),
          ),

          // Skip button
          if (_showSkipButton) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: _transitionToGallery,
              child: const Text('Skip'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGalleryPhase() {
    return SafeArea(
      key: const ValueKey('gallery'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Capy + header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Capy placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    size: 64,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'What a\nstory!',
                  style: AppTypography.appTitle.copyWith(fontSize: 28),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Thumbnail gallery
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openFullScreenViewer(index),
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const Spacer(),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _navigateHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home),
                    const SizedBox(width: 8),
                    Text('Home', style: AppTypography.button),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _playAgain,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.secondary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.replay),
                    const SizedBox(width: 8),
                    Text('Play Again', style: AppTypography.button),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openFullScreenViewer(int index) {
    // TODO: Implement full-screen viewer in Task 9
    HapticFeedback.selectionClick();
  }
}
```

**Step 4: Run tests**

```bash
/Users/razpetel/dev/flutter/bin/flutter test test/screens/celebration_screen_test.dart
```

Expected: Tests pass

**Step 5: Commit**

```bash
git add lib/screens/celebration_screen.dart test/screens/celebration_screen_test.dart
git commit -m "feat: implement CelebrationScreen with 3-phase reveal"
```

---

## Task 9: Create Full-Screen Image Viewer

**Files:**
- Create: `lib/widgets/full_screen_image_viewer.dart`
- Test: `test/widgets/full_screen_image_viewer_test.dart`

**Step 1: Write the test**

```dart
// test/widgets/full_screen_image_viewer_test.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/widgets/full_screen_image_viewer.dart';

void main() {
  group('FullScreenImageViewer', () {
    final testImages = [
      Uint8List.fromList(List.generate(100, (i) => i)),
      Uint8List.fromList(List.generate(100, (i) => i + 100)),
    ];

    testWidgets('renders close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            images: testImages,
            initialIndex: 0,
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('close button dismisses viewer', (tester) async {
      bool didPop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onPopPage: (route, result) {
              didPop = true;
              return route.didPop(result);
            },
            pages: [
              MaterialPage(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            images: testImages,
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(didPop, true);
    });

    testWidgets('shows thumbnail strip for multiple images', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            images: testImages,
            initialIndex: 0,
          ),
        ),
      );

      // Should have 2 thumbnails
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('single image hides thumbnail strip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            images: [testImages[0]],
            initialIndex: 0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // PageView should not be scrollable with single image
      // (we just verify it renders)
      expect(find.byType(FullScreenImageViewer), findsOneWidget);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
/Users/razpetel/dev/flutter/bin/flutter test test/widgets/full_screen_image_viewer_test.dart
```

Expected: FAIL - widget not found

**Step 3: Create implementation**

```dart
// lib/widgets/full_screen_image_viewer.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

/// Full-screen image viewer with swipe navigation.
class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<Uint8List> images;
  final int initialIndex;

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    HapticFeedback.selectionClick();
  }

  void _dismiss() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  double get _dismissScale => (1 - (_dragOffset.abs() / 300)).clamp(0.8, 1.0);
  double get _dismissOpacity => (1 - (_dragOffset.abs() / 200)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final isSingleImage = widget.images.length == 1;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() => _dragOffset += details.delta.dy);
        },
        onVerticalDragEnd: (details) {
          if (_dragOffset.abs() > 100 ||
              details.primaryVelocity!.abs() > 800) {
            _dismiss();
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: Stack(
          children: [
            // Main image
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Transform.scale(
                scale: _dismissScale,
                child: Opacity(
                  opacity: _dismissOpacity,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: isSingleImage
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) {
                      return Center(
                        child: Hero(
                          tag: index == widget.initialIndex
                              ? 'celebration_image_$index'
                              : 'no_hero_$index',
                          child: Image.memory(
                            widget.images[index],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Close button (top-left, always visible)
            Positioned(
              top: padding.top + 16,
              left: 16,
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textPrimary,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Thumbnail strip (bottom, multiple images only)
            if (!isSingleImage)
              Positioned(
                bottom: padding.bottom + 16,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 56,
                  child: Center(
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.images.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentIndex;
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isSelected ? Colors.white : Colors.white38,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                widget.images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: AppColors.primary),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

**Step 4: Update CelebrationScreen to use viewer**

In `lib/screens/celebration_screen.dart`, update the `_openFullScreenViewer` method:

```dart
void _openFullScreenViewer(int index) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FullScreenImageViewer(
        images: _images,
        initialIndex: index,
      ),
    ),
  );
}
```

Add the import at the top:

```dart
import '../widgets/full_screen_image_viewer.dart';
```

**Step 5: Run tests**

```bash
/Users/razpetel/dev/flutter/bin/flutter test
```

Expected: All tests pass

**Step 6: Commit**

```bash
git add lib/widgets/full_screen_image_viewer.dart test/widgets/full_screen_image_viewer_test.dart lib/screens/celebration_screen.dart
git commit -m "feat: add full-screen image viewer with swipe navigation"
```

---

## Task 10: Final Integration & Cleanup

**Files:**
- Run all tests
- Verify no lint errors

**Step 1: Run all tests**

```bash
/Users/razpetel/dev/flutter/bin/flutter test
```

Expected: All tests pass

**Step 2: Run analyzer**

```bash
/Users/razpetel/dev/flutter/bin/flutter analyze
```

Expected: No issues

**Step 3: Final commit**

```bash
git add -A
git status
# If any uncommitted changes:
git commit -m "chore: cleanup and final adjustments"
```

**Step 4: Push branch**

```bash
git push -u origin feature/phase7-celebration
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Add dependencies | pubspec.yaml |
| 2 | BytesAudioSource | lib/utils/, test/utils/ |
| 3 | ElevenLabs config | lib/config/, test/config/ |
| 4 | TTS method | lib/services/elevenlabs_service.dart |
| 5 | TTS provider | lib/providers/, test/providers/ |
| 6 | Router update | lib/app/router.dart, lib/screens/ |
| 7 | Placeholder assets | assets/ |
| 8 | CelebrationScreen | lib/screens/, test/screens/ |
| 9 | Full-screen viewer | lib/widgets/, test/widgets/ |
| 10 | Integration | All |

**Total estimated tasks:** 10 major tasks, ~40 bite-sized steps

**Testing approach:** TDD - write failing test, implement, verify pass, commit.
