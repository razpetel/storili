# Initial Setup (Phase 1: Shell) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Set up the Flutter project shell with navigation, theme, and placeholder screens for Storili.

**Architecture:** Standard Flutter project with Riverpod for state management, go_router for navigation, and a clean folder structure following the design spec. Portrait-locked, iOS + Android targets.

**Tech Stack:** Flutter 3.x, Dart, flutter_riverpod, go_router

---

## Task 1: Create Flutter Project

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `analysis_options.yaml`

**Step 1: Create new Flutter project**

Run:
```bash
cd /Users/razpetel/projects/storili/.worktrees/initial-setup
flutter create . --project-name storili --org com.storili --platforms ios,android
```

Expected: Flutter project created with default structure

**Step 2: Verify project builds**

Run:
```bash
flutter pub get
flutter analyze
```

Expected: No errors

**Step 3: Commit**

```bash
git add .
git commit -m "feat: create Flutter project scaffold"
```

---

## Task 2: Add Core Dependencies

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add dependencies to pubspec.yaml**

Replace the `dependencies` and `dev_dependencies` sections:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  go_router: ^14.6.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

**Step 2: Install dependencies**

Run:
```bash
flutter pub get
```

Expected: Dependencies resolved successfully

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add core dependencies (riverpod, go_router)"
```

---

## Task 3: Create Folder Structure

**Files:**
- Create: `lib/app/` directory
- Create: `lib/services/` directory
- Create: `lib/models/` directory
- Create: `lib/providers/` directory
- Create: `lib/screens/` directory
- Create: `lib/widgets/` directory
- Create: `assets/stories/` directory

**Step 1: Create directory structure**

Run:
```bash
cd /Users/razpetel/projects/storili/.worktrees/initial-setup
mkdir -p lib/app lib/services lib/models lib/providers lib/screens lib/widgets
mkdir -p assets/stories
```

Expected: Directories created

**Step 2: Add .gitkeep files to preserve empty directories**

Run:
```bash
touch lib/services/.gitkeep lib/models/.gitkeep lib/providers/.gitkeep lib/widgets/.gitkeep
touch assets/stories/.gitkeep
```

**Step 3: Update pubspec.yaml to include assets**

Add to `pubspec.yaml` after `flutter:` section:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/stories/
```

**Step 4: Commit**

```bash
git add .
git commit -m "feat: create folder structure per design spec"
```

---

## Task 4: Create Theme

**Files:**
- Create: `lib/app/theme.dart`
- Test: `test/app/theme_test.dart`

**Step 1: Write the failing test**

Create `test/app/theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/app/theme.dart';

void main() {
  group('StoriliTheme', () {
    test('lightTheme returns a ThemeData', () {
      final theme = StoriliTheme.lightTheme;
      expect(theme, isA<ThemeData>());
    });

    test('lightTheme uses correct primary color', () {
      final theme = StoriliTheme.lightTheme;
      expect(theme.colorScheme.primary, equals(StoriliTheme.primaryColor));
    });

    test('lightTheme uses rounded card shapes', () {
      final theme = StoriliTheme.lightTheme;
      final cardTheme = theme.cardTheme;
      expect(cardTheme.shape, isA<RoundedRectangleBorder>());
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/app/theme_test.dart
```

Expected: FAIL - Cannot find 'package:storili/app/theme.dart'

**Step 3: Write minimal implementation**

Create `lib/app/theme.dart`:

```dart
import 'package:flutter/material.dart';

class StoriliTheme {
  StoriliTheme._();

  // Warm, child-friendly colors
  static const Color primaryColor = Color(0xFF8B5E3C); // Capy brown
  static const Color secondaryColor = Color(0xFF4A7C59); // Forest green
  static const Color backgroundColor = Color(0xFFFFF8F0); // Warm cream
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFE57373);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D2D2D),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D2D2D),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF4A4A4A),
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run:
```bash
flutter test test/app/theme_test.dart
```

Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/app/theme.dart test/app/theme_test.dart
git commit -m "feat: add StoriliTheme with child-friendly colors"
```

---

## Task 5: Create Placeholder Screens

**Files:**
- Create: `lib/screens/home_screen.dart`
- Create: `lib/screens/story_screen.dart`
- Create: `lib/screens/settings_screen.dart`
- Create: `lib/screens/celebration_screen.dart`
- Test: `test/screens/screens_test.dart`

**Step 1: Write the failing test**

Create `test/screens/screens_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/screens/home_screen.dart';
import 'package:storili/screens/story_screen.dart';
import 'package:storili/screens/settings_screen.dart';
import 'package:storili/screens/celebration_screen.dart';

void main() {
  group('Screens', () {
    testWidgets('HomeScreen renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      expect(find.text('Storili'), findsOneWidget);
    });

    testWidgets('StoryScreen renders with storyId', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StoryScreen(storyId: 'test-story')),
      );
      expect(find.text('test-story'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('CelebrationScreen renders with storyId', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CelebrationScreen(storyId: 'test-story')),
      );
      expect(find.text('Congratulations'), findsOneWidget);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/screens/screens_test.dart
```

Expected: FAIL - Cannot find screen imports

**Step 3: Write HomeScreen**

Create `lib/screens/home_screen.dart`:

```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storili'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Story cards will appear here'),
      ),
    );
  }
}
```

**Step 4: Write StoryScreen**

Create `lib/screens/story_screen.dart`:

```dart
import 'package:flutter/material.dart';

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // TODO: Show exit confirmation
          },
        ),
      ),
      body: Center(
        child: Text(storyId),
      ),
    );
  }
}
```

**Step 5: Write SettingsScreen**

Create `lib/screens/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Reset Story Progress'),
            subtitle: const Text('Start all stories fresh'),
            onTap: () {
              // TODO: Show confirmation dialog
            },
          ),
        ],
      ),
    );
  }
}
```

**Step 6: Write CelebrationScreen**

Create `lib/screens/celebration_screen.dart`:

```dart
import 'package:flutter/material.dart';

class CelebrationScreen extends StatelessWidget {
  const CelebrationScreen({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Congratulations',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('You completed $storyId!'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate home
              },
              child: const Text('Home'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 7: Run tests to verify they pass**

Run:
```bash
flutter test test/screens/screens_test.dart
```

Expected: All tests PASS

**Step 8: Commit**

```bash
git add lib/screens/ test/screens/
git commit -m "feat: add placeholder screens (home, story, settings, celebration)"
```

---

## Task 6: Create Router

**Files:**
- Create: `lib/app/router.dart`
- Test: `test/app/router_test.dart`

**Step 1: Write the failing test**

Create `test/app/router_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:storili/app/router.dart';

void main() {
  group('AppRouter', () {
    test('router is a GoRouter instance', () {
      final router = AppRouter.router;
      expect(router, isA<GoRouter>());
    });

    test('initial location is home', () {
      final router = AppRouter.router;
      expect(router.routerDelegate.currentConfiguration.uri.path, equals('/'));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/app/router_test.dart
```

Expected: FAIL - Cannot find 'package:storili/app/router.dart'

**Step 3: Write minimal implementation**

Create `lib/app/router.dart`:

```dart
import 'package:flutter/material.dart';
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
```

**Step 4: Run test to verify it passes**

Run:
```bash
flutter test test/app/router_test.dart
```

Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/app/router.dart test/app/router_test.dart
git commit -m "feat: add go_router configuration with all routes"
```

---

## Task 7: Create App Widget

**Files:**
- Create: `lib/app/app.dart`
- Test: `test/app/app_test.dart`

**Step 1: Write the failing test**

Create `test/app/app_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/app/app.dart';

void main() {
  group('StoriliApp', () {
    testWidgets('renders MaterialApp with router', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: StoriliApp()),
      );
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('shows HomeScreen at start', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: StoriliApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Storili'), findsOneWidget);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/app/app_test.dart
```

Expected: FAIL - Cannot find 'package:storili/app/app.dart'

**Step 3: Write minimal implementation**

Create `lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storili/app/router.dart';
import 'package:storili/app/theme.dart';

class StoriliApp extends StatelessWidget {
  const StoriliApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lock to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp.router(
      title: 'Storili',
      theme: StoriliTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run:
```bash
flutter test test/app/app_test.dart
```

Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/app/app.dart test/app/app_test.dart
git commit -m "feat: add StoriliApp with theme and router"
```

---

## Task 8: Update main.dart

**Files:**
- Modify: `lib/main.dart`
- Test: `test/main_test.dart`

**Step 1: Write the failing test**

Create `test/main_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storili/app/app.dart';

void main() {
  testWidgets('App starts successfully', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: StoriliApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Storili'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it passes (uses existing app)**

Run:
```bash
flutter test test/main_test.dart
```

Expected: PASS

**Step 3: Update main.dart**

Replace `lib/main.dart` contents:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storili/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: StoriliApp(),
    ),
  );
}
```

**Step 4: Run all tests**

Run:
```bash
flutter test
```

Expected: All tests PASS

**Step 5: Run the app to verify it works**

Run:
```bash
flutter run
```

Expected: App launches showing "Storili" header with placeholder content

**Step 6: Commit**

```bash
git add lib/main.dart test/main_test.dart
git commit -m "feat: wire up main.dart with ProviderScope and StoriliApp"
```

---

## Task 9: Add Navigation Integration

**Files:**
- Modify: `lib/screens/home_screen.dart`
- Test: `test/navigation_test.dart`

**Step 1: Write the failing test**

Create `test/navigation_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/app/app.dart';

void main() {
  group('Navigation', () {
    testWidgets('settings icon navigates to settings', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: StoriliApp()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('back from settings returns to home', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: StoriliApp()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Storili'), findsOneWidget);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/navigation_test.dart
```

Expected: FAIL - navigation doesn't work yet

**Step 3: Update HomeScreen with navigation**

Replace `lib/screens/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storili'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: const Center(
        child: Text('Story cards will appear here'),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run:
```bash
flutter test test/navigation_test.dart
```

Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/screens/home_screen.dart test/navigation_test.dart
git commit -m "feat: wire up navigation between screens"
```

---

## Task 10: Clean Up and Final Verification

**Files:**
- Remove: `lib/services/.gitkeep`
- Remove: `lib/models/.gitkeep`
- Remove: `lib/providers/.gitkeep`
- Remove: `lib/widgets/.gitkeep`
- Remove: `assets/stories/.gitkeep`

**Step 1: Run all tests**

Run:
```bash
flutter test
```

Expected: All tests PASS

**Step 2: Run flutter analyze**

Run:
```bash
flutter analyze
```

Expected: No issues found

**Step 3: Remove .gitkeep files**

Run:
```bash
rm -f lib/services/.gitkeep lib/models/.gitkeep lib/providers/.gitkeep lib/widgets/.gitkeep assets/stories/.gitkeep
```

**Step 4: Final commit**

```bash
git add .
git commit -m "chore: clean up gitkeep files, Phase 1 complete"
```

---

## Summary

After completing all tasks, you will have:

- **Flutter project** configured for iOS + Android
- **Dependencies**: flutter_riverpod, go_router
- **Theme**: Child-friendly colors (Capy brown, forest green, warm cream)
- **Screens**: HomeScreen, StoryScreen, SettingsScreen, CelebrationScreen
- **Router**: go_router with routes for all screens
- **Navigation**: Working navigation between all screens
- **Tests**: Unit and widget tests for theme, screens, router, navigation
- **Portrait lock**: App locked to portrait orientation

Ready for Phase 2: Audio Pipeline.
