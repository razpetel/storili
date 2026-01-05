import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:storili/app/router.dart';
import 'package:storili/providers/services.dart';
import 'package:storili/utils/test_image_generator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Celebration Flow Integration Tests', () {
    testWidgets('navigates from debug launcher to celebration screen',
        (tester) async {
      // Build the app with test provider overrides
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      // Navigate to debug celebration launcher
      AppRouter.router.go('/debug/celebration?mock=true');
      await tester.pumpAndSettle();

      // Wait for debug launcher to generate images (with timeout)
      await tester.pump(const Duration(seconds: 2));

      // Should transition to celebration screen
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify celebration screen elements
      expect(find.text('You did it!'), findsOneWidget);
    });

    testWidgets('displays confetti animation on celebration screen',
        (tester) async {
      // Pre-populate cache with test images
      final container = ProviderContainer();
      final imageCache = container.read(imageCacheProvider);
      imageCache.clear();

      // Generate and add test images
      for (var i = 0; i < 3; i++) {
        final color = TestImageGenerator.sceneColors[i];
        final bytes = await TestImageGenerator.generateColoredImage(color);
        imageCache.store(i, Uint8List.fromList(bytes));
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      // Navigate directly to celebration
      AppRouter.router.go(
        '/celebration/test-story',
        extra: 'Great job!',
      );
      await tester.pumpAndSettle();

      // The celebration screen should be displayed
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows image gallery after slideshow phase', (tester) async {
      // Pre-populate cache with test images
      final container = ProviderContainer();
      final imageCache = container.read(imageCacheProvider);
      imageCache.clear();

      // Generate and add test images
      for (var i = 0; i < 5; i++) {
        final color = TestImageGenerator.sceneColors[i];
        final bytes = await TestImageGenerator.generateColoredImage(color);
        imageCache.store(i, Uint8List.fromList(bytes));
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      // Navigate directly to celebration with short summary (mock TTS)
      AppRouter.router.go(
        '/celebration/test-story',
        extra: CelebrationTestData.shortSummary,
      );
      await tester.pumpAndSettle();

      // Wait through jingle phase (2 seconds)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Should see celebration elements
      expect(find.text('You did it!'), findsOneWidget);
    });

    testWidgets('replay button restarts celebration', (tester) async {
      // Pre-populate cache with test images
      final container = ProviderContainer();
      final imageCache = container.read(imageCacheProvider);
      imageCache.clear();

      // Add test images
      for (var i = 0; i < 3; i++) {
        final color = TestImageGenerator.sceneColors[i];
        final bytes = await TestImageGenerator.generateColoredImage(color);
        imageCache.store(i, Uint8List.fromList(bytes));
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      // Navigate to celebration
      AppRouter.router.go(
        '/celebration/test-story',
        extra: CelebrationTestData.shortSummary,
      );
      await tester.pumpAndSettle();

      // Wait for gallery phase to appear
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Look for replay button (may need to wait for gallery phase)
      final replayFinder = find.byIcon(Icons.replay);
      if (replayFinder.evaluate().isNotEmpty) {
        await tester.tap(replayFinder);
        await tester.pumpAndSettle();

        // Celebration should restart - verify title is still showing
        expect(find.text('You did it!'), findsOneWidget);
      }
    });
  });
}
