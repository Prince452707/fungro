# Scored Assumptions & Questions

> **Scoring Note**: The assessment guidelines explicitly state:
> *"Where something is ambiguous, state the assumption, proceed, and note the question that would have been asked. This is scored."*

---

## 1. Refresh Behavior: Keep Old List Visible vs. Wipe to Blank Screen

### Assumption Made
When pull-to-refresh is triggered, we **retain the existing list of loaded items on screen** with the native refresh indicator spinning at the top. Once the fresh page 0 response succeeds, the list updates smoothly. If the refresh request fails due to a network drop, the existing items remain visible and the error is communicated via a transient floating notification or snackbar.

### Why
On budget ₹8,000 Android phones operating on flaky 2G/3G or throttled cellular networks, blanking the screen leaves the user staring at an empty white page or full-screen error state. Retaining cached data preserves user trust and perceived speed.

### Questions for Product & Backend
* **To Product**: *"If pull-to-refresh fails while offline, should we display an unobtrusive top banner (e.g. 'Offline • Showing saved projects') rather than leaving the user uncertain whether the data refreshed?"*
* **To Backend**: *"Can the refresh endpoint support `If-Modified-Since` or `ETag` headers so the mobile client doesn't re-download 20 identical projects if nothing has changed?"*

---

## 2. End-of-List Heuristic: Page 7 Limit vs. Chunk Size Heuristic

### Assumption Made
Rather than hardcoding `page == 7` in client UI logic, we treat **receiving fewer than 20 items or an empty list `[]`** as the definitive end-of-list signal (`hasReachedEnd = true`).

### Why
Hardcoding magic numbers like `page == 7` tightly couples the client to a static mock dataset. If the backend team adjusts pagination size from 20 to 50, or if total projects grow from 160 to 500, a hardcoded client check silently fails or prevents users from accessing fresh projects.

### Questions for Backend Team
* **To Backend**: *"Can the pagination contract provide an explicit envelope containing `total_count: int` and `has_more: bool` (e.g. `{ 'data': [...], 'meta': { 'has_more': true, 'total': 160 } }`) so the mobile app doesn't have to rely on page chunk heuristics?"*

---

## 3. Error Recovery: User-Triggered Inline Retry vs. Automatic Exponential Backoff

### Assumption Made
When a mid-list pagination page fails (e.g. 1 in 5 failure rate from `ProjectsApi`), we display a dedicated **inline footer retry row** that preserves all loaded items and waits for an **explicit user tap**. We do not fire automatic background retries in a tight loop.

### Why
On unstable mobile connections (e.g. traveling in public transit), automatic retries quickly burn battery life, consume metered data limits, and trigger network congestion. Explicit user retry gives the teen control and clear feedback.

### Questions for Engineering Lead
* **To Tech Lead**: *"Would the team prefer a hybrid pattern: 1 automatic immediate retry with jitter for transient socket timeouts, followed by the inline user button if the retry also fails?"*

---

## 4. Race Conditions on Fast Search & Pull-to-Refresh

### Assumption Made
We implemented a monotonic integer `generationToken` counter in `ProjectsController`. Every time a user initiates `refresh()` or resets the list, the token increments. When asynchronous HTTP futures return, responses matching outdated generation tokens are silently discarded.

### Why
If a user is on page 3, scrolls (dispatching page 4), and immediately pulls down to refresh (dispatching page 0), a slow network might return page 4 *after* page 0 has already rendered. Without generation tokens, page 4 items would erroneously append to the refreshed list, corrupting list ordering.

### Questions for Senior Architect
* **To Architect**: *"Do we have an established standard in the app (e.g. CancelableOperation from `async` package, RxDart `switchMap`, or generation tokens) for in-flight request cancellation that our team standardizes on?"*
