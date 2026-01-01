# Home Screen Implementation Plan

> **Status:** ✅ COMPLETED (2026-01-01)

**Goal:** Build a claymorphism-styled home screen with hero story card for the Three Little Pigs story.

**Architecture:** Single-story hero layout with CapyWelcome header and StoryCard. Uses ThemeData extensions for consistent styling. Claymorphism via layered shadows and thick borders.

**Tech Stack:** Flutter, Riverpod, go_router, google_fonts

**QA Results:**
- ✅ All 142 tests passing
- ✅ Visual QA on iOS 26.2 (iPhone 16 Pro) - claymorphism styling verified
- ✅ Visual QA on Chrome - cross-platform consistency confirmed
- ✅ Navigation flows working (Home → Story Player → Exit confirmation)

---

## Task 1: Add Google Fonts Dependency

**Files:**
- Modify: `pubspec.yaml:30-37`

**Step 1: Add google_fonts package**

Add to dependencies section in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  go_router: ^14.6.2
  elevenlabs_agents: ^0.3.0
  http: ^1.2.0
  permission_handler: ^11.3.0
  google_fonts: ^6.2.1
```

**Step 2: Install dependencies**

Run: `flutter pub get`
Expected: Dependencies resolved successfully

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add google_fonts dependency"
```

---

## Task 2: Create AppColors Class

**Files:**
- Modify: `lib/app/theme.dart`
- Test: `test/app/theme_test.dart`

**Step 1: Write the failing test**

Create `test/app/theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/app/theme.dart';

void main() {
  group('AppColors', () {
    test('primary is warm cream', () {
      expect(AppColors.primary, const Color(0xFFF5E6D3));
    });

    test('accent is friendly orange', () {
      expect(AppColors.accent, const Color(0xFFF97316));
    });

    test('background is light warm', () {
      expect(AppColors.background, const Color(0xFFFDF8F3));
    });

    test('textPrimary is deep brown', () {
      expect(AppColors.textPrimary, const Color(0xFF3D2914));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/app/theme_test.dart`
Expected: FAIL with "AppColors not defined"

**Step 3: Add AppColors to theme.dart**

Add to `lib/app/theme.dart` before StoriliTheme class:

```dart
/// Claymorphism color palette for Storili.
/// Warm storybook colors optimized for children ages 3-5.
class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFFF5E6D3);      // Warm cream
  static const Color secondary = Color(0xFF8B7355);    // Soft brown
  static const Color accent = Color(0xFFF97316);       // Friendly orange

  // Background
  static const Color background = Color(0xFFFDF8F3);   // Light warm

  // Text
  static const Color textPrimary = Color(0xFF3D2914);  // Deep brown
  static const Color textSecondary = Color(0xFF6B5344); // Medium brown

  // Shadows (claymorphism)
  static const Color shadowOuter = Color(0xFFFDBCB4);  // Soft peach
  static const Color shadowInner = Color(0xFFFFE4D6);  // Light peach

  // Legacy (keep for backward compatibility)
  static const Color capyBrown = Color(0xFF8B5E3C);
  static const Color forestGreen = Color(0xFF4A7C59);
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/app/theme_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/app/theme.dart test/app/theme_test.dart
git commit -m "feat: add AppColors with claymorphism palette"
```

---

## Task 3: Create AppTypography Class

**Files:**
- Modify: `lib/app/theme.dart`
- Modify: `test/app/theme_test.dart`

**Step 1: Write the failing test**

Add to `test/app/theme_test.dart`:

```dart
  group('AppTypography', () {
    test('cardTitle uses Fredoka family', () {
      expect(AppTypography.cardTitle.fontFamily, 'Fredoka');
    });

    test('cardTitle is 22sp semibold', () {
      expect(AppTypography.cardTitle.fontSize, 22);
      expect(AppTypography.cardTitle.fontWeight, FontWeight.w600);
    });

    test('body uses Nunito family', () {
      expect(AppTypography.body.fontFamily, 'Nunito');
    });
  });
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/app/theme_test.dart`
Expected: FAIL with "AppTypography not defined"

**Step 3: Add AppTypography to theme.dart**

Add import at top of `lib/app/theme.dart`:

```dart
import 'package:google_fonts/google_fonts.dart';
```

Add after AppColors class:

```dart
/// Typography using Fredoka (headings) and Nunito (body).
/// Playful, rounded fonts suitable for children's apps.
class AppTypography {
  AppTypography._();

  static TextStyle get appTitle => GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get cardTitle => GoogleFonts.fredoka(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/app/theme_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/app/theme.dart test/app/theme_test.dart
git commit -m "feat: add AppTypography with Fredoka and Nunito fonts"
```

---

## Task 4: Create StoryInfo Model

**Files:**
- Create: `lib/models/story_info.dart`
- Test: `test/models/story_info_test.dart`

**Step 1: Write the failing test**

Create `test/models/story_info_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/story_info.dart';

void main() {
  group('StoryInfo', () {
    test('can be instantiated', () {
      const story = StoryInfo(
        id: 'test-story',
        title: 'Test Story',
        primaryColor: Color(0xFFFFFFFF),
        secondaryColor: Color(0xFF000000),
      );

      expect(story.id, 'test-story');
      expect(story.title, 'Test Story');
    });
  });

  group('availableStories', () {
    test('contains three-little-pigs', () {
      expect(availableStories.length, 1);
      expect(availableStories.first.id, 'three-little-pigs');
    });

    test('three-little-pigs has correct title', () {
      final pigs = availableStories.first;
      expect(pigs.title, 'The Three Little Pigs');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/models/story_info_test.dart`
Expected: FAIL with "story_info.dart not found"

**Step 3: Create StoryInfo model**

Create `lib/models/story_info.dart`:

```dart
import 'package:flutter/material.dart';

/// Metadata for a story available in the app.
class StoryInfo {
  final String id;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;

  const StoryInfo({
    required this.id,
    required this.title,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

/// Available stories in the app.
/// Hardcoded for MVP; will load from manifests later.
const List<StoryInfo> availableStories = [
  StoryInfo(
    id: 'three-little-pigs',
    title: 'The Three Little Pigs',
    primaryColor: Color(0xFFF5E6D3), // Warm cream
    secondaryColor: Color(0xFF8B7355), // Soft brown
  ),
];
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/models/story_info_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/models/story_info.dart test/models/story_info_test.dart
git commit -m "feat: add StoryInfo model with Three Little Pigs"
```

---

## Task 5: Create CapyWelcome Widget

**Files:**
- Create: `lib/widgets/capy_welcome.dart`
- Test: `test/widgets/capy_welcome_test.dart`

**Step 1: Write the failing test**

Create `test/widgets/capy_welcome_test.dart`:

```dart
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
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/capy_welcome_test.dart`
Expected: FAIL with "capy_welcome.dart not found"

**Step 3: Create CapyWelcome widget**

Create `lib/widgets/capy_welcome.dart`:

```dart
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Welcome header featuring Capy the capybara.
/// Placeholder implementation for MVP.
class CapyWelcome extends StatelessWidget {
  const CapyWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Capy placeholder - will be replaced with illustration
          Icon(
            Icons.pets,
            size: 64,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready for a story?',
            style: AppTypography.body.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/capy_welcome_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/widgets/capy_welcome.dart test/widgets/capy_welcome_test.dart
git commit -m "feat: add CapyWelcome widget with placeholder"
```

---

## Task 6: Create StoryCard Widget

**Files:**
- Create: `lib/widgets/story_card.dart`
- Test: `test/widgets/story_card_test.dart`

**Step 1: Write the failing test**

Create `test/widgets/story_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/models/story_info.dart';
import 'package:storili/widgets/story_card.dart';

void main() {
  const testStory = StoryInfo(
    id: 'test-story',
    title: 'Test Story Title',
    primaryColor: Color(0xFFF5E6D3),
    secondaryColor: Color(0xFF8B7355),
  );

  group('StoryCard', () {
    testWidgets('displays story title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCard(
              story: testStory,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Story Title'), findsOneWidget);
    });

    testWidgets('displays play icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCard(
              story: testStory,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCard(
              story: testStory,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StoryCard));
      expect(tapped, isTrue);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/story_card_test.dart`
Expected: FAIL with "story_card.dart not found"

**Step 3: Create StoryCard widget**

Create `lib/widgets/story_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/story_info.dart';

/// Claymorphism-styled story card with gradient and layered shadows.
class StoryCard extends StatelessWidget {
  final StoryInfo story;
  final VoidCallback onTap;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              story.primaryColor,
              story.secondaryColor.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: story.secondaryColor.withOpacity(0.3),
            width: 3,
          ),
          boxShadow: [
            // Outer shadow (claymorphism)
            BoxShadow(
              color: AppColors.shadowOuter.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            // Secondary shadow for depth
            BoxShadow(
              color: AppColors.shadowInner.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    story.title,
                    style: AppTypography.cardTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Icon(
                    Icons.play_circle_filled,
                    size: 64,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/story_card_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/widgets/story_card.dart test/widgets/story_card_test.dart
git commit -m "feat: add StoryCard widget with claymorphism styling"
```

---

## Task 7: Update HomeScreen

**Files:**
- Modify: `lib/screens/home_screen.dart`
- Modify: `test/screens/home_screen_test.dart` (create if not exists)

**Step 1: Write the failing test**

Create/update `test/screens/home_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:storili/screens/home_screen.dart';
import 'package:storili/widgets/capy_welcome.dart';
import 'package:storili/widgets/story_card.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('displays CapyWelcome', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
        ),
      );

      expect(find.byType(CapyWelcome), findsOneWidget);
    });

    testWidgets('displays StoryCard for Three Little Pigs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
        ),
      );

      expect(find.byType(StoryCard), findsOneWidget);
      expect(find.text('The Three Little Pigs'), findsOneWidget);
    });

    testWidgets('displays settings button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/screens/home_screen_test.dart`
Expected: FAIL (CapyWelcome/StoryCard not found in HomeScreen)

**Step 3: Update HomeScreen**

Replace `lib/screens/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../models/story_info.dart';
import '../widgets/capy_welcome.dart';
import '../widgets/story_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Storili',
          style: AppTypography.appTitle,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: AppColors.secondary,
            ),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Capy welcome area
              const Expanded(
                flex: 3,
                child: CapyWelcome(),
              ),
              const SizedBox(height: 24),
              // Story card
              Expanded(
                flex: 5,
                child: StoryCard(
                  story: availableStories.first,
                  onTap: () => context.go('/story/${availableStories.first.id}'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/screens/home_screen_test.dart`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/screens/home_screen.dart test/screens/home_screen_test.dart
git commit -m "feat: update HomeScreen with CapyWelcome and StoryCard"
```

---

## Task 8: Run Full Test Suite and Verify

**Step 1: Run all tests**

Run: `flutter test`
Expected: All tests pass

**Step 2: Run the app visually**

Run: `flutter run`
Expected: Home screen displays with Capy welcome and Three Little Pigs story card

**Step 3: Verify navigation**

- Tap story card → navigates to `/story/three-little-pigs`
- Tap settings → navigates to `/settings`

**Step 4: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "fix: address any test or visual issues"
```

---

## Summary

| Task | Files | Description |
|------|-------|-------------|
| 1 | pubspec.yaml | Add google_fonts dependency |
| 2 | theme.dart, theme_test.dart | Create AppColors class |
| 3 | theme.dart, theme_test.dart | Create AppTypography class |
| 4 | story_info.dart, story_info_test.dart | Create StoryInfo model |
| 5 | capy_welcome.dart, capy_welcome_test.dart | Create CapyWelcome widget |
| 6 | story_card.dart, story_card_test.dart | Create StoryCard widget |
| 7 | home_screen.dart, home_screen_test.dart | Update HomeScreen |
| 8 | - | Verify full test suite |

Total: 8 tasks, ~7 commits, ~30 minutes
