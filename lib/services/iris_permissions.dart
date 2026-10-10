import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_language.dart';
import 'localization_service.dart';

/// What still blocks the hands-free (screen-off) Iris trigger.
enum HandsFreeIssue {
  /// "FindIt Iris trigger" accessibility service is off: Volume Up long
  /// press cannot be detected.
  accessibilityOff,

  /// Full-screen notifications are not allowed: Iris cannot turn the screen
  /// on or appear over the lock screen.
  screenWakeNotAllowed,
}

/// Pure state/status logic for the hands-free trigger permissions.
/// The native side only reports two booleans; everything else is decided here
/// so it can be unit-tested.
class HandsFreeStatus {
  const HandsFreeStatus({
    required this.accessibilityEnabled,
    required this.fullScreenAllowed,
  });

  final bool accessibilityEnabled;
  final bool fullScreenAllowed;

  /// Used when the status cannot be read: do not nag the user about
  /// something we cannot verify.
  static const HandsFreeStatus unknown = HandsFreeStatus(
    accessibilityEnabled: true,
    fullScreenAllowed: true,
  );

  factory HandsFreeStatus.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return unknown;
    return HandsFreeStatus(
      accessibilityEnabled: map['accessibility'] as bool? ?? false,
      fullScreenAllowed: map['fullScreen'] as bool? ?? true,
    );
  }

  bool get longPressReady => accessibilityEnabled;
  bool get screenWakeReady => fullScreenAllowed;
  bool get allReady => longPressReady && screenWakeReady;

  List<HandsFreeIssue> get issues => [
    if (!accessibilityEnabled) HandsFreeIssue.accessibilityOff,
    if (!fullScreenAllowed) HandsFreeIssue.screenWakeNotAllowed,
  ];

  /// Warnings to speak when Iris is armed (one per missing permission).
  List<String> armedWarnings(AppLanguage lang, LocalizationService l10n) => [
    for (final issue in issues)
      switch (issue) {
        HandsFreeIssue.accessibilityOff => l10n.longPressNeedsAccessibility(
          lang,
        ),
        HandsFreeIssue.screenWakeNotAllowed => l10n.screenWakeNeedsPermission(
          lang,
        ),
      },
  ];

  /// First-run guidance is offered only once, and only if something is missing.
  bool shouldShowFirstRunGuide({required bool guideAlreadyShown}) =>
      !guideAlreadyShown && !allReady;

  @override
  bool operator ==(Object other) =>
      other is HandsFreeStatus &&
      other.accessibilityEnabled == accessibilityEnabled &&
      other.fullScreenAllowed == fullScreenAllowed;

  @override
  int get hashCode => Object.hash(accessibilityEnabled, fullScreenAllowed);
}

/// Remembers (on this device only) that the first-run guide was shown or skipped.
class HandsFreeGuideStore {
  HandsFreeGuideStore._();

  static const String _key = 'findit_hands_free_guide_shown';

  static Future<bool> wasShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      // If storage fails, do not nag on every visit.
      return true;
    }
  }

  static Future<void> markShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {}
  }
}
