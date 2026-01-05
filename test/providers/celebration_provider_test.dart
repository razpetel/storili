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
