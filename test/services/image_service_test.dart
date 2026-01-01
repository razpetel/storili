import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:storili/services/image_service.dart';

void main() {
  group('ImageService', () {
    test('generate returns image bytes on success', () async {
      // Mock the OpenAI API response
      final mockClient = MockClient((request) async {
        // Verify request
        expect(request.url.toString(),
            'https://api.openai.com/v1/images/generations');
        expect(request.headers['Authorization'], 'Bearer test-key');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body);
        expect(body['model'], 'dall-e-3');
        expect(body['size'], '1024x1024');
        expect(body['quality'], 'standard');
        expect(body['prompt'], contains('test prompt'));

        // Return mock response with URL
        return http.Response(
          jsonEncode({
            'data': [
              {'url': 'https://example.com/image.png'}
            ]
          }),
          200,
        );
      });

      // Mock the image download
      final imageBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header
      final mockImageClient = MockClient((request) async {
        if (request.url.toString() == 'https://example.com/image.png') {
          return http.Response.bytes(imageBytes, 200);
        }
        return http.Response('Not found', 404);
      });

      final service = ImageService(
        apiKey: 'test-key',
        client: mockClient,
        imageClient: mockImageClient,
      );

      final result = await service.generate('test prompt');

      expect(result, equals(imageBytes));
    });

    test('generate throws on API error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': {'message': 'Invalid API key'}}),
          401,
        );
      });

      final service = ImageService(
        apiKey: 'bad-key',
        client: mockClient,
      );

      expect(
        () => service.generate('test prompt'),
        throwsA(isA<ImageGenerationException>()),
      );
    });

    test('generate retries on failure', () async {
      var attempts = 0;

      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts < 3) {
          return http.Response('Server error', 500);
        }
        return http.Response(
          jsonEncode({
            'data': [{'url': 'https://example.com/image.png'}]
          }),
          200,
        );
      });

      final mockImageClient = MockClient((request) async {
        return http.Response.bytes(Uint8List.fromList([1, 2, 3]), 200);
      });

      final service = ImageService(
        apiKey: 'test-key',
        client: mockClient,
        imageClient: mockImageClient,
        maxRetries: 3,
      );

      final result = await service.generate('test prompt');

      expect(result, isNotNull);
      expect(attempts, 3);
    });

    test('generate throws after max retries', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final service = ImageService(
        apiKey: 'test-key',
        client: mockClient,
        maxRetries: 2,
      );

      expect(
        () => service.generate('test prompt'),
        throwsA(isA<ImageGenerationException>()),
      );
    });
  });
}
