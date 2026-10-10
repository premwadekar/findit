import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_language.dart';
import '../screens/finder_screen.dart';
import 'assistant_service.dart';
import 'iris_triggers.dart';
import 'localization_service.dart';
import 'lost_phone_service.dart';
import 'settings_service.dart';
import 'speech_service.dart';

/// Executes ONE Iris command and confirms it by voice.
///
/// Flow: trigger (wake word / double Volume Up / notification / button)
/// -> native beep + "Yes, tell me" -> native listens once -> the transcript
/// arrives here -> offline intent parsing -> action -> spoken confirmation
/// -> [LostPhoneService.irisDone] so wake-word listening resumes.
///
/// Fully offline: only [AssistantService.parseOffline] is used, never the
/// optional cloud fallback. Every reply describes what actually happened.
class IrisController {
  IrisController._();
  static final IrisController instance = IrisController._();

  /// Shared with MaterialApp so commands can open screens from anywhere.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final LostPhoneService _lostPhone = LostPhoneService.instance;
  final SpeechService _speech = SpeechService();
  final TriggerDebouncer _buttonDebounce = TriggerDebouncer();
  final LocalizationService _l10n = LocalizationService.instance;

  StreamSubscription<String>? _sub;
  AppLanguage? _speechLang;
  bool _busy = false;

  /// Begins listening for commands. Call once before runApp.
  void start() {
    if (_sub != null) return;
    _lostPhone.initialize();
    _sub = _lostPhone.onVoiceCommand.listen(_handleCommand);
    // Cold start from a screen-off trigger: the command may have arrived
    // before this handler existed.
    unawaited(_lostPhone.takePendingCommand().then((cmd) {
      if (cmd != null && cmd.isNotEmpty) _handleCommand(cmd);
    }));
  }

  AppLanguage get _lang => SettingsService.instance.preferredLanguage;

  /// On-screen "Talk to Iris" button. Arms Iris first if it is off, then
  /// starts a session exactly like the other triggers.
  /// Returns false if the press was debounced or Iris could not start.
  Future<bool> talk() async {
    if (!_buttonDebounce.accept(DateTime.now().millisecondsSinceEpoch)) {
      return false;
    }
    if (!_lostPhone.isRunning) {
      final ok = await _lostPhone.startLostPhoneMode();
      if (!ok) return false;
      // Wait (briefly) for the foreground service to come up.
      for (var i = 0; i < 10 && !_lostPhone.isRunning; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        await _lostPhone.refreshState();
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
    return _lostPhone.talkToIris();
  }

  Future<void> _say(String text) async {
    final lang = _lang;
    if (_speechLang != lang) {
      await _speech.initialize(language: lang);
      _speechLang = lang;
    }
    await _speech.speak(text, urgent: true);
  }

  Future<void> _handleCommand(String command) async {
    if (_busy || command.trim().isEmpty) return;
    _busy = true;
    try {
      final lang = _lang;
      final res = AssistantService.instance.parseOffline(
        command,
        language: lang,
      );

      switch (res.intent) {
        case AssistantIntent.findObject:
          if (res.isUnsupported || res.target == null) {
            await _say(res.spokenReply ?? _l10n.unsupportedObject(lang));
          } else if (_openFinder(res.target!)) {
            // FinderScreen announces "Searching for <object>" itself.
          } else {
            await _say(_l10n.irisCantDoThat(lang));
          }
        case AssistantIntent.lostPhone:
          await _say(_l10n.lostPhoneAlert(lang));
          if (!await _lostPhone.ringAlarm()) {
            await _say(_l10n.irisCantDoThat(lang));
          }
        case AssistantIntent.stopAlarm:
          if (_lostPhone.isAlarmRinging) {
            // Native + screen listeners announce "Alarm silenced".
            await _lostPhone.stopAlarm();
          } else {
            await _say(_l10n.noAlarmRinging(lang));
          }
        case AssistantIntent.battery:
          final pct = await _lostPhone.batteryPercent();
          await _say(
            pct == null
                ? _l10n.batteryUnavailable(lang)
                : _l10n.batteryLevel(pct, lang),
          );
        case AssistantIntent.time:
          await _say(_l10n.timeIs(DateTime.now(), lang));
        case AssistantIntent.describeSurroundings:
          // No scene-summary feature exists yet: say so instead of inventing one.
          await _say(_l10n.surroundingsUnavailable(lang));
        case AssistantIntent.irisWakeup:
        case AssistantIntent.settings:
        case AssistantIntent.help:
        case AssistantIntent.helpMeUnderstand:
        case AssistantIntent.unknown:
          await _say(_l10n.irisCantDoThat(lang));
      }
    } catch (_) {
      // A failed command must never leave the microphone loop stuck.
    } finally {
      _busy = false;
      await _lostPhone.irisDone();
    }
  }

  bool _openFinder(String target) {
    final nav = navigatorKey.currentState;
    if (nav == null) return false;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => FinderScreen(initialTarget: target)),
      (route) => route.isFirst,
    );
    return true;
  }
}

