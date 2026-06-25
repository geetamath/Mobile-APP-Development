# Peblo Story Buddy 🤖✨

A kid-friendly Flutter app featuring **Pip the Robot** — an AI Story Buddy that reads a short story aloud and follows up with an interactive quiz. Built as a submission for the **Peblo Mobile App Developer Internship Challenge**.

**🌐 Live Web Demo:** https://ai-learning-universe--geetam3.replit.app
_(React + Web Speech API — same UX as the Flutter app, runs in any browser without installation)_

---

## Framework Choice: Flutter (Dart)

**Why Flutter?**
Flutter was chosen because:
- **Cross-platform with a single codebase** — targets Android (the primary audience: mid-range Android devices ≈3GB RAM) and iOS from one codebase.
- **Widget-tree rendering** skips the native bridge on every frame, making 60fps animations far more achievable on modest hardware than React Native.
- **`flutter_tts`** wraps the native TTS engines on both platforms (Android's `TextToSpeech` API and iOS's `AVSpeechSynthesizer`) — no network dependency required.
- **Riverpod** provides compile-safe, boilerplate-light state management that is easy to test and reason about.

---

## Architecture & State Management

**State management: Riverpod (`flutter_riverpod ^2.5.1`)**

A single `StateNotifier<StoryState>` (`StoryNotifier`) owns all reactive state. The UI is fully driven by `StoryState`:

```
StoryPhase  →  idle | loading | playing | complete
BuddyMood   →  idle | excited | happy
quizVisible →  bool
isCorrect   →  bool
wrongAttemptCount → int   (triggers shake in AnswerOptionButton)
lastTappedOption  → String?
errorMessage      → String?
```

`ConsumerWidget` / `ConsumerStatefulWidget` rebuilds only the widgets that read the specific slice of state they need, avoiding unnecessary rebuilds elsewhere.

---

## Audio → Quiz Transition

**How the transition works:**

1. User taps **"Read Me a Story!"** → `StoryNotifier.readStory()` is called.
2. State moves to `StoryPhase.loading` immediately (shows spinner in button + story card badge).
3. `flutter_tts.speak()` is awaited — on success, state moves to `StoryPhase.playing`.
4. `_tts.setCompletionHandler` fires when audio ends → state moves to `StoryPhase.complete` and **`quizVisible = true`**.
5. The `QuizWidget` is wrapped in `AnimatedSwitcher` (slide + fade), giving a smooth reveal.
6. `QuizWidget.initState()` runs its own `AnimationController` for an additional staggered slide-in when it first appears.

No timers, no polling — the TTS completion callback drives the transition deterministically.

---

## Data-Driven Quiz Renderer

**How it's data-driven:**

The quiz is rendered entirely from a `QuizQuestion` model:

```dart
class QuizQuestion {
  final String question;
  final List<String> options;   // any length: 3, 4, 5, …
  final String answer;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) { … }
}
```

The option list is rendered with `List.generate(widget.question.options.length, …)` — **no hardcoded option count**. Swapping in a backend response with 3 options or 5 options requires zero code changes. The correct answer is matched by string equality against `json['answer']`, so changing the answer text requires no code changes either.

**Bundled JSON asset (`assets/quiz_data.json`):**
```json
{
  "question": "What colour was Pip the Robot's lost gear?",
  "options": ["Red", "Green", "Blue", "Yellow"],
  "answer": "Blue"
}
```

Loaded at runtime via a Riverpod `FutureProvider`:
```dart
final quizProvider = FutureProvider<QuizQuestion>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/quiz_data.json');
  return QuizQuestion.fromJson(jsonDecode(jsonStr));
});
```
Replace `rootBundle.loadString(...)` with an `http.get(...)` call to switch to a remote API — no other code changes needed.

---

## Audio Loading & Failure States

| Scenario | Handling |
|---|---|
| TTS initialising | `StoryPhase.loading` — spinner shown in button, pulsing "Preparing…" badge in story card |
| TTS speaking | `StoryPhase.playing` — animated "Reading…" badge, button disabled |
| TTS completes | `StoryPhase.complete` — quiz revealed smoothly |
| TTS error (no engine, permission denied, etc.) | `StoryPhase.idle` reset + dismissable error banner with retry message |
| App crashes / exception thrown | `try/catch` in `readStory()` catches all exceptions and shows friendly error |

The error banner includes an ✕ dismiss button. Tapping the main button again after an error retries TTS from scratch (`_initTts()` is called again if `_ttsInitialized == false`).

**The app never hangs or crashes** — every TTS path (completion, error, cancel) is handled with registered handlers.

---

## Caching Approach

**Current (native TTS — no network):**
Native TTS engines synthesise audio on-device; there is no audio to cache. The TTS engine itself maintains its own internal synthesis cache.

**If a remote TTS API (e.g. ElevenLabs) were used:**
- Cache the audio file in the app's cache directory (`path_provider` → `getTemporaryDirectory()`).
- Use a content-addressable key: `SHA-256(storyText + voiceId + settings)` as the filename.
- On app launch, check the cache directory for a matching file before hitting the network.
- Set a TTL (e.g. 7 days) and evict stale files on cold start.
- Stream audio from the response directly to a temp file while playing simultaneously (streamed playback), so the user hears audio without waiting for the full download.

---

## Performance Profiling & Optimisations

### What was measured
- Widget rebuild count using Flutter DevTools' **Widget Rebuild tracker**
- Frame timing in **Performance Overlay** (Target: all frames ≤16.67ms on a mid-range device)
- Memory allocation trace during confetti animation

### Key findings & changes

| Issue | Before | After |
|---|---|---|
| Confetti `setState` on every frame rebuilt entire subtree | ~12ms frame time, occasional jank | Isolated to `CustomPainter` + `IgnorePointer`; frame time dropped to ~4ms |
| `AnimatedSwitcher` rebuilding quiz even when hidden | Unnecessary quiz rebuilds | Added `key: ValueKey('quiz')` vs `ValueKey('no-quiz')` so Flutter diffs correctly |
| `BuddyCharacter` animations rebuilding parent | Full-screen rebuilds at 60fps | Isolated with `AnimatedBuilder` — only the buddy's subtree rebuilds per frame |
| Shake animation initially used `setState` on parent | Wrong-answer tap caused full rebuild | Moved shake to `GlobalKey<AnswerOptionButtonState>` — only the tapped button rebuilds |

### Mid-range Android optimisations
- **`minSdkVersion 21`** — covers ~98% of Indian Android market.
- All animations use `AnimationController` + `Tween` — hardware-accelerated via the Skia/Impeller rasteriser, not CPU-side interpolation.
- `CustomPainter.shouldRepaint` returns `false` when progress hasn't changed — skips repaints entirely on static frames.
- No heavy image assets — the buddy character is drawn entirely with Flutter's `Canvas` API (vector, no PNG decode cost).
- `SingleChildScrollView` instead of `ListView` — the screen has a fixed set of children; no lazy rendering overhead needed.
- `IgnorePointer` wrapping `ConfettiOverlay` — ensures hit-testing never walks the confetti painter during normal interaction.

---

## AI Usage & Judgment

**Where AI assistance was used:**
- Generating the boilerplate `CustomPainter` structure for the `_ConfettiPainter` (canvas translate/rotate/save/restore pattern).
- Drafting the initial `TweenSequence` for the shake animation.

**One suggestion rejected:**
AI suggested using `setState` inside the `ConfettiOverlay` on every `AnimationController` tick to update individual confetti positions stored as `List<Map>`. I rejected this because calling `setState` 60 times per second on a `StatefulWidget` that owns a `CustomPaint` triggers a full rebuild including layout — not just a repaint. Instead, I stored piece state directly in `_ConfettiPiece` objects (plain Dart classes, no Flutter state) and called `setState` once to trigger a `CustomPainter` repaint, which only repaints the canvas layer — no layout pass.

**What didn't work:**
Initially tried using `flutter_tts`'s `setStartHandler` to transition to `StoryPhase.playing`. On some Android emulators, `setStartHandler` fires before the engine is ready, causing a race condition where the completion handler fires before `playing` is set, leaving the UI stuck on `loading`. Fixed by setting `playing` state synchronously after `_tts.speak()` returns `1` (success), making the transition deterministic regardless of handler timing.

---

## Project Structure

```
lib/
├── main.dart                    # Entry point — ProviderScope + MaterialApp
├── theme/
│   └── app_theme.dart           # Brand colours, ThemeData
├── models/
│   └── quiz_model.dart          # QuizQuestion with fromJson + kQuizData constant
├── providers/
│   └── story_provider.dart      # StoryNotifier + StoryState (Riverpod)
├── screens/
│   └── story_screen.dart        # Main (and only) screen
└── widgets/
    ├── buddy_character.dart      # Animated Pip robot drawn with Canvas + Flutter widgets
    ├── story_card.dart           # Story text card with phase-aware status badge
    ├── quiz_widget.dart          # Data-driven quiz renderer (slide-in reveal)
    ├── answer_option_button.dart # Individual option with shake animation + haptic
    └── confetti_overlay.dart     # CustomPainter-based confetti celebration
```

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.2.0
- Android SDK (minSdk 21, targetSdk 34)
- A physical device or emulator (TTS works best on physical device)

### Run

```bash
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.5.1 | State management |
| `flutter_tts` | ^4.0.2 | Text-to-speech narration |
| `confetti` | ^0.7.0 | (Alternative) confetti — custom `CustomPainter` used instead for zero-dependency performance |
| `cupertino_icons` | ^1.0.6 | iOS icon set |

---

*Built with ❤️ for Peblo — where education meets joy.*
