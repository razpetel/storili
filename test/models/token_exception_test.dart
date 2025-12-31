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
