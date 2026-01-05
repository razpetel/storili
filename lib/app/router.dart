import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:storili/screens/home_screen.dart';
import 'package:storili/screens/story_screen.dart';
import 'package:storili/screens/settings_screen.dart';
import 'package:storili/screens/celebration_screen.dart';
import 'package:storili/screens/debug/celebration_debug_launcher.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/story/:storyId',
        name: 'story',
        builder: (context, state) {
          final storyId = state.pathParameters['storyId']!;
          return StoryScreen(storyId: storyId);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/celebration/:storyId',
        name: 'celebration',
        builder: (context, state) {
          final storyId = state.pathParameters['storyId']!;
          final summary = state.extra as String? ?? '';
          return CelebrationScreen(storyId: storyId, summary: summary);
        },
      ),
      // Debug routes (only available in debug builds)
      if (kDebugMode)
        GoRoute(
          path: '/debug/celebration',
          name: 'debug-celebration',
          builder: (context, state) {
            // Parse query parameters for configuration
            final useMockTts =
                state.uri.queryParameters['mock'] == 'true';
            final imageCount = int.tryParse(
                  state.uri.queryParameters['images'] ?? '5',
                ) ??
                5;
            return CelebrationDebugLauncher(
              useMockTts: useMockTts,
              imageCount: imageCount,
            );
          },
        ),
    ],
  );
}
