# Iris hands-free assistant — report

Flow: **trigger → beep + vibrate → "Yes, tell me" (user's language) → listen for ONE command (8 s) → execute → spoken confirmation → idle.**

## Results
- `flutter analyze`: no issues.
- `flutter test`: 93 tests pass (74 existing + 19 new in `test/iris_test.dart`).
- `flutter build apk --debug`: succeeded, so the Kotlin compiles. (Only the existing Gradle/AGP/Kotlin "will soon be dropped" warnings.)
- Committed as `e1ebf42`. Not pushed. This report is not committed yet.

## What changed (file by file)
**Dart**
- `lib/services/iris_triggers.dart` (new): `IrisWakeWord` (the one wake-word pattern, en + hi/kn/te/ta, mis-hearings), `DoublePressDetector` (injected timestamps, 600 ms window, 40 ms bounce guard), `TriggerDebouncer` (2 s cooldown).
- `lib/services/iris_controller.dart` (new): one central executor for every Iris command. Uses only `parseOffline` (never the cloud). Find object → opens the finder; where are you → rings the alarm; stop → stops the alarm or says none is ringing; battery/time → spoken from the device; "around me" → says honestly it is not available yet; anything else → the localized "Sorry, I can't do that yet…". Also drives the home "Talk to Iris" button and pulls a command that arrived before the app was ready (cold start).
- `lib/services/assistant_service.dart`: new `parseOffline()` (synchronous, offline) plus intents `stopAlarm`, `battery`, `time`. Battery/time/stop are checked before object matching ("battery of my phone" is not "find my phone"). `processUserInput` now calls `parseOffline` first; existing behaviour and tests are unchanged.
- `lib/services/lost_phone_service.dart`: sends the wake pattern and localized strings to the service on arming; new `talkToIris`, `irisDone`, `ringAlarm`, `batteryPercent`, `takePendingCommand`, `syncIrisConfig`.
- `lib/services/localization_service.dart`: 14 new strings × 5 languages (yes/didn't hear/can't do that/armed/disarmed/notification/Talk to Iris/status on-off/battery/battery unavailable/time/no alarm/surroundings unavailable).
- `lib/screens/home_screen.dart`: big "Talk to Iris" button; removed its duplicate voice-command listener.
- `lib/screens/lost_phone_screen.dart`: "IRIS IS ON/OFF" status, "TURN IRIS ON/OFF", localized spoken armed/disarmed confirmations, trigger/command help text; removed duplicate listener. Timeout chips (10/20/30/45 min) and the native 5–60 min clamp are unchanged.
- `lib/main.dart`: shared navigator key, controller started before `runApp`.

**Android (Kotlin)**
- `LostPhoneService.kt`: single `beginIrisSession()` used by every trigger, debounced (2 s cooldown and no new session while one is active). System beep (ToneGenerator, no asset), one vibration, wake-word loop paused, TTS "Yes, tell me", 350 ms clearance, 8 s command window, localized "I didn't hear anything" on timeout, then idle. The wake-loop restarts only after Dart reports its reply finished (20 s safety net). Wake word is read from the Dart pattern; it is acted on only for final recognition results, so "Hey Iris find my bottle" is not cut short. Notification now shows how to trigger Iris and has a **Talk to Iris** action next to STOP. Active `MediaSession` with a remote `VolumeProvider` tries to receive Volume keys with the screen off; non-trigger presses are passed through to the system volume. Battery-low shutdown, auto-timeout and wake lock are untouched.
- `DoublePressDetector.kt` (new): Kotlin mirror of the tested Dart detector.
- `MainActivity.kt`: double Volume Up (second press within ~600 ms) triggers Iris while Iris is armed and no screen is intercepting volume keys. The first press is never consumed, so volume works normally; with Iris off the code path does nothing. The language-selection key handling is untouched. New channel methods: `talkToIris`, `irisDone`, `ringAlarm`, `getBatteryPercent`, `updateIrisConfig`, `takePendingCommand`.

## Could NOT be verified without a physical phone
- Double Volume Up **with the screen off or locked**: depends on the `MediaSession` volume routing, which some Android versions and OEM skins don't honour. It fails silently (no crash); the wake word, notification button and in-app triggers still work.
- Wake-word recognition quality (Indian-accent English, Hindi, etc.) and the Kannada/Telugu/Tamil phrasings: the regex is unit-tested, the recogniser's actual transcripts are not.
- Voice quality of the kn/te/ta translations and the TTS voices installed on the phone. The translations were written by me and should be reviewed by native speakers.
- Cold start: when a command arrives with the app process dead, it is launched and the command is handed over after start-up; timing is untested.
- Behaviour under battery saver, Doze, silent mode, and OEM background-audio limits.
- The `ToneGenerator` beep volume in silent mode.

## Known limits and things to decide
- **Offline caveat (existing design):** the wake-word and command listening use Android's `SpeechRecognizer`. Whether that runs on-device depends on the phone having offline speech packs; I did not force `EXTRA_PREFER_OFFLINE`, because with no offline pack recognition would then fail. The app code makes no network calls for Iris. Say if you want it forced.
- Every command opens the app (existing behaviour), so "battery"/"time" will turn the screen on.
- The wake word is acted on after the phrase ends (final results), adding about a second of latency.
- The native listener still recognises the old "where are you / find my phone" alarm phrases without the wake word (existing behaviour). Its native alarm regex only covers English, Hindi and Kannada.
- Notification title ("FindIt: Iris is on") and the STOP label are English only. After a language change, Iris texts update the next time the app opens.
- The home "Talk to Iris" button turns Iris mode on (microphone on, default 20-minute auto-off) if it was off.
- The Kotlin `DoublePressDetector` is a mirror and has no native unit test.

## TEST ON PHONE
- [ ] Turn Iris ON in Lost Phone screen: spoken confirmation in your language, notification shows how to trigger and a **Talk to Iris** button
- [ ] Double-press Volume Up with the app open: beep, short vibration, "Yes, tell me"
- [ ] Double-press Volume Up with the screen off
- [ ] Double-press Volume Up with the phone locked
- [ ] Battery saver on: repeat the wake word and double-press tests
- [ ] Silent mode on: still audible and vibrating?
- [ ] Wake word in English: "Hey Iris", "Hey Iris find my bottle" (no repeated prompt)
- [ ] Wake word in Hindi: "हे आइरिस"
- [ ] "Find my bottle" opens the finder; "find my keys" says it can't reliably find that
- [ ] "Where are you" rings the loud alarm; "stop" by voice silences it
- [ ] "Battery" and "time" are spoken correctly; "what's around me" says it isn't available yet
- [ ] A nonsense request gets the "Sorry, I can't do that yet…" reply
- [ ] Stay silent after "Yes, tell me": "I didn't hear anything" after ~8 s, then back to idle
- [ ] Notification **Talk to Iris** button
- [ ] Home screen **Talk to Iris** button
- [ ] One press never starts two sessions (tap the button twice quickly)
- [ ] With Iris **OFF**: Volume Up/Down change the volume normally, in the app and on the home screen
- [ ] With Iris ON: single Volume Up/Down presses still change the volume
- [ ] Language selection screen: volume keys still cycle languages
- [ ] Auto-off after the chosen time, and shutdown on low battery
