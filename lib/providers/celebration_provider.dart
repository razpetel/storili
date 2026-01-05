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
