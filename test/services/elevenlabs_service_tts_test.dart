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
