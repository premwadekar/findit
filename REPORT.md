# Safe-reach guidance — report

## Files changed
- `lib/services/guidance_engine.dart` — `GuidanceStage`, per-object found thresholds, fragile set, nearby-box check, one-time `reachPhrases`
- `lib/services/localization_service.dart` — 3 new phrases + 8 object names, all 5 languages
- `lib/models/target_objects.dart` — chair, bowl, scissors, toothbrush, tv, spoon, fork, knife (laptop already present); multilingual synonyms; unsupported list untouched
- `lib/services/haptic_service.dart` — `safeReachPattern()` (long gentle pattern)
- `lib/services/speech_service.dart` — optional `calm` flag (speech rate x0.8, restored after)
- `lib/screens/finder_screen.dart` — passes other detections; on FOUND plays haptic + spoken reach phrases, then opens the found screen (delay 1.5s -> 0.8s after speech ends)
- `test/safe_reach_test.dart` (new), `FINDIT_JURY_GUIDE.md` (new section), `REPORT.md`

Notes: bottle threshold is 0.18 and book 0.20 so existing tests/behaviour are preserved. Nearby check ignores person, dining table, couch, bed, bench.

## Results
- `flutter analyze`: 1 info (`use_build_context_synchronously`, `lib/screens/lost_phone_screen.dart:82`) in a file I did not touch; no issues in changed files.
- `flutter test`: all 74 tests pass (59 existing + 15 new).
- Git: project folder is not a git repository, so nothing was committed.

## TEST ON PHONE
- [ ] Safe-reach after FOUND: slow voice "Found. Stop. Move your hand slowly forward, palm open." + long gentle vibration, spoken once
- [ ] Fragile warning with a cup (also bottle/laptop/bowl): "This can fall. Bring your hand from below, slowly."
- [ ] Nearby warning: put a book/bottle next to the target; hear "There is also a ... nearby, go slowly." once
- [ ] New objects: chair, bowl, scissors, toothbrush, tv, spoon, fork, knife appear in the list, are detected, and are found at a sensible distance
- [ ] Per-object distance: phone/remote/mouse found at arm's length; laptop/backpack need to be closer
- [ ] Hindi: switch language, repeat the above; Hindi voice names ("कुर्सी", "चम्मच") are recognised
- [ ] Airplane mode: everything above still works offline
- [ ] Keys/wallet/glasses/watch still answer "can't reliably find that yet"
