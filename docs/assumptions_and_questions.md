# Assumptions & Strategic Questions (Candidate Scored Section)

In accordance with Section 1 and Section 7 of the Funngro Engineering Assessment PRD, all ambiguities encountered during architecture and implementation were resolved by stating clear engineering assumptions, proceeding cleanly, and documenting the explicit questions that would be addressed to Product, Design, and Backend teams in a production environment.

---

## 1. Part 1: Earnings Screen Assumptions & Questions

### Assumptions Made:
1. **List Virtualization vs. Server Pagination:**
   * *Assumption:* The assessment requirement stipulated showing 3,000 items locally to demonstrate 60fps virtualization on low-end hardware. We assumed the client should load all 3,000 items in the initial fetch and virtualize them via `ListView.builder(itemExtent: 84.0)` rather than requiring an additional paginated API for this specific screen.
2. **Currency and Locale Formatting:**
   * *Assumption:* Funngro operates primarily for Indian teenagers; therefore, currency formatting defaults to Indian Rupee (`₹`, `en_IN`) with zero decimal digits for clean readability (`₹1,250`).
3. **Live Stream Conflict Resolution:**
   * *Assumption:* Live wallet updates arriving via the periodic broadcast stream are prepended to the top of the list, de-duplicated by unique transaction ID (`id`), and visually distinguished with an amber accent to signal real-time credit to the teen.

### Questions for Product & Backend:
* **To Backend:** *"For users with over 5,000 historical transactions, is there a cursor-based pagination endpoint planned for earnings history, or should we implement local SQLite/Isar database caching with background sync?"*
* **To Product/Design:** *"When a live wallet credit arrives while the teen is scrolling lower in their history, should we display a floating pill ('New earning received ↑') or auto-scroll with a subtle highlight animation?"*
* **To Business:** *"Are we expanding Funngro to international teen demographics (e.g., Southeast Asia, MENA) where multi-currency formatting and dynamic exchange rates must be driven by user locale or account currency?"*

---

## 2. Part 2: Projects List with Infinite Scroll Assumptions & Questions

### Assumptions Made:
1. **End-of-List Determination:**
   * *Assumption:* The app treats any response returning fewer than 20 items (or an empty array `[]`) as the definitive end of the list (`hasReachedEnd = true`), rather than hardcoding a magic constant `page == 7`. This adheres to standard REST API contracts where dataset sizes change dynamically.
2. **Pull-to-Refresh UX Policy:**
   * *Assumption:* Pull-to-refresh preserves existing items on screen while the refresh spinner is active at the top. Only upon successful arrival of fresh page 0 data is the list cleanly replaced. This prevents jarring white-screen flickers on slow 2G/3G connections.
3. **Automatic vs. User-Driven Retry:**
   * *Assumption:* Failed pagination requests show an inline "Retry" button rather than executing automatic exponential backoff loops. On flaky cellular networks, automatic retries can rapidly drain battery and trigger repeated network timeouts without the teen's consent.
4. **Tall Viewport Edge Case:**
   * *Assumption:* On modern high-resolution or tablet devices where 20 items might not exceed the viewport height (`maxScrollExtent == 0`), an automated post-frame callback checks scroll extent and triggers the next page to ensure the list is scrollable.

### Questions for Product & Backend:
* **To Product:** *"When a user pulls to refresh, if fresh data cannot be fetched due to network loss, should we keep showing the cached list with a subtle warning banner ('Showing offline data'), or show a full-screen error?"*
* **To Backend:** *"Can we include total item counts or a `next_cursor` / `has_more` boolean in the pagination response envelope to avoid relying solely on chunk-size heuristics?"*
* **To Engineering Lead:** *"Funngro uses `async_redux` internally; for this take-home, a pure Dart controller with `ChangeNotifier` and generation tokens was used to keep abstractions whiteboard-ready. In the on-site round, should we implement this using `async_redux` actions and reducers?"*

---

## 3. Part 3: Production Incident Assumptions & Questions

### Assumptions Made:
1. **Rollout Decision Hierarchy:**
   * *Assumption:* A drop from 99.6% to 98.1% crash-free sessions represents a severe critical regression warranting an immediate freeze of the rollout at 20% to prevent exposing the remaining 80% of active users.
2. **Feature Flag Infrastructure:**
   * *Assumption:* The application utilizes Firebase Remote Config or an internal LaunchDarkly feature flag system capable of pushing updates within 15–30 minutes without client app updates.

### Questions for Leadership & Team:
* **To Founder / Head of Product:** *"What is Funngro's formal SLA for crash-free users (e.g., must stay above 99.5%) that automatically triggers a release halt without manual deliberation?"*
* **To Release Lead:** *"Who holds the authoritative Play Console permissions to halt staged rollouts if the on-call engineer is diagnosing the stack trace?"*
* **To Monetization Team:** *"What is the projected revenue impact of disabling app-resume interstitial ads for 24 hours vs. the estimated customer acquisition cost of replacing churned users?"*
