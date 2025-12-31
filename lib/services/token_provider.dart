import '../models/token_exception.dart';

abstract class TokenProvider {
  Future<String> getToken(String agentId);
}

class MockTokenProvider implements TokenProvider {
  final String? _fixedToken;
  final TokenException? _exception;

  MockTokenProvider(String token)
      : _fixedToken = token,
        _exception = null;

  MockTokenProvider.throwing(TokenException exception)
      : _fixedToken = null,
        _exception = exception;

  @override
  Future<String> getToken(String agentId) async {
    if (_exception != null) {
      throw _exception;
    }
    return _fixedToken!;
  }
}
