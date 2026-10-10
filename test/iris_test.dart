import 'package:findit/models/app_language.dart';
import 'package:findit/services/assistant_service.dart';
import 'package:findit/services/iris_triggers.dart';
import 'package:findit/services/localization_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Wake word', () {
    test('matches Hey Iris and common mis-hearings', () {
      for (final s in [
        'hey iris',
        'Hey Iris',
        'hi iris',
        'okay iris',
        'iris',
        'hey iris find my bottle',
        'hay airis',
        'hey harris',
        'hey it is',
        'hi irish',
        'hello iris',
      ]) {
        expect(IrisWakeWord.matches(s), isTrue, reason: s);
      }
    });

    test('matches Hindi, Kannada, Telugu and Tamil variants', () {
      for (final s in [
        'हे आइरिस',
        'आयरिस',
        'हेलो आईरिस',
        'ಹೇ ಐರಿಸ್',
        'ಐರಿಸ್',
        'హే ఐరిస్',
        'ஹே ஐரிஸ்',
      ]) {
        expect(IrisWakeWord.matches(s), isTrue, reason: s);
      }
    });

    test('does not fire on ordinary speech', () {
      for (final s in [
        'it is raining',
        'here is the book',
        'irish coffee',
        'harry potter',
        'find my bottle',
        'what time is it',
        'where are you',
        '',
      ]) {
        expect(IrisWakeWord.matches(s), isFalse, reason: s);
      }
    });

    test('stripPrefix returns the command after the wake word', () {
      expect(
        IrisWakeWord.stripPrefix('Hey Iris, find my bottle'),
        'find my bottle',
      );
      expect(IrisWakeWord.stripPrefix('iris battery'), 'battery');
      expect(IrisWakeWord.stripPrefix('hey iris'), '');
      expect(IrisWakeWord.stripPrefix('हे आइरिस बोतल ढूंढो'), 'बोतल ढूंढो');
      expect(IrisWakeWord.stripPrefix('find my bottle'), 'find my bottle');
    });
  });

  group('DoublePressDetector', () {
    test('two presses inside the window trigger once', () {
      final d = DoublePressDetector(windowMs: 600);
      expect(d.onPress(1000), isFalse);
      expect(d.onPress(1400), isTrue);
      // The pair is consumed: a third press starts a new pair.
      expect(d.onPress(1500), isFalse);
    });

    test('slow second press does not trigger', () {
      final d = DoublePressDetector(windowMs: 600);
      expect(d.onPress(0), isFalse);
      expect(d.onPress(601), isFalse);
      expect(d.onPress(900), isTrue);
    });

    test('same physical press seen twice (bounce) is ignored', () {
      final d = DoublePressDetector(windowMs: 600, bounceMs: 40);
      expect(d.onPress(1000), isFalse);
      expect(d.onPress(1010), isFalse);
      expect(d.onPress(1300), isTrue);
    });

    test('reset clears a pending first press', () {
      final d = DoublePressDetector();
      d.onPress(100);
      d.reset();
      expect(d.onPress(300), isFalse);
    });
  });

  group('TriggerDebouncer', () {
    test('one trigger never fires twice within the cooldown', () {
      final t = TriggerDebouncer(cooldownMs: 2000);
      expect(t.accept(10000), isTrue);
      expect(t.accept(10001), isFalse);
      expect(t.accept(11999), isFalse);
      expect(t.accept(12000), isTrue);
    });
  });

  group('Offline intent matching', () {
    final a = AssistantService.instance;
    IntentResult parse(String s, [AppLanguage l = AppLanguage.english]) =>
        a.parseOffline(s, language: l);

    test('find my <object> resolves the target', () {
      final r = parse('find my bottle');
      expect(r.intent, AssistantIntent.findObject);
      expect(r.target, 'bottle');
      expect(parse('मेरी बोतल ढूंढो', AppLanguage.hindi).target, 'bottle');
    });

    test('unsupported objects stay honest', () {
      expect(parse('find my keys').isUnsupported, isTrue);
      expect(
        parse('मेरी चाबी ढूंढो', AppLanguage.hindi).isUnsupported,
        isTrue,
      );
    });

    test('where are you / find my phone ring the phone', () {
      expect(parse('where are you').intent, AssistantIntent.lostPhone);
      expect(parse('find my phone').intent, AssistantIntent.lostPhone);
      expect(
        parse('फोन ढूंढो', AppLanguage.hindi).intent,
        AssistantIntent.lostPhone,
      );
    });

    test('stop / silence', () {
      expect(parse('stop').intent, AssistantIntent.stopAlarm);
      expect(parse('silence the alarm').intent, AssistantIntent.stopAlarm);
      expect(
        parse('बंद करो', AppLanguage.hindi).intent,
        AssistantIntent.stopAlarm,
      );
      expect(
        parse('ఆపు', AppLanguage.telugu).intent,
        AssistantIntent.stopAlarm,
      );
    });

    test('battery and time win over object words', () {
      expect(
        parse('what is the battery of my phone').intent,
        AssistantIntent.battery,
      );
      expect(parse('battery').intent, AssistantIntent.battery);
      expect(
        parse('बैटरी कितनी है', AppLanguage.hindi).intent,
        AssistantIntent.battery,
      );
      expect(parse('what time is it').intent, AssistantIntent.time);
      expect(parse("what's the time").intent, AssistantIntent.time);
      expect(
        parse('कितने बजे हैं', AppLanguage.hindi).intent,
        AssistantIntent.time,
      );
    });

    test('around me is recognised (the controller answers honestly)', () {
      expect(
        parse('what is around me').intent,
        AssistantIntent.describeSurroundings,
      );
    });

    test('anything else is unknown, never invented', () {
      expect(parse('tell me a joke').intent, AssistantIntent.unknown);
      expect(parse('order a pizza').intent, AssistantIntent.unknown);
    });

    test('commands survive a leading wake word', () {
      expect(parse('hey iris find my cup').target, 'cup');
      expect(parse('iris battery').intent, AssistantIntent.battery);
    });
  });

  group('Iris localization completeness', () {
    final l = LocalizationService.instance;
    final now = DateTime(2026, 1, 1, 15, 5);

    Map<String, String> phrases(AppLanguage lang) => {
      'yesTellMe': l.yesTellMe(lang),
      'didntHear': l.didntHearAnything(lang),
      'cantDoThat': l.irisCantDoThat(lang),
      'armed': l.irisArmed(20, lang),
      'disarmed': l.irisDisarmed(lang),
      'notification': l.irisNotificationText(20, lang),
      'talk': l.talkToIris(lang),
      'statusOn': l.irisStatusOn(lang),
      'statusOff': l.irisStatusOff(lang),
      'battery': l.batteryLevel(80, lang),
      'batteryUnavailable': l.batteryUnavailable(lang),
      'time': l.timeIs(now, lang),
      'noAlarm': l.noAlarmRinging(lang),
      'surroundings': l.surroundingsUnavailable(lang),
    };

    test('every phrase exists, is non-empty and translated in all 5 languages',
        () {
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

    test('numbers and times are interpolated', () {
      expect(l.irisArmed(20, AppLanguage.hindi), contains('20'));
      expect(l.batteryLevel(80, AppLanguage.tamil), contains('80'));
      expect(l.timeIs(now, AppLanguage.english), 'The time is 3:05 PM.');
      expect(l.timeIs(now, AppLanguage.hindi), contains('15:05'));
    });
  });
}
