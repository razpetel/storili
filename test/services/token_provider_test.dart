import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  group('CloudflareTokenProvider', () {
    test('fetches token successfully', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body);
        expect(body['agent_id'], 'three-little-pigs');

        return http.Response(
          jsonEncode({'token': 'signed-url-token'}),
          200,
        );
      });

      final provider = CloudflareTokenProvider(
        baseUrl: Uri.parse('https://test.workers.dev'),
        client: mockClient,
      );

      final token = await provider.getToken('three-little-pigs');
      expect(token, 'signed-url-token');
    });

    test('throws TokenException on network error', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      final provider = CloudflareTokenProvider(
        baseUrl: Uri.parse('https://test.workers.dev'),
        client: mockClient,
      );

      expect(
        () => provider.getToken('any-agent'),
        throwsA(
          isA<TokenException>().having((e) => e.type, 'type', TokenErrorType.network),
        ),
      );
    });

    test('throws TokenException on server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal error', 500);
      });

      final provider = CloudflareTokenProvider(
        baseUrl: Uri.parse('https://test.workers.dev'),
        client: mockClient,
      );

      expect(
        () => provider.getToken('any-agent'),
        throwsA(
          isA<TokenException>().having((e) => e.type, 'type', TokenErrorType.serverError),
        ),
      );
    });

    test('throws TokenException on invalid agent', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Invalid agent_id', 400);
      });

      final provider = CloudflareTokenProvider(
        baseUrl: Uri.parse('https://test.workers.dev'),
        client: mockClient,
      );

      expect(
        () => provider.getToken('bad-agent'),
        throwsA(
          isA<TokenException>().having((e) => e.type, 'type', TokenErrorType.invalidAgent),
        ),
      );
    });

    test('throws TokenException on rate limit', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Too many requests', 429);
      });

      final provider = CloudflareTokenProvider(
        baseUrl: Uri.parse('https://test.workers.dev'),
        client: mockClient,
      );

      expect(
        () => provider.getToken('any-agent'),
        throwsA(
          isA<TokenException>().having((e) => e.type, 'type', TokenErrorType.rateLimited),
        ),
      );
    });
  });
}
