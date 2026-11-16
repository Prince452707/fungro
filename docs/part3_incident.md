# Part 3: Production Incident Response & Investigation Plan

## Scenario Overview
* **Release:** v6.4.0 at 20% staged rollout on Google Play.
* **Crash:** `PlatformException` originating from the third-party Ad SDK during app resume (`AppLifecycleState.resumed`).
* **Metric Degradation:** Crash-free users dropped from **99.6% to 98.1%** in the 20% rollout cohort (~1.5% drop = 15 extra crash victims per 1,000 active users).
* **Context:** The Ad SDK version itself was **not** bumped in this release. Ad monetization represents a critical revenue stream for Funngro.

---

## Deliverable A: Chat Message to Founder (Slack/WhatsApp)

> **Hi [Founder Name],**  
> **Short answer:** I recommend we **pause rollout expansion at 20% immediately** (not a full rollback yet) while we inspect device logs, with a final go/no-go call by **2:30 PM today**.  
>  
> In the 20% test cohort, crash-free users dropped from 99.6% to 98.1%—that is roughly 15 additional users crashing out of every 1,000 on app resume. Because the ad SDK itself didn’t change in 6.4.0, an underlying lifecycle change or memory kill is likely passing a null Activity on resume.  
>  
> Existing users on 6.3 remain completely safe. I’m isolating the affected Android versions and testing a remote kill-switch for resume ads now.  
>  
> **Next update at 1:30 PM sharp.**

---

### Candidate Fill-In Guide (Customize Before Sending):
1. **[Founder Name]:** Replace with actual founder name (e.g., Aniketh / Payal).
2. **[2:30 PM today] & [1:30 PM sharp]:** Set to concrete local times (~1 hour and ~2 hours from detection).
3. **Rollout percentage:** Confirmed at 20% staged release.
4. **Crash rate drop:** $99.6\% - 98.1\% = 1.5\%$ (15 users per 1,000 active sessions).

---

## Deliverable B: Investigation Plan & Decision Framework

### 1. First 6 Checks in Crashlytics (Strict Priority Order)
1. **Version Comparison Verification:**
   * Confirm the crash signature (`PlatformException` in Ad SDK on resume) is strictly isolated to v6.4.0 and at zero baseline in v6.3.x.
2. **User Concentration & Crash-Loop Factor:**
   * Evaluate `Events / Users` ratio. Is this 150 crashes across 10 users caught in a boot/resume loop, or 150 unique users crashing once? A repeating crash loop on resume completely breaks app utility and forces an emergency halt.
3. **De-obfuscated Stack Trace & Exception Code Analysis:**
   * Inspect the exact `PlatformException` code and details (e.g., `ACTIVITY_NOT_FOUND`, `ILLEGAL_STATE`, `NullPointerException` on `adView.resume()`, or `METHOD_NOT_IMPLEMENTED`).
4. **Breadcrumbs and Temporal State:**
   * Read preceding user actions. Was the app placed in the background for >5 minutes (triggering low-memory OS process reclamation)? Did an interstitial ad open before the user switched apps?
5. **Hardware & OS Clustering:**
   * Filter crash incidence by:
     * Android OS version (e.g., Android 14/15 strict background execution limits).
     * Device RAM ($<3\text{GB}$ devices vs flagship).
     * OEM distribution (e.g., Xiaomi MIUI, Samsung OneUI with aggressive task killers).
6. **Fatal vs. Non-Fatal Impact:**
   * Confirm whether the unhandled exception terminates the OS process (fatal crash) or triggers an unhandled Flutter error dialog that freezes the render tree.

---

### 2. Patterns & Root Cause Hypotheses
Since the Ad SDK was not bumped, the regression is caused by an environmental interaction introduced in v6.4.0:
* **Flutter Engine / Android Lifecycle Hook Changes:**
  * Changes in `MainActivity.kt` (e.g., migration to FlutterActivity with custom `onPostResume` or window focus overrides).
* **Transitive Dependency Resolution Drift:**
  * Even if the ad SDK artifact version was pinned, one of its underlying Google Play Services or AndroidX dependencies (e.g., `play-services-ads-identifier` or `lifecycle-runtime`) bumped via Gradle range resolution.
* **ProGuard / R8 Obfuscation & Shrinking Rules:**
  * New R8/ProGuard optimizations in 6.4.0 stripped reflection entry points or JNI callback interfaces required when native Ad adapters re-attach to the Flutter engine.
* **Low-Memory Process Death & State Restoration:**
  * On low-end Android phones, the OS kills the background Activity. When resumed, the Flutter engine restores before the Ad SDK initializes its native context, causing a `null` Activity handle.

---

### 3. Objective Decision Framework

| Option | Trigger Conditions | Action Items |
| :--- | :--- | :--- |
| **Hold at 20%** | Crash is non-blocking, concentrated on specific low-frequency devices, and root-cause verification is underway. | Freeze rollout at 20% on Google Play Console. Protect 80% of user base while gathering diagnostic data. |
| **Full Halt / Rollback** | Crash rate escalates ($>2\%$), creates infinite resume loops, blocks app launch, or affects primary device segments. | Press **Halt Rollout** in Play Console immediately. Users remain on stable v6.3.x. |
| **Fix-Forward Hotfix (v6.4.1)** | Root cause identified (e.g., missing null guard or R8 keep rule), fix is low-risk, and verified on test hardware. | Commit fix, add regression test, build v6.4.1, submit for expedited Google Play review. |

> **Core Engineering Principle:** Data before decisions, but user retention and experience always precede ad monetization. Pausing rollout costs zero revenue from existing 6.3 users, whereas a crashing app generates negative 1-star reviews and uninstalls that take months to recover.

---

### 4. Remote Config & Feature Flag Mitigation Strategy
Every commercial third-party SDK in a high-scale mobile app must be insulated by an operational kill switch and defensive wrappers:

1. **Placement-Specific Remote Config Flag:**
   * Maintain a Firebase Remote Config boolean: `enable_resume_interstitial_ads` (default: `true`, with cached last-known configuration).
   * **Action during incident:** Flip `enable_resume_interstitial_ads = false` remotely in Firebase console. Within minutes, all devices fetch the update and bypass the crashing method call—completely mitigating user crashes without requiring a store release or sacrificing banner/rewarded ad revenue.
2. **Defensive Platform Channel Wrapper:**
   * All method channel invocations into third-party native libraries must be enclosed in resilient try/catch blocks:
   ```dart
   try {
     if (remoteConfig.getBool('enable_resume_interstitial_ads')) {
       await AdManager.handleAppResume();
     }
   } on PlatformException catch (e, stack) {
     FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Non-fatal ad resume failure');
     // Gracefully allow user to continue using the Funngro app
   }
   ```
