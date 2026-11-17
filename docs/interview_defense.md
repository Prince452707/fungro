# Interview Defense & Walkthrough Guide (Part 4)

## 1. 5-Minute Screen Recording Cue Sheet (Unedited Loom Video)

> **Time Cap**: 5 minutes maximum.
> **Format**: Loom or phone camera pointed at device screen. Talk naturally like a colleague.

```
00:00 - 00:45 | Intro & Part 2 Projects List Live Walkthrough
               - Open app on device or emulator.
               - Navigate to Projects tab.
               - Show first-load spinner resolving to Page 0 (20 items).
               - Scroll down to trigger Page 1 (items count updates from 20 -> 40 -> 60).

00:45 - 01:45 | Demo Error & Inline Retry Path (Scored Requirement)
               - Tap the Bug Icon in the AppBar (sets forceFailNext = true).
               - Scroll down: show that the network error triggers the inline footer row.
               - Highlight that already-loaded items are NOT wiped from the screen.
               - Tap "Retry" button: watch the exact failed page load successfully and append.
               - Scroll to Page 7 / 8 to show the visually distinct "End of List" banner.

01:45 - 02:45 | Pull-to-Refresh & Race Safety
               - Pull down from the top to trigger Refresh.
               - Explain the `generationToken` counter: if an older page was in flight when refresh
                 was triggered, its response is silently dropped so stale items never contaminate page 0.

02:45 - 03:45 | Part 1 Worst Bug & Ranking Rationale
               - Jump to Earnings tab (shows 3,000 items scrolling at a smooth 60fps).
               - Name the #1 worst bug: `fetchEarnings()` and `walletUpdates().listen()` inside `build()`.
               - Explain why: `setState()` inside `build()` triggers an infinite recursive rebuild loop,
                 spawning hundreds of HTTP requests/second, locking the main thread, and causing an immediate ANR/OOM crash.

03:45 - 04:30 | Frame Rate & Memory Protections on Cheap Hardware
               - Mention `itemExtent: 84.0` in `ListView.builder` for O(1) scroll layout.
               - Mention cached `NumberFormat` eliminating repeated 3ms locale parsing per item.
               - Show the live wallet stream prepending bonuses safely with de-duplication.

04:30 - 05:00 | Ambiguity & Question I Would Ask the Funngro Team
               - "One ambiguity I noted: should a failed pull-to-refresh keep the existing list visible
                 or wipe to a blank retry screen? I assumed keeping data visible protects trust on 3G networks.
                 I'd love to ask the product team their preference on offline indicators."
               - Wrap up with thanks.
```

---

## 2. Top 10 Tough Interview Questions & Direct Answers

### 1. "Why did you use ChangeNotifier and ListenableBuilder instead of Bloc or Riverpod?"
> **Answer**: The PRD explicitly stated: *"Keep the code small and readable. No extra packages unless listed. No clever abstractions the candidate could not rewrite on a whiteboard."* `ChangeNotifier` with `ListenableBuilder` is built directly into Flutter's core framework (`flutter/foundation.dart`). It has zero external dependencies, minimal memory overhead, and decouples business logic from the UI cleanly. In a production app using `async_redux` or `bloc`, this exact state machine maps 1:1 to Actions or Events.

### 2. "How does `itemExtent: 84.0` prevent layout thrashing on low-RAM devices?"
> **Answer**: In a default `ListView.builder`, Flutter must perform layout passes to measure each item's actual rendered height before it knows where the next item starts. With `itemExtent: 84.0`, Flutter skips layout measurement entirely. Scroll offset calculations are constant time $O(1)$: item at index $n$ is at exactly $n \times 84.0\text{ px}$. This prevents frame drops during fast fling gestures on budget GPUs.

### 3. "What happens if a user pulls to refresh while page 3 is still loading?"
> **Answer**: In `ProjectsController`, every `refresh()` increments `_generationToken`. If page 3 was in-flight with token 1, and refresh sets the token to 2, when page 3's Future returns, it checks `if (token != _generationToken) return;`. It silently discards the stale page 3 data, ensuring only fresh page 0 data is displayed.

### 4. "Why is `SingleChildScrollView + Column` an anti-pattern for large lists?"
> **Answer**: `SingleChildScrollView` does not implement viewport virtualization. It gives infinite vertical space to its child, so `Column` instantiates every single child widget, element, and RenderObject in memory at once. For 3,000 items, that means ~10,000 live objects consuming 80MB+ RAM. `ListView.builder` only instantiates widgets currently visible on screen (~10 items).

### 5. "Why did you cache `NumberFormat`?"
> **Answer**: Instantiating `NumberFormat.currency(locale: 'en_IN')` synchronously loads and parses locale data tables. In the prompt's original code, it was called for every row on every build (~3ms per item). For 3,000 items, that would block the UI thread for 9 full seconds. By creating a single static/final instance in the controller, formatting is practically instantaneous.

### 6. "How do you handle rapid double-taps on project or earning items?"
> **Answer**: We use an in-flight boolean flag (`isFetchingDetail`). If a user taps twice within 100ms, the second tap is ignored until the first call completes. Additionally, we check `if (!mounted) return;` immediately after the async gap before touching context or state.

### 7. "How do you detect the end of the list without hardcoding page 7?"
> **Answer**: `ProjectsApi` returns 20 items per page. When a page returns fewer than 20 items (`items.length < 20`) or an empty list `[]`, `hasReachedEnd` is set to `true`. This relies on standard REST chunk size conventions rather than hardcoding static mock boundaries.

### 8. "Why did you keep loaded items visible when a page fails?"
> **Answer**: If a user has scrolled down to page 4 (80 items) and page 5 fails due to a network glitch, replacing the screen with a full-screen error destroys the user's progress and orientation. Retaining the 80 items and rendering an inline retry button at the bottom allows the user to simply tap "Retry" and continue uninterrupted.

### 9. "What if the screen is tall (e.g. tablet) and 20 items don't fill the screen to trigger scroll?"
> **Answer**: In `initState()`, we register a post-frame callback (`WidgetsBinding.instance.addPostFrameCallback`). If `scrollController.position.maxScrollExtent == 0`, the viewport is not yet scrollable, so it automatically triggers `loadMore()` until content exceeds the viewport height.

### 10. "How do you test stream cancellation in unit tests?"
> **Answer**: We create a `ScriptableEarningsApi` with a `StreamController.broadcast()`. When `controller.dispose()` is called, our test verifies that emitting new events on the stream controller no longer updates controller state, proving the subscription was cancelled.

---

## 3. Live-Coding Variations (Be Ready on the Whiteboard)

### Variation A: Add Local Search/Filter to Loaded Projects
```dart
// Filter loaded projects without triggering network calls:
final filtered = _searchQuery.isEmpty 
    ? state.items 
    : state.items.where((p) => 
        p.title.toLowerCase().contains(_searchQuery) ||
        p.company.toLowerCase().contains(_searchQuery)).toList();
```

### Variation B: Convert to ValueNotifier
```dart
class ProjectsNotifier extends ValueNotifier<ProjectsState> {
  ProjectsNotifier(this._api) : super(const ProjectsState());
  // Call `value = value.copyWith(...)` instead of `notifyListeners()`
}
```

### Variation C: Add Pull-to-Refresh on Earnings
```dart
Future<void> refreshEarnings() async {
  final fresh = await _api.fetchEarnings();
  _state = EarningsData(fresh);
  notifyListeners();
}
```
