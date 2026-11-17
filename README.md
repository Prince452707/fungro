PART 3 - Production scenario (~15 min, written answer)
You released v6.4.0 yesterday at 20% staged rollout on the Play Store. This morning Crashlytics shows a new crash - PlatformException in the ad SDK on app resume - at a rate that has moved crash-free users from 99.6% to 98.1% within the rollout group. The ad SDK was not updated in this release. Revenue from ads matters. The founder is asking whether to halt the rollout.



answer -

Sir, let us not increase the rollout beyond 20% today. I will check the data and tell you by 1 pm today whether to halt or continue.

Crashes in the new version went from 0.4% to 1.9% of users. All are from the ad SDK when the user returns to the app. We did not change the SDK, so something else in this release is causing it.

If many users are affected, or the app is not opening, I will halt immediately. If only a few phones are affected, I will switch off the resume ads for them and release a fix. User safety comes first, then ad revenue.

I will send you one more update by 4 pm today.





vedio of project - https://drive.google.com/drive/folders/1gwYEQYGftX9i-fqFNvmSiqaMdQ0GMvsb
