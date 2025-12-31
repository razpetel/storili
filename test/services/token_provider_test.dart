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
