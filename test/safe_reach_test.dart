import 'package:findit/models/app_language.dart';
import 'package:findit/models/detection.dart';
import 'package:findit/models/target_objects.dart';
import 'package:findit/services/guidance_engine.dart';
import 'package:findit/services/localization_service.dart';
import 'package:flutter_test/flutter_test.dart';

Detection _box(String label, double l, double t, double r, double b) =>
    Detection(
      label: label,
      confidence: 0.8,
      left: l,
      top: t,
      right: r,
      bottom: b,
    );

void main() {
  group('Safe-reach stage switching', () {
    test('navigation until found, then safe reach with calm phrases', () {
      final e = GuidanceEngine(targetFriendlyName: 'bottle');
      final nav = e.guide(_box('bottle', 0.45, 0.4, 0.55, 0.5));
      expect(nav.stage, GuidanceStage.navigation);
      expect(nav.reachPhrases, isEmpty);
      expect(e.stage, GuidanceStage.navigation);

      final found = e.guide(_box('bottle', 0.25, 0.2, 0.75, 0.8));
      expect(found.isFound, isTrue);
      expect(found.stage, GuidanceStage.safeReach);
      expect(e.stage, GuidanceStage.safeReach);
      expect(found.reachPhrases.first, contains('Move your hand slowly'));
    });

    test('reach phrases are spoken only once per found-stage', () {
      final e = GuidanceEngine(targetFriendlyName: 'cup');
      final box = _box('cup', 0.25, 0.2, 0.75, 0.8);
      expect(e.guide(box).reachPhrases, isNotEmpty);
      expect(e.guide(box).reachPhrases, isEmpty);
      e.reset();
      expect(e.guide(box).reachPhrases, isNotEmpty);
    });
  });

  group('Fragile warning', () {
    test('cup, bottle, laptop, bowl are fragile; phone is not', () {
      for (final n in ['cup', 'bottle', 'laptop', 'bowl']) {
        expect(GuidanceEngine.isFragile(n), isTrue, reason: n);
      }
      expect(GuidanceEngine.isFragile('phone'), isFalse);
    });

    test('cup found includes fall warning, phone does not', () {
      final cup = GuidanceEngine(
        targetFriendlyName: 'cup',
      ).guide(_box('cup', 0.25, 0.2, 0.75, 0.8));
      expect(cup.reachPhrases.join(' '), contains('This can fall'));
      final phone = GuidanceEngine(
        targetFriendlyName: 'phone',
      ).guide(_box('cell phone', 0.25, 0.2, 0.75, 0.8));
      expect(phone.reachPhrases.join(' '), isNot(contains('This can fall')));
    });
  });

  group('Per-object FOUND thresholds', () {
    test('small objects are found at smaller area than large ones', () {
      expect(
        GuidanceEngine.foundAreaFor('phone'),
        lessThan(GuidanceEngine.foundAreaFor('backpack')),
      );
      expect(
        GuidanceEngine.foundAreaFor('mouse'),
        lessThan(GuidanceEngine.foundAreaFor('laptop')),
      );
      expect(
        GuidanceEngine.foundAreaFor('unknown-thing'),
        GuidanceEngine.foundArea,
      );
    });

    test('same box: found for phone, not found for backpack', () {
      // area = 0.3 * 0.4 = 0.12, centered
      final b = _box('x', 0.35, 0.3, 0.65, 0.7);
      expect(
        GuidanceEngine(targetFriendlyName: 'phone').guide(b).isFound,
        isTrue,
      );
      expect(
        GuidanceEngine(targetFriendlyName: 'backpack').guide(b).isFound,
        isFalse,
      );
    });

    test('still requires centering', () {
      final off = _box('x', 0.70, 0.3, 0.95, 0.7);
      expect(
        GuidanceEngine(targetFriendlyName: 'phone').guide(off).isFound,
        isFalse,
      );
    });
  });

  group('Nearby-object warning', () {
    final target = _box('cup', 0.3, 0.3, 0.6, 0.7);

    test('overlapping or close box is reported', () {
      expect(
        GuidanceEngine.nearbyLabel(target, [_box('bottle', 0.55, 0.3, 0.8, 0.7)]),
        'bottle',
      );
      expect(
        GuidanceEngine.nearbyLabel(target, [_box('book', 0.62, 0.3, 0.8, 0.7)]),
        'book',
      );
    });

    test('far box, same label and big surfaces are ignored', () {
      expect(
        GuidanceEngine.nearbyLabel(target, [_box('book', 0.8, 0.3, 0.95, 0.7)]),
        isNull,
      );
      expect(
        GuidanceEngine.nearbyLabel(target, [_box('cup', 0.3, 0.3, 0.6, 0.7)]),
        isNull,
      );
      expect(
        GuidanceEngine.nearbyLabel(target, [
          _box('dining table', 0.0, 0.2, 1.0, 1.0),
        ]),
        isNull,
      );
    });

    test('engine speaks nearby warning once', () {
      final e = GuidanceEngine(targetFriendlyName: 'cup');
      final others = [_box('book', 0.62, 0.3, 0.9, 0.7)];
      final g1 = e.guide(_box('cup', 0.25, 0.2, 0.65, 0.8), others: others);
      expect(
        g1.reachPhrases.join(' '),
        contains('There is also a book nearby, go slowly.'),
      );
      final g2 = e.guide(_box('cup', 0.25, 0.2, 0.65, 0.8), others: others);
      expect(g2.reachPhrases, isEmpty);
    });
  });

  group('New targets', () {
    test('new objects map to model labels and voice input', () {
      for (final n in [
        'chair',
        'bowl',
        'scissors',
        'toothbrush',
        'tv',
        'spoon',
        'fork',
        'knife',
        'laptop',
      ]) {
        expect(TargetObjects.isSupported(n), isTrue, reason: n);
      }
      expect(TargetObjects.matchVoiceInput('मेरी कुर्सी ढूंढो'), 'chair');
      expect(TargetObjects.matchVoiceInput('चम्मच कहाँ है'), 'spoon');
      expect(TargetObjects.matchVoiceInput('find my scissors'), 'scissors');
    });

    test('honest unsupported list is kept', () {
      for (final n in ['keys', 'wallet', 'glasses', 'watch', 'coin']) {
        expect(TargetObjects.unsupported, contains(n));
      }
    });
  });

  group('Localization of safe-reach phrases', () {
    final l10n = LocalizationService.instance;
    final english = {
      'safeReach': l10n.safeReachInstruction(AppLanguage.english),
      'fragile': l10n.fragileWarning(AppLanguage.english),
      'nearby': l10n.nearbyObjectWarning('bottle', AppLanguage.english),
    };

    test('every new phrase exists in all 5 languages', () {
      for (final lang in AppLanguage.values) {
        final phrases = {
          'safeReach': l10n.safeReachInstruction(lang),
          'fragile': l10n.fragileWarning(lang),
          'nearby': l10n.nearbyObjectWarning('bottle', lang),
        };
        phrases.forEach((key, text) {
          expect(text.trim(), isNotEmpty, reason: '$key/$lang');
          if (lang != AppLanguage.english) {
            expect(text, isNot(english[key]), reason: '$key/$lang untranslated');
          }
        });
      }
    });

    test('every supported target has a name in all 5 languages', () {
      for (final key in TargetObjects.supported.keys) {
        final en = l10n.objectName(key, AppLanguage.english);
        for (final lang in AppLanguage.values) {
          final name = l10n.objectName(key, lang);
          expect(name, isNotEmpty, reason: '$key/$lang');
          if (lang != AppLanguage.english) {
            expect(name, isNot(en), reason: '$key/$lang untranslated');
          }
        }
      }
    });

    test('nearby warning names the other object in the chosen language', () {
      expect(
        l10n.nearbyObjectWarning('bottle', AppLanguage.hindi),
        contains('बोतल'),
      );
      expect(
        l10n.nearbyObjectWarning('cell phone', AppLanguage.english),
        contains('phone'),
      );
    });
  });
}
