# Interview Defense Guide & Live Coding Playbook

This document is your preparation shield for the Funngro on-site interview round. It covers the **5-minute screen recording script**, the **10 tough architectural questions** interviewers will ask about this exact code, and the **3 most likely live-coding extensions** with complete solutions.

---

## 1. Five-Minute Screen Recording Script & Cue Sheet

| Timestamp | Screen / Visual | Spoken Script (Conversational & Confident) |
| :--- | :--- | :--- |
| **0:00 – 0:30** | App Home Screen | *"Hi team, I'm presenting my submission for the Funngro Mobile Engineer assessment. Today I'll demonstrate two key pieces: our resilient paginated Projects list and our virtualized Earnings screen optimized for 3,000 items on low-end hardware, followed by a breakdown of the critical architectural decisions."* |
| **0:30 – 1:30** | Tap **Projects List** -> Smooth Infinite Scroll | *"Here on the Projects screen, notice the clean initial loading state followed by the first 20 items. As I scroll near the bottom—within 200 pixels—the scroll controller seamlessly requests the next page. Notice the subtle bottom loading indicator. We load page after page smoothly all the way to 160 items across pages 0 through 7."* |
| **1:30 – 2:10** | Tap AppBar **Bug Icon** (Deterministic Error Injection) | *"Now let's test our error recovery. I built a deterministic debug toggle right here in the AppBar. I'll toggle it on and scroll. Notice that when page 3 fails, the 40 already-loaded items remain completely visible and untouched! We display an inline retry row with clear feedback. Tapping 'Retry' loads the exact same page 3 without skipping items or duplicating data."* |
| **2:10 – 2:30** | Scroll to End -> Pull to Refresh | *"Once we reach the 160th item, you see the distinct 'You've reached the end' footer, and further scroll attempts are strictly guarded. Pulling to refresh cleanly resets to page 0 without white-screen flickering, using our generation token to discard any stale in-flight responses."* |
| **2:30 – 4:00** | Switch to **Earnings Screen** -> Explain Part 1 | *"Turning to Part 1: the original Earnings code had 8 major bugs, but the single worst bug was executing network calls and stream subscriptions directly inside `build()`. `build()` in Flutter must be a pure function. Putting async calls there triggers an infinite loop: fetch -> setState -> build -> fetch. Worse, each rebuild attached a new `walletUpdates` listener, multiplying memory leaks and backend load. In our rewrite, state logic lives in a controller created once in `initState()`, the stream subscription is cancelled in `dispose()`, and we use `ListView.builder` with `itemExtent: 84` to render 3,000 items at a locked 60 frames per second on an ₹8,000 device."* |
| **4:00 – 5:00** | Questions & Trade-offs | *"One deliberate trade-off I made was in pull-to-refresh: I opted to keep previously loaded items visible while the refresh indicator spins, rather than wiping the screen. If network drops mid-refresh, the user still sees their data. I'd love to ask the product team whether they prefer this graceful fallback or an explicit error state. Thank you!"* |

---

## 2. Top 10 Hard Interview Questions & Model Answers

### Q1: Why did you use `generationToken` in `ProjectsController` instead of a simple boolean flag?
* **Model Answer:**
  *"A boolean flag like `isLoading` only guards against duplicate calls in one direction. It does not solve race conditions during pull-to-refresh. If a user triggers a refresh while page 2 is in-flight, both requests are running concurrently. If page 2 resolves after page 0, a boolean flag wouldn't know which response is newer, resulting in old page 2 data being appended to the fresh page 0 list. The generation token is an integer incremented on every refresh; any response returning with an older token is immediately dropped."*

### Q2: Why is `itemExtent: 84.0` critical on a ₹8,000 Android device?
* **Model Answer:**
  *"Without `itemExtent`, Flutter's `RenderViewport` must perform layout passes on rendered tiles to discover their heights and compute scroll offsets. When scrolling rapidly through 3,000 items, calculating dynamic heights causes layout recalculations on the UI thread. By providing a fixed `itemExtent: 84.0`, the scroll physics engine computes offsets in $O(1)$ constant time with simple math (`index * 84`), completely eliminating layout thrashing."*

### Q3: Why is `NumberFormat.currency` kept in the controller rather than instantiated inside `itemBuilder`?
* **Model Answer:**
  *"Instantiating `NumberFormat` parses locale tables, currency symbols, and grouping rules from the intl locale cache, which costs ~2.5ms to 3ms per invocation on low-tier mobile processors. Doing that for every visible tile on scroll easily blows the 16.6ms frame budget. By instantiating it once as a final field in the controller, formatting is reduced to a fast string lookup taking under 0.05ms."*

### Q4: In `EarningsController`, what prevents a memory leak if the user leaves the screen while `fetchEarnings` is in flight?
* **Model Answer:**
  *"First, the controller's `_walletSubscription` is explicitly cancelled in `dispose()`. Second, `EarningsController` does not hold a reference to `BuildContext`. Third, the UI listens via `ListenableBuilder`, which removes its listener when the widget is unmounted. Even if an async future finishes after `dispose()`, calling `notifyListeners()` is guarded or safe because no unmounted widget attempts to invoke `setState()`."*

### Q5: How did you handle the edge case where 20 items do not fill a tall screen or tablet?
* **Model Answer:**
  *"If 20 items fit completely within the viewport on a high-DPI or tablet screen, `maxScrollExtent` remains `0`, so the user cannot scroll to trigger the next page. We handle this in `initState` via `WidgetsBinding.instance.addPostFrameCallback`: once the first frame renders, we inspect if `maxScrollExtent == 0` and `hasReachedEnd == false`. If so, we trigger `loadMore()` immediately until the viewport is scrollable."*

### Q6: Why did you pick `ListView.builder` over `SingleChildScrollView + Column`?
* **Model Answer:**
  *"`SingleChildScrollView + Column` creates and retains the entire element and render tree for all 3,000 items in memory simultaneously, consuming over 150MB of RAM and causing seconds of startup lag. `ListView.builder` virtualizes the list: it only builds elements and RenderBoxes for the 10–12 items currently in the viewport plus a small cache extent, recycling elements as the user scrolls."*

### Q7: Why is `ValueKey(earning.id)` needed on each tile?
* **Model Answer:**
  *"When a real-time wallet credit is prepended to the top of the list, all existing tile indices shift by +1. Without keys, Flutter identifies widgets by position, causing it to match the old tile's Element state to the wrong data. Providing a unique `ValueKey(earning.id)` allows Flutter's element reconciliation algorithm to preserve identity, avoid unnecessary re-paints, and run clean insertion animations."*

### Q8: What happens if `walletUpdates()` emits an item that already exists in the list?
* **Model Answer:**
  *"In `EarningsController._subscribeToWalletUpdates()`, we check `currentItems.any((e) => e.id == newEarning.id)`. If the transaction ID is already present, the update is discarded. This prevents duplicate entries if the stream reconnects or re-emits historical transactions."*

### Q9: Why did you choose `ChangeNotifier` / `ListenableBuilder` over third-party packages like Bloc or Riverpod for this submission?
* **Model Answer:**
  *"The PRD explicitly prioritized clean, readable code that can be defended and rewritten on a whiteboard without heavy abstractions. `ChangeNotifier` with immutable states and `ListenableBuilder` is built directly into the Flutter SDK, requires zero third-party boilerplate, enforces unidirectional data flow (UI intent -> Controller API call -> State update -> UI render), and is easily transferable to `async_redux`."*

### Q10: How would you scale this architecture to support offline-first persistence?
* **Model Answer:**
  *"I would introduce a repository layer between the controller and the API backed by an SQLite (Drift) or Isar database. The controller would observe a reactive local query (`watchProjects()`). On screen open, the UI immediately displays cached local data. The repository triggers a background network sync, updates the local DB within a transaction, and the database stream automatically emits the updated list to the controller."*

---

## 3. Live-Coding Variations & Ready Solutions

In the on-site round, interviewers typically ask you to modify the running code live. Here are the three most probable exercises:

### Variation 1: Add a Search/Filter Box to the Projects List
**Requirement:** Add a search field in the AppBar that filters projects by company name in real time without making new network calls.

```dart
// Step 1: In ProjectsController, add a filter query:
String _searchQuery = '';
String get searchQuery => _searchQuery;

void updateSearchQuery(String query) {
  _searchQuery = query.toLowerCase();
  notifyListeners();
}

List<Project> get filteredItems {
  if (_searchQuery.isEmpty) return _state.items;
  return _state.items
      .where((p) =>
          p.title.toLowerCase().contains(_searchQuery) ||
          p.company.toLowerCase().contains(_searchQuery))
      .toList();
}

// Step 2: In ProjectsScreen, replace state.items with _controller.filteredItems!
```

### Variation 2: Add Pull-to-Refresh to the Earnings Screen
*(Already fully implemented in our `EarningsScreen`!)*
```dart
RefreshIndicator(
  onRefresh: () => _controller.refresh(),
  child: ListView.builder(
    itemExtent: 84.0,
    itemCount: items.length,
    itemBuilder: (context, index) => _EarningListTile(...),
  ),
)
```

### Variation 3: Change Page Size from 20 to 10 Dynamically
**Requirement:** Allow the client to pass a `pageSize` parameter to `ProjectsApi.fetchProjects(int page, {int pageSize = 10})`.

```dart
// In ProjectsApi:
Future<List<Project>> fetchProjects(int page, {int pageSize = 20}) async {
  ...
  final startId = page * pageSize;
  return List.generate(pageSize, (index) {
    final idNum = startId + index;
    ...
  });
}

// In ProjectsController:
final int pageSize = 10;
final reachedEnd = items.length < pageSize;
```
