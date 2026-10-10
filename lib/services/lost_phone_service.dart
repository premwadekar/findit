import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'iris_permissions.dart';
import 'iris_triggers.dart';
import 'localization_service.dart';
import 'settings_service.dart';

/// Service managing Android Compliant Foreground Microphone Service for Lost Phone Mode.
///
/// Features:
/// - Microphone is strictly kept OFF during normal app use.
/// - Only when Lost Phone Mode is enabled, requests RECORD_AUDIO and POST_NOTIFICATIONS
///   and starts a compliant Android foreground service with microphone type.
/// - Continuous hotword listener watches for "Hey Iris" (or "Find my phone").
/// - When detected, triggers max-volume alarm and SOS vibration.
/// - Automatically shuts off after [timeoutMinutes] (default 20 min) or on battery low
///   to prevent draining phone battery.
class LostPhoneService extends ChangeNotifier {
  LostPhoneService._();
  static final LostPhoneService instance = LostPhoneService._();

  static const MethodChannel _channel = MethodChannel('com.findit.findit/lost_phone');

  bool _initialized = false;
  bool _isRunning = false;
  bool _isAlarmRinging = false;
  String? _triggeredPhrase;
  String? _lastError;
  String? _lastVoiceCommand;
  DateTime? _lastVoiceCommandTime;

  bool get isRunning => _isRunning;
  bool get isAlarmRinging => _isAlarmRinging;
  String? get triggeredPhrase => _triggeredPhrase;
  String? get lastError => _lastError;

  final StreamController<bool> _runningController = StreamController<bool>.broadcast();
  final StreamController<bool> _alarmController = StreamController<bool>.broadcast();
  final StreamController<void> _alarmStoppedController = StreamController<void>.broadcast();
  final StreamController<String> _triggerController = StreamController<String>.broadcast();
  final StreamController<String> _irisWakeupController = StreamController<String>.broadcast();
  final StreamController<String> _voiceCommandController = StreamController<String>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  Stream<bool> get onRunningChanged => _runningController.stream;
  Stream<bool> get onAlarmChanged => _alarmController.stream;
  Stream<void> get onAlarmStopped => _alarmStoppedController.stream;
  Stream<String> get onTriggerDetected => _triggerController.stream;
  Stream<String> get onIrisWakeup => _irisWakeupController.stream;
  Stream<String> get onVoiceCommand => _voiceCommandController.stream;
  Stream<String> get onErrorOccurred => _errorController.stream;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_handleNativeCallback);
    refreshState();
  }

  Future<void> refreshState() async {
    try {
      final running = await _channel.invokeMethod<bool>('isServiceRunning') ?? false;
      final alarm = await _channel.invokeMethod<bool>('isAlarmRinging') ?? false;
      _isRunning = running;
      _isAlarmRinging = alarm;
      notifyListeners();
      if (running) syncIrisConfig();
    } catch (_) {}
  }

  Future<void> _handleNativeCallback(MethodCall call) async {
    switch (call.method) {
      case 'onServiceStateChanged':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final running = args?['isRunning'] as bool? ?? false;
        _isRunning = running;
        if (!running) {
          _isAlarmRinging = false;
        }
        _runningController.add(running);
        notifyListeners();
        break;

      case 'onAlarmTriggered':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final phrase = args?['phrase'] as String? ?? 'Hey Iris';
        _isAlarmRinging = true;
        _triggeredPhrase = phrase;
        _alarmController.add(true);
        _triggerController.add(phrase);
        notifyListeners();
        break;

      case 'onAlarmStopped':
        _isAlarmRinging = false;
        _alarmController.add(false);
        _alarmStoppedController.add(null);
        notifyListeners();
        break;

      case 'onIrisWakeup':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final phrase = args?['phrase'] as String? ?? 'Hey Iris';
        _irisWakeupController.add(phrase);
        notifyListeners();
        break;

      case 'onVoiceCommand':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final command = args?['command'] as String? ?? '';
        final now = DateTime.now();
        if (command.isNotEmpty) {
          if (_lastVoiceCommand == command &&
              _lastVoiceCommandTime != null &&
              now.difference(_lastVoiceCommandTime!) < const Duration(milliseconds: 1500)) {
            break;
          }
          _lastVoiceCommand = command;
          _lastVoiceCommandTime = now;
          _voiceCommandController.add(command);
          notifyListeners();
        }
        break;

      case 'onServiceError':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final error = args?['error'] as String? ?? 'Unknown error';
        _lastError = error;
        _errorController.add(error);
        notifyListeners();
        break;
    }
  }

  /// Checks and requests necessary permissions (Microphone + Notifications).
  /// Returns a status result with diagnostic information.
  Future<({bool success, String? message})> checkAndRequestPermissions() async {
    // 1. Microphone permission
    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        return (
          success: false,
          message: 'Microphone permission is required to listen for "Hey Iris".',
        );
      }
    }

    // 2. Notification permission (Android 13+ / API 33+)
    var notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      notifStatus = await Permission.notification.request();
      if (!notifStatus.isGranted) {
        return (
          success: false,
          message:
              'Notification permission is required to keep Lost Phone Mode active in the background.',
        );
      }
    }

    return (success: true, message: null);
  }

  /// Starts compliant foreground microphone service with [timeoutMinutes] auto-shutoff.
  Future<bool> startLostPhoneMode({int timeoutMinutes = 20}) async {
    initialize();
    _lastError = null;

    final permCheck = await checkAndRequestPermissions();
    if (!permCheck.success) {
      _lastError = permCheck.message;
      notifyListeners();
      return false;
    }

    try {
      final success = await _channel.invokeMethod<bool>(
            'startLostPhoneMode',
            {
              'timeoutMinutes': timeoutMinutes,
              'config': _irisConfig(timeoutMinutes),
            },
          ) ??
          false;
      if (success) {
        _isRunning = true;
        _isAlarmRinging = false;
        _timeoutMinutes = timeoutMinutes;
        notifyListeners();
      }
      return success;
    } on PlatformException catch (e) {
      _lastError = e.message ?? 'Failed to start Lost Phone Mode.';
      notifyListeners();
      return false;
    }
  }

  /// Stops Lost Phone Mode foreground service completely.
  Future<bool> stopLostPhoneMode() async {
    initialize();
    try {
      final success =
          await _channel.invokeMethod<bool>('stopLostPhoneMode') ?? false;
      _isRunning = false;
      _isAlarmRinging = false;
      notifyListeners();
      return success;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Silences an actively ringing alarm without stopping the service.
  Future<bool> stopAlarm() async {
    initialize();
    try {
      final success = await _channel.invokeMethod<bool>('stopAlarm') ?? false;
      _isAlarmRinging = false;
      notifyListeners();
      return success;
    } catch (e) {
      return false;
    }
  }

  int? _timeoutMinutes;

  /// Strings and wake-word pattern the native service needs. Dart owns all
  /// user-facing text so every language lives in LocalizationService.
  Map<String, String> _irisConfig(int? minutes) {
    final lang = SettingsService.instance.preferredLanguage;
    final l10n = LocalizationService.instance;
    return {
      'wake_pattern': IrisWakeWord.pattern,
      'yes_tell_me': l10n.yesTellMe(lang),
      'didnt_hear': l10n.didntHearAnything(lang),
      if (minutes != null)
        'notif_text': l10n.irisNotificationText(minutes, lang),
      'talk_action': l10n.talkToIris(lang),
      'listening_title': l10n.irisListeningTitle(lang),
      'fsi_title': l10n.fsiNotifTitle(lang),
      'fsi_text': l10n.fsiNotifText(lang),
      'fsi_action': l10n.allowScreenWake(lang),
    };
  }

  /// Re-sends strings (e.g. after a language change) to a running service.
  Future<void> syncIrisConfig() async {
    if (!_isRunning) return;
    try {
      await _channel.invokeMethod('updateIrisConfig', {
        'config': _irisConfig(_timeoutMinutes),
      });
    } catch (_) {}
  }

  /// Starts one Iris session (beep, "Yes, tell me", listen once).
  /// The service must be armed; the native side debounces repeat triggers.
  Future<bool> talkToIris() async {
    initialize();
    try {
      return await _channel.invokeMethod<bool>('talkToIris') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Tells the service the spoken reply finished so it can resume wake-word
  /// listening (prevents the mic hearing Iris's own voice).
  Future<void> irisDone() async {
    try {
      await _channel.invokeMethod('irisDone');
    } catch (_) {}
  }

  /// Whether the Iris accessibility service is on and full-screen
  /// notifications are allowed. Returns [HandsFreeStatus.unknown] on error.
  Future<HandsFreeStatus> handsFreeStatus() async {
    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getHandsFreeStatus',
      );
      return HandsFreeStatus.fromMap(map);
    } catch (_) {
      return HandsFreeStatus.unknown;
    }
  }

  Future<bool> openAccessibilitySettings() async {
    try {
      return await _channel.invokeMethod<bool>('openAccessibilitySettings') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openFullScreenSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openFullScreenSettings') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// A command heard while the app was not ready to receive it (cold start).
  Future<String?> takePendingCommand() async {
    try {
      return await _channel.invokeMethod<String>('takePendingCommand');
    } catch (_) {
      return null;
    }
  }

  /// Battery percentage from the OS, or null when unavailable.
  Future<int?> batteryPercent() async {
    try {
      final v = await _channel.invokeMethod<int>('getBatteryPercent');
      return (v == null || v < 0) ? null : v;
    } catch (_) {
      return null;
    }
  }

  /// Rings the loud alarm because the user asked Iris where the phone is.
  Future<bool> ringAlarm() async {
    initialize();
    try {
      return await _channel.invokeMethod<bool>('ringAlarm') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sounds a loud test alert and vibration to verify loudness before leaving phone.
  Future<bool> testAlarm() async {
    initialize();
    try {
      return await _channel.invokeMethod<bool>('testAlarm') ?? false;
    } catch (_) {
      return false;
    }
  }
}
