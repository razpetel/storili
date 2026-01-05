# App Assets Design

**Date:** 2026-01-05
**Status:** Ready for Implementation
**Phase:** Cross-cutting (supports Phases 4, 6, 7)

## Overview

This document specifies all static assets needed for the Storili app, including Capy character illustrations, audio, and supporting graphics. Assets integrate with the existing claymorphism UI and watercolor story image aesthetic.

## Asset Inventory

| Asset | File | Size | Purpose | Generation Method |
|-------|------|------|---------|-------------------|
| Capy Welcome | `assets/images/capy_welcome.png` | 480x480 @2x | Home screen | DALL-E 3 |
| Capy Celebrate | `assets/images/capy_celebrate.png` | 480x480 @2x | Celebration screen | DALL-E 3 |
| Capy Wave | `assets/images/capy_wave.png` | 480x480 @2x | Time limit dialog | DALL-E 3 |
| Capy Sleep | `assets/images/capy_sleep.png` | 480x480 @2x | Playtime blocked | DALL-E 3 |
| Placeholder | `assets/images/placeholder.png` | 1024x1024 | Image fallback | DALL-E 3 |
| Celebration Stars | `assets/images/celebration_stars.png` | 1024x1024 | Reduced motion alt | DALL-E 3 |
| Celebration Jingle | `assets/audio/celebration_jingle.mp3` | ~2s | Celebration audio | Stock library |

## Capy Character Specification

### Visual Identity

Capy is the app's capybara mascot companion.

```
Species:        Capybara (Hydrochoerus hydrochaeris)
Fur Color:      #A67C52 (warm brown) with #D4A574 highlights
Eye Color:      #4A3728 (deep warm brown)
Expression:     Soft smile, slightly sleepy/content eyes, no teeth visible
Body:           Rounded, chunky proportions (claymorphism-compatible)
Art Style:      Classic storybook watercolor, hand-painted brushstrokes
```

### Signature Accessories

Always present in every illustration:

| Accessory | Colors | Position | Details |
|-----------|--------|----------|---------|
| Rubber Duck | Body: #FFD93D, Beak: #FF8C42, Eye: #1A1A1A | Centered on head, 10° left tilt | Classic bath duck shape |
| Striped Sock | Stripes: #FF6B6B, #FFD93D, #4ECDC4, #9B59B6 (repeat) | Covering ~30% of tail tip | Horizontal stripes, slightly bunched |

### Size Specifications

```
DALL-E Output:   1024x1024px (native)
Export @2x:      480x480px (app usage for Capy)
Export @1x:      240x240px (low-res fallback)
Format:          PNG with transparency
Safe Zone:       Character within center 80%
Background:      Transparent (UI provides #FDF8F3)
```

### Pose Definitions

#### 1. Welcome (`capy_welcome.png`)

| Aspect | Specification |
|--------|---------------|
| Emotion | Warm, inviting |
| Body | Sitting upright, one paw raised in small wave |
| Face | Soft smile, eyes open and friendly |
| Duck | Upright, looking forward |
| Sock | Relaxed |
| Mood | "Hello, friend!" |

#### 2. Celebrate (`capy_celebrate.png`)

| Aspect | Specification |
|--------|---------------|
| Emotion | Joyful, excited |
| Body | Standing on hind legs, both paws up |
| Face | Big smile, eyes squeezed happy |
| Duck | Tilted back (excitement) |
| Sock | Bouncy/dynamic |
| Mood | "You did it!" |

#### 3. Wave (`capy_wave.png`)

| Aspect | Specification |
|--------|---------------|
| Emotion | Gentle, reassuring |
| Body | Sitting, one paw extended waving |
| Face | Calm smile, understanding eyes |
| Duck | Slight tilt toward viewer |
| Sock | Relaxed |
| Mood | "See you soon!" |

#### 4. Sleep (`capy_sleep.png`)

| Aspect | Specification |
|--------|---------------|
| Emotion | Peaceful, cozy |
| Body | Curled up, paws tucked |
| Face | Eyes closed, serene smile |
| Duck | Nestled down with Capy |
| Sock | Curled around tail |
| Mood | "Rest time" |

## DALL-E Prompt Templates

### Base Prompt (prepend to all Capy poses)

```
A friendly capybara character in classic storybook watercolor illustration style.
Soft hand-painted brushstrokes with visible paper texture. Warm golden-hour lighting.

The capybara has warm brown fur (#A67C52 tone), a rounded chunky body, and a soft
friendly face with slightly sleepy, content eyes and a gentle closed-mouth smile.

IMPORTANT ACCESSORIES (must appear in every image):
- A classic yellow rubber duck sitting centered on the capybara's head, tilted
  slightly to the left. The duck has a bright yellow body, orange beak, and small
  black dot eye.
- A colorful horizontally-striped sock covering the tip of the capybara's tail
  (about 30% of the tail). The sock has red, yellow, teal, and purple stripes
  repeating, and is slightly bunched.

Style: Children's book illustration, Caldecott medal aesthetic, soft edges,
gentle shadows, no harsh lines, warm and cozy atmosphere, suitable for ages 3-5.
Square format with character centered and breathing room around edges.
Cream/warm white background (#FDF8F3).
```

### Pose: Welcome

```
POSE: The capybara is sitting upright facing the viewer, with one front paw
raised in a friendly small wave. Expression is warm and inviting, eyes open
and friendly, as if greeting a child for the first time. The rubber duck
looks forward contentedly. Welcoming, safe feeling.
```

### Pose: Celebrate

```
POSE: The capybara is standing on hind legs with both front paws raised up
in celebration. Expression is joyful and excited - bigger smile, eyes squeezed
in happiness. The rubber duck is tilted back slightly as if caught in the
excitement. The sock appears bouncy/dynamic. Triumphant, party feeling.
```

### Pose: Wave

```
POSE: The capybara is sitting calmly, with one paw extended in a gentle
reassuring wave. Expression is calm and understanding, a soft supportive smile,
eyes conveying "it's okay" energy. The rubber duck tilts slightly toward the
viewer. Comforting, reassuring feeling.
```

### Pose: Sleep

```
POSE: The capybara is curled up in a cozy sleeping position, paws tucked in,
tail curled around body. Eyes are peacefully closed with a serene gentle smile.
The rubber duck has nestled down with the capybara, also appearing sleepy.
The sock is curled naturally with the tail. Peaceful, bedtime feeling.
```

### Prompt: Placeholder Image

```
A soft watercolor illustration of an open storybook with blank pages, centered
in the frame. Gentle golden light rays emanate from the book's pages, suggesting
magic and possibility. Three small gold 5-pointed stars float above the book.

Style: Classic children's book watercolor, soft brushstrokes, visible paper
texture, warm and inviting. Soft cream background gradient from light (#FDF8F3)
at top to warmer cream (#F5E6D3) at bottom.

Square format, 1024x1024 pixels. The mood is hopeful and anticipatory -
"a story is waiting to appear." Suitable for ages 3-5.
```

### Prompt: Celebration Stars

```
A scattered pattern of watercolor stars and sparkles on a transparent background.
The composition forms a gentle arc from top-left to bottom-right, denser at the
top (like a celebration burst) and fading toward the bottom.

Elements:
- 8-10 larger 5-pointed stars (gold/yellow #FFD93D) with soft watercolor edges
- 6-8 medium 5-pointed stars (soft peach #FDBCB4)
- 10-12 small 4-pointed sparkle shapes (mix of teal #4ECDC4 and gold #FFD93D)

Style: Watercolor with soft glowing edges, children's book illustration quality.
Each star should have subtle color variation and soft shadows. Joyful, celebratory
feeling without being overwhelming.

Square format, 1024x1024 pixels, TRANSPARENT BACKGROUND (no cream, no white).
```

## Audio Specification

### Celebration Jingle

| Property | Value |
|----------|-------|
| File | `assets/audio/celebration_jingle.mp3` |
| Duration | 1.8-2.2 seconds (target 2.0s) |
| Format | MP3 or AAC, mono, 128kbps minimum |
| Loudness | Normalized to -14 LUFS |
| Style | Xylophone/glockenspiel, ascending major scale, magical shimmer tail |
| Fade | 0.3s fade-out at end |
| License | CC0 or Pixabay License only (no attribution required) |

### Source Strategy

**Priority order:**
1. Freesound.org (CC0)
2. Pixabay Music
3. Mixkit

**Search queries:**
- `"celebration chime short CC0"`
- `"xylophone success sound effect"`
- `"kids achievement jingle"`
- `"magical sparkle bell"`

**Selection criteria:**
- [ ] Duration under 2.5 seconds (trim if needed)
- [ ] No lyrics or voice
- [ ] Major key (happy feeling)
- [ ] Clean ending (no abrupt cut)
- [ ] Warm tone matching app aesthetic
- [ ] Not overly "gamey" or arcade-like

**Fallback:** Suno AI generation if no suitable stock found.

## Supporting Images

### Placeholder Image

| Property | Value |
|----------|-------|
| File | `assets/images/placeholder.png` |
| Size | 1024x1024px |
| Background | Soft cream watercolor wash with transparency |
| Content | Open storybook with light rays, 3 gold stars |
| Style | Watercolor, matches art_style.txt |
| Usage | Error fallback when DALL-E image generation fails |

### Celebration Stars

| Property | Value |
|----------|-------|
| File | `assets/images/celebration_stars.png` |
| Size | 1024x1024px |
| Background | Fully transparent |
| Content | 8-10 gold stars, 6-8 peach stars, 10-12 teal/gold sparkles |
| Distribution | Arc burst from top-left, fading toward bottom-right |
| Style | Watercolor with soft glow |
| Usage | `prefers-reduced-motion` alternative to confetti animation |

## Integration Points

### Widget Updates Required

| Widget | File | Change |
|--------|------|--------|
| CapyWelcome | `lib/widgets/capy_welcome.dart` | Replace `Icons.pets` with `capy_welcome.png` |
| CelebrationScreen | `lib/screens/celebration_screen.dart` | Add `capy_celebrate.png`, jingle, stars |
| SceneImage | `lib/widgets/scene_image.dart` | Use `placeholder.png` for error state |
| TimeLimit dialog | (Phase 6) | Use `capy_wave.png`, `capy_sleep.png` |

### pubspec.yaml Update

```yaml
flutter:
  assets:
    - assets/audio/
    - assets/images/
    - assets/stories/
```

## Implementation Workflow

### Phase A: Setup

1. Create git worktree: `feature/app-assets`
2. Create directories: `assets/audio/`, `assets/images/`
3. Update `pubspec.yaml` with asset paths

### Phase B: Audio Acquisition

1. Search Freesound.org for CC0 celebration jingles
2. Download top 3 candidates
3. Evaluate against selection criteria
4. Process selected audio:
   - Trim to ~2.0s
   - Normalize to -14 LUFS
   - Convert to mono MP3 128kbps
   - Add 0.3s fade-out
5. Save as `assets/audio/celebration_jingle.mp3`

### Phase C: Image Generation

For each image asset:
1. Call OpenAI DALL-E 3 API with appropriate prompt
2. Download generated image
3. Post-process:
   - Remove/verify background transparency
   - Resize to spec dimensions
   - Optimize PNG file size
4. Save to `assets/images/`

### Phase D: Integration

1. Place assets in correct directories
2. Update widgets to reference new assets
3. Test on iOS simulator + Android emulator
4. Verify reduced-motion accessibility works

### Phase E: Verification

1. Run `flutter build` to verify no errors
2. Test full user flow (home → story → celebration)
3. Verify assets display correctly at 1x, 2x, 3x scales
4. Check total asset bundle size increase (target: <2MB)
5. Commit and merge

## Accessibility Checklist

- [ ] Capy silhouette readable at 48x48px (thumbnail)
- [ ] Fur contrast ratio >=3:1 against #FDF8F3 background
- [ ] Duck and sock distinguishable for colorblind users
- [ ] No fine details lost at 1x resolution
- [ ] `celebration_stars.png` works as reduced-motion alternative
- [ ] Audio not required for core functionality

## Design System Alignment

| App Token | Value | Asset Usage |
|-----------|-------|-------------|
| `AppColors.secondary` | #8B7355 | Near-match to Capy fur (#A67C52) |
| `AppColors.accent` | #F97316 | Harmonizes with duck beak (#FF8C42) |
| `AppColors.primary` | #F5E6D3 | UI provides background, not baked into assets |
| `AppColors.shadowOuter` | #FDBCB4 | Peach tones in celebration stars |

## API Keys Required

| Service | Key Needed | Purpose |
|---------|------------|---------|
| OpenAI | `OPENAI_API_KEY` | DALL-E 3 image generation |
| (none) | - | Stock audio is free |

## Fallback Strategy

| Asset | Primary | Fallback |
|-------|---------|----------|
| Capy illustrations | DALL-E 3 | Midjourney manual, then commission |
| Audio jingle | Freesound CC0 | Pixabay -> Suno AI -> commission |
| Placeholder | DALL-E 3 | Keep existing gradient in code |
| Celebration stars | DALL-E 3 | Simple CSS/Flutter painted shapes |

## File Size Budget

| Asset Type | Count | Est. Size Each | Total |
|------------|-------|----------------|-------|
| Capy PNGs | 4 | ~150KB | ~600KB |
| Placeholder PNG | 1 | ~200KB | ~200KB |
| Celebration Stars PNG | 1 | ~150KB | ~150KB |
| Celebration Jingle | 1 | ~50KB | ~50KB |
| **Total** | **7** | - | **~1MB** |

Target: Under 2MB total asset bundle increase.
