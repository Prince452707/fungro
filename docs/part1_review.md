# Part 1: Earnings Screen Code Review & Architecture

## 1. Executive Summary & Context
The Earnings screen displays a teen's transaction history on Funngro. A typical user has between 800 and 3,000 entries, accessing the application primarily on low-to-mid-range Android smartphones (such as ₹8,000 devices with 2GB–3GB RAM and modest quad/octa-core MediaTek or Unisoc processors). While the original implementation functioned in a basic local demo, in production it would cause infinite network loops, catastrophic out-of-memory (OOM) crashes, frozen frame rates (severe jank), and ghost transactions.

Below is an impact-ordered breakdown of all eight flaws, prioritized strictly by real-world user damage.

---

## 2. Problem List (Ranked Worst to Least Severe)

### Rank 1: Network Calls and Stream Subscriptions Inside `build()`
* **What the User Experiences:**
  The phone rapidly overheats, consumes battery within minutes, burns through cellular data, and freezes completely with stuttering, duplicate earnings rows flickering across the screen. The backend servers experience a DDoS-like storm of requests.
* **Framework Mechanics:**
  `build()` is intended by the Flutter framework to be a pure, idempotent function with zero side effects. It executes on every `setState`, inherited widget change (e.g., Theme, MediaQuery), keyboard appearance, or parent animation tick. Invoking `fetchEarnings()` inside `build()` completes asynchronously and calls `setState()`, which schedules a re-build, which invokes `fetchEarnings()` again—creating an uncontrollable infinite loop. Simultaneously, every rebuild calls `walletUpdates().listen(...)`, registering a new `StreamSubscription` without discarding the previous ones. A single incoming wallet event then fires dozens or hundreds of duplicate listeners, mutating state exponentially.
* **The Fix:**
  Extract all side effects out of `build()`. Instantiate the controller/state holder once in `initState()` (or via an inherited dependency injection container), trigger the network fetch once, maintain a single stream subscription, and ensure `build()` is strictly a passive projection of immutable state.

---

### Rank 2: Stream Subscription is Never Cancelled
* **What the User Experiences:**
  Over time, navigating in and out of the Earnings screen degrades app performance across other tabs, causes sudden crashes when leaving the screen, and leaks sensitive background data.
* **Framework Mechanics:**
  When a widget is popped off the navigation stack, its `State` object is unmounted and `dispose()` is executed. If a `StreamSubscription` created on that screen is not cancelled, the underlying stream keeps a strong reference to the listener closure. When the stream emits an event in the background, the listener attempts to call `setState()` on a deactivated `State` (`mounted == false`), throwing an unhandled `FlutterError: setState() called after dispose()`. Furthermore, the uncancelled listener retains the entire widget tree, its models, and associated memory, creating a catastrophic memory leak.
* **The Fix:**
  Store the `StreamSubscription<Earning>` as a private member in the controller or State class, and explicitly invoke `_subscription?.cancel()` inside `dispose()`.

---

### Rank 3: Eager List Rendering (`SingleChildScrollView` + `Column` + `.map().toList()`)
* **What the User Experiences:**
  Opening the earnings tab freezes the device for 4 to 8 seconds. Scrolling is virtually impossible due to dropped frames (0–5 fps), and the operating system frequently kills the app with an Out-Of-Memory (OOM) termination on low-RAM devices.
* **Framework Mechanics:**
  `SingleChildScrollView` combined with a `Column` forces the framework to build, lay out, and paint all 3,000 `RenderObject`s immediately on the initial frame, regardless of whether they fit on the screen. Each tile allocates RenderParagraphs, text caches, and paint layers in heap memory. In contrast, Flutter's viewport system supports lazy virtualization: only visible elements plus a small cache buffer are realized.
* **The Fix:**
  Replace the eager column with `ListView.builder` (or `SliverList`). Provide an `itemExtent` (or `prototypeItem`) so the viewport layout engine calculates scroll offsets in $O(1)$ constant time without querying unrendered children.

---

### Rank 4: Locale-Heavy `formatCurrency` Invoked Per Item Inside `build()`
* **What the User Experiences:**
  Continuous UI jank and severe frame drops whenever scrolling or when any minor widget update occurs.
* **Framework Mechanics:**
  `NumberFormat.currency` parses locale configuration tables and pattern symbols. On low-end mobile CPUs, initializing and formatting an individual currency string costs ~2.5ms to 3ms on the Dart UI thread. Multiplying 3ms across 3,000 items inside `build()` totals ~9 seconds of blocking CPU work on the main thread, instantly exceeding the 16.6ms frame budget (60fps) and violating the Android Choreographer frame window.
* **The Fix:**
  Cache a single instance of `NumberFormat.currency(locale: 'en_IN', symbol: '₹')` inside the controller or view-model layer upon initialization, or format the string lazily inside the `itemBuilder` only for viewport-visible tiles.

---

### Rank 5: Absence of Discrete Loading, Error, and Empty States
* **What the User Experiences:**
  The user is greeted with a blank white screen upon opening the app. If a network blip occurs, the screen remains blank indefinitely with zero feedback, leading teens to assume the app is broken and uninstall it.
* **Framework Mechanics:**
  The original code initialized `loading = false`, so the initial frame painted an empty column before the asynchronous call was made. Unhandled asynchronous futures failed silently without a `catchError` or `try/catch` block, swallowing network errors and leaving the UI permanently unpopulated.
* **The Fix:**
  Model UI state as a sealed class hierarchy (`EarningsInitial`, `EarningsLoading`, `EarningsData`, `EarningsEmpty`, `EarningsError`). Force the view to exhaustively handle each state using Dart 3 pattern matching, displaying a spinner on launch, an empty-state illustration when balance is zero, and an actionable "Retry" button on failure.

---

### Rank 6: Race Condition Between Initial Fetch and Live Wallet Stream
* **What the User Experiences:**
  Teens report missing referral earnings or approved gig payouts that flashed for a second and then vanished from their history.
* **Framework Mechanics:**
  The initial HTTP fetch and the WebSocket/stream updates execute concurrently. If a live stream update arrives at $t = 300\text{ms}$ while the main history fetch is still resolving ($t = 650\text{ms}$), the update is prepended to the partial list. When the fetch resolves, its assignment (`earnings = fetchedList`) completely overwrites the array, permanently discarding the live transaction.
* **The Fix:**
  Either defer listening to the live stream until the initial fetch resolves, or buffer incoming live updates in an event queue and merge them using unique item IDs (`ValueKey(id)`) to guarantee deduplication and data integrity.

---

### Rank 7: Unsafe `onTap` Handling, Direct State Mutation, and Double Taps
* **What the User Experiences:**
  Rapidly tapping an earning item opens multiple detail screens stacked on top of each other. If the user navigates back quickly, the app crashes.
* **Framework Mechanics:**
  1. The original code executed `await fetchDetail()` followed by `setState()` and `Navigator.push()` without checking `if (!mounted) return;`. If the user popped the screen before the network call resolved, `context` referenced an unmounted element tree.
  2. Modifying properties directly in place (`e.detail = result`) violates state immutability, creating hidden side effects that bypass Flutter's change detection.
  3. Lack of an in-flight guard allowed concurrent taps to fire duplicate requests.
* **The Fix:**
  Add an `_isFetchingDetail` guard flag to drop duplicate taps, verify `if (!mounted) return;` after every `await`, present clear user feedback (snackbars), and use immutable `copyWith` semantics.

---

### Rank 8: Sub-Optimal Code Hygiene, Keys, and Accessibility
* **What the User Experiences:**
  Subtle UI glitches when lists re-order, sluggish accessibility services (TalkBack/ScreenReader), and general codebase fragility.
* **Framework Mechanics:**
  Mutating lists in place via `.insert(0, ...)` mutates object references without triggering immutable diffing. Omitting `ValueKey` on dynamic list items forces Flutter to reconcile widgets purely by index, leading to incorrect state retention when items shift. Missing `const` constructors prevents the framework from short-circuiting element rebuilds.
* **The Fix:**
  Return new list instances on updates (`[newEarning, ...currentItems]`), apply `ValueKey(earning.id)` to each tile, apply `const` to invariant subtrees, and ensure proper `Semantics` tags.

---

## 3. Organizational Guardrails (3 to 5 Sentences)
To prevent these performance regressions across a growing engineering team, we enforce a strict custom lint ruleset (via `custom_lint` and `flutter_lints`) in CI that bans asynchronous dispatches and stream subscriptions inside `Widget.build()`. All screen implementations must extend a standardized controller architecture featuring exhaustive compile-time sealed states (`Loading`, `Data`, `Empty`, `Error`) and mandatory `dispose()` registration for streams and controllers. Any collection rendering dynamically must utilize a virtualized builder (`ListView.builder` or Slivers) accompanied by automated frame-budget smoke tests run on low-end Android emulators during pull request review. Finally, all locale-sensitive formatters (currency, dates) are centralized as singletons within a shared domain utility package to eliminate main-thread CPU overhead.
