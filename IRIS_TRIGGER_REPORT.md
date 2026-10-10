# Iris hands-free trigger (screen-off long press) — report

Goal: long-press Volume Up, even with the screen off, starts Iris; the screen turns on, the app appears over the lock screen, and the command runs.

## Results
- `flutter analyze`: no issues.
- `flutter test`: 102 tests pass (93 before + 9 new in `test/iris_permissions_test.dart`).
- `flutter build apk --debug`: succeeded, so the Kotlin, manifest and new resources compile.
- Committed as `7414460`. Not pushed. (That commit also picked up `IRIS_REPORT.md`, which was previously uncommitted.)

## Files changed
**Android**
- `AndroidManifest.xml`: `USE_FULL_SCREEN_INTENT`; `showWhenLocked` + `turnScreenOn` on `MainActivity` (it already set both in `onCreate` for API 27+); new accessibility service entry.
- `IrisAccessibilityService.kt` (new): `onKeyEvent` watches Volume Up only. A hold of ~700 ms calls `LostPhoneService.triggerIris("volume_long_press")`, the same code path as the wake word (beep, vibrate, "Yes, tell me", listen once). The first press is passed through, so short presses change the volume normally. After a long press has triggered Iris, its remaining repeats and key-up are consumed, so the volume stops changing. It only watches while Iris is armed. Debounced by the existing session logic (2 s cooldown, one session at a time), plus one trigger per press.
- `res/xml/iris_accessibility_config.xml` (new): `canRequestFilterKeyEvents`, `flagRequestFilterKeyEvents`, `canRetrieveWindowContent="false"`, no event types requested.
- `res/values*/strings.xml` (new; en, hi, kn, te, ta): service label and the honest description: only detects a long press of Volume Up, does not read the screen or content, nothing is stored or sent. Android shows it in the phone's system language, not the app language.
- `LostPhoneService.kt`: on every trigger (wake word, long press, double press, notification, home button) it now takes a 5 s `SCREEN_BRIGHT | ACQUIRE_CAUSES_WAKEUP` wake lock, tries a direct activity start, and posts a high-priority notification with a full-screen intent (new channel). On Android 14+ without the permission (`canUseFullScreenIntent()` false) the notification becomes a heads-up in the user's language with an "Allow screen wake" button that opens the full-screen-intent settings page. The wake lock and notification are released/cancelled on timeout, when the app appears, and in `onDestroy`. `beginIrisSession` now returns whether it started.
- `MainActivity.kt`: `getHandsFreeStatus`, `openAccessibilitySettings`, `openFullScreenSettings`; clears the wake notification in `onResume`.

**Dart**
- `iris_permissions.dart` (new): `HandsFreeStatus` (pure logic: issues, armed warnings, first-run rule) and `HandsFreeGuideStore` (shown-once flag).
- `lost_phone_screen.dart`: new "Hands-free trigger" card (explanation, accessibility ON/OFF, screen-wake allowed/not allowed, big **Open Accessibility settings** button, **Allow screen wake** button, **Hear explanation**). Status refreshes when you return from Android Settings. Arming Iris speaks the confirmation and then, if needed, "Long press needs Accessibility turned on." and/or the full-screen warning. A spoken, skippable first-run guide appears once if something is missing.
- `lost_phone_service.dart`, `localization_service.dart` (16 new strings × 5 languages): plumbing and text, including the notification strings sent to the native service.

## Could NOT be verified without a physical phone
- **Whether Android delivers Volume Up key events to an accessibility service while the screen is off or the phone is locked.** This is the core of the feature and may vary by Android version and iQOO/Funtouch OS. If it doesn't, long press works only when the screen is on; the wake word, double-press, notification button and home button still work.
- Whether the screen actually turns on and the app shows over a **secure** lock screen from the full-screen notification, and whether the camera finder works over the lock screen.
- Behaviour on Android 14+ when full-screen notifications are denied (code path written, not exercised).
- iQOO/Funtouch background limits: autostart, battery "unrestricted", and "display over other apps" may block starting the app from the background. I did not add the overlay permission.
- Whether holding Volume Up raises the volume by a step or two before the 700 ms trigger fires (the first press is intentionally passed through).
- Translations (kn/te/ta/hi) were written by me; a native speaker should review them.

## Known limits
- Long press only works while Iris is armed (microphone service running); otherwise the key is untouched.
- Nothing is read, stored or sent by the accessibility service; it requests no events and cannot read window content.
- Enabling an accessibility service is always a manual user action in Android Settings; the app can only open that page.

## TEST ON PHONE
- [ ] Settings → Accessibility → turn on **FindIt Iris trigger**; the app's Hands-free card shows ON when you return
- [ ] Turn Iris ON (Lost Phone screen); confirmation is spoken, plus a warning if a permission is missing
- [ ] Long-press Volume Up (~1 s) with the app open: beep, vibrate, "Yes, tell me"
- [ ] Long-press with the app in the background: the app comes to the front
- [ ] Long-press with the screen off: the screen turns on and the app appears
- [ ] Long-press with the phone locked: the app appears over the lock screen
- [ ] "Find my cup" works end to end from the locked/screen-off state (the finder opens)
- [ ] Short presses of Volume Up/Down still change the volume (Iris on and off, accessibility on)
- [ ] Holding Volume Up after Iris triggers does not keep changing the volume
- [ ] Turn full-screen notifications OFF: graceful localized heads-up with an **Allow screen wake** button; the voice command still works
- [ ] Hands-free card status updates after returning from each Settings page
- [ ] First-run guide is spoken once and can be skipped
- [ ] Battery saver ON: repeat the long-press tests
- [ ] iQOO: enable autostart, set battery to unrestricted, allow display over other apps, then repeat the screen-off test
- [ ] Hindi: switch the app language; strings and spoken warnings are in Hindi
