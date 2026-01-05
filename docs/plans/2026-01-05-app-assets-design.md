# App Assets Design

**Date:** 2026-01-05
**Status:** ✅ Implemented
**Phase:** Cross-cutting (supports Phases 4, 6, 7)
**Branch:** `feature/app-assets`

> **Implementation Note:** The original design specified a "sock on tail" accessory for Capy. After extensive testing with DALL-E 3, this was simplified to "duck on head only" due to AI limitations with tail accessories. See [DALL-E 3 Learnings](#dall-e-3-learnings) section below.

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

### Signature Accessory

Always present in every illustration:

| Accessory | Colors | Position | Details |
|-----------|--------|----------|---------|
| Rubber Duck | Body: #FFD93D, Beak: #FF8C42, Eye: #1A1A1A | Centered on top of head | Classic bath duck shape, sitting like a tiny hat |

> **Design Evolution:** Original spec included a striped sock on tail. Removed after DALL-E 3 testing showed consistent failure to place accessories on tails (see [DALL-E 3 Learnings](#dall-e-3-learnings)).

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
| Duck | Sitting on head, looking forward |
| Mood | "Hello, friend!" |

#### 2. Celebrate (`capy_celebrate.png`)

| Aspect | Specification |
|--------|---------------|
| Emotion | Joyful, excited |
| Body | Standing on hind legs, both paws up |
| Face | Big smile, eyes squeezed happy |
| Duck | On head, tilted back with excitement |
| Mood | "You did it!" |

#### 3. Wave (`capy_wave.png`)

| Aspect | Specification |
|--------|---------------|
| Emotion | Gentle, reassuring |
| Body | Sitting, one paw extended waving |
| Face | Calm smile, understanding eyes |
| Duck | On head, slight tilt toward viewer |
| Mood | "See you soon!" |

#### 4. Sleep (`capy_sleep.png`)

| Aspect | Specification |
|--------|---------------|
| Emotion | Peaceful, cozy |
| Body | Curled up, paws tucked |
| Face | Eyes closed, serene smile |
| Duck | Nestled on head, also appearing sleepy |
| Mood | "Rest time" |

## DALL-E Prompt Templates

### Base Prompt (prepend to all Capy poses)

```
Children's storybook watercolor illustration of a friendly capybara character.

THE CAPYBARA:
- Warm brown fur (#A67C52) covering entire body
- Rounded, chunky, friendly body shape
- Natural brown furry paws
- Soft friendly face with slightly sleepy, content eyes

ACCESSORY: A bright yellow rubber duck toy sitting on top of the capybara's head,
like a tiny hat. The duck has a yellow body, orange beak, and small black dot eye.

STYLE: Caldecott medal quality, soft watercolor brushstrokes, visible paper texture,
warm golden-hour lighting, cream background (#FDF8F3), suitable for ages 3-5.
Square format, character centered with breathing room.
```

### Pose: Welcome

```
POSE: Sitting upright facing viewer, one front paw raised in a friendly small wave.
Expression is warm and inviting, eyes open and friendly. The rubber duck on head
looks forward contentedly. Welcoming, safe feeling.
```

### Pose: Celebrate

```
POSE: Standing on hind legs with both front paws raised high in celebration.
Expression is joyful - big smile, eyes squeezed happy. The rubber duck on head
tilts back excitedly. Triumphant, party feeling.
```

### Pose: Wave

```
POSE: Sitting calmly, one paw extended in gentle reassuring wave.
Expression is calm and understanding, soft supportive smile. The rubber duck
on head tilts slightly toward viewer. Comforting, reassuring feeling.
```

### Pose: Sleep

```
POSE: Curled up in cozy sleeping position, paws tucked in.
Eyes peacefully closed with serene smile. The rubber duck has nestled down
on head, also appearing sleepy. Peaceful, bedtime feeling.
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

- [x] Capy silhouette readable at 48x48px (thumbnail)
- [x] Fur contrast ratio >=3:1 against #FDF8F3 background
- [x] Duck distinguishable (yellow on brown = good contrast)
- [x] No fine details lost at 1x resolution
- [x] `celebration_stars.png` works as reduced-motion alternative
- [x] Audio not required for core functionality

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

### Estimated vs Actual

| Asset Type | Count | Estimated | Actual |
|------------|-------|-----------|--------|
| Capy PNGs (480x480) | 4 | ~600KB | 1.5MB |
| Placeholder PNG (1024x1024) | 1 | ~200KB | 1.6MB |
| Celebration Stars PNG (1024x1024) | 1 | ~150KB | 1.6MB |
| Celebration Jingle (MP3) | 1 | ~50KB | 32KB |
| **Total** | **7** | **~1MB** | **~5.6MB** |

> **Note:** 1024x1024 images are larger than estimated. Could resize to 512x512 to save ~3MB if needed. Current size acceptable for modern devices.

---

## DALL-E 3 Learnings

### What Worked Well

1. **Watercolor style** - DALL-E 3 excels at children's book illustration styles
2. **Duck-on-head placement** - Successful with explicit "sitting on top of head like a hat" phrasing
3. **Consistent character** - Brown capybara with friendly expression reproduced well
4. **Supporting images** - Placeholder and celebration stars generated perfectly on first try

### What Didn't Work

1. **Tail accessories** - DALL-E 3 consistently fails to place accessories specifically on tails
   - Tried: "sock on tail", "tail cozy", "tail warmer", "knitted sleeve on tail"
   - Result: Always placed on feet, body, or as scarf instead

2. **Negative prompts for body parts** - "No socks on feet" often backfires
   - DALL-E interprets "sock" and puts socks on feet anyway
   - Better to describe what IS there ("natural brown furry paws")

### Best Practices Discovered

| Technique | Effectiveness |
|-----------|---------------|
| Describe what IS there, not what ISN'T | ✅ High |
| Use "like a hat" for head accessories | ✅ High |
| Spatial anchoring ("centered on top of skull") | ✅ High |
| Mentioning specific hex colors | ⚠️ Medium (influences tone but not exact) |
| Regional exclusions ("no X on Y") | ❌ Low (often ignored) |
| Synonym substitution for stubborn concepts | ❌ Low (tail remained problematic) |

### Prompt Engineering Tips

1. **For reliable head placement:**
   ```
   A [accessory] sitting on top of the [character]'s head, like a tiny hat.
   The [accessory] is centered on the very top of the head.
   ```

2. **For bare body parts:**
   ```
   Natural brown furry paws (not "no socks on feet")
   Four brown paws matching body fur color
   ```

3. **For watercolor children's style:**
   ```
   Caldecott medal quality, soft watercolor brushstrokes,
   visible paper texture, warm golden-hour lighting
   ```

### Recommendation

For character designs requiring specific accessory placements on non-standard body parts (tails, ears, etc.), consider:
1. Simplify the design to achievable placements (head, body, hands)
2. Use Midjourney with `--cref` for better character consistency
3. Commission an illustrator for complex requirements
4. Use AI generation as base, then manual editing in image editor
