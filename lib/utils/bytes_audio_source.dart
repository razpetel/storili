import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

/// Audio source that plays from in-memory bytes.
///
/// Used for playing TTS audio received from ElevenLabs API
/// without writing to a temporary file.
class BytesAudioSource extends StreamAudioSource {
  final Uint8List bytes;

  BytesAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
