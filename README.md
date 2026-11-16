# Funngro Mobile Engineer Take-Home Assessment

A production-grade, high-performance Flutter solution engineered specifically for hundreds of thousands of teenagers on low-to-mid-range Android smartphones (e.g. ₹8,000 devices with 2GB–3GB RAM).

Built according to the official **Funngro Take-Home PRD**.

---

## 🚀 Quick Start: How to Run

### Prerequisites
* Flutter SDK (3.12+ / 3.44+ compatible)
* Dart SDK 3.12+

### Run the App
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run on connected Android device, emulator, or Windows desktop
flutter run

# 3. Run all unit tests
flutter test
```

### Run Unit Tests Separately
```bash
# Test Part 2: ProjectsController pagination, race conditions & error recovery (7 tests)
flutter test test/projects_controller_test.dart

# Test Part 1: EarningsController virtualization, live streams & deduplication (4 tests)
flutter test test/earnings_controller_test.dart

# App Smoke Test
flutter test test/widget_test.dart
```

---

## 📂 Project Structure

```
funngro_assessment/
├── README.md                           # Project overview, run instructions & test guide
├── pubspec.yaml                        # Dependencies (intl, flutter, flutter_test)
├── docs/
│   ├── part1_review.md                 # Problem list (worst first), mechanics & org guardrails
│   ├── part3_incident.md               # Founder chat message (<120w) & investigation plan
│   ├── assumptions_and_questions.md    # Scored assumptions & questions for Product/Backend
│   └── interview_defense.md            # 10 hard interview Q&As, 3 live-coding variations & script
├── lib/
│   ├── main.dart                       # Entry point: Material 3 home with Earnings & Projects buttons
│   ├── part1_earnings/
│   │   ├── models.dart                 # Immutable Earning model
│   │   ├── fake_earnings_api.dart      # Generates 3,000 items + live walletUpdates periodic stream
│   │   ├── earnings_state.dart         # Sealed state hierarchy (Initial, Loading, Data, Empty, Error)
│   │   ├── earnings_controller.dart    # Manages single subscription, cached NumberFormat, deduplication
│   │   └── earnings_screen.dart        # ListView.builder with itemExtent: 84.0, pull-to-refresh & debug toggle
│   └── part2_projects/
│       ├── projects_api.dart           # Given API: 20/page, pages 0-7, ~900ms delay, 1-in-5 failure
│       ├── projects_state.dart         # Immutable state model (ListStatus, items, loadMoreError, etc.)
│       ├── projects_controller.dart    # Race-safe controller with generation tokens & error recovery
│       └── projects_screen.dart        # Infinite scroll, dynamic footer (spinner/retry/end), pull-to-refresh
└── test/
    ├── widget_test.dart                # App smoke test
    ├── earnings_controller_test.dart   # Tests for 3,000 item generation, live stream, formatters
    └── projects_controller_test.dart   # Tests for all 8 acceptance criteria + scriptable mock API
```

---

## 📋 Deliverables Summary

| Deliverable | Location | Description |
| :--- | :--- | :--- |
| **Part 1 Review** | [docs/part1_review.md](file:///d:/programs/fungro/docs/part1_review.md) | 8 flaws ranked by impact (build side effects, uncancelled streams, eager rendering, 3ms formatCurrency penalty, etc.) + 3–5 sentences on org guardrails. |
| **Part 1 Rewrite** | [lib/part1_earnings/](file:///d:/programs/fungro/lib/part1_earnings/) | Sealed states, `ListView.builder(itemExtent: 84.0)`, single stream subscription cancelled in `dispose()`, cached `NumberFormat`, in-flight tap guard. |
| **Part 2 Projects List** | [lib/part2_projects/](file:///d:/programs/fungro/lib/part2_projects/) | Infinite scroll (F1–F8), inline error retry keeping loaded items intact, race safety via generation tokens, tall screen edge case handling. |
| **Part 3 Incident** | [docs/part3_incident.md](file:///d:/programs/fungro/docs/part3_incident.md) | Chat message to founder (<120 words), 6 prioritized Crashlytics checks, root cause patterns, Remote Config kill-switch strategy. |
| **Part 4 Recording Plan**| [docs/interview_defense.md](file:///d:/programs/fungro/docs/interview_defense.md) | 5-minute timeline, step-by-step cue sheet, and talking points. |
| **Part 5 Assumptions** | [docs/assumptions_and_questions.md](file:///d:/programs/fungro/docs/assumptions_and_questions.md) | Scored assumptions and strategic questions for Product, Backend, and Leadership. |
| **Defend Mode** | [docs/interview_defense.md](file:///d:/programs/fungro/docs/interview_defense.md) | Top 10 tough interview questions with answers + 3 live coding solutions. |

---

## 💡 Assumptions and Questions (Scored Section)

### 1. Should pull-to-refresh keep the old list visible or clear it?
* **Assumption Made:** Pull-to-refresh **keeps the existing list visible** while the refresh indicator spins at the top. Once the fresh page 0 response resolves, the list cleanly updates. If the refresh fails due to a network drop, the existing items remain untouched and the user is notified via snackbar rather than stranded on a blank error screen.
* **Why:** On low-tier Android phones running on 2G/3G or flaky cellular connections, blanking the screen causes jarring white flickers and destroys user trust.
* **Question to Product:** *"In production, should a failed pull-to-refresh retain stale cached data with an offline banner, or should it wipe the view and show an explicit full-screen retry state?"*

### 2. Is page 7 the true end, or does an empty page mark the end?
* **Assumption Made:** We treat **receiving fewer than 20 items or an empty list `[]`** as the definitive indicator that the end has been reached (`hasReachedEnd = true`), rather than hardcoding a magic number `page == 7`.
* **Why:** Hardcoding `page == 7` couples the client tightly to static mock data and breaks if the database pagination size changes. Checking `newItems.length < 20` or empty dynamically adheres to standard REST API contracts.
* **Question to Backend:** *"Can the backend pagination contract provide an explicit `has_more: bool` or `total_count: int` header to eliminate reliance on chunk-size heuristics?"*

### 3. Should failed requests be retried automatically with backoff, or only by user action?
* **Assumption Made:** Failed page requests require **explicit user action (tapping the inline 'Retry' button)** rather than firing automatic background retries with exponential backoff.
* **Why:** On unstable mobile networks, uncontrolled automatic retries rapidly drain device battery, consume metered cellular data, and keep the UI thread busy with repeated network timeouts.
* **Question to Engineering Lead:** *"Does the team prefer an automatic 1-time immediate retry with jitter for transient socket timeouts, followed by the inline user button on a second failure?"*

---

## 🎯 Deterministic Error Testing (Loom Demo Tip)
Both **EarningsScreen** and **ProjectsScreen** feature a **Bug Icon button in the AppBar**.
* Tapping the bug icon toggles `forceFailNext = true`.
* The very next network request is guaranteed to fail deterministically.
* This allows you to effortlessly showcase full-screen retry (page 0) and inline footer retry (mid-list pagination) on camera during your 5-minute Loom recording!

---

## 🧪 Verification & Acceptance Criteria
* [x] **0 analyzer issues**: Passes `flutter analyze` with 0 errors and 0 warnings.
* [x] **12 unit tests passing**: Verifies state transitions, deduplication, stream disposal, and race condition token invalidation.
* [x] **60fps Virtualization**: Fixed `itemExtent: 84.0` enables constant-time $O(1)$ layout calculation for 3,000 items.
* [x] **Lifecycle Safety**: All controllers and stream subscriptions are cancelled in `dispose()`.
