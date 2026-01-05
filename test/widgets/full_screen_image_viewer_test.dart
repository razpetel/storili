// test/widgets/full_screen_image_viewer_test.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/widgets/full_screen_image_viewer.dart';

void main() {
  group('FullScreenImageViewer', () {
    final testImages = [
      Uint8List.fromList(List.generate(100, (i) => i)),
      Uint8List.fromList(List.generate(100, (i) => i + 100)),
    ];

    testWidgets('renders close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            images: testImages,
            initialIndex: 0,
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('shows thumbnail strip for multiple images', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            images: testImages,
            initialIndex: 0,
          ),
        ),
      );

      // Should have thumbnail GestureDetectors
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
