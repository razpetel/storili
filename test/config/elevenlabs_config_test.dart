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
