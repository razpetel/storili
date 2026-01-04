import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:storili/utils/bytes_audio_source.dart';

void main() {
  group('BytesAudioSource', () {
    test('returns full content when no range specified', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final source = BytesAudioSource(bytes);

      final response = await source.request();

      expect(response.sourceLength, 5);
      expect(response.contentLength, 5);
      expect(response.offset, 0);
      expect(response.contentType, 'audio/mpeg');
    });

    test('returns partial content when range specified', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final source = BytesAudioSource(bytes);

      final response = await source.request(1, 4);

      expect(response.sourceLength, 5);
      expect(response.contentLength, 3);
      expect(response.offset, 1);
    });

    test('stream yields correct bytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final source = BytesAudioSource(bytes);

      final response = await source.request(1, 4);
      final chunks = await response.stream.toList();

      expect(chunks.length, 1);
      expect(chunks[0], [2, 3, 4]);
    });
  });
}
