import 'package:go_router/go_router.dart';
import 'package:storili/screens/home_screen.dart';
import 'package:storili/screens/story_screen.dart';
import 'package:storili/screens/settings_screen.dart';
import 'package:storili/screens/celebration_screen.dart';

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
          return CelebrationScreen(storyId: storyId);
        },
      ),
    ],
  );
}
