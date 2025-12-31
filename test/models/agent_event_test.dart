import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';

void main() {
  group('AgentEvent', () {
    group('SceneChange', () {
      test('stores scene name correctly', () {
        const event = SceneChange('straw_house');
        expect(event.sceneName, 'straw_house');
      });

      test('toString includes scene name', () {
        const event = SceneChange('brick_house');
        expect(event.toString(), 'SceneChange(brick_house)');
      });
    });

    group('SuggestedActions', () {
      test('stores actions list correctly', () {
        const event = SuggestedActions(['Hide', 'Run', 'Call for help']);
        expect(event.actions, hasLength(3));
        expect(event.actions[0], 'Hide');
        expect(event.actions[1], 'Run');
        expect(event.actions[2], 'Call for help');
      });

      test('handles empty list', () {
        const event = SuggestedActions([]);
        expect(event.actions, isEmpty);
      });
    });

    group('GenerateImage', () {
      test('stores prompt correctly', () {
        const event = GenerateImage('A cozy cottage with flowers');
        expect(event.prompt, 'A cozy cottage with flowers');
      });
    });

    group('SessionEnded', () {
      test('stores summary correctly', () {
        const event = SessionEnded('Emma helped the piggies build a house');
        expect(event.summary, 'Emma helped the piggies build a house');
      });
    });

    group('AgentStartedSpeaking', () {
      test('is a valid AgentEvent', () {
        const event = AgentStartedSpeaking();
        expect(event, isA<AgentEvent>());
      });
    });

    group('AgentStoppedSpeaking', () {
      test('is a valid AgentEvent', () {
        const event = AgentStoppedSpeaking();
        expect(event, isA<AgentEvent>());
      });
    });

    group('UserTranscript', () {
      test('stores transcript correctly', () {
        const event = UserTranscript('I want to help the pig!');
        expect(event.transcript, 'I want to help the pig!');
      });
    });

    group('AgentResponse', () {
      test('stores text correctly', () {
        const event = AgentResponse('Look at the three little piggies!');
        expect(event.text, 'Look at the three little piggies!');
      });
    });

    group('ConnectionStatusChanged', () {
      test('stores status correctly', () {
        const event =
            ConnectionStatusChanged(ElevenLabsConnectionStatus.connected);
        expect(event.status, ElevenLabsConnectionStatus.connected);
      });

      test('works with all status values', () {
        for (final status in ElevenLabsConnectionStatus.values) {
          final event = ConnectionStatusChanged(status);
          expect(event.status, status);
        }
      });
    });

    group('AgentError', () {
      test('stores message correctly', () {
        const event = AgentError('Connection failed');
        expect(event.message, 'Connection failed');
        expect(event.context, isNull);
      });

      test('stores message and context correctly', () {
        const event = AgentError('Connection failed', 'Network timeout');
        expect(event.message, 'Connection failed');
        expect(event.context, 'Network timeout');
      });

      test('toString includes message and context', () {
        const event = AgentError('Failed', 'Details');
        expect(event.toString(), 'AgentError(Failed, Details)');
      });

      test('toString omits context when null', () {
        const event = AgentError('Failed');
        expect(event.toString(), 'AgentError(Failed)');
      });
    });

    group('sealed class pattern matching', () {
      test('can match all event types', () {
        final events = <AgentEvent>[
          const SceneChange('test'),
          const SuggestedActions(['a', 'b']),
          const GenerateImage('prompt'),
          const SessionEnded('summary'),
          const AgentStartedSpeaking(),
          const AgentStoppedSpeaking(),
          const UserTranscript('hello'),
          const AgentResponse('hi'),
          const ConnectionStatusChanged(ElevenLabsConnectionStatus.connected),
          const AgentError('error'),
        ];

        for (final event in events) {
          final result = switch (event) {
            SceneChange() => 'scene',
            SuggestedActions() => 'actions',
            GenerateImage() => 'image',
            SessionEnded() => 'ended',
            AgentStartedSpeaking() => 'speaking',
            AgentStoppedSpeaking() => 'stopped',
            UserTranscript() => 'user',
            AgentResponse() => 'agent',
            ConnectionStatusChanged() => 'status',
            AgentError() => 'error',
          };
          expect(result, isNotEmpty);
        }
      });
    });
  });

  group('ElevenLabsConnectionStatus', () {
    test('has all expected values', () {
      expect(ElevenLabsConnectionStatus.values, hasLength(4));
      expect(
        ElevenLabsConnectionStatus.values,
        contains(ElevenLabsConnectionStatus.disconnected),
      );
      expect(
        ElevenLabsConnectionStatus.values,
        contains(ElevenLabsConnectionStatus.connecting),
      );
      expect(
        ElevenLabsConnectionStatus.values,
        contains(ElevenLabsConnectionStatus.connected),
      );
      expect(
        ElevenLabsConnectionStatus.values,
        contains(ElevenLabsConnectionStatus.disconnecting),
      );
    });
  });
}
