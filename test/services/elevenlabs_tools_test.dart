import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/agent_event.dart';
import 'package:storili/services/elevenlabs_tools.dart';

void main() {
  group('ElevenLabs Client Tools', () {
    late StreamController<AgentEvent> eventController;
    late List<AgentEvent> emittedEvents;
    late StreamSubscription<AgentEvent> subscription;

    setUp(() {
      eventController = StreamController<AgentEvent>.broadcast();
      emittedEvents = [];
      subscription = eventController.stream.listen((event) {
        emittedEvents.add(event);
      });
    });

    tearDown(() async {
      await subscription.cancel();
      await eventController.close();
    });

    group('ChangeSceneTool', () {
      late ChangeSceneTool tool;

      setUp(() {
        tool = ChangeSceneTool(eventController);
      });

      test('emits SceneChange event with correct scene name', () async {
        final result = await tool.execute({'scene_name': 'forest_clearing'});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SceneChange>());
        expect((emittedEvents.first as SceneChange).sceneName, 'forest_clearing');
        expect(result, isNull);
      });

      test('returns null as required by ClientTool interface', () async {
        final result = await tool.execute({'scene_name': 'castle'});
        expect(result, isNull);
      });

      test('handles empty scene name', () async {
        final result = await tool.execute({'scene_name': ''});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SceneChange>());
        expect((emittedEvents.first as SceneChange).sceneName, '');
        expect(result, isNull);
      });

      test('handles missing scene_name parameter', () async {
        final result = await tool.execute({});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SceneChange>());
        expect((emittedEvents.first as SceneChange).sceneName, '');
        expect(result, isNull);
      });

      test('handles null scene_name parameter', () async {
        final result = await tool.execute({'scene_name': null});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SceneChange>());
        expect((emittedEvents.first as SceneChange).sceneName, '');
        expect(result, isNull);
      });

      test('handles scene name with special characters', () async {
        final result = await tool.execute({'scene_name': 'scene_1/chapter_2'});

        expect(emittedEvents, hasLength(1));
        expect((emittedEvents.first as SceneChange).sceneName, 'scene_1/chapter_2');
        expect(result, isNull);
      });

      test('handles scene name with unicode characters', () async {
        final result = await tool.execute({'scene_name': 'magical_forest_🌲🧚'});

        expect(emittedEvents, hasLength(1));
        expect((emittedEvents.first as SceneChange).sceneName, 'magical_forest_🌲🧚');
        expect(result, isNull);
      });
    });

    group('SuggestActionsTool', () {
      late SuggestActionsTool tool;

      setUp(() {
        tool = SuggestActionsTool(eventController);
      });

      test('emits SuggestedActions event with correct actions', () async {
        final result = await tool.execute({
          'actions': ['Run away', 'Hide behind the tree', 'Call for help']
        });

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SuggestedActions>());
        final event = emittedEvents.first as SuggestedActions;
        expect(event.actions, hasLength(3));
        expect(event.actions[0], 'Run away');
        expect(event.actions[1], 'Hide behind the tree');
        expect(event.actions[2], 'Call for help');
        expect(result, isNull);
      });

      test('returns null as required by ClientTool interface', () async {
        final result = await tool.execute({'actions': ['Test']});
        expect(result, isNull);
      });

      test('handles empty actions list', () async {
        final result = await tool.execute({'actions': []});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SuggestedActions>());
        expect((emittedEvents.first as SuggestedActions).actions, isEmpty);
        expect(result, isNull);
      });

      test('handles missing actions parameter', () async {
        final result = await tool.execute({});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SuggestedActions>());
        expect((emittedEvents.first as SuggestedActions).actions, isEmpty);
        expect(result, isNull);
      });

      test('handles null actions parameter', () async {
        final result = await tool.execute({'actions': null});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SuggestedActions>());
        expect((emittedEvents.first as SuggestedActions).actions, isEmpty);
        expect(result, isNull);
      });

      test('truncates actions to maximum of 3 items', () async {
        final result = await tool.execute({
          'actions': ['Action 1', 'Action 2', 'Action 3', 'Action 4', 'Action 5']
        });

        expect(emittedEvents, hasLength(1));
        final event = emittedEvents.first as SuggestedActions;
        expect(event.actions, hasLength(3));
        expect(event.actions[0], 'Action 1');
        expect(event.actions[1], 'Action 2');
        expect(event.actions[2], 'Action 3');
        expect(result, isNull);
      });

      test('handles exactly 4 actions and truncates to 3', () async {
        final result = await tool.execute({
          'actions': ['One', 'Two', 'Three', 'Four']
        });

        expect(emittedEvents, hasLength(1));
        final event = emittedEvents.first as SuggestedActions;
        expect(event.actions, hasLength(3));
        expect(event.actions, ['One', 'Two', 'Three']);
        expect(result, isNull);
      });

      test('handles single action', () async {
        final result = await tool.execute({
          'actions': ['Only one option']
        });

        expect(emittedEvents, hasLength(1));
        final event = emittedEvents.first as SuggestedActions;
        expect(event.actions, hasLength(1));
        expect(event.actions[0], 'Only one option');
        expect(result, isNull);
      });

      test('handles two actions', () async {
        final result = await tool.execute({
          'actions': ['First', 'Second']
        });

        expect(emittedEvents, hasLength(1));
        final event = emittedEvents.first as SuggestedActions;
        expect(event.actions, hasLength(2));
        expect(event.actions, ['First', 'Second']);
        expect(result, isNull);
      });

      test('converts non-string elements to strings', () async {
        final result = await tool.execute({
          'actions': [123, true, 'string']
        });

        expect(emittedEvents, hasLength(1));
        final event = emittedEvents.first as SuggestedActions;
        expect(event.actions, hasLength(3));
        expect(event.actions[0], '123');
        expect(event.actions[1], 'true');
        expect(event.actions[2], 'string');
        expect(result, isNull);
      });

      test('handles actions with unicode characters', () async {
        final result = await tool.execute({
          'actions': ['Build the house 🏠', 'Help the piggy 🐷', 'Run! 🏃']
        });

        expect(emittedEvents, hasLength(1));
        final event = emittedEvents.first as SuggestedActions;
        expect(event.actions, hasLength(3));
        expect(event.actions[0], 'Build the house 🏠');
        expect(event.actions[1], 'Help the piggy 🐷');
        expect(event.actions[2], 'Run! 🏃');
        expect(result, isNull);
      });

      test('handles non-list actions parameter', () async {
        final result = await tool.execute({'actions': 'not a list'});
        expect(emittedEvents, hasLength(1));
        expect((emittedEvents.first as SuggestedActions).actions, isEmpty);
        expect(result, isNull);
      });

      test('handles exactly 3 actions without truncation', () async {
        final result = await tool.execute({'actions': ['One', 'Two', 'Three']});
        expect(emittedEvents, hasLength(1));
        final event = emittedEvents.first as SuggestedActions;
        expect(event.actions, hasLength(3));
        expect(event.actions, ['One', 'Two', 'Three']);
        expect(result, isNull);
      });
    });

    group('GenerateImageTool', () {
      late GenerateImageTool tool;

      setUp(() {
        tool = GenerateImageTool(eventController);
      });

      test('emits GenerateImage event with correct prompt', () async {
        const testPrompt =
            'A cozy cottage in the forest with smoke coming from the chimney';
        final result = await tool.execute({'prompt': testPrompt});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<GenerateImage>());
        expect((emittedEvents.first as GenerateImage).prompt, testPrompt);
        expect(result, isNull);
      });

      test('returns null as required by ClientTool interface', () async {
        final result = await tool.execute({'prompt': 'test'});
        expect(result, isNull);
      });

      test('handles empty prompt', () async {
        final result = await tool.execute({'prompt': ''});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<GenerateImage>());
        expect((emittedEvents.first as GenerateImage).prompt, '');
        expect(result, isNull);
      });

      test('handles missing prompt parameter', () async {
        final result = await tool.execute({});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<GenerateImage>());
        expect((emittedEvents.first as GenerateImage).prompt, '');
        expect(result, isNull);
      });

      test('handles null prompt parameter', () async {
        final result = await tool.execute({'prompt': null});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<GenerateImage>());
        expect((emittedEvents.first as GenerateImage).prompt, '');
        expect(result, isNull);
      });

      test('handles very long prompt', () async {
        final longPrompt = 'A beautiful scene ' * 100;
        final result = await tool.execute({'prompt': longPrompt});

        expect(emittedEvents, hasLength(1));
        expect((emittedEvents.first as GenerateImage).prompt, longPrompt);
        expect(result, isNull);
      });

      test('handles prompt with special characters', () async {
        const specialPrompt =
            'A house with "windows" & <doors> at 100% opacity';
        final result = await tool.execute({'prompt': specialPrompt});

        expect(emittedEvents, hasLength(1));
        expect((emittedEvents.first as GenerateImage).prompt, specialPrompt);
        expect(result, isNull);
      });

      test('handles prompt with newlines', () async {
        const multilinePrompt = 'Line 1\nLine 2\nLine 3';
        final result = await tool.execute({'prompt': multilinePrompt});

        expect(emittedEvents, hasLength(1));
        expect((emittedEvents.first as GenerateImage).prompt, multilinePrompt);
        expect(result, isNull);
      });

      test('handles prompt with unicode characters', () async {
        const emojiPrompt = 'A magical forest 🌲 with fairies 🧚 and sparkles ✨';
        final result = await tool.execute({'prompt': emojiPrompt});

        expect(emittedEvents, hasLength(1));
        expect((emittedEvents.first as GenerateImage).prompt, emojiPrompt);
        expect(result, isNull);
      });
    });

    group('SessionEndTool', () {
      late SessionEndTool tool;

      setUp(() {
        tool = SessionEndTool(eventController);
      });

      test('emits SessionEnded event with correct summary', () async {
        const testSummary =
            'Emma had a wonderful adventure helping the three little pigs build their house of bricks!';
        final result = await tool.execute({'summary': testSummary});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SessionEnded>());
        expect((emittedEvents.first as SessionEnded).summary, testSummary);
        expect(result, isNull);
      });

      test('returns null as required by ClientTool interface', () async {
        final result = await tool.execute({'summary': 'test'});
        expect(result, isNull);
      });

      test('handles empty summary', () async {
        final result = await tool.execute({'summary': ''});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SessionEnded>());
        expect((emittedEvents.first as SessionEnded).summary, '');
        expect(result, isNull);
      });

      test('handles missing summary parameter', () async {
        final result = await tool.execute({});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SessionEnded>());
        expect((emittedEvents.first as SessionEnded).summary, '');
        expect(result, isNull);
      });

      test('handles null summary parameter', () async {
        final result = await tool.execute({'summary': null});

        expect(emittedEvents, hasLength(1));
        expect(emittedEvents.first, isA<SessionEnded>());
        expect((emittedEvents.first as SessionEnded).summary, '');
        expect(result, isNull);
      });

      test('handles very long summary', () async {
        final longSummary = 'What a wonderful story! ' * 50;
        final result = await tool.execute({'summary': longSummary});

        expect(emittedEvents, hasLength(1));
        expect((emittedEvents.first as SessionEnded).summary, longSummary);
        expect(result, isNull);
      });

      test('handles summary with special characters', () async {
        const specialSummary = 'Emma\'s adventure was "amazing" - 100% fun!';
        final result = await tool.execute({'summary': specialSummary});

        expect(emittedEvents, hasLength(1));
        expect((emittedEvents.first as SessionEnded).summary, specialSummary);
        expect(result, isNull);
      });

      test('handles summary with unicode characters', () async {
        const emojiSummary = 'Emma saved the day! 🎉 The princess 👸 lived happily ever after 💖';
        final result = await tool.execute({'summary': emojiSummary});

        expect(emittedEvents, hasLength(1));
        expect((emittedEvents.first as SessionEnded).summary, emojiSummary);
        expect(result, isNull);
      });
    });

    group('Tool integration scenarios', () {
      test('multiple tools can share the same event controller', () async {
        final changeSceneTool = ChangeSceneTool(eventController);
        final suggestActionsTool = SuggestActionsTool(eventController);
        final generateImageTool = GenerateImageTool(eventController);
        final sessionEndTool = SessionEndTool(eventController);

        await changeSceneTool.execute({'scene_name': 'forest'});
        await suggestActionsTool.execute({'actions': ['Walk', 'Run']});
        await generateImageTool.execute({'prompt': 'A dark forest'});
        await sessionEndTool.execute({'summary': 'The end'});

        expect(emittedEvents, hasLength(4));
        expect(emittedEvents[0], isA<SceneChange>());
        expect(emittedEvents[1], isA<SuggestedActions>());
        expect(emittedEvents[2], isA<GenerateImage>());
        expect(emittedEvents[3], isA<SessionEnded>());
      });

      test('events are emitted in order', () async {
        final tool = ChangeSceneTool(eventController);

        await tool.execute({'scene_name': 'scene_1'});
        await tool.execute({'scene_name': 'scene_2'});
        await tool.execute({'scene_name': 'scene_3'});

        expect(emittedEvents, hasLength(3));
        expect((emittedEvents[0] as SceneChange).sceneName, 'scene_1');
        expect((emittedEvents[1] as SceneChange).sceneName, 'scene_2');
        expect((emittedEvents[2] as SceneChange).sceneName, 'scene_3');
      });

      test('tools handle concurrent execution', () async {
        final changeSceneTool = ChangeSceneTool(eventController);
        final generateImageTool = GenerateImageTool(eventController);

        // Execute concurrently
        await Future.wait([
          changeSceneTool.execute({'scene_name': 'scene_a'}),
          generateImageTool.execute({'prompt': 'image_a'}),
          changeSceneTool.execute({'scene_name': 'scene_b'}),
          generateImageTool.execute({'prompt': 'image_b'}),
        ]);

        // Allow stream events to propagate
        await Future<void>.delayed(Duration.zero);

        expect(emittedEvents, hasLength(4));
        // All events should be present (order may vary due to concurrency)
        final sceneChanges = emittedEvents.whereType<SceneChange>().toList();
        final imageGenerations = emittedEvents.whereType<GenerateImage>().toList();
        expect(sceneChanges, hasLength(2));
        expect(imageGenerations, hasLength(2));
      });
    });

    group('Event type verification', () {
      test('SceneChange is an AgentEvent', () async {
        final tool = ChangeSceneTool(eventController);
        await tool.execute({'scene_name': 'test'});

        expect(emittedEvents.first, isA<AgentEvent>());
      });

      test('SuggestedActions is an AgentEvent', () async {
        final tool = SuggestActionsTool(eventController);
        await tool.execute({'actions': ['test']});

        expect(emittedEvents.first, isA<AgentEvent>());
      });

      test('GenerateImage is an AgentEvent', () async {
        final tool = GenerateImageTool(eventController);
        await tool.execute({'prompt': 'test'});

        expect(emittedEvents.first, isA<AgentEvent>());
      });

      test('SessionEnded is an AgentEvent', () async {
        final tool = SessionEndTool(eventController);
        await tool.execute({'summary': 'test'});

        expect(emittedEvents.first, isA<AgentEvent>());
      });
    });
  });
}
