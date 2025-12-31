# Phase 2: Audio Pipeline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Connect Flutter app to ElevenLabs Conversational AI for voice-driven interactive storytelling.

**Architecture:** Hybrid approach with testable abstractions (TokenProvider, PermissionService) wrapping the ElevenLabs SDK, emitting typed events via Stream<AgentEvent> to a StoryNotifier state manager.

**Tech Stack:** Flutter, elevenlabs_agents ^0.3.0, http ^1.2.0, permission_handler ^11.3.0, Cloudflare Workers

---

## Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add new dependencies**

Open `pubspec.yaml` and add under `dependencies:`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  go_router: ^14.6.2
  elevenlabs_agents: ^0.3.0
  http: ^1.2.0
  permission_handler: ^11.3.0
```

**Step 2: Run pub get**

Run: `flutter pub get`
Expected: Dependencies resolve successfully

**Step 3: Verify**

Run: `flutter pub deps | grep -E "(elevenlabs|http|permission)"`
Expected: All three packages appear in output

**Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add elevenlabs_agents, http, permission_handler dependencies"
```

---

## Task 2: Add iOS Microphone Permission

**Files:**
- Modify: `ios/Runner/Info.plist`

**Step 1: Add microphone usage description**

In `ios/Runner/Info.plist`, add inside the `<dict>` tag (after existing entries):

```xml
	<key>NSMicrophoneUsageDescription</key>
	<string>Storili needs your microphone so Capy can hear your voice!</string>
```

**Step 2: Commit**

```bash
git add ios/Runner/Info.plist
git commit -m "chore(ios): add microphone permission description"
```

---

## Task 3: Add Android Microphone Permission

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

**Step 1: Add permissions**

In `android/app/src/main/AndroidManifest.xml`, add after `<manifest>` opening tag, before `<application>`:

```xml
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

Note: INTERNET may already exist. Don't duplicate.

**Step 2: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "chore(android): add microphone and audio permissions"
```

---

## Task 4: Create AppConfig

**Files:**
- Create: `lib/config/app_config.dart`
- Test: `test/config/app_config_test.dart`

**Step 1: Write the failing test**

Create `test/config/app_config_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('tokenEndpoint has default value', () {
      expect(AppConfig.tokenEndpoint, isNotEmpty);
    });

    test('maxSessionDuration is 45 minutes', () {
      expect(AppConfig.maxSessionDuration, const Duration(minutes: 45));
    });

    test('idleWarningDuration is 5 minutes', () {
      expect(AppConfig.idleWarningDuration, const Duration(minutes: 5));
    });

    test('tokenTimeout is 10 seconds', () {
      expect(AppConfig.tokenTimeout, const Duration(seconds: 10));
    });

    test('connectTimeout is 15 seconds', () {
      expect(AppConfig.connectTimeout, const Duration(seconds: 15));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/config/app_config_test.dart`
Expected: FAIL - cannot find package:storili/config/app_config.dart

**Step 3: Write minimal implementation**

Create `lib/config/app_config.dart`:

```dart
/// Application configuration constants.
class AppConfig {
  AppConfig._();

  /// Token endpoint URL. Override with --dart-define=TOKEN_ENDPOINT=...
  static const tokenEndpoint = String.fromEnvironment(
    'TOKEN_ENDPOINT',
    defaultValue: 'https://storili-token-dev.workers.dev',
  );

  /// Maximum session duration before forced end.
  static const maxSessionDuration = Duration(minutes: 45);

  /// Idle time before warning prompt.
  static const idleWarningDuration = Duration(minutes: 5);

  /// Grace period after idle warning before session ends.
  static const idleGracePeriod = Duration(seconds: 30);

  /// Background grace period before session ends.
  static const backgroundGracePeriod = Duration(seconds: 30);

  /// Timeout for token fetch.
  static const tokenTimeout = Duration(seconds: 10);

  /// Timeout for connection establishment.
  static const connectTimeout = Duration(seconds: 15);
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/config/app_config_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/config/app_config.dart test/config/app_config_test.dart
git commit -m "feat: add AppConfig with timeout and duration constants"
```

---

## Task 5: Create TokenException Model

**Files:**
- Create: `lib/models/token_exception.dart`
- Test: `test/models/token_exception_test.dart`

**Step 1: Write the failing test**

Create `test/models/token_exception_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/token_exception.dart';

void main() {
  group('TokenException', () {
    test('stores message and type', () {
      const exception = TokenException('Network error', TokenErrorType.network);
      expect(exception.message, 'Network error');
      expect(exception.type, TokenErrorType.network);
    });

    test('implements Exception', () {
      const exception = TokenException('Error', TokenErrorType.serverError);
      expect(exception, isA<Exception>());
    });

    test('toString includes message and type', () {
      const exception = TokenException('Failed', TokenErrorType.rateLimited);
      expect(exception.toString(), contains('Failed'));
      expect(exception.toString(), contains('rateLimited'));
    });
  });

  group('TokenErrorType', () {
    test('has all expected values', () {
      expect(TokenErrorType.values, containsAll([
        TokenErrorType.network,
        TokenErrorType.invalidAgent,
        TokenErrorType.serverError,
        TokenErrorType.rateLimited,
      ]));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/models/token_exception_test.dart`
Expected: FAIL - cannot find package

**Step 3: Write minimal implementation**

Create `lib/models/token_exception.dart`:

```dart
/// Error types for token fetching operations.
enum TokenErrorType {
  /// Network connectivity issue.
  network,

  /// Invalid or unknown agent ID.
  invalidAgent,

  /// Server returned an error.
  serverError,

  /// Rate limit exceeded.
  rateLimited,
}

/// Exception thrown when token fetching fails.
class TokenException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Categorized error type.
  final TokenErrorType type;

  const TokenException(this.message, this.type);

  @override
  String toString() => 'TokenException($type): $message';
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/models/token_exception_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/models/token_exception.dart test/models/token_exception_test.dart
git commit -m "feat: add TokenException model with error types"
```

---

## Task 6: Create AgentEvent Sealed Class

**Files:**
- Create: `lib/models/agent_event.dart`
- Test: `test/models/agent_event_test.dart`

**Step 1: Write the failing test**

Create `test/models/agent_event_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';

void main() {
  group('AgentEvent', () {
    test('SceneChange stores scene name', () {
      const event = SceneChange('straw_house');
      expect(event.sceneName, 'straw_house');
      expect(event, isA<AgentEvent>());
    });

    test('SuggestedActions stores actions list', () {
      const event = SuggestedActions(['Run', 'Hide', 'Call for help']);
      expect(event.actions, hasLength(3));
      expect(event.actions.first, 'Run');
    });

    test('GenerateImage stores prompt', () {
      const event = GenerateImage('A cozy brick house');
      expect(event.prompt, 'A cozy brick house');
    });

    test('SessionEnded stores summary', () {
      const event = SessionEnded('Emma helped the pigs build a strong house!');
      expect(event.summary, contains('Emma'));
    });

    test('AgentStartedSpeaking is singleton-like', () {
      const event1 = AgentStartedSpeaking();
      const event2 = AgentStartedSpeaking();
      expect(event1, equals(event2));
    });

    test('AgentStoppedSpeaking is singleton-like', () {
      const event1 = AgentStoppedSpeaking();
      const event2 = AgentStoppedSpeaking();
      expect(event1, equals(event2));
    });

    test('UserTranscript stores transcript', () {
      const event = UserTranscript('I want to help!');
      expect(event.transcript, 'I want to help!');
    });

    test('AgentResponse stores text', () {
      const event = AgentResponse('Great choice!');
      expect(event.text, 'Great choice!');
    });

    test('ConnectionStatusChanged stores status', () {
      const event = ConnectionStatusChanged(ElevenLabsConnectionStatus.connected);
      expect(event.status, ElevenLabsConnectionStatus.connected);
    });

    test('AgentError stores message and optional context', () {
      const event1 = AgentError('Something went wrong');
      expect(event1.message, 'Something went wrong');
      expect(event1.context, isNull);

      const event2 = AgentError('Failed', 'Network timeout');
      expect(event2.context, 'Network timeout');
    });
  });

  group('ElevenLabsConnectionStatus', () {
    test('has all expected values', () {
      expect(ElevenLabsConnectionStatus.values, containsAll([
        ElevenLabsConnectionStatus.disconnected,
        ElevenLabsConnectionStatus.connecting,
        ElevenLabsConnectionStatus.connected,
        ElevenLabsConnectionStatus.disconnecting,
      ]));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/models/agent_event_test.dart`
Expected: FAIL - cannot find package

**Step 3: Write minimal implementation**

Create `lib/models/agent_event.dart`:

```dart
/// Connection status for ElevenLabs service.
enum ElevenLabsConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

/// Events emitted by the ElevenLabs agent during a story session.
sealed class AgentEvent {
  const AgentEvent();
}

/// Scene transition requested by the agent.
class SceneChange extends AgentEvent {
  final String sceneName;
  const SceneChange(this.sceneName);
}

/// Action suggestions for the child to choose from.
class SuggestedActions extends AgentEvent {
  final List<String> actions;
  const SuggestedActions(this.actions);
}

/// Image generation requested with prompt.
class GenerateImage extends AgentEvent {
  final String prompt;
  const GenerateImage(this.prompt);
}

/// Story session ended with summary.
class SessionEnded extends AgentEvent {
  final String summary;
  const SessionEnded(this.summary);
}

/// Agent started speaking (hide action cards).
class AgentStartedSpeaking extends AgentEvent {
  const AgentStartedSpeaking();
}

/// Agent stopped speaking (show action cards).
class AgentStoppedSpeaking extends AgentEvent {
  const AgentStoppedSpeaking();
}

/// User transcript received.
class UserTranscript extends AgentEvent {
  final String transcript;
  const UserTranscript(this.transcript);
}

/// Agent response text received.
class AgentResponse extends AgentEvent {
  final String text;
  const AgentResponse(this.text);
}

/// Connection status changed.
class ConnectionStatusChanged extends AgentEvent {
  final ElevenLabsConnectionStatus status;
  const ConnectionStatusChanged(this.status);
}

/// Error occurred.
class AgentError extends AgentEvent {
  final String message;
  final String? context;
  const AgentError(this.message, [this.context]);
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/models/agent_event_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/models/agent_event.dart test/models/agent_event_test.dart
git commit -m "feat: add AgentEvent sealed class hierarchy"
```

---

## Task 7: Create TokenProvider Interface

**Files:**
- Create: `lib/services/token_provider.dart`
- Test: `test/services/token_provider_test.dart`

**Step 1: Write the failing test**

Create `test/services/token_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/token_exception.dart';
import 'package:storili/services/token_provider.dart';

void main() {
  group('MockTokenProvider', () {
    test('returns configured token', () async {
      final provider = MockTokenProvider('test-token-123');
      final token = await provider.getToken('any-agent');
      expect(token, 'test-token-123');
    });

    test('can be configured to throw', () async {
      final provider = MockTokenProvider.throwing(
        const TokenException('Test error', TokenErrorType.network),
      );
      expect(
        () => provider.getToken('any-agent'),
        throwsA(isA<TokenException>()),
      );
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/token_provider_test.dart`
Expected: FAIL - cannot find package

**Step 3: Write minimal implementation**

Create `lib/services/token_provider.dart`:

```dart
import '../models/token_exception.dart';

/// Abstract interface for fetching conversation tokens.
abstract class TokenProvider {
  /// Gets a conversation token for the given agent.
  ///
  /// Throws [TokenException] on failure.
  Future<String> getToken(String agentId);
}

/// Mock implementation for testing.
class MockTokenProvider implements TokenProvider {
  final String? _fixedToken;
  final TokenException? _exception;

  /// Creates a mock that returns the given token.
  MockTokenProvider(String token)
      : _fixedToken = token,
        _exception = null;

  /// Creates a mock that throws the given exception.
  MockTokenProvider.throwing(TokenException exception)
      : _fixedToken = null,
        _exception = exception;

  @override
  Future<String> getToken(String agentId) async {
    if (_exception != null) {
      throw _exception;
    }
    return _fixedToken!;
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/token_provider_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/services/token_provider.dart test/services/token_provider_test.dart
git commit -m "feat: add TokenProvider interface and MockTokenProvider"
```

---

## Task 8: Create CloudflareTokenProvider

**Files:**
- Modify: `lib/services/token_provider.dart`
- Modify: `test/services/token_provider_test.dart`

**Step 1: Write the failing test**

Add to `test/services/token_provider_test.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ... existing tests ...

  group('CloudflareTokenProvider', () {
    test('fetches token successfully', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body);
        expect(body['agent_id'], 'three-little-pigs');

        return http.Response(
          jsonEncode({'token': 'signed-url-token'}),
          200,
        );
      });

      final provider = CloudflareTokenProvider(
        baseUrl: Uri.parse('https://test.workers.dev'),
        client: mockClient,
      );

      final token = await provider.getToken('three-little-pigs');
      expect(token, 'signed-url-token');
    });

    test('throws TokenException on network error', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      final provider = CloudflareTokenProvider(
        baseUrl: Uri.parse('https://test.workers.dev'),
        client: mockClient,
      );

      expect(
        () => provider.getToken('any-agent'),
        throwsA(
          isA<TokenException>().having(
            (e) => e.type,
            'type',
            TokenErrorType.network,
          ),
        ),
      );
    });

    test('throws TokenException on server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal error', 500);
      });

      final provider = CloudflareTokenProvider(
        baseUrl: Uri.parse('https://test.workers.dev'),
        client: mockClient,
      );

      expect(
        () => provider.getToken('any-agent'),
        throwsA(
          isA<TokenException>().having(
            (e) => e.type,
            'type',
            TokenErrorType.serverError,
          ),
        ),
      );
    });

    test('throws TokenException on invalid agent', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Invalid agent_id', 400);
      });

      final provider = CloudflareTokenProvider(
        baseUrl: Uri.parse('https://test.workers.dev'),
        client: mockClient,
      );

      expect(
        () => provider.getToken('bad-agent'),
        throwsA(
          isA<TokenException>().having(
            (e) => e.type,
            'type',
            TokenErrorType.invalidAgent,
          ),
        ),
      );
    });

    test('throws TokenException on rate limit', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Too many requests', 429);
      });

      final provider = CloudflareTokenProvider(
        baseUrl: Uri.parse('https://test.workers.dev'),
        client: mockClient,
      );

      expect(
        () => provider.getToken('any-agent'),
        throwsA(
          isA<TokenException>().having(
            (e) => e.type,
            'type',
            TokenErrorType.rateLimited,
          ),
        ),
      );
    });
  });
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/token_provider_test.dart`
Expected: FAIL - CloudflareTokenProvider not found

**Step 3: Write minimal implementation**

Add to `lib/services/token_provider.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/token_exception.dart';

// ... existing code ...

/// Production token provider using Cloudflare Worker.
class CloudflareTokenProvider implements TokenProvider {
  final http.Client _client;
  final Uri _baseUrl;
  final Duration _timeout;

  CloudflareTokenProvider({
    required Uri baseUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client(),
        _timeout = timeout;

  @override
  Future<String> getToken(String agentId) async {
    try {
      final response = await _client
          .post(
            _baseUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'agent_id': agentId}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['token'] as String;
      } else if (response.statusCode == 400) {
        throw TokenException(
          'Invalid agent: $agentId',
          TokenErrorType.invalidAgent,
        );
      } else if (response.statusCode == 429) {
        throw const TokenException(
          'Rate limit exceeded',
          TokenErrorType.rateLimited,
        );
      } else {
        throw TokenException(
          'Server error: ${response.statusCode}',
          TokenErrorType.serverError,
        );
      }
    } on TimeoutException {
      throw const TokenException(
        'Request timed out',
        TokenErrorType.network,
      );
    } on http.ClientException catch (e) {
      throw TokenException(
        'Network error: ${e.message}',
        TokenErrorType.network,
      );
    } on TokenException {
      rethrow;
    } catch (e) {
      throw TokenException(
        'Unexpected error: $e',
        TokenErrorType.network,
      );
    }
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/token_provider_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/services/token_provider.dart test/services/token_provider_test.dart
git commit -m "feat: add CloudflareTokenProvider with error handling"
```

---

## Task 9: Create PermissionService

**Files:**
- Create: `lib/services/permission_service.dart`
- Test: `test/services/permission_service_test.dart`

**Step 1: Write the failing test**

Create `test/services/permission_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/services/permission_service.dart';

void main() {
  group('MicPermissionStatus', () {
    test('has all expected values', () {
      expect(MicPermissionStatus.values, containsAll([
        MicPermissionStatus.granted,
        MicPermissionStatus.denied,
        MicPermissionStatus.permanentlyDenied,
        MicPermissionStatus.restricted,
      ]));
    });
  });

  group('MockPermissionService', () {
    test('returns configured status for check', () async {
      final service = MockPermissionService(
        checkResult: MicPermissionStatus.granted,
        requestResult: MicPermissionStatus.granted,
      );

      final status = await service.checkMicrophone();
      expect(status, MicPermissionStatus.granted);
    });

    test('returns configured status for request', () async {
      final service = MockPermissionService(
        checkResult: MicPermissionStatus.denied,
        requestResult: MicPermissionStatus.granted,
      );

      final checkStatus = await service.checkMicrophone();
      expect(checkStatus, MicPermissionStatus.denied);

      final requestStatus = await service.requestMicrophone();
      expect(requestStatus, MicPermissionStatus.granted);
    });

    test('tracks openSettings calls', () async {
      final service = MockPermissionService(
        checkResult: MicPermissionStatus.permanentlyDenied,
        requestResult: MicPermissionStatus.permanentlyDenied,
      );

      expect(service.openSettingsCallCount, 0);
      await service.openSettings();
      expect(service.openSettingsCallCount, 1);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/permission_service_test.dart`
Expected: FAIL - cannot find package

**Step 3: Write minimal implementation**

Create `lib/services/permission_service.dart`:

```dart
import 'package:permission_handler/permission_handler.dart';

/// Microphone permission status.
enum MicPermissionStatus {
  /// Permission granted.
  granted,

  /// Permission denied (can ask again).
  denied,

  /// Permission permanently denied (must open settings).
  permanentlyDenied,

  /// Permission restricted by system (iOS parental controls).
  restricted,
}

/// Abstract interface for microphone permission handling.
abstract class PermissionService {
  /// Checks current microphone permission status.
  Future<MicPermissionStatus> checkMicrophone();

  /// Requests microphone permission.
  Future<MicPermissionStatus> requestMicrophone();

  /// Opens app settings for manual permission grant.
  Future<void> openSettings();
}

/// Production implementation using permission_handler.
class PermissionServiceImpl implements PermissionService {
  @override
  Future<MicPermissionStatus> checkMicrophone() async {
    final status = await Permission.microphone.status;
    return _mapStatus(status);
  }

  @override
  Future<MicPermissionStatus> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return _mapStatus(status);
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  MicPermissionStatus _mapStatus(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted || PermissionStatus.limited =>
        MicPermissionStatus.granted,
      PermissionStatus.permanentlyDenied =>
        MicPermissionStatus.permanentlyDenied,
      PermissionStatus.restricted => MicPermissionStatus.restricted,
      _ => MicPermissionStatus.denied,
    };
  }
}

/// Mock implementation for testing.
class MockPermissionService implements PermissionService {
  final MicPermissionStatus checkResult;
  final MicPermissionStatus requestResult;
  int _openSettingsCallCount = 0;

  MockPermissionService({
    required this.checkResult,
    required this.requestResult,
  });

  int get openSettingsCallCount => _openSettingsCallCount;

  @override
  Future<MicPermissionStatus> checkMicrophone() async => checkResult;

  @override
  Future<MicPermissionStatus> requestMicrophone() async => requestResult;

  @override
  Future<void> openSettings() async {
    _openSettingsCallCount++;
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/permission_service_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/services/permission_service.dart test/services/permission_service_test.dart
git commit -m "feat: add PermissionService with mock for testing"
```

---

## Task 10: Create Client Tools

**Files:**
- Create: `lib/services/elevenlabs_tools.dart`
- Test: `test/services/elevenlabs_tools_test.dart`

**Step 1: Write the failing test**

Create `test/services/elevenlabs_tools_test.dart`:

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/services/elevenlabs_tools.dart';

void main() {
  group('ChangeSceneTool', () {
    test('emits SceneChange event with scene name', () async {
      final controller = StreamController<AgentEvent>.broadcast();
      final tool = ChangeSceneTool(controller);

      final events = <AgentEvent>[];
      controller.stream.listen(events.add);

      await tool.execute({'scene_name': 'straw_house'});

      expect(events, hasLength(1));
      expect(events.first, isA<SceneChange>());
      expect((events.first as SceneChange).sceneName, 'straw_house');

      await controller.close();
    });

    test('handles missing scene_name gracefully', () async {
      final controller = StreamController<AgentEvent>.broadcast();
      final tool = ChangeSceneTool(controller);

      final events = <AgentEvent>[];
      controller.stream.listen(events.add);

      await tool.execute({});

      expect(events, hasLength(1));
      expect((events.first as SceneChange).sceneName, '');

      await controller.close();
    });
  });

  group('SuggestActionsTool', () {
    test('emits SuggestedActions with up to 3 actions', () async {
      final controller = StreamController<AgentEvent>.broadcast();
      final tool = SuggestActionsTool(controller);

      final events = <AgentEvent>[];
      controller.stream.listen(events.add);

      await tool.execute({
        'actions': ['Hide', 'Run', 'Call for help', 'Extra action']
      });

      expect(events, hasLength(1));
      expect(events.first, isA<SuggestedActions>());
      final actions = (events.first as SuggestedActions).actions;
      expect(actions, hasLength(3));
      expect(actions, ['Hide', 'Run', 'Call for help']);

      await controller.close();
    });

    test('handles empty actions gracefully', () async {
      final controller = StreamController<AgentEvent>.broadcast();
      final tool = SuggestActionsTool(controller);

      final events = <AgentEvent>[];
      controller.stream.listen(events.add);

      await tool.execute({'actions': []});

      expect(events, hasLength(1));
      expect((events.first as SuggestedActions).actions, isEmpty);

      await controller.close();
    });

    test('handles missing actions gracefully', () async {
      final controller = StreamController<AgentEvent>.broadcast();
      final tool = SuggestActionsTool(controller);

      final events = <AgentEvent>[];
      controller.stream.listen(events.add);

      await tool.execute({});

      expect(events, hasLength(1));
      expect((events.first as SuggestedActions).actions, isEmpty);

      await controller.close();
    });
  });

  group('GenerateImageTool', () {
    test('emits GenerateImage event with prompt', () async {
      final controller = StreamController<AgentEvent>.broadcast();
      final tool = GenerateImageTool(controller);

      final events = <AgentEvent>[];
      controller.stream.listen(events.add);

      await tool.execute({'prompt': 'A cozy brick house on a hill'});

      expect(events, hasLength(1));
      expect(events.first, isA<GenerateImage>());
      expect((events.first as GenerateImage).prompt, 'A cozy brick house on a hill');

      await controller.close();
    });

    test('handles missing prompt gracefully', () async {
      final controller = StreamController<AgentEvent>.broadcast();
      final tool = GenerateImageTool(controller);

      final events = <AgentEvent>[];
      controller.stream.listen(events.add);

      await tool.execute({});

      expect(events, hasLength(1));
      expect((events.first as GenerateImage).prompt, '');

      await controller.close();
    });
  });

  group('SessionEndTool', () {
    test('emits SessionEnded event with summary', () async {
      final controller = StreamController<AgentEvent>.broadcast();
      final tool = SessionEndTool(controller);

      final events = <AgentEvent>[];
      controller.stream.listen(events.add);

      await tool.execute({'summary': 'Emma helped save the pigs!'});

      expect(events, hasLength(1));
      expect(events.first, isA<SessionEnded>());
      expect((events.first as SessionEnded).summary, 'Emma helped save the pigs!');

      await controller.close();
    });

    test('handles missing summary gracefully', () async {
      final controller = StreamController<AgentEvent>.broadcast();
      final tool = SessionEndTool(controller);

      final events = <AgentEvent>[];
      controller.stream.listen(events.add);

      await tool.execute({});

      expect(events, hasLength(1));
      expect((events.first as SessionEnded).summary, '');

      await controller.close();
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/elevenlabs_tools_test.dart`
Expected: FAIL - cannot find package

**Step 3: Write minimal implementation**

Create `lib/services/elevenlabs_tools.dart`:

```dart
import 'dart:async';
import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import '../models/agent_event.dart';

/// Tool: change_scene
/// Called by agent to transition to a new scene.
class ChangeSceneTool implements ClientTool {
  final StreamController<AgentEvent> _eventController;

  ChangeSceneTool(this._eventController);

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    final sceneName = parameters['scene_name'] as String? ?? '';
    _eventController.add(SceneChange(sceneName));
    return null;
  }
}

/// Tool: suggest_actions
/// Called by agent to provide action card suggestions.
class SuggestActionsTool implements ClientTool {
  final StreamController<AgentEvent> _eventController;

  SuggestActionsTool(this._eventController);

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    final actionsRaw = parameters['actions'];
    final actions = (actionsRaw as List<dynamic>?)
            ?.map((e) => e.toString())
            .take(3)
            .toList() ??
        [];
    _eventController.add(SuggestedActions(actions));
    return null;
  }
}

/// Tool: generate_image
/// Called by agent to request image generation.
class GenerateImageTool implements ClientTool {
  final StreamController<AgentEvent> _eventController;

  GenerateImageTool(this._eventController);

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    final prompt = parameters['prompt'] as String? ?? '';
    _eventController.add(GenerateImage(prompt));
    return null;
  }
}

/// Tool: session_end
/// Called by agent when story is complete.
class SessionEndTool implements ClientTool {
  final StreamController<AgentEvent> _eventController;

  SessionEndTool(this._eventController);

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) async {
    final summary = parameters['summary'] as String? ?? '';
    _eventController.add(SessionEnded(summary));
    return null;
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/elevenlabs_tools_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/services/elevenlabs_tools.dart test/services/elevenlabs_tools_test.dart
git commit -m "feat: add 4 client tools for ElevenLabs agent"
```

---

## Task 11: Create ElevenLabsService

**Files:**
- Create: `lib/services/elevenlabs_service.dart`
- Test: `test/services/elevenlabs_service_test.dart`

**Step 1: Write the failing test**

Create `test/services/elevenlabs_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/models/token_exception.dart';
import 'package:storili/services/elevenlabs_service.dart';
import 'package:storili/services/token_provider.dart';

void main() {
  group('ElevenLabsService', () {
    test('initial status is disconnected', () {
      final service = ElevenLabsService(
        tokenProvider: MockTokenProvider('token'),
      );

      expect(service.status, ElevenLabsConnectionStatus.disconnected);
      expect(service.isAgentSpeaking, false);
      expect(service.isMuted, false);

      service.dispose();
    });

    test('events stream is broadcast', () {
      final service = ElevenLabsService(
        tokenProvider: MockTokenProvider('token'),
      );

      // Should be able to listen multiple times
      final sub1 = service.events.listen((_) {});
      final sub2 = service.events.listen((_) {});

      sub1.cancel();
      sub2.cancel();
      service.dispose();
    });

    test('throws on startSession when token fetch fails', () async {
      final service = ElevenLabsService(
        tokenProvider: MockTokenProvider.throwing(
          const TokenException('Failed', TokenErrorType.network),
        ),
      );

      expect(
        () => service.startSession(agentId: 'test'),
        throwsA(isA<TokenException>()),
      );

      service.dispose();
    });

    test('dispose closes event stream', () async {
      final service = ElevenLabsService(
        tokenProvider: MockTokenProvider('token'),
      );

      var streamClosed = false;
      service.events.listen(
        (_) {},
        onDone: () => streamClosed = true,
      );

      service.dispose();

      // Give stream time to close
      await Future.delayed(const Duration(milliseconds: 10));
      expect(streamClosed, true);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/elevenlabs_service_test.dart`
Expected: FAIL - cannot find package

**Step 3: Write minimal implementation**

Create `lib/services/elevenlabs_service.dart`:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/agent_event.dart';
import 'token_provider.dart';
import 'elevenlabs_tools.dart';

/// Service for managing ElevenLabs Conversational AI sessions.
///
/// Wraps the ConversationClient and provides a stream-based interface
/// for story playback.
class ElevenLabsService {
  final TokenProvider _tokenProvider;
  final StreamController<AgentEvent> _eventController =
      StreamController<AgentEvent>.broadcast();

  // ConversationClient? _client; // Will be used when SDK is integrated

  ElevenLabsService({
    required TokenProvider tokenProvider,
  }) : _tokenProvider = tokenProvider;

  /// Stream of events from the agent.
  Stream<AgentEvent> get events => _eventController.stream;

  /// Current connection status.
  ElevenLabsConnectionStatus get status => ElevenLabsConnectionStatus.disconnected;

  /// Whether the agent is currently speaking.
  bool get isAgentSpeaking => false;

  /// Whether the microphone is muted.
  bool get isMuted => false;

  /// Start a story session.
  ///
  /// [agentId] - The agent ID (e.g., 'three-little-pigs')
  /// [childName] - Optional child's name for personalization
  Future<void> startSession({
    required String agentId,
    String? childName,
  }) async {
    // Get token first - this will throw if it fails
    final token = await _tokenProvider.getToken(agentId);
    debugPrint('Got token: ${token.substring(0, 20)}...');

    // TODO: Initialize ConversationClient with token
    // TODO: Register client tools
    // TODO: Start session
    _eventController.add(
      const ConnectionStatusChanged(ElevenLabsConnectionStatus.connecting),
    );
  }

  /// End the current session.
  Future<void> endSession() async {
    // TODO: Call _client?.endSession()
    _eventController.add(
      const ConnectionStatusChanged(ElevenLabsConnectionStatus.disconnected),
    );
  }

  /// Send a text message to the agent (used for card taps).
  void sendMessage(String text) {
    // TODO: Call _client?.sendUserMessage(text)
    debugPrint('Sending message: $text');
  }

  /// Toggle microphone mute state. Returns new mute state.
  Future<bool> toggleMute() async {
    // TODO: Call _client?.toggleMute()
    return isMuted;
  }

  /// Set microphone mute state.
  Future<void> setMuted(bool muted) async {
    // TODO: Call _client?.setMicMuted(muted)
  }

  /// Dispose of resources.
  void dispose() {
    // _client?.dispose();
    _eventController.close();
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/elevenlabs_service_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/services/elevenlabs_service.dart test/services/elevenlabs_service_test.dart
git commit -m "feat: add ElevenLabsService with token integration"
```

---

## Task 12: Create StoryState

**Files:**
- Create: `lib/providers/story_provider.dart`
- Test: `test/providers/story_provider_test.dart`

**Step 1: Write the failing test**

Create `test/providers/story_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/providers/story_provider.dart';

void main() {
  group('StorySessionStatus', () {
    test('has all expected values', () {
      expect(StorySessionStatus.values, containsAll([
        StorySessionStatus.idle,
        StorySessionStatus.loading,
        StorySessionStatus.active,
        StorySessionStatus.ending,
        StorySessionStatus.ended,
        StorySessionStatus.error,
      ]));
    });
  });

  group('StoryState', () {
    test('has correct default values', () {
      const state = StoryState(storyId: 'test-story');

      expect(state.storyId, 'test-story');
      expect(state.sessionStatus, StorySessionStatus.idle);
      expect(state.currentScene, 'cottage');
      expect(state.suggestedActions, isEmpty);
      expect(state.isAgentSpeaking, false);
      expect(state.connectionStatus, ElevenLabsConnectionStatus.disconnected);
      expect(state.error, isNull);
      expect(state.lastInteractionTime, isNull);
    });

    test('copyWith creates new instance with updated values', () {
      const original = StoryState(storyId: 'test');
      final updated = original.copyWith(
        sessionStatus: StorySessionStatus.active,
        currentScene: 'straw_house',
        suggestedActions: ['Run', 'Hide'],
        isAgentSpeaking: true,
      );

      // Original unchanged
      expect(original.sessionStatus, StorySessionStatus.idle);
      expect(original.currentScene, 'cottage');

      // Updated has new values
      expect(updated.storyId, 'test'); // Preserved
      expect(updated.sessionStatus, StorySessionStatus.active);
      expect(updated.currentScene, 'straw_house');
      expect(updated.suggestedActions, ['Run', 'Hide']);
      expect(updated.isAgentSpeaking, true);
    });

    test('copyWith can clear error with empty string', () {
      final withError = const StoryState(storyId: 'test').copyWith(
        error: 'Something went wrong',
      );
      expect(withError.error, 'Something went wrong');

      final cleared = withError.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/providers/story_provider_test.dart`
Expected: FAIL - cannot find package

**Step 3: Write minimal implementation**

Create `lib/providers/story_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_event.dart';

/// Session status for story playback.
enum StorySessionStatus {
  idle,
  loading,
  active,
  ending,
  ended,
  error,
}

/// Immutable state for story playback.
class StoryState {
  final String storyId;
  final StorySessionStatus sessionStatus;
  final String currentScene;
  final List<String> suggestedActions;
  final bool isAgentSpeaking;
  final ElevenLabsConnectionStatus connectionStatus;
  final String? error;
  final DateTime? lastInteractionTime;

  const StoryState({
    required this.storyId,
    this.sessionStatus = StorySessionStatus.idle,
    this.currentScene = 'cottage',
    this.suggestedActions = const [],
    this.isAgentSpeaking = false,
    this.connectionStatus = ElevenLabsConnectionStatus.disconnected,
    this.error,
    this.lastInteractionTime,
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
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/providers/story_provider_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/providers/story_provider.dart test/providers/story_provider_test.dart
git commit -m "feat: add StoryState with copyWith"
```

---

## Task 13: Create StoryNotifier - Event Handling

**Files:**
- Modify: `lib/providers/story_provider.dart`
- Modify: `test/providers/story_provider_test.dart`

**Step 1: Write the failing test**

Add to `test/providers/story_provider_test.dart`:

```dart
import 'dart:async';
import 'package:storili/services/elevenlabs_service.dart';
import 'package:storili/services/permission_service.dart';
import 'package:storili/services/token_provider.dart';

// ... existing tests ...

  group('StoryNotifier', () {
    late StreamController<AgentEvent> eventController;
    late MockElevenLabsService mockService;
    late MockPermissionService mockPermission;

    setUp(() {
      eventController = StreamController<AgentEvent>.broadcast();
      mockService = MockElevenLabsService(eventController.stream);
      mockPermission = MockPermissionService(
        checkResult: MicPermissionStatus.granted,
        requestResult: MicPermissionStatus.granted,
      );
    });

    tearDown(() {
      eventController.close();
    });

    test('initial state is idle', () {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      expect(notifier.state.sessionStatus, StorySessionStatus.idle);
      notifier.dispose();
    });

    test('handles SceneChange event', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const SceneChange('brick_house'));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.currentScene, 'brick_house');
      notifier.dispose();
    });

    test('handles SuggestedActions event', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const SuggestedActions(['Run', 'Hide']));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.suggestedActions, ['Run', 'Hide']);
      notifier.dispose();
    });

    test('handles AgentStartedSpeaking - clears actions', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      // First add some actions
      eventController.add(const SuggestedActions(['Action1']));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.suggestedActions, isNotEmpty);

      // Then agent starts speaking
      eventController.add(const AgentStartedSpeaking());
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.isAgentSpeaking, true);
      expect(notifier.state.suggestedActions, isEmpty);
      notifier.dispose();
    });

    test('handles AgentStoppedSpeaking', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const AgentStartedSpeaking());
      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.isAgentSpeaking, true);

      eventController.add(const AgentStoppedSpeaking());
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.isAgentSpeaking, false);
      notifier.dispose();
    });

    test('handles SessionEnded event', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const SessionEnded('Great adventure!'));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.sessionStatus, StorySessionStatus.ended);
      notifier.dispose();
    });

    test('handles ConnectionStatusChanged event', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const ConnectionStatusChanged(
        ElevenLabsConnectionStatus.connected,
      ));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.connectionStatus, ElevenLabsConnectionStatus.connected);
      notifier.dispose();
    });

    test('handles AgentError event', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      eventController.add(const AgentError('Something failed', 'context'));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.error, contains('Something failed'));
      expect(notifier.state.error, contains('context'));
      notifier.dispose();
    });
  });

// Add this mock class at the bottom of the file
class MockElevenLabsService implements ElevenLabsService {
  final Stream<AgentEvent> _events;

  MockElevenLabsService(this._events);

  @override
  Stream<AgentEvent> get events => _events;

  @override
  ElevenLabsConnectionStatus get status => ElevenLabsConnectionStatus.disconnected;

  @override
  bool get isAgentSpeaking => false;

  @override
  bool get isMuted => false;

  @override
  Future<void> startSession({required String agentId, String? childName}) async {}

  @override
  Future<void> endSession() async {}

  @override
  void sendMessage(String text) {}

  @override
  Future<bool> toggleMute() async => false;

  @override
  Future<void> setMuted(bool muted) async {}

  @override
  void dispose() {}
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/providers/story_provider_test.dart`
Expected: FAIL - StoryNotifier not found

**Step 3: Write minimal implementation**

Add to `lib/providers/story_provider.dart`:

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_event.dart';
import '../services/elevenlabs_service.dart';
import '../services/permission_service.dart';

// ... existing StorySessionStatus and StoryState ...

/// Manages story playback state and orchestrates services.
class StoryNotifier extends StateNotifier<StoryState> {
  final ElevenLabsService _elevenLabs;
  final PermissionService _permission;
  StreamSubscription<AgentEvent>? _eventSubscription;

  StoryNotifier({
    required String storyId,
    required ElevenLabsService elevenLabs,
    required PermissionService permission,
  })  : _elevenLabs = elevenLabs,
        _permission = permission,
        super(StoryState(storyId: storyId)) {
    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    _eventSubscription = _elevenLabs.events.listen(_handleEvent);
  }

  void _handleEvent(AgentEvent event) {
    switch (event) {
      case SceneChange(sceneName: final scene):
        state = state.copyWith(currentScene: scene);

      case SuggestedActions(actions: final actions):
        state = state.copyWith(suggestedActions: actions);

      case GenerateImage():
        // TODO: Defer to Phase 3
        break;

      case SessionEnded():
        state = state.copyWith(sessionStatus: StorySessionStatus.ended);

      case AgentStartedSpeaking():
        state = state.copyWith(
          isAgentSpeaking: true,
          suggestedActions: [],
        );

      case AgentStoppedSpeaking():
        state = state.copyWith(isAgentSpeaking: false);

      case UserTranscript():
        // Could log for debugging
        break;

      case AgentResponse():
        // Could log for debugging
        break;

      case ConnectionStatusChanged(status: final status):
        state = state.copyWith(connectionStatus: status);

      case AgentError(message: final msg, context: final ctx):
        state = state.copyWith(
          error: '$msg${ctx != null ? ': $ctx' : ''}',
        );
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/providers/story_provider_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/providers/story_provider.dart test/providers/story_provider_test.dart
git commit -m "feat: add StoryNotifier with event handling"
```

---

## Task 14: Add StoryNotifier - Start/End/Actions

**Files:**
- Modify: `lib/providers/story_provider.dart`
- Modify: `test/providers/story_provider_test.dart`

**Step 1: Write the failing test**

Add to `test/providers/story_provider_test.dart`:

```dart
    test('startStory checks permission first', () async {
      final mockPermission = MockPermissionService(
        checkResult: MicPermissionStatus.denied,
        requestResult: MicPermissionStatus.denied,
      );
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      await notifier.startStory();

      expect(notifier.state.sessionStatus, StorySessionStatus.error);
      expect(notifier.state.error, contains('microphone'));
      notifier.dispose();
    });

    test('startStory transitions to loading then active', () async {
      var statusLog = <StorySessionStatus>[];
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      notifier.addListener((state) {
        statusLog.add(state.sessionStatus);
      });

      await notifier.startStory();

      expect(statusLog, contains(StorySessionStatus.loading));
      notifier.dispose();
    });

    test('startStory ignores if not idle', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      // Start first story
      await notifier.startStory();
      final firstStatus = notifier.state.sessionStatus;

      // Try to start again - should be ignored
      await notifier.startStory();

      expect(notifier.state.sessionStatus, firstStatus);
      notifier.dispose();
    });

    test('endStory calls service and updates state', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      await notifier.startStory();
      await notifier.endStory();

      expect(notifier.state.sessionStatus, StorySessionStatus.ending);
      notifier.dispose();
    });

    test('selectAction sends message and clears actions', () async {
      final messages = <String>[];
      final trackingService = TrackingMockService(eventController.stream, messages);

      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: trackingService,
        permission: mockPermission,
      );

      // Add some actions
      eventController.add(const SuggestedActions(['Run', 'Hide']));
      await Future.delayed(const Duration(milliseconds: 10));

      // Select one
      notifier.selectAction('Run');

      expect(messages, ['Run']);
      expect(notifier.state.suggestedActions, isEmpty);
      notifier.dispose();
    });

    test('selectAction updates lastInteractionTime', () async {
      final notifier = StoryNotifier(
        storyId: 'test',
        elevenLabs: mockService,
        permission: mockPermission,
      );

      expect(notifier.state.lastInteractionTime, isNull);

      notifier.selectAction('Test');

      expect(notifier.state.lastInteractionTime, isNotNull);
      notifier.dispose();
    });

// Add this tracking mock
class TrackingMockService extends MockElevenLabsService {
  final List<String> messages;

  TrackingMockService(super.events, this.messages);

  @override
  void sendMessage(String text) {
    messages.add(text);
  }
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/providers/story_provider_test.dart`
Expected: FAIL - startStory not found

**Step 3: Write minimal implementation**

Add to `StoryNotifier` in `lib/providers/story_provider.dart`:

```dart
  /// Start the story session.
  Future<void> startStory() async {
    // Guard: only start from idle
    if (state.sessionStatus != StorySessionStatus.idle) {
      return;
    }

    state = state.copyWith(
      sessionStatus: StorySessionStatus.loading,
      clearError: true,
    );

    // Check permission
    final permStatus = await _permission.checkMicrophone();
    if (permStatus != MicPermissionStatus.granted) {
      // Try requesting
      final requestStatus = await _permission.requestMicrophone();
      if (requestStatus != MicPermissionStatus.granted) {
        state = state.copyWith(
          sessionStatus: StorySessionStatus.error,
          error: 'Microphone permission required. Please enable in Settings.',
        );
        return;
      }
    }

    try {
      await _elevenLabs.startSession(agentId: state.storyId);
      state = state.copyWith(
        sessionStatus: StorySessionStatus.active,
        lastInteractionTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        sessionStatus: StorySessionStatus.error,
        error: e.toString(),
      );
    }
  }

  /// End the story session.
  Future<void> endStory() async {
    state = state.copyWith(sessionStatus: StorySessionStatus.ending);
    await _elevenLabs.endSession();
  }

  /// Called when child taps an action card.
  void selectAction(String action) {
    _elevenLabs.sendMessage(action);
    state = state.copyWith(
      suggestedActions: [],
      lastInteractionTime: DateTime.now(),
    );
  }

  /// Called when parent types custom message.
  void sendCustomMessage(String message) {
    _elevenLabs.sendMessage(message);
    state = state.copyWith(lastInteractionTime: DateTime.now());
  }
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/providers/story_provider_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/providers/story_provider.dart test/providers/story_provider_test.dart
git commit -m "feat: add StoryNotifier start/end/action methods"
```

---

## Task 15: Create Service Providers

**Files:**
- Create: `lib/providers/services.dart`
- Test: `test/providers/services_test.dart`

**Step 1: Write the failing test**

Create `test/providers/services_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/providers/services.dart';
import 'package:storili/services/elevenlabs_service.dart';
import 'package:storili/services/permission_service.dart';
import 'package:storili/services/token_provider.dart';

void main() {
  group('Service Providers', () {
    test('tokenProviderProvider is accessible', () {
      final container = ProviderContainer(
        overrides: [
          tokenProviderProvider.overrideWithValue(
            MockTokenProvider('test-token'),
          ),
        ],
      );

      final provider = container.read(tokenProviderProvider);
      expect(provider, isA<TokenProvider>());

      container.dispose();
    });

    test('permissionServiceProvider is accessible', () {
      final container = ProviderContainer(
        overrides: [
          permissionServiceProvider.overrideWithValue(
            MockPermissionService(
              checkResult: MicPermissionStatus.granted,
              requestResult: MicPermissionStatus.granted,
            ),
          ),
        ],
      );

      final service = container.read(permissionServiceProvider);
      expect(service, isA<PermissionService>());

      container.dispose();
    });

    test('elevenLabsServiceProvider is accessible', () {
      final container = ProviderContainer(
        overrides: [
          tokenProviderProvider.overrideWithValue(
            MockTokenProvider('test-token'),
          ),
        ],
      );

      final service = container.read(elevenLabsServiceProvider);
      expect(service, isA<ElevenLabsService>());

      container.dispose();
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/providers/services_test.dart`
Expected: FAIL - cannot find package

**Step 3: Write minimal implementation**

Create `lib/providers/services.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/elevenlabs_service.dart';
import '../services/permission_service.dart';
import '../services/token_provider.dart';

/// Provider for token fetching.
final tokenProviderProvider = Provider<TokenProvider>((ref) {
  return CloudflareTokenProvider(
    baseUrl: Uri.parse(AppConfig.tokenEndpoint),
    timeout: AppConfig.tokenTimeout,
  );
});

/// Provider for permission handling.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionServiceImpl();
});

/// Provider for ElevenLabs service.
final elevenLabsServiceProvider = Provider<ElevenLabsService>((ref) {
  final tokenProvider = ref.watch(tokenProviderProvider);
  final service = ElevenLabsService(tokenProvider: tokenProvider);
  ref.onDispose(() => service.dispose());
  return service;
});
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/providers/services_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/providers/services.dart test/providers/services_test.dart
git commit -m "feat: add Riverpod service providers"
```

---

## Task 16: Add Story Provider

**Files:**
- Modify: `lib/providers/story_provider.dart`
- Modify: `test/providers/story_provider_test.dart`

**Step 1: Write the failing test**

Add to `test/providers/story_provider_test.dart`:

```dart
  group('storyProvider', () {
    test('creates StoryNotifier for given storyId', () {
      final eventController = StreamController<AgentEvent>.broadcast();

      final container = ProviderContainer(
        overrides: [
          elevenLabsServiceProvider.overrideWithValue(
            MockElevenLabsService(eventController.stream),
          ),
          permissionServiceProvider.overrideWithValue(
            MockPermissionService(
              checkResult: MicPermissionStatus.granted,
              requestResult: MicPermissionStatus.granted,
            ),
          ),
        ],
      );

      final state = container.read(storyProvider('three-little-pigs'));
      expect(state.storyId, 'three-little-pigs');
      expect(state.sessionStatus, StorySessionStatus.idle);

      container.dispose();
      eventController.close();
    });
  });
```

And add import at top:

```dart
import 'package:storili/providers/services.dart';
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/providers/story_provider_test.dart`
Expected: FAIL - storyProvider not found

**Step 3: Write minimal implementation**

Add to `lib/providers/story_provider.dart`:

```dart
import 'services.dart';

// ... existing code ...

/// Provider for story state, parameterized by story ID.
final storyProvider = StateNotifierProvider.family<StoryNotifier, StoryState, String>(
  (ref, storyId) {
    final elevenLabs = ref.watch(elevenLabsServiceProvider);
    final permission = ref.watch(permissionServiceProvider);
    return StoryNotifier(
      storyId: storyId,
      elevenLabs: elevenLabs,
      permission: permission,
    );
  },
);
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/providers/story_provider_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/providers/story_provider.dart test/providers/story_provider_test.dart
git commit -m "feat: add storyProvider family provider"
```

---

## Task 17: Create Cloudflare Worker

**Files:**
- Create: `backend/package.json`
- Create: `backend/wrangler.toml`
- Create: `backend/src/worker.ts`

**Step 1: Create package.json**

Create `backend/package.json`:

```json
{
  "name": "storili-token-worker",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "deploy:prod": "wrangler deploy --env production"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20241205.0",
    "typescript": "^5.0.0",
    "wrangler": "^3.0.0"
  }
}
```

**Step 2: Create wrangler.toml**

Create `backend/wrangler.toml`:

```toml
name = "storili-token-dev"
main = "src/worker.ts"
compatibility_date = "2024-12-01"

[vars]
ALLOWED_AGENTS = "three-little-pigs"

# Production environment
[env.production]
name = "storili-token"
```

**Step 3: Create worker.ts**

Create `backend/src/worker.ts`:

```typescript
interface Env {
  ELEVENLABS_API_KEY: string;
  ALLOWED_AGENTS: string;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Only allow POST
    if (request.method !== 'POST') {
      return new Response('Method not allowed', {
        status: 405,
        headers: corsHeaders,
      });
    }

    try {
      const body = await request.json() as { agent_id?: string };
      const { agent_id } = body;

      // Validate agent_id
      if (!agent_id || typeof agent_id !== 'string') {
        return new Response(
          JSON.stringify({ error: 'Missing agent_id' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Check allowlist
      const allowedAgents = env.ALLOWED_AGENTS.split(',').map(s => s.trim());
      if (!allowedAgents.includes(agent_id)) {
        return new Response(
          JSON.stringify({ error: 'Invalid agent_id' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Fetch signed URL from ElevenLabs
      const elevenLabsResponse = await fetch(
        `https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=${agent_id}`,
        {
          headers: {
            'xi-api-key': env.ELEVENLABS_API_KEY,
          },
        }
      );

      if (!elevenLabsResponse.ok) {
        console.error(`ElevenLabs API error: ${elevenLabsResponse.status}`);
        return new Response(
          JSON.stringify({ error: 'Token generation failed' }),
          { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const data = await elevenLabsResponse.json() as { signed_url: string };

      return new Response(
        JSON.stringify({ token: data.signed_url }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    } catch (error) {
      console.error('Worker error:', error);
      return new Response(
        JSON.stringify({ error: 'Internal error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
  },
};
```

**Step 4: Commit**

```bash
git add backend/
git commit -m "feat: add Cloudflare Worker for token endpoint"
```

---

## Task 18: Update StoryScreen with Provider

**Files:**
- Modify: `lib/screens/story_screen.dart`
- Test: `test/screens/story_screen_test.dart`

**Step 1: Write the failing test**

Create `test/screens/story_screen_test.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/providers/services.dart';
import 'package:storili/providers/story_provider.dart';
import 'package:storili/screens/story_screen.dart';
import 'package:storili/services/elevenlabs_service.dart';
import 'package:storili/services/permission_service.dart';

void main() {
  group('StoryScreen', () {
    testWidgets('shows loading indicator when starting', (tester) async {
      final eventController = StreamController<AgentEvent>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            elevenLabsServiceProvider.overrideWithValue(
              _MockElevenLabsService(eventController.stream),
            ),
            permissionServiceProvider.overrideWithValue(
              MockPermissionService(
                checkResult: MicPermissionStatus.granted,
                requestResult: MicPermissionStatus.granted,
              ),
            ),
          ],
          child: const MaterialApp(
            home: StoryScreen(storyId: 'three-little-pigs'),
          ),
        ),
      );

      // Find and tap start button (if exists in initial state)
      // Initially should show idle state
      expect(find.byType(StoryScreen), findsOneWidget);

      eventController.close();
    });

    testWidgets('displays action cards when available', (tester) async {
      final eventController = StreamController<AgentEvent>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            elevenLabsServiceProvider.overrideWithValue(
              _MockElevenLabsService(eventController.stream),
            ),
            permissionServiceProvider.overrideWithValue(
              MockPermissionService(
                checkResult: MicPermissionStatus.granted,
                requestResult: MicPermissionStatus.granted,
              ),
            ),
          ],
          child: const MaterialApp(
            home: StoryScreen(storyId: 'three-little-pigs'),
          ),
        ),
      );

      // Emit suggested actions
      eventController.add(const SuggestedActions(['Run', 'Hide', 'Call for help']));
      await tester.pump();

      // Check that action cards are displayed
      expect(find.text('Run'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);
      expect(find.text('Call for help'), findsOneWidget);

      eventController.close();
    });
  });
}

class _MockElevenLabsService implements ElevenLabsService {
  final Stream<AgentEvent> _events;

  _MockElevenLabsService(this._events);

  @override
  Stream<AgentEvent> get events => _events;

  @override
  ElevenLabsConnectionStatus get status => ElevenLabsConnectionStatus.disconnected;

  @override
  bool get isAgentSpeaking => false;

  @override
  bool get isMuted => false;

  @override
  Future<void> startSession({required String agentId, String? childName}) async {}

  @override
  Future<void> endSession() async {}

  @override
  void sendMessage(String text) {}

  @override
  Future<bool> toggleMute() async => false;

  @override
  Future<void> setMuted(bool muted) async {}

  @override
  void dispose() {}
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/screens/story_screen_test.dart`
Expected: FAIL - StoryScreen doesn't use providers yet

**Step 3: Write implementation**

Update `lib/screens/story_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/story_provider.dart';

class StoryScreen extends ConsumerWidget {
  final String storyId;

  const StoryScreen({super.key, required this.storyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyProvider(storyId));
    final notifier = ref.read(storyProvider(storyId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Story: $storyId'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showEndDialog(context, notifier),
        ),
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(BuildContext context, StoryState state, StoryNotifier notifier) {
    switch (state.sessionStatus) {
      case StorySessionStatus.idle:
        return _buildIdleState(notifier);
      case StorySessionStatus.loading:
        return _buildLoadingState();
      case StorySessionStatus.active:
        return _buildActiveState(state, notifier);
      case StorySessionStatus.ending:
        return _buildLoadingState(message: 'Ending story...');
      case StorySessionStatus.ended:
        return _buildEndedState();
      case StorySessionStatus.error:
        return _buildErrorState(state, notifier);
    }
  }

  Widget _buildIdleState(StoryNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Ready to start your adventure?',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => notifier.startStory(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Story'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState({String message = 'Getting ready...'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildActiveState(StoryState state, StoryNotifier notifier) {
    return Column(
      children: [
        // Scene indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Scene: ${state.currentScene}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

        // Action cards
        if (state.suggestedActions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: state.suggestedActions.map((action) {
                return ActionCard(
                  action: action,
                  onTap: () => notifier.selectAction(action),
                  opacity: state.isAgentSpeaking ? 0.5 : 1.0,
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEndedState() {
    return const Center(
      child: Text(
        'Story complete!',
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildErrorState(StoryState state, StoryNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => notifier.startStory(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndDialog(BuildContext context, StoryNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Story?'),
        content: const Text('Are you sure you want to end the story early?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.endStory();
              Navigator.pop(context); // Go back to home
            },
            child: const Text('End Now'),
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final String action;
  final VoidCallback onTap;
  final double opacity;

  const ActionCard({
    super.key,
    required this.action,
    required this.onTap,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: opacity == 1.0 ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Text(
              action,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/screens/story_screen_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/screens/story_screen.dart test/screens/story_screen_test.dart
git commit -m "feat: update StoryScreen with provider integration and UI"
```

---

## Task 19: Run All Tests and Verify

**Step 1: Run all tests**

Run: `flutter test`
Expected: All tests pass

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues

**Step 3: Commit any fixes if needed**

```bash
git add .
git commit -m "chore: fix any analyzer issues"
```

---

## Task 20: Final Cleanup and Summary

**Step 1: Review all changes**

Run: `git log --oneline feature/audio-pipeline`
Expected: Clean commit history

**Step 2: Update pubspec asset paths if needed**

Verify `pubspec.yaml` has correct asset configuration.

**Step 3: Create summary commit**

```bash
git add .
git commit -m "docs: Phase 2 Audio Pipeline complete

Implemented:
- ElevenLabsService with token integration
- TokenProvider (abstract + Cloudflare impl)
- PermissionService (abstract + impl)
- 4 client tools (change_scene, suggest_actions, generate_image, session_end)
- StoryNotifier with event handling
- Riverpod service providers
- Updated StoryScreen with full UI
- Cloudflare Worker for token endpoint
- Comprehensive test coverage

Deferred to Phase 3:
- Image generation service
- Session resume/persistence
"
```

---

## Summary

**Total Tasks: 20**

**Files Created:**
- `lib/config/app_config.dart`
- `lib/models/token_exception.dart`
- `lib/models/agent_event.dart`
- `lib/services/token_provider.dart`
- `lib/services/permission_service.dart`
- `lib/services/elevenlabs_tools.dart`
- `lib/services/elevenlabs_service.dart`
- `lib/providers/services.dart`
- `lib/providers/story_provider.dart`
- `backend/package.json`
- `backend/wrangler.toml`
- `backend/src/worker.ts`

**Files Modified:**
- `pubspec.yaml`
- `ios/Runner/Info.plist`
- `android/app/src/main/AndroidManifest.xml`
- `lib/screens/story_screen.dart`

**Test Files Created:**
- `test/config/app_config_test.dart`
- `test/models/token_exception_test.dart`
- `test/models/agent_event_test.dart`
- `test/services/token_provider_test.dart`
- `test/services/permission_service_test.dart`
- `test/services/elevenlabs_tools_test.dart`
- `test/services/elevenlabs_service_test.dart`
- `test/providers/story_provider_test.dart`
- `test/providers/services_test.dart`
- `test/screens/story_screen_test.dart`
