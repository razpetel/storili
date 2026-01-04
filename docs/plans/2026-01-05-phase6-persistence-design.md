# Phase 6: Persistence - Design Document

**Date:** 2026-01-05
**Status:** Approved
**Author:** Claude + User collaboration

## Overview

Implement local persistence for Storili app including session save/resume, playtime tracking with 30-minute daily cap, and related UI updates.

## Decisions

| Decision | Choice |
|----------|--------|
| Scope | Full Phase 6 spec |
| Storage backend | shared_preferences |
| Save triggers | All (completion, exit, time cap, backgrounded) |
| Time cap behavior | Graceful exit at 30 min, no warning |
| Resume UX | Silent auto-resume + "Continue" badge |
| Celebration screen | Defer to Phase 7 |
| Image persistence | Skip (text summaries only) |
| Time cap exit | Disconnect + local Capy goodbye UI |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     PHASE 6 ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  New Files:                                                 │
│  ├── lib/models/story_progress.dart     (data model)        │
│  ├── lib/services/storage_service.dart  (persistence)       │
│  └── lib/widgets/time_limit_dialog.dart (Capy goodbye UI)   │
│                                                             │
│  Modified Files:                                            │
│  ├── lib/providers/story_provider.dart  (save triggers)     │
│  ├── lib/providers/services.dart        (storage provider)  │
│  ├── lib/screens/home_screen.dart       (load progress)     │
│  ├── lib/screens/story_screen.dart      (lifecycle + exit)  │
│  ├── lib/screens/settings_screen.dart   (reset dialog)      │
│  ├── lib/widgets/story_card.dart        (status badges)     │
│  └── pubspec.yaml                       (add dependency)    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Model

### StoryProgress

```dart
// lib/models/story_progress.dart
enum StoryStatus { notStarted, inProgress, completed }

class StoryProgress {
  final StoryStatus status;
  final String? summary;      // AI-generated resume context
  final DateTime? updatedAt;

  const StoryProgress({
    this.status = StoryStatus.notStarted,
    this.summary,
    this.updatedAt,
  });

  static const notStarted = StoryProgress(status: StoryStatus.notStarted);

  StoryProgress copyWith({
    StoryStatus? status,
    String? summary,
    DateTime? updatedAt,
  }) {
    return StoryProgress(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'summary': summary,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory StoryProgress.fromJson(Map<String, dynamic> json) {
    return StoryProgress(
      status: StoryStatus.values.byName(json['status'] as String),
      summary: json['summary'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
```

### Storage Keys

| Key | Type | Purpose |
|-----|------|---------|
| `storili_playtime_minutes` | int | Today's cumulative playtime |
| `storili_playtime_date` | String | Date of last update (YYYY-MM-DD) |
| `storili_progress_{storyId}` | JSON | StoryProgress per story |

---

## StorageService

```dart
// lib/services/storage_service.dart
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Story Progress
  StoryProgress? getProgress(String storyId) {
    final json = _prefs.getString('storili_progress_$storyId');
    if (json == null) return null;
    try {
      return StoryProgress.fromJson(jsonDecode(json));
    } catch (_) {
      return null;  // Corrupted data → treat as not started
    }
  }

  Future<void> saveProgress(String storyId, StoryProgress progress) async {
    await _prefs.setString(
      'storili_progress_$storyId',
      jsonEncode(progress.toJson()),
    );
  }

  Future<void> clearProgress(String storyId) async {
    await _prefs.remove('storili_progress_$storyId');
  }

  Future<void> clearAllProgress() async {
    final keys = _prefs.getKeys()
        .where((k) => k.startsWith('storili_progress_'));
    for (final key in keys) {
      await _prefs.remove(key);
    }
    await _prefs.remove('storili_playtime_minutes');
    await _prefs.remove('storili_playtime_date');
  }

  // Playtime Tracking
  int getTodayPlaytimeMinutes() {
    final storedDate = _prefs.getString('storili_playtime_date');
    final today = _todayString();

    if (storedDate != today) {
      return 0;  // New day, reset
    }
    return _prefs.getInt('storili_playtime_minutes') ?? 0;
  }

  Future<void> addPlaytimeMinutes(int minutes) async {
    final today = _todayString();
    final storedDate = _prefs.getString('storili_playtime_date');

    int current = 0;
    if (storedDate == today) {
      current = _prefs.getInt('storili_playtime_minutes') ?? 0;
    }

    await _prefs.setString('storili_playtime_date', today);
    await _prefs.setInt('storili_playtime_minutes', current + minutes);
  }

  String _todayString() => DateTime.now().toIso8601String().split('T')[0];
}
```

### Provider Setup

```dart
// lib/providers/services.dart
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Override in main.dart');
});

// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(StorageService(prefs)),
      ],
      child: const StoriliApp(),
    ),
  );
}
```

---

## StoryNotifier Changes

```dart
class StoryNotifier extends StateNotifier<StoryState> {
  final StorageService _storage;
  final ElevenLabsService _elevenLabs;

  DateTime? _sessionStartTime;
  Timer? _timeLimitTimer;

  static const _dailyLimitMinutes = 30;

  // Session Lifecycle
  Future<bool> canStartSession() async {
    final played = _storage.getTodayPlaytimeMinutes();
    return played < _dailyLimitMinutes;
  }

  int getRemainingMinutes() {
    final played = _storage.getTodayPlaytimeMinutes();
    return (_dailyLimitMinutes - played).clamp(0, _dailyLimitMinutes);
  }

  Future<void> startSession(String storyId) async {
    // Reset state for new session
    state = StoryState.initial().copyWith(storyId: storyId);

    // Load existing progress for resume
    final progress = _storage.getProgress(storyId);
    final resumeSummary = progress?.summary;

    _sessionStartTime = DateTime.now();
    _startTimeLimitTimer();

    await _elevenLabs.startStory(
      storyId: storyId,
      resumeSummary: resumeSummary,
    );

    state = state.copyWith(sessionStatus: StorySessionStatus.active);
  }

  void _startTimeLimitTimer() {
    final remaining = getRemainingMinutes();
    if (remaining <= 0) return;

    _timeLimitTimer?.cancel();
    _timeLimitTimer = Timer(
      Duration(minutes: remaining),
      _onTimeLimitReached,
    );
  }

  void _onTimeLimitReached() {
    saveAndExit(reason: ExitReason.timeLimit);
  }

  // Save Logic
  Future<void> saveAndExit({required ExitReason reason}) async {
    if (_sessionStartTime == null) return;  // No active session

    _timeLimitTimer?.cancel();

    final duration = DateTime.now().difference(_sessionStartTime!);
    await _storage.addPlaytimeMinutes(duration.inMinutes);

    final status = reason == ExitReason.completed
        ? StoryStatus.completed
        : StoryStatus.inProgress;

    final progress = StoryProgress(
      status: status,
      summary: state.lastSummary,
      updatedAt: DateTime.now(),
    );

    await _storage.saveProgress(state.storyId!, progress);
    await _elevenLabs.disconnect();

    _sessionStartTime = null;

    state = state.copyWith(
      sessionStatus: StorySessionStatus.ended,
      exitReason: reason,
    );
  }

  void handleSessionEnded(String summary) {
    state = state.copyWith(lastSummary: summary);
    saveAndExit(reason: ExitReason.completed);
  }

  @override
  void dispose() {
    _timeLimitTimer?.cancel();
    super.dispose();
  }
}

enum ExitReason { completed, userExit, timeLimit, backgrounded }
```

### New StoryState Fields

```dart
class StoryState {
  // ... existing fields ...
  final String? lastSummary;
  final ExitReason? exitReason;
}
```

---

## StoryScreen Changes

- Add `WidgetsBindingObserver` mixin for lifecycle
- Save on `AppLifecycleState.paused`
- Listen for `exitReason` changes
- Show `TimeLimitDialog` when `exitReason == timeLimit`
- Fix double navigation bug: `userExit` handled by `_onWillPop`, skip in `_handleExit`
- Use `PopScope` instead of deprecated `WillPopScope`

---

## HomeScreen Changes

- Load `StoryProgress` for each story on build
- Pass `progress` to `StoryCard` for badge display
- Check playtime on story tap
- Show "Come back tomorrow" dialog if limit exceeded

---

## StoryCard Badge Design

Claymorphism-styled badges matching app theme:

| Status | Label | Background | Border |
|--------|-------|------------|--------|
| `notStarted` | "New" | Warm cream (#FFF0E6) | Orange (accent) |
| `inProgress` | "Continue" | Primary (#F5E6D3) | Brown (secondary) |
| `completed` | "Done!" | Light mint (#E8F5E9) | Forest green |

Uses `AppColors.shadowOuter` for consistent shadows, 20px border radius, Fredoka font.

---

## Settings Screen

- Implement reset confirmation dialog
- Warning icon + clear messaging ("cannot be undone")
- "Keep Progress" as safe default (left)
- "Start Fresh" in red with icon (destructive)
- SnackBar confirmation after reset

---

## Assets Required

| Asset | Used In |
|-------|---------|
| `assets/images/capy_wave.png` | TimeLimitDialog |
| `assets/images/capy_sleep.png` | HomeScreen playtime block |

---

## Edge Cases

| Case | Handling |
|------|----------|
| App force-killed | Progress lost (acceptable) |
| Mid-story exit without summary | Save with null, resume fresh |
| Corrupted storage JSON | Return null, treat as not started |
| Exactly 30 minutes | Block further play |
| Timer precision | ±1 minute tolerance |
| Multiple rapid saves | Guard with `_sessionStartTime == null` |

---

## Testing Focus

| Component | Tests |
|-----------|-------|
| StoryProgress | JSON round-trip, edge cases |
| StorageService | Save/load/clear, day rollover |
| StoryNotifier | Timer, save triggers, state |
| HomeScreen | Playtime block, progress load |
| StoryScreen | Lifecycle, navigation |

---

## Implementation Order

1. `pubspec.yaml` - Add dependency
2. `lib/models/story_progress.dart` - Data model
3. `lib/services/storage_service.dart` - Storage layer
4. `lib/providers/services.dart` - Provider
5. `lib/main.dart` - Async init
6. `lib/providers/story_provider.dart` - Timer + save logic
7. `lib/widgets/story_card.dart` - Badge
8. `lib/screens/home_screen.dart` - Progress + playtime
9. `lib/screens/story_screen.dart` - Lifecycle
10. `lib/widgets/time_limit_dialog.dart` - Dialog
11. `lib/screens/settings_screen.dart` - Reset
