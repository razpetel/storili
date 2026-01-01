# Home Screen Design

> Phase 4 - Full Loop: Story selection home screen for Storili

## Overview

Single-story hero layout optimized for children ages 3-5. Claymorphism style with warm storybook colors. Touch-first, pre-reader friendly.

## Design Decisions

### Layout: Hero Invitation (not grid)

With one story, a grid looks empty. Instead: full-focus hero card.

```
┌─────────────────────────────────────────┐
│ Storili                            ⚙️   │
│                                         │
│     ┌─────────────────────────────┐     │
│     │      Capy Welcome Area      │     │  ← Delight, connection
│     │      "Ready for a story?"   │     │
│     └─────────────────────────────┘     │
│                                         │
│     ┌─────────────────────────────┐     │
│     │                             │     │
│     │    [Warm gradient bg]       │     │
│     │                             │     │
│     │    The Three Little Pigs    │     │
│     │                             │     │
│     │         ▶ Play              │     │
│     │                             │     │
│     └─────────────────────────────┘     │  ← Full card tappable
│                                         │
└─────────────────────────────────────────┘
```

Scales to grid when more stories added.

### Style: Claymorphism

Source: UI/UX Pro Max - recommended for children's apps, educational apps.

- Soft 3D, chunky, playful, toy-like, bubbly
- Thick borders (3-4px), rounded corners (16-24px)
- Double shadows (inner + outer) for "squeezable" feel
- Soft press animation (200ms ease-out)

### Typography: Playful Creative

Source: UI/UX Pro Max - best for children's apps, educational, entertainment.

| Role | Font | Weight | Size |
|------|------|--------|------|
| App Title | Fredoka | 700 | 24sp |
| Card Title | Fredoka | 600 | 22sp |
| Body/Capy | Nunito | 500 | 18sp |
| Button | Nunito | 600 | 16sp |

Google Fonts import:
```
https://fonts.googleapis.com/css2?family=Fredoka:wght@400;500;600;700&family=Nunito:wght@300;400;500;600;700&display=swap
```

### Color Palette: Warm Storybook

Cottage-inspired warmth + claymorphism pastels.

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Primary | Warm Cream | `#F5E6D3` | Card backgrounds |
| Secondary | Soft Brown | `#8B7355` | Borders, icons |
| Accent | Friendly Orange | `#F97316` | CTA buttons, highlights |
| Background | Light Warm | `#FDF8F3` | Screen background |
| Text Primary | Deep Brown | `#3D2914` | Headings |
| Text Secondary | Medium Brown | `#6B5344` | Body text |
| Shadow | Soft Peach | `#FDBCB4` | Outer shadows |
| Shadow Inner | Light Peach | `#FFE4D6` | Inner shadows |

### Touch Targets

Source: UI/UX Pro Max UX guidelines.

- Story card: Full-width, 200dp+ height (far exceeds 48dp minimum)
- Minimum 8px gap between elements
- No hover-only interactions (tap-first)
- Entire card tappable, not just button

### Accessibility

- Text contrast: Deep Brown on Warm Cream = 7.2:1 (WCAG AAA)
- Touch targets exceed WCAG 2.2 requirements
- Reduced motion: respect `MediaQuery.disableAnimations`

## Component Structure

### StoryInfo Model

```dart
class StoryInfo {
  final String id;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;

  const StoryInfo({...});
}

const availableStories = [
  StoryInfo(
    id: 'three-little-pigs',
    title: 'The Three Little Pigs',
    primaryColor: Color(0xFFF5E6D3),  // Warm cream
    secondaryColor: Color(0xFF8B7355), // Soft brown
  ),
];
```

### HomeScreen Layout

```dart
Scaffold(
  backgroundColor: AppColors.background,
  appBar: AppBar(title: 'Storili', actions: [settings]),
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(flex: 3, child: CapyWelcome()),
          SizedBox(height: 24),
          Expanded(flex: 5, child: StoryCard(...)),
          SizedBox(height: 24),
        ],
      ),
    ),
  ),
)
```

### CapyWelcome Widget

Placeholder for MVP, easy to enhance:

- Rounded container with soft shadow
- Capybara placeholder (icon or simple illustration)
- "Ready for a story?" text
- Later: animated Capy, personalized greeting

### StoryCard Widget

Claymorphism card with:

- Gradient background (primaryColor → secondaryColor)
- Rounded corners (20dp)
- Double shadow (outer soft peach, inner light peach)
- Title text (Fredoka 600)
- Play icon (centered, large)
- InkWell for tap ripple
- Scale animation on press (0.98, 200ms)

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [story.primaryColor, story.secondaryColor.withOpacity(0.3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: story.secondaryColor.withOpacity(0.3), width: 3),
    boxShadow: [
      // Outer shadow
      BoxShadow(
        color: AppColors.shadowOuter,
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
      // Inner shadow effect via gradient
    ],
  ),
  child: InkWell(
    onTap: () => context.go('/story/${story.id}'),
    borderRadius: BorderRadius.circular(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(story.title, style: AppTypography.cardTitle),
        SizedBox(height: 16),
        Icon(Icons.play_circle_filled, size: 64, color: AppColors.accent),
      ],
    ),
  ),
)
```

## Theme Integration

Update `lib/app/theme.dart`:

```dart
class AppColors {
  static const primary = Color(0xFFF5E6D3);
  static const secondary = Color(0xFF8B7355);
  static const accent = Color(0xFFF97316);
  static const background = Color(0xFFFDF8F3);
  static const textPrimary = Color(0xFF3D2914);
  static const textSecondary = Color(0xFF6B5344);
  static const shadowOuter = Color(0xFFFDBCB4);
  static const shadowInner = Color(0xFFFFE4D6);
}

class AppTypography {
  static const cardTitle = TextStyle(
    fontFamily: 'Fredoka',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  // ... more styles
}
```

## Files to Create/Modify

| File | Action |
|------|--------|
| `lib/models/story_info.dart` | Create |
| `lib/widgets/story_card.dart` | Create |
| `lib/widgets/capy_welcome.dart` | Create |
| `lib/screens/home_screen.dart` | Modify |
| `lib/app/theme.dart` | Modify (add colors, typography) |
| `pubspec.yaml` | Add Google Fonts |

## Future Enhancements (Out of Scope)

- Animated Capy (waving, bouncing)
- Story cover illustrations
- Progress badges (NEW, CONTINUE, COMPLETED)
- Multiple story grid layout
- Personalized greeting with child's name
