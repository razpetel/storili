import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/widgets/capy_welcome.dart';

void main() {
  group('CapyWelcome', () {
    testWidgets('displays welcome message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CapyWelcome(),
          ),
        ),
      );

      expect(find.text('Ready for a story?'), findsOneWidget);
    });

    testWidgets('displays capybara icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CapyWelcome(),
          ),
        ),
      );

      // Using pets icon as Capy placeholder
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });
  });
}
