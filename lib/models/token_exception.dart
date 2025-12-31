enum TokenErrorType {
  network,
  invalidAgent,
  serverError,
  rateLimited,
}

class TokenException implements Exception {
  final String message;
  final TokenErrorType type;

  const TokenException(this.message, this.type);

  @override
  String toString() => 'TokenException($type): $message';
}
