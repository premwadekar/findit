import 'package:findit/models/app_language.dart';
import 'package:findit/services/iris_permissions.dart';
import 'package:findit/services/localization_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = LocalizationService.instance;

  group('HandsFreeStatus', () {
    test('all permissions granted -> ready, no issues, no warnings', () {
      const s = HandsFreeStatus(
        accessibilityEnabled: true,
        fullScreenAllowed: true,
      );
      expect(s.allReady, isTrue);
      expect(s.issues, isEmpty);
      expect(s.armedWarnings(AppLanguage.english, l10n), isEmpty);
    });

    test('accessibility off -> long press warning only', () {
      const s = HandsFreeStatus(
        accessibilityEnabled: false,
        fullScreenAllowed: true,
      );
      expect(s.longPressReady, isFalse);
      expect(s.issues, [HandsFreeIssue.accessibilityOff]);
      expect(s.armedWarnings(AppLanguage.english, l10n), [
        'Long press needs Accessibility turned on.',
      ]);
    });

    test('full-screen not allowed -> screen wake warning only', () {
      const s = HandsFreeStatus(
        accessibilityEnabled: true,
        fullScreenAllowed: false,
      );
      expect(s.screenWakeReady, isFalse);
      expect(s.issues, [HandsFreeIssue.screenWakeNotAllowed]);
      expect(s.armedWarnings(AppLanguage.hindi, l10n), hasLength(1));
    });

    test('both missing -> two warnings, accessibility first', () {
      const s = HandsFreeStatus(
        accessibilityEnabled: false,
        fullScreenAllowed: false,
      );
      expect(s.issues, [
        HandsFreeIssue.accessibilityOff,
        HandsFreeIssue.screenWakeNotAllowed,
      ]);
      expect(s.armedWarnings(AppLanguage.tamil, l10n), hasLength(2));
    });

    test('fromMap parses native values; null/error does not nag', () {
      final s = HandsFreeStatus.fromMap({
        'accessibility': false,
        'fullScreen': true,
      });
      expect(s.accessibilityEnabled, isFalse);
      expect(s.fullScreenAllowed, isTrue);
      expect(HandsFreeStatus.fromMap(null), HandsFreeStatus.unknown);
      expect(HandsFreeStatus.unknown.allReady, isTrue);
      // Missing keys: accessibility is treated as off, full-screen as allowed.
      final partial = HandsFreeStatus.fromMap(<String, Object>{});
      expect(partial.accessibilityEnabled, isFalse);
      expect(partial.fullScreenAllowed, isTrue);
    });

    test('first-run guide: only once, only when something is missing', () {
      const missing = HandsFreeStatus(
        accessibilityEnabled: false,
        fullScreenAllowed: true,
      );
      expect(missing.shouldShowFirstRunGuide(guideAlreadyShown: false), isTrue);
      expect(missing.shouldShowFirstRunGuide(guideAlreadyShown: true), isFalse);
      const ready = HandsFreeStatus(
        accessibilityEnabled: true,
        fullScreenAllowed: true,
      );
      expect(ready.shouldShowFirstRunGuide(guideAlreadyShown: false), isFalse);
    });
  });

  group('HandsFreeGuideStore', () {
    test('remembers that the guide was shown', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await HandsFreeGuideStore.wasShown(), isFalse);
      await HandsFreeGuideStore.markShown();
      expect(await HandsFreeGuideStore.wasShown(), isTrue);
    });
  });

  group('Hands-free localization completeness', () {
    Map<String, String> phrases(AppLanguage lang) => {
      'title': l10n.handsFreeTitle(lang),
      'explain': l10n.handsFreeExplain(lang),
      'a11yOn': l10n.accessibilityStatusOn(lang),
      'a11yOff': l10n.accessibilityStatusOff(lang),
      'wakeOn': l10n.screenWakeStatusOn(lang),
      'wakeOff': l10n.screenWakeStatusOff(lang),
      'openA11y': l10n.openAccessibilitySettings(lang),
      'allowWake': l10n.allowScreenWake(lang),
      'longPressWarn': l10n.longPressNeedsAccessibility(lang),
      'wakeWarn': l10n.screenWakeNeedsPermission(lang),
      'guide': l10n.handsFreeGuide(lang),
      'skip': l10n.skipForNow(lang),
      'hear': l10n.hearExplanation(lang),
      'listening': l10n.irisListeningTitle(lang),
      'fsiTitle': l10n.fsiNotifTitle(lang),
      'fsiText': l10n.fsiNotifText(lang),
    };

    test('every phrase exists and is translated in all 5 languages', () {
      final en = phrases(AppLanguage.english);
      for (final lang in AppLanguage.values) {
        phrases(lang).forEach((key, text) {
          expect(text.trim(), isNotEmpty, reason: '$key/$lang');
          if (lang != AppLanguage.english) {
            expect(text, isNot(en[key]), reason: '$key/$lang untranslated');
          }
        });
      }
    });

    test('explanation is honest: long press only, nothing read or sent', () {
      final text = l10n.handsFreeExplain(AppLanguage.english).toLowerCase();
      expect(text, contains('long press'));
      expect(text, contains('does not read your screen'));
      expect(text, contains('nothing is stored or sent'));
    });
  });
}
