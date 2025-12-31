import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/models/token_exception.dart';
import 'package:storili/services/elevenlabs_service.dart';
import 'package:storili/services/token_provider.dart';

void main() {
  group('ElevenLabsService', () {
    test('initial status is disconnected', () {
      final service = ElevenLabsService(
        tokenProvider: MockTokenProvider('token'),
      );

      expect(service.status, ElevenLabsConnectionStatus.disconnected);
      expect(service.isAgentSpeaking, false);
      expect(service.isMuted, false);

      service.dispose();
    });

    test('events stream is broadcast', () {
      final service = ElevenLabsService(
        tokenProvider: MockTokenProvider('token'),
      );

      final sub1 = service.events.listen((_) {});
      final sub2 = service.events.listen((_) {});

      sub1.cancel();
      sub2.cancel();
      service.dispose();
    });

    test('throws on startSession when token fetch fails', () async {
      final service = ElevenLabsService(
        tokenProvider: MockTokenProvider.throwing(
          const TokenException('Failed', TokenErrorType.network),
        ),
      );

      expect(
        () => service.startSession(agentId: 'test'),
        throwsA(isA<TokenException>()),
      );

      service.dispose();
    });

    test('dispose closes event stream', () async {
      final service = ElevenLabsService(
        tokenProvider: MockTokenProvider('token'),
      );

      var streamClosed = false;
      service.events.listen(
        (_) {},
        onDone: () => streamClosed = true,
      );

      service.dispose();

      await Future.delayed(const Duration(milliseconds: 10));
      expect(streamClosed, true);
    });
  });
}
