# Part 3: Production Incident Response (v6.4.0 Crash Spike)

## 1. Message to Founder (Slack/WhatsApp)

> "Sir, let us not increase the rollout beyond 20% today. I will check the data and tell you by 1 pm today whether to halt or continue.
> 
> Crashes in the new version went from 0.4% to 1.9% of users. All are from the ad SDK when the user returns to the app. We did not change the SDK, so something else in this release is causing it.
> 
> If many users are affected, or the app is not opening, I will halt immediately. If only a few phones are affected, I will switch off the resume ads for them and release a fix. User safety comes first, then ad revenue.
> 
> I will send you one more update by 4 pm today."

---

## 2. Crashlytics Investigation Plan for the Day

### Step 1: Compare Versions & Isolate the Anomaly
* **Crash Velocity**: Compare raw crash counts and crash rates between v6.3.9 and v6.4.0.
* **First Seen**: Check if the exception existed as an edge-case in v6.3.9 that was magnified by higher traffic or if it is 100% net new to v6.4.0.
* **Stack Trace Analysis**: Inspect the exact method channel name and invocation arguments:
  * Look for: `PlatformException(error, "AdView was destroyed or Activity detached", null)` or `MissingPluginException`.
  * Determine if the crash occurs on the Dart side (unhandled exception in an `onActivityResumed` callback) or on the Android JVM/Kotlin side (null Activity context passed to the ad banner view).

### Step 2: Slice and Filter by Device Dimensions
* **Android OS Versions**: Is the crash clustered on specific API levels (e.g., Android 13/14 Predictive Back, or Android 10/11 background process execution limits)?
* **OEM Custom Skins**: Filter by manufacturer. Budget devices frequently run aggressive OEM battery managers:
  * Xiaomi / Redmi (MIUI / HyperOS)
  * Samsung (One UI Core)
  * Transsion (Infinix, Tecno, Itel)
  * Realme / Vivo / Oppo
* **Device RAM & Hardware**: Check free RAM at time of crash. If 90%+ of crashes occur on devices with <200MB free RAM, the OS is killing the background Activity, and upon resume, Flutter tries to re-attach to a dead native ad view.
* **Foreground vs. Background Resume**: Check Crashlytics breadcrumbs for app state transitions: `Background -> Foreground` or `App Switcher -> Resume`.

### Step 3: Git Diff Audit of v6.4.0
* Audit every PR that merged into v6.4.0, specifically looking for:
  1. Changes to `MainActivity.kt` or `AndroidManifest.xml` (e.g. `android:configChanges`, `launchMode: singleTask`, hardware acceleration flags).
  2. Upgrades to Flutter engine or Dart SDK.
  3. Upgrades to other native plugins that may have bundled a conflicting transitive dependency (e.g. Google Play Services / Play Core version collision).
  4. Any `WidgetsBindingObserver.didChangeAppLifecycleState` callbacks added in Dart that eagerly invoke the ad SDK before the native platform view has re-attached.

---

## 3. Decision Rules: Halt vs. Hold at 20% vs. Fix-Forward

| Decision | Condition | Action Plan |
| :--- | :--- | :--- |
| **HALT (Rollback)** | Crash rate worsens past **97.0%**, or the crash occurs during core teen payout/earnings flows, or root cause cannot be isolated within 3 hours. | Immediately halt rollout on Google Play Console. Unaffected 80% remain on stable v6.3.9. Prepare hotfix v6.4.1. |
| **HOLD at 20%** *(Current State)* | Crash rate stabilizes between **98.0%–98.5%**, crash is strictly confined to ad impressions on resume, and core wallet/project functionality works. | Keep rollout paused at 20% while diagnosing root cause. Protects 80% of user base while maintaining statistical significance to verify hotfix. |
| **FIX-FORWARD** | Root cause is identified (e.g., adding `if (adView == null || !mounted) return;` or catching the `PlatformException` during lifecycle resume). | Build hotfix v6.4.1, run sanity regression on low-RAM device, release to 100% directly or ramp 20% ➔ 50% ➔ 100% within 4 hours. |

---

## 4. The Lever We Wish We Had: Remote Config Ad SDK Kill-Switch

### The Lever
A Firebase Remote Config / Feature Flag boolean: `is_ad_sdk_enabled: bool` (default: `true`), paired with a dynamic `ad_provider_version: string` and `kill_switch_threshold_version: string`.

### How It Works in Code
```dart
class AdManager {
  static Future<void> showResumeBanner() async {
    final remoteEnabled = RemoteConfigService.instance.getBool('is_ad_sdk_enabled');
    if (!remoteEnabled) {
      // Gracefully bypass ad display without crashing
      return;
    }
    try {
      await AdSdk.showResumeAd();
    } on PlatformException catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
      // Suppress crash from killing the user session
    }
  }
}
```

### Why I Would Have Shipped It
1. **Zero-Day Incident Mitigation**: Third-party ad SDKs are inherently unstable on heterogeneous Android hardware. With a remote kill switch, we could flip `is_ad_sdk_enabled: false` from the Firebase console in **30 seconds** without waiting 4–8 hours for Google Play store review.
2. **Targeted Disablement**: Modern remote config allows targeting specific app versions (`v6.4.0` only) or specific OEMs. We could disable ads exclusively on crashing devices while leaving them active for the remaining 95% of users, protecting revenue while eliminating crashes.

---

## 5. Interview Defense: 3 Likely Questions & Answers

### Q1: Why not halt the rollout immediately when crash-free users dropped below 99%?
> **Answer**: Halting immediately stops the rollout to new users, but leaves the existing 20% stuck on the crashing build until an update is approved. By holding at 20%, we protect 80% of our audience while keeping the rollout channel open so that as soon as our fix-forward hotfix (v6.4.1) is built, Google Play can distribute it immediately to the impacted 20% first.

### Q2: Why would an ad SDK crash on resume if the ad SDK itself wasn't updated in this release?
> **Answer**: Android Activity recreation under memory pressure. If v6.4.0 increased the app's baseline memory footprint (even by 15MB), the Android OS is much more likely to kill the background Activity while the user is away. When the user returns, the OS restores the Activity, but the Flutter engine reattaches asynchronously. If Dart code in `didChangeAppLifecycleState(AppLifecycleState.resumed)` calls the native ad SDK before the platform view or SurfaceView is completely attached, the native channel throws a `PlatformException`.

### Q3: How do you prevent an ad SDK crash from bringing down the entire Flutter process?
> **Answer**: All platform channel invocations must be enclosed in `try / on PlatformException catch (e, st)`. Platform channels cross an asynchronous IPC boundary; unhandled native exceptions surface as unhandled Dart errors. Wrapping channel calls ensures a third-party ad failure never prevents a teenager from viewing their wallet or submitting a project.
