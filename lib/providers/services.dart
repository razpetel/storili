import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/elevenlabs_service.dart';

/// Provider for the ElevenLabs service.
///
/// Initializes the service and disposes it when no longer needed.
final elevenLabsServiceProvider = Provider<ElevenLabsService>((ref) {
  final service = ElevenLabsService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});
