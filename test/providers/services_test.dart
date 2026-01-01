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
