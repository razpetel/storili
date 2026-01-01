import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

class CloudflareTokenProvider implements TokenProvider {
  final http.Client _client;
  final Uri _baseUrl;
  final Duration _timeout;

  CloudflareTokenProvider({
    required Uri baseUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client(),
        _timeout = timeout;

  @override
  Future<String> getToken(String storyId) async {
    try {
      final response = await _client
          .post(
            _baseUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'story_id': storyId}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['token'] as String;
      } else if (response.statusCode == 400) {
        throw TokenException('Unknown story: $storyId', TokenErrorType.invalidAgent);
      } else if (response.statusCode == 429) {
        throw const TokenException('Rate limit exceeded', TokenErrorType.rateLimited);
      } else {
        throw TokenException('Server error: ${response.statusCode}', TokenErrorType.serverError);
      }
    } on TimeoutException {
      throw const TokenException('Request timed out', TokenErrorType.network);
    } on http.ClientException catch (e) {
      throw TokenException('Network error: ${e.message}', TokenErrorType.network);
    } on TokenException {
      rethrow;
    } catch (e) {
      throw TokenException('Unexpected error: $e', TokenErrorType.network);
    }
  }
}
