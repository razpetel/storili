import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../services/image_cache.dart';
import '../services/image_service.dart';
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

/// Provider for the ElevenLabs service.
///
/// Initializes the service and disposes it when no longer needed.
final elevenLabsServiceProvider = Provider<ElevenLabsService>((ref) {
  final tokenProvider = ref.watch(tokenProviderProvider);
  final service = ElevenLabsService(tokenProvider: tokenProvider);
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

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
