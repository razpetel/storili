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
