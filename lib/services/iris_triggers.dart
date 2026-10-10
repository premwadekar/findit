/// Pure-Dart building blocks for the Iris hands-free assistant.
///
/// The wake-word pattern defined here is the single source of truth: it is
/// sent to the Android foreground service when Iris mode is armed, so the
/// native listener and these unit-tested rules cannot drift apart.
/// [DoublePressDetector] and [TriggerDebouncer] are mirrored 1:1 in Kotlin
/// (`DoublePressDetector.kt`, `LostPhoneService.beginIrisSession`).
library;

class IrisWakeWord {
  IrisWakeWord._();

  // Spoken forms that are unlikely to be said by accident: accepted alone.
  static const String _strong =
      r'iris|iriss|airis|ayris|eyris|irus|iras|aeris|ireis';

  // Common mis-hearings of "Hey Iris". Real words ("irish", "harry",
  // "it is") are accepted ONLY directly after a greeting.
  static const String _weak =
      r'irish|ayres|aires|eris|ires|aris|harris|harry|heiress|high\s*risk|'
      r'it\s+is|here\s+is|a\s+ris';

  static const String _greet = r'hey|hi|hay|hai|hei|hello|helo|ok|okay';

  /// Latin script (English accents) + Hindi, Kannada, Telugu, Tamil.
  /// Uses only non-capturing groups and no inline flags, so the same string
  /// compiles in both Dart (caseSensitive: false) and Java/Kotlin.
  static const String pattern =
      r'\b(?:(?:' '$_greet' r')[\s,]*(?:' '$_strong|$_weak' r')|(?:' '$_strong'
      r'))\b'
      // Hindi
      r'|(?:(?:हे|हाय|हेलो|हैलो|ओके)\s*)?(?:आइरिस|आयरिस|आईरिस|आइरीस|आयरीस|इरिस|ऐरिस|एरिस)'
      // Kannada
      r'|(?:(?:ಹೇ|ಹಾಯ್|ಹಲೋ)\s*)?(?:ಐರಿಸ್|ಐರೀಸ್|ಇರಿಸ್)'
      // Telugu
      r'|(?:(?:హే|హాయ్|హలో)\s*)?(?:ఐరిస్|ఐరీస్|ఇరిస్)'
      // Tamil
      r'|(?:(?:ஹே|ஹாய்|ஹலோ)\s*)?(?:ஐரிஸ்|ஐரிஷ்|இரிஸ்)';

  static final RegExp _wake = RegExp(pattern, caseSensitive: false);
  static final RegExp _prefix = RegExp(
    r'^\s*(?:' '$pattern' r')[:,\s]*',
    caseSensitive: false,
  );

  /// True when [transcript] contains the wake word.
  static bool matches(String transcript) => _wake.hasMatch(transcript);

  /// Removes a leading wake word, returning the command that follows it
  /// ("Hey Iris find my bottle" -> "find my bottle").
  static String stripPrefix(String transcript) =>
      transcript.replaceFirst(_prefix, '').trim();
}

/// Detects two presses of the same button within [windowMs].
/// Timestamps are injected so the logic is deterministic and testable.
class DoublePressDetector {
  DoublePressDetector({this.windowMs = 600, this.bounceMs = 40});

  final int windowMs;

  /// Presses closer than this are treated as the same physical press
  /// (contact bounce, or the same key event seen by two code paths).
  final int bounceMs;

  int? _lastPressMs;

  /// Registers a press at [nowMs]; returns true on the second press.
  bool onPress(int nowMs) {
    final last = _lastPressMs;
    if (last != null) {
      final gap = nowMs - last;
      if (gap >= 0 && gap < bounceMs) return false;
      if (gap >= bounceMs && gap <= windowMs) {
        _lastPressMs = null;
        return true;
      }
    }
    _lastPressMs = nowMs;
    return false;
  }

  void reset() => _lastPressMs = null;
}

/// Guarantees one physical trigger never starts two Iris sessions.
class TriggerDebouncer {
  TriggerDebouncer({this.cooldownMs = 2000});

  final int cooldownMs;
  int? _lastAcceptedMs;

  /// Returns true if a trigger at [nowMs] should start a session.
  bool accept(int nowMs) {
    final last = _lastAcceptedMs;
    if (last != null && nowMs - last >= 0 && nowMs - last < cooldownMs) {
      return false;
    }
    _lastAcceptedMs = nowMs;
    return true;
  }

  void reset() => _lastAcceptedMs = null;
}
