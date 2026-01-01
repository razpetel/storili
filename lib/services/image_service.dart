import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Exception thrown when image generation fails.
class ImageGenerationException implements Exception {
  final String message;
  final int? statusCode;

  ImageGenerationException(this.message, [this.statusCode]);

  @override
  String toString() => 'ImageGenerationException: $message (status: $statusCode)';
}

/// Service for generating images via DALL-E 3 API.
class ImageService {
  final String apiKey;
  final http.Client _client;
  final http.Client _imageClient;
  final int maxRetries;

  static const _baseUrl = 'https://api.openai.com/v1/images/generations';

  ImageService({
    required this.apiKey,
    http.Client? client,
    http.Client? imageClient,
    this.maxRetries = 2,
  })  : _client = client ?? http.Client(),
        _imageClient = imageClient ?? http.Client();

  /// Generate an image from the given prompt.
  ///
  /// Returns the image bytes on success.
  /// Throws [ImageGenerationException] on failure after retries.
  Future<Uint8List> generate(String prompt) async {
    Exception? lastError;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final imageUrl = await _callApi(prompt);
        final bytes = await _downloadImage(imageUrl);
        return bytes;
      } on ImageGenerationException catch (e) {
        lastError = e;
        if (attempt < maxRetries) {
          // Exponential backoff: 1s, 2s, 4s...
          await Future.delayed(Duration(seconds: 1 << attempt));
        }
      }
    }

    throw lastError ?? ImageGenerationException('Unknown error');
  }

  Future<String> _callApi(String prompt) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'dall-e-3',
        'prompt': prompt,
        'size': '1024x1024',
        'quality': 'standard',
        'response_format': 'url',
        'n': 1,
      }),
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw ImageGenerationException(error, response.statusCode);
    }

    final data = jsonDecode(response.body);
    return data['data'][0]['url'] as String;
  }

  Future<Uint8List> _downloadImage(String url) async {
    final response = await _imageClient.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw ImageGenerationException(
        'Failed to download image',
        response.statusCode,
      );
    }

    return response.bodyBytes;
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      return data['error']['message'] ?? 'Unknown error';
    } catch (_) {
      return body;
    }
  }

  /// Dispose of HTTP clients.
  void dispose() {
    _client.close();
    _imageClient.close();
  }
}
