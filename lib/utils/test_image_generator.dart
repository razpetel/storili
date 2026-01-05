import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Generates colored test images for debugging the celebration screen.
///
/// Creates simple solid-color PNG images using dart:ui Canvas,
/// avoiding the need for external asset files during testing.
class TestImageGenerator {
  TestImageGenerator._();

  /// Default colors for test scene images.
  /// Represents different "scenes" in a story playthrough.
  static const List<Color> sceneColors = [
    Color(0xFFE57373), // Red - "The cottage"
    Color(0xFFFFB74D), // Orange - "The forest path"
    Color(0xFF81C784), // Green - "The meadow"
    Color(0xFF64B5F6), // Blue - "The river"
    Color(0xFFBA68C8), // Purple - "The castle"
  ];

  /// Generates a solid-color PNG image.
  ///
  /// [color] - The fill color for the image
  /// [size] - Width and height in pixels (square image)
  ///
  /// Returns PNG bytes that can be displayed with Image.memory()
  static Future<List<int>> generateColoredImage(
    Color color, {
    int size = 512,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw solid color background
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      paint,
    );

    // Add a subtle gradient overlay for visual interest
    final gradientPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size * 0.3, size * 0.3),
        size * 0.8,
        [
          Colors.white.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      gradientPaint,
    );

    // Add scene number indicator (circle in corner)
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size * 0.85, size * 0.85),
      size * 0.08,
      circlePaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to generate test image');
    }

    return byteData.buffer.asUint8List();
  }

  /// Generates a set of test scene images.
  ///
  /// [count] - Number of images to generate (default 5)
  /// [size] - Image dimensions in pixels (default 512)
  ///
  /// Returns a list of PNG byte arrays.
  static Future<List<List<int>>> generateSceneImages({
    int count = 5,
    int size = 512,
  }) async {
    final images = <List<int>>[];

    for (var i = 0; i < count; i++) {
      final color = sceneColors[i % sceneColors.length];
      final imageBytes = await generateColoredImage(color, size: size);
      images.add(imageBytes);
    }

    return images;
  }
}

/// Test data for the celebration debug flow.
class CelebrationTestData {
  CelebrationTestData._();

  /// Test story ID
  static const String storyId = 'three-little-pigs-test';

  /// Predetermined summary for Capy's voice recap.
  /// This exercises the TTS with a realistic message.
  static const String summary = '''
What an amazing adventure! You helped the three little pigs build their houses.
You were so brave when you told the big bad wolf to go away!
The wolf huffed and puffed, but together we outsmarted him.
Great job, little storyteller!''';

  /// Shorter summary for quick testing (skips TTS delay)
  static const String shortSummary = 'Great job finishing the story!';
}
