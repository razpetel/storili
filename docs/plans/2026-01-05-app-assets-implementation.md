# App Assets Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Generate and integrate all static assets (Capy illustrations, celebration jingle, placeholder, celebration stars) into the Storili app.

**Architecture:** Assets are generated via DALL-E 3 API (images) and sourced from stock libraries (audio). Images are post-processed for transparency and sizing, then integrated into existing Flutter widgets.

**Tech Stack:** OpenAI DALL-E 3 API, Freesound.org (CC0 audio), Flutter asset system, PNG optimization

**Working Directory:** `/Users/razpetel/projects/storili/.worktrees/app-assets`

**OpenAI API Key:** `$OPENAI_API_KEY` (provide at runtime)

---

## Task 1: Source Celebration Jingle

**Goal:** Find and download a CC0-licensed celebration jingle from Freesound.org

**Files:**
- Create: `assets/audio/celebration_jingle.mp3`

**Step 1: Search Freesound for candidates**

Search Freesound.org for CC0 celebration sounds:
- Query: `"celebration chime short"` or `"xylophone success"` or `"achievement jingle"`
- Filter: License = CC0, Duration < 3 seconds
- Look for: Major key, xylophone/bells, warm tone

**Step 2: Evaluate candidates**

Selection criteria:
- [ ] Duration: 1.5-2.5 seconds
- [ ] No vocals/lyrics
- [ ] Major key (happy feeling)
- [ ] Clean ending (no abrupt cut)
- [ ] Warm tone matching app aesthetic

**Step 3: Download selected audio**

Download the best match from Freesound (CC0 license = no attribution needed).

**Step 4: Process audio (if needed)**

If trimming/normalization needed:
```bash
# Using ffmpeg (if installed)
ffmpeg -i input.wav -t 2.0 -af "afade=t=out:st=1.7:d=0.3,loudnorm=I=-14" -ac 1 -b:a 128k assets/audio/celebration_jingle.mp3
```

Or manually:
- Trim to ~2.0 seconds
- Add 0.3s fade-out at end
- Normalize to -14 LUFS
- Convert to mono MP3 128kbps

**Step 5: Verify audio file**

```bash
file assets/audio/celebration_jingle.mp3
# Expected: assets/audio/celebration_jingle.mp3: Audio file with ID3 version 2.4.0...
```

**Step 6: Commit**

```bash
git add assets/audio/celebration_jingle.mp3
git commit -m "feat: add celebration jingle audio (CC0 from Freesound)"
```

---

## Task 2: Generate Capy Welcome Illustration

**Goal:** Generate the welcome pose Capy illustration using DALL-E 3

**Files:**
- Create: `assets/images/capy_welcome.png`

**Step 1: Call DALL-E 3 API**

```bash
curl -X POST "https://api.openai.com/v1/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "dall-e-3",
    "prompt": "A friendly capybara character in classic storybook watercolor illustration style. Soft hand-painted brushstrokes with visible paper texture. Warm golden-hour lighting.\n\nThe capybara has warm brown fur (#A67C52 tone), a rounded chunky body, and a soft friendly face with slightly sleepy, content eyes and a gentle closed-mouth smile.\n\nIMPORTANT ACCESSORIES (must appear in every image):\n- A classic yellow rubber duck sitting centered on the capybara head, tilted slightly to the left. The duck has a bright yellow body, orange beak, and small black dot eye.\n- A colorful horizontally-striped sock covering the tip of the capybara tail (about 30% of the tail). The sock has red, yellow, teal, and purple stripes repeating, and is slightly bunched.\n\nPOSE: The capybara is sitting upright facing the viewer, with one front paw raised in a friendly small wave. Expression is warm and inviting, eyes open and friendly, as if greeting a child for the first time. The rubber duck looks forward contentedly. Welcoming, safe feeling.\n\nStyle: Children book illustration, Caldecott medal aesthetic, soft edges, gentle shadows, no harsh lines, warm and cozy atmosphere, suitable for ages 3-5. Square format with character centered and breathing room around edges. Cream/warm white background (#FDF8F3).",
    "n": 1,
    "size": "1024x1024",
    "quality": "hd"
  }'
```

**Step 2: Download generated image**

Extract URL from response and download:
```bash
curl -o assets/images/capy_welcome_raw.png "<URL_FROM_RESPONSE>"
```

**Step 3: Verify image**

Open and visually verify:
- [ ] Capybara is present and friendly-looking
- [ ] Rubber duck on head (yellow with orange beak)
- [ ] Striped sock on tail (red, yellow, teal, purple)
- [ ] Watercolor style
- [ ] Warm cream background
- [ ] Welcome pose (paw raised)

**Step 4: Process image (resize to 480x480)**

```bash
# Using sips (macOS built-in)
sips -z 480 480 assets/images/capy_welcome_raw.png --out assets/images/capy_welcome.png
rm assets/images/capy_welcome_raw.png
```

**Step 5: Commit**

```bash
git add assets/images/capy_welcome.png
git commit -m "feat: add Capy welcome illustration"
```

---

## Task 3: Generate Capy Celebrate Illustration

**Goal:** Generate the celebrate pose Capy illustration using DALL-E 3

**Files:**
- Create: `assets/images/capy_celebrate.png`

**Step 1: Call DALL-E 3 API**

```bash
curl -X POST "https://api.openai.com/v1/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "dall-e-3",
    "prompt": "A friendly capybara character in classic storybook watercolor illustration style. Soft hand-painted brushstrokes with visible paper texture. Warm golden-hour lighting.\n\nThe capybara has warm brown fur (#A67C52 tone), a rounded chunky body, and a soft friendly face with slightly sleepy, content eyes and a gentle closed-mouth smile.\n\nIMPORTANT ACCESSORIES (must appear in every image):\n- A classic yellow rubber duck sitting centered on the capybara head, tilted slightly to the left. The duck has a bright yellow body, orange beak, and small black dot eye.\n- A colorful horizontally-striped sock covering the tip of the capybara tail (about 30% of the tail). The sock has red, yellow, teal, and purple stripes repeating, and is slightly bunched.\n\nPOSE: The capybara is standing on hind legs with both front paws raised up in celebration. Expression is joyful and excited - bigger smile, eyes squeezed in happiness. The rubber duck is tilted back slightly as if caught in the excitement. The sock appears bouncy/dynamic. Triumphant, party feeling.\n\nStyle: Children book illustration, Caldecott medal aesthetic, soft edges, gentle shadows, no harsh lines, warm and cozy atmosphere, suitable for ages 3-5. Square format with character centered and breathing room around edges. Cream/warm white background (#FDF8F3).",
    "n": 1,
    "size": "1024x1024",
    "quality": "hd"
  }'
```

**Step 2: Download generated image**

Extract URL from response and download:
```bash
curl -o assets/images/capy_celebrate_raw.png "<URL_FROM_RESPONSE>"
```

**Step 3: Verify image**

Open and visually verify:
- [ ] Capybara celebrating (paws up)
- [ ] Rubber duck on head (tilted back excitedly)
- [ ] Striped sock on tail (bouncy/dynamic)
- [ ] Joyful expression
- [ ] Watercolor style

**Step 4: Process image (resize to 480x480)**

```bash
sips -z 480 480 assets/images/capy_celebrate_raw.png --out assets/images/capy_celebrate.png
rm assets/images/capy_celebrate_raw.png
```

**Step 5: Commit**

```bash
git add assets/images/capy_celebrate.png
git commit -m "feat: add Capy celebrate illustration"
```

---

## Task 4: Generate Capy Wave Illustration

**Goal:** Generate the wave pose Capy illustration using DALL-E 3

**Files:**
- Create: `assets/images/capy_wave.png`

**Step 1: Call DALL-E 3 API**

```bash
curl -X POST "https://api.openai.com/v1/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "dall-e-3",
    "prompt": "A friendly capybara character in classic storybook watercolor illustration style. Soft hand-painted brushstrokes with visible paper texture. Warm golden-hour lighting.\n\nThe capybara has warm brown fur (#A67C52 tone), a rounded chunky body, and a soft friendly face with slightly sleepy, content eyes and a gentle closed-mouth smile.\n\nIMPORTANT ACCESSORIES (must appear in every image):\n- A classic yellow rubber duck sitting centered on the capybara head, tilted slightly to the left. The duck has a bright yellow body, orange beak, and small black dot eye.\n- A colorful horizontally-striped sock covering the tip of the capybara tail (about 30% of the tail). The sock has red, yellow, teal, and purple stripes repeating, and is slightly bunched.\n\nPOSE: The capybara is sitting calmly, with one paw extended in a gentle reassuring wave. Expression is calm and understanding, a soft supportive smile, eyes conveying it is okay energy. The rubber duck tilts slightly toward the viewer. Comforting, reassuring feeling.\n\nStyle: Children book illustration, Caldecott medal aesthetic, soft edges, gentle shadows, no harsh lines, warm and cozy atmosphere, suitable for ages 3-5. Square format with character centered and breathing room around edges. Cream/warm white background (#FDF8F3).",
    "n": 1,
    "size": "1024x1024",
    "quality": "hd"
  }'
```

**Step 2: Download generated image**

Extract URL from response and download:
```bash
curl -o assets/images/capy_wave_raw.png "<URL_FROM_RESPONSE>"
```

**Step 3: Verify image**

Open and visually verify:
- [ ] Capybara waving gently
- [ ] Rubber duck on head (tilted toward viewer)
- [ ] Striped sock on tail
- [ ] Calm, reassuring expression
- [ ] Watercolor style

**Step 4: Process image (resize to 480x480)**

```bash
sips -z 480 480 assets/images/capy_wave_raw.png --out assets/images/capy_wave.png
rm assets/images/capy_wave_raw.png
```

**Step 5: Commit**

```bash
git add assets/images/capy_wave.png
git commit -m "feat: add Capy wave illustration"
```

---

## Task 5: Generate Capy Sleep Illustration

**Goal:** Generate the sleep pose Capy illustration using DALL-E 3

**Files:**
- Create: `assets/images/capy_sleep.png`

**Step 1: Call DALL-E 3 API**

```bash
curl -X POST "https://api.openai.com/v1/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "dall-e-3",
    "prompt": "A friendly capybara character in classic storybook watercolor illustration style. Soft hand-painted brushstrokes with visible paper texture. Warm golden-hour lighting.\n\nThe capybara has warm brown fur (#A67C52 tone), a rounded chunky body, and a soft friendly face with slightly sleepy, content eyes and a gentle closed-mouth smile.\n\nIMPORTANT ACCESSORIES (must appear in every image):\n- A classic yellow rubber duck sitting centered on the capybara head, tilted slightly to the left. The duck has a bright yellow body, orange beak, and small black dot eye.\n- A colorful horizontally-striped sock covering the tip of the capybara tail (about 30% of the tail). The sock has red, yellow, teal, and purple stripes repeating, and is slightly bunched.\n\nPOSE: The capybara is curled up in a cozy sleeping position, paws tucked in, tail curled around body. Eyes are peacefully closed with a serene gentle smile. The rubber duck has nestled down with the capybara, also appearing sleepy. The sock is curled naturally with the tail. Peaceful, bedtime feeling.\n\nStyle: Children book illustration, Caldecott medal aesthetic, soft edges, gentle shadows, no harsh lines, warm and cozy atmosphere, suitable for ages 3-5. Square format with character centered and breathing room around edges. Cream/warm white background (#FDF8F3).",
    "n": 1,
    "size": "1024x1024",
    "quality": "hd"
  }'
```

**Step 2: Download generated image**

Extract URL from response and download:
```bash
curl -o assets/images/capy_sleep_raw.png "<URL_FROM_RESPONSE>"
```

**Step 3: Verify image**

Open and visually verify:
- [ ] Capybara curled up sleeping
- [ ] Rubber duck nestled with Capy
- [ ] Striped sock curled with tail
- [ ] Peaceful, serene expression
- [ ] Watercolor style

**Step 4: Process image (resize to 480x480)**

```bash
sips -z 480 480 assets/images/capy_sleep_raw.png --out assets/images/capy_sleep.png
rm assets/images/capy_sleep_raw.png
```

**Step 5: Commit**

```bash
git add assets/images/capy_sleep.png
git commit -m "feat: add Capy sleep illustration"
```

---

## Task 6: Generate Placeholder Image

**Goal:** Generate the placeholder/fallback image for failed image generation

**Files:**
- Create: `assets/images/placeholder.png`

**Step 1: Call DALL-E 3 API**

```bash
curl -X POST "https://api.openai.com/v1/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "dall-e-3",
    "prompt": "A soft watercolor illustration of an open storybook with blank pages, centered in the frame. Gentle golden light rays emanate from the book pages, suggesting magic and possibility. Three small gold 5-pointed stars float above the book.\n\nStyle: Classic children book watercolor, soft brushstrokes, visible paper texture, warm and inviting. Soft cream background gradient from light (#FDF8F3) at top to warmer cream (#F5E6D3) at bottom.\n\nSquare format, 1024x1024 pixels. The mood is hopeful and anticipatory - a story is waiting to appear. Suitable for ages 3-5.",
    "n": 1,
    "size": "1024x1024",
    "quality": "hd"
  }'
```

**Step 2: Download generated image**

Extract URL from response and download:
```bash
curl -o assets/images/placeholder.png "<URL_FROM_RESPONSE>"
```

**Step 3: Verify image**

Open and visually verify:
- [ ] Open storybook centered
- [ ] Golden light rays from pages
- [ ] Small gold stars above book
- [ ] Warm cream background
- [ ] Watercolor style

**Step 4: Commit**

```bash
git add assets/images/placeholder.png
git commit -m "feat: add placeholder image for failed image generation"
```

---

## Task 7: Generate Celebration Stars Image

**Goal:** Generate the celebration stars for reduced-motion accessibility

**Files:**
- Create: `assets/images/celebration_stars.png`

**Step 1: Call DALL-E 3 API**

```bash
curl -X POST "https://api.openai.com/v1/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "dall-e-3",
    "prompt": "A scattered pattern of watercolor stars and sparkles on a transparent background. The composition forms a gentle arc from top-left to bottom-right, denser at the top (like a celebration burst) and fading toward the bottom.\n\nElements:\n- 8-10 larger 5-pointed stars (gold/yellow #FFD93D) with soft watercolor edges\n- 6-8 medium 5-pointed stars (soft peach #FDBCB4)\n- 10-12 small 4-pointed sparkle shapes (mix of teal #4ECDC4 and gold #FFD93D)\n\nStyle: Watercolor with soft glowing edges, children book illustration quality. Each star should have subtle color variation and soft shadows. Joyful, celebratory feeling without being overwhelming.\n\nSquare format, 1024x1024 pixels, TRANSPARENT BACKGROUND (no cream, no white, pure transparency).",
    "n": 1,
    "size": "1024x1024",
    "quality": "hd"
  }'
```

**Step 2: Download generated image**

Extract URL from response and download:
```bash
curl -o assets/images/celebration_stars.png "<URL_FROM_RESPONSE>"
```

**Step 3: Verify image**

Open and visually verify:
- [ ] Gold, peach, and teal stars/sparkles
- [ ] Arc pattern (dense top, sparse bottom)
- [ ] Watercolor style
- [ ] Background (Note: DALL-E may not produce true transparency - may need post-processing)

**Step 4: Commit**

```bash
git add assets/images/celebration_stars.png
git commit -m "feat: add celebration stars for reduced-motion accessibility"
```

---

## Task 8: Update pubspec.yaml

**Goal:** Register new asset directories in Flutter

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Read current pubspec.yaml**

Check current asset configuration in pubspec.yaml.

**Step 2: Update assets section**

Ensure the flutter assets section includes:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/audio/
    - assets/images/
    - assets/stories/
    - assets/stories/_shared/
    - assets/stories/three-little-pigs/
    - assets/stories/three-little-pigs/characters/
    - assets/stories/three-little-pigs/scenes/
```

**Step 3: Commit**

```bash
git add pubspec.yaml
git commit -m "chore: register audio and images asset directories"
```

---

## Task 9: Update CapyWelcome Widget

**Goal:** Replace placeholder icon with actual Capy welcome illustration

**Files:**
- Modify: `lib/widgets/capy_welcome.dart`

**Step 1: Read current widget**

Examine current CapyWelcome implementation.

**Step 2: Update to use image asset**

Replace the placeholder Icon with Image.asset:

```dart
import 'package:flutter/material.dart';

class CapyWelcome extends StatelessWidget {
  const CapyWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/capy_welcome.png',
          width: 240,
          height: 240,
          fit: BoxFit.contain,
          semanticLabel: 'Capy the capybara waving hello',
        ),
        const SizedBox(height: 16),
        Text(
          'Hi there!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}
```

**Step 3: Commit**

```bash
git add lib/widgets/capy_welcome.dart
git commit -m "feat: update CapyWelcome to use illustration asset"
```

---

## Task 10: Update SceneImage Fallback

**Goal:** Use placeholder.png as fallback in SceneImage widget

**Files:**
- Modify: `lib/widgets/scene_image.dart`

**Step 1: Read current widget**

Examine current SceneImage error/placeholder handling.

**Step 2: Update error state to use placeholder image**

Find the placeholder/error widget section and update to:

```dart
Widget _buildPlaceholder() {
  return Image.asset(
    'assets/images/placeholder.png',
    fit: BoxFit.cover,
    semanticLabel: 'Story image loading',
  );
}
```

**Step 3: Commit**

```bash
git add lib/widgets/scene_image.dart
git commit -m "feat: update SceneImage to use placeholder asset"
```

---

## Task 11: Verify All Assets Load

**Goal:** Ensure all assets are correctly registered and loadable

**Step 1: Run Flutter analyze**

```bash
flutter analyze
```

Expected: No errors related to assets.

**Step 2: Build app**

```bash
flutter build ios --debug
# or
flutter build apk --debug
```

Expected: Build succeeds without asset errors.

**Step 3: Run app and verify visually**

```bash
flutter run
```

Navigate through app and verify:
- [ ] Home screen shows Capy welcome illustration
- [ ] Story images show placeholder on error
- [ ] (If celebration screen accessible) Shows celebrate Capy

---

## Task 12: Final Commit and Summary

**Goal:** Create summary commit with all assets

**Step 1: Check git status**

```bash
git status
git log --oneline -10
```

**Step 2: Verify asset file sizes**

```bash
du -sh assets/audio/* assets/images/*
```

Expected: Total under 2MB.

**Step 3: Push branch**

```bash
git push -u origin feature/app-assets
```

---

## Asset Checklist

| Asset | File | Status |
|-------|------|--------|
| Celebration Jingle | `assets/audio/celebration_jingle.mp3` | [ ] |
| Capy Welcome | `assets/images/capy_welcome.png` | [ ] |
| Capy Celebrate | `assets/images/capy_celebrate.png` | [ ] |
| Capy Wave | `assets/images/capy_wave.png` | [ ] |
| Capy Sleep | `assets/images/capy_sleep.png` | [ ] |
| Placeholder | `assets/images/placeholder.png` | [ ] |
| Celebration Stars | `assets/images/celebration_stars.png` | [ ] |

## Notes for Executor

- **DALL-E may require regeneration** - If an image doesn't match spec (missing duck, wrong pose), regenerate with same prompt
- **Transparency** - DALL-E 3 doesn't produce true transparency; celebration_stars.png may need manual background removal
- **Audio processing** - If ffmpeg not available, use online tool or GarageBand
- **Flutter path** - Flutter may not be in PATH; use full path or source shell profile
