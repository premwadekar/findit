import 'package:findit/models/app_language.dart';
import 'package:findit/services/localization_service.dart';
import 'package:findit/services/startup_guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Permission outcome', () {
    test('granted -> no failure', () {
      expect(
        StartupGuard.permissionOutcome(isGranted: true, isPermanentlyDenied: false),
        StartupFailure.none,
      );
    });

    test('denied but can ask again -> permissionDenied', () {
      expect(
        StartupGuard.permissionOutcome(isGranted: false, isPermanentlyDenied: false),
        StartupFailure.permissionDenied,
      );
    });

    test('permanently denied -> permissionPermanentlyDenied', () {
      expect(
        StartupGuard.permissionOutcome(isGranted: false, isPermanentlyDenied: true),
        StartupFailure.permissionPermanentlyDenied,
      );
    });
  });

  group('Which actions each failure offers', () {
    test('permission failures offer settings; only denied offers retry', () {
      expect(StartupGuard.offersSettingsButton(StartupFailure.permissionPermanentlyDenied), isTrue);
      expect(StartupGuard.offersSettingsButton(StartupFailure.permissionDenied), isTrue);
      expect(StartupGuard.offersRetry(StartupFailure.permissionDenied), isTrue);
      expect(StartupGuard.offersRetry(StartupFailure.permissionPermanentlyDenied), isFalse);
    });

    test('a missing camera or failed model offers retry, not settings', () {
      expect(StartupGuard.offersSettingsButton(StartupFailure.noCamera), isFalse);
      expect(StartupGuard.offersSettingsButton(StartupFailure.modelLoad), isFalse);
      expect(StartupGuard.offersRetry(StartupFailure.modelLoad), isTrue);
      expect(StartupGuard.offersRetry(StartupFailure.cameraInit), isTrue);
      expect(StartupGuard.offersRetry(StartupFailure.noCamera), isFalse);
    });

    test('no failure offers nothing', () {
      expect(StartupGuard.offersSettingsButton(StartupFailure.none), isFalse);
      expect(StartupGuard.offersRetry(StartupFailure.none), isFalse);
    });
  });

  group('Lifecycle: camera follows foreground/background', () {
    test('going to background pauses the camera once', () {
      expect(
        StartupGuard.lifecycleAction(AppLifecycleState.resumed, AppLifecycleState.paused),
        LifecycleAction.pauseCamera,
      );
      expect(
        StartupGuard.lifecycleAction(AppLifecycleState.resumed, AppLifecycleState.inactive),
        LifecycleAction.pauseCamera,
      );
      // Already hidden: inactive -> paused must not pause again.
      expect(
        StartupGuard.lifecycleAction(AppLifecycleState.inactive, AppLifecycleState.paused),
        LifecycleAction.none,
      );
    });

    test('coming back to the foreground resumes the camera', () {
      expect(
        StartupGuard.lifecycleAction(AppLifecycleState.paused, AppLifecycleState.resumed),
        LifecycleAction.resumeCamera,
      );
      expect(
        StartupGuard.lifecycleAction(AppLifecycleState.inactive, AppLifecycleState.resumed),
        LifecycleAction.resumeCamera,
      );
    });

    test('resumed -> resumed or unrelated states do nothing', () {
      expect(
        StartupGuard.lifecycleAction(AppLifecycleState.resumed, AppLifecycleState.resumed),
        LifecycleAction.none,
      );
    });
  });

  group('Startup failure messages are localized', () {
    final l10n = LocalizationService.instance;
    Map<String, String> phrases(AppLanguage lang) => {
      'permission': l10n.cameraPermissionNeeded(lang),
      'blocked': l10n.cameraPermissionBlocked(lang),
      'noCamera': l10n.noCameraFound(lang),
      'cameraStart': l10n.cameraStartFailed(lang),
      'model': l10n.modelLoadFailed(lang),
      'settings': l10n.openAppSettings(lang),
      'retry': l10n.tryAgain(lang),
    };

    test('every startup phrase exists and is translated in all 5 languages', () {
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
  });
}
