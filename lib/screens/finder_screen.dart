import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_language.dart';
import '../models/detection.dart';
import '../models/target_objects.dart';
import '../services/detection_service.dart';
import '../services/guidance_engine.dart';
import '../services/haptic_service.dart';
import '../services/localization_service.dart';
import '../services/object_tracker.dart';
import '../services/settings_service.dart';
import '../services/speech_service.dart';
import '../services/startup_guard.dart';
import '../theme/app_theme.dart';
import '../widgets/detection_overlay.dart';
import 'found_screen.dart';
import 'object_selection_screen.dart';

/// Screen 3 — Modern, Accessible Camera Guidance HUD
///
/// Features:
/// - Edge-to-edge camera viewport with high-contrast HUD elements.
/// - Clear search and real-time guidance telemetry pill.
/// - Live visual directional cues (panning arrows) complementing voice & haptics.
/// - Large, unmistakable STOP control for instant cancellation.
/// - Quick-target horizontal switch bar.
class FinderScreen extends StatefulWidget {
  const FinderScreen({super.key, this.initialTarget = 'bottle'});

  final String initialTarget;

  @override
  State<FinderScreen> createState() => _FinderScreenState();
}

class _FinderScreenState extends State<FinderScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  DetectionService _detections = DetectionService();
  final ObjectTracker _tracker = ObjectTracker();
  final SpeechService _speech = SpeechService();
  final HapticService _haptics = HapticService();
  final SettingsService _settings = SettingsService.instance;
  final LocalizationService _l10n = LocalizationService.instance;

  StreamSubscription<DetectionFrame>? _sub;
  GuidanceEngine? _guidance;

  late String _targetFriendly;
  List<Detection> _latest = const [];
  Detection? _tracked;
  Guidance _guidanceState = Guidance.lost;

  String _status = 'Starting camera and vision system...';
  bool _failed = false;
  bool _scanning = false;
  bool _foundHandled = false;
  int _lastInferenceMs = 0;
  DateTime _lastSubmit = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastHaptic = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _searchStartTime = DateTime.now();
  DateTime _lastUncertainSpoken = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastScanRoomPrompt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastGuidanceSpoken = DateTime.fromMillisecondsSinceEpoch(0);
  HorizontalZone? _lastZone;
  bool _wasTracking = false;
  StartupFailure _failure = StartupFailure.none;
  AppLifecycleState? _lastLifecycle;

  AppLanguage get _lang => _settings.preferredLanguage;
  String get _targetModelLabel =>
      TargetObjects.modelLabelFor(_targetFriendly) ?? '';
  String get _localizedTargetName => _l10n.objectName(_targetFriendly, _lang);

  @override
  void initState() {
    super.initState();
    _targetFriendly = widget.initialTarget;
    _guidance = GuidanceEngine(
      targetFriendlyName: _targetFriendly,
      language: _lang,
    );
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  Future<void> _boot() async {
    CameraController? controller;
    try {
      final cam = await Permission.camera.request();
      final denied = StartupGuard.permissionOutcome(
        isGranted: cam.isGranted,
        isPermanentlyDenied: cam.isPermanentlyDenied,
      );
      if (denied != StartupFailure.none) {
        _showFailure(denied);
        return;
      }

      setState(() => _status = 'Loading on-device model...');
      try {
        await _detections.initialize();
      } catch (_) {
        _showFailure(StartupFailure.modelLoad);
        return;
      }
      final langResult = await _speech.initialize(language: _lang);
      if (langResult != null && !langResult.isSupported && _lang != AppLanguage.english) {
        _settings.setPreferredLanguage(AppLanguage.english);
        _guidance = GuidanceEngine(
          targetFriendlyName: _targetFriendly,
          language: AppLanguage.english,
        );
      }
      await _haptics.initialize();

      List<CameraDescription> cameras;
      try {
        cameras = await availableCameras();
      } catch (_) {
        cameras = const [];
      }
      if (cameras.isEmpty) {
        _showFailure(StartupFailure.noCamera);
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      try {
        await controller.initialize();
      } catch (_) {
        _showFailure(StartupFailure.cameraInit);
        return;
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _camera = controller;
      controller = null; // now owned by _camera (disposed in dispose/_retry)
      _sub = _detections.results.listen(_onResults);

      _searchStartTime = DateTime.now();
      final startPhrase = _l10n.searchingTarget(_targetFriendly, _lang);
      setState(() {
        _scanning = true;
        _status = startPhrase;
      });

      await _speech.speak(startPhrase, urgent: true);
      await _camera!.startImageStream(_onImage);
    } catch (_) {
      await controller?.dispose();
      if (!mounted) return;
      _showFailure(StartupFailure.cameraInit);
    }
  }

  /// Shows a localized, spoken explanation and switches to the error screen,
  /// which offers the actions that can actually fix this failure.
  void _showFailure(StartupFailure failure) {
    if (!mounted) return;
    final lang = _lang;
    final message = switch (failure) {
      StartupFailure.permissionDenied => _l10n.cameraPermissionNeeded(lang),
      StartupFailure.permissionPermanentlyDenied => _l10n.cameraPermissionBlocked(lang),
      StartupFailure.noCamera => _l10n.noCameraFound(lang),
      StartupFailure.modelLoad => _l10n.modelLoadFailed(lang),
      _ => _l10n.cameraStartFailed(lang),
    };
    setState(() {
      _failed = true;
      _failure = failure;
      _scanning = false;
      _status = message;
    });
    () async {
      await _speech.initialize(language: lang);
      await _speech.speak(message, urgent: true);
    }();
  }

  /// Tears down the failed attempt and boots again (new detector, new camera).
  void _retry() {
    _camera?.dispose().catchError((_) {});
    _camera = null;
    _sub?.cancel();
    _sub = null;
    _detections.dispose();
    _detections = DetectionService();
    setState(() {
      _failed = false;
      _failure = StartupFailure.none;
      _status = 'Starting camera and vision system...';
    });
    _boot();
  }

  /// Stops the camera stream when the app is hidden and restarts it on return.
  /// If the OS took the camera away, a full retry is used instead.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previous = _lastLifecycle ?? AppLifecycleState.resumed;
    _lastLifecycle = state;
    final action = StartupGuard.lifecycleAction(previous, state);

    if (action == LifecycleAction.pauseCamera) {
      _camera?.stopImageStream().catchError((_) {});
      return;
    }
    if (action != LifecycleAction.resumeCamera) return;

    // Back in front: the permission may have been granted in app settings.
    if (_failed) {
      if (StartupGuard.offersSettingsButton(_failure)) _retry();
      return;
    }
    final camera = _camera;
    if (camera == null || !_scanning) return;
    if (!camera.value.isInitialized) {
      _retry();
      return;
    }
    camera
        .startImageStream(_onImage)
        .catchError((_) => _showFailure(StartupFailure.cameraInit));
  }

  void _onImage(CameraImage image) {
    if (!_scanning || _foundHandled) return;

    final now = DateTime.now();
    // Throttle frames submitted to the isolate: at most one every 280ms
    if (now.difference(_lastSubmit).inMilliseconds < 280) return;
    _lastSubmit = now;

    final camera = _camera;
    if (camera == null) return;

    try {
      final u = image.planes[1];
      _detections.submitFrame(
        y: image.planes[0].bytes,
        u: u.bytes,
        v: image.planes[2].bytes,
        width: image.width,
        height: image.height,
        yRowStride: image.planes[0].bytesPerRow,
        uvRowStride: u.bytesPerRow,
        uvPixelStride: u.bytesPerPixel ?? 1,
        rotation: camera.description.sensorOrientation,
        threshold: _settings.confidenceThreshold - 0.10,
      );
    } catch (_) {}
  }

  Future<void> _onResults(DetectionFrame frame) async {
    if (!mounted || !_scanning || _foundHandled) return;
    final engine = _guidance;
    if (engine == null) return;

    _lastInferenceMs = frame.inferenceMs;
    final targetLabel = _targetModelLabel;

    final targetCandidates = frame.detections
        .where((d) => d.label == targetLabel)
        .toList();
    final confidentDetections = targetCandidates
        .where((d) => d.confidence >= _settings.confidenceThreshold)
        .toList();
    final marginalDetections = targetCandidates
        .where((d) => d.confidence < _settings.confidenceThreshold)
        .toList();

    final bool isUncertain =
        confidentDetections.isEmpty &&
        marginalDetections.isNotEmpty &&
        _tracked == null;

    final tracked = _tracker.update(confidentDetections, targetLabel);
    final g = engine.guide(
      tracked,
      isCandidateUncertain: isUncertain,
      others: frame.detections.where((d) => d.label != targetLabel).toList(),
    );

    final now = DateTime.now();

    // Scan room prompt if nothing found after 12s
    if (tracked == null &&
        !isUncertain &&
        now.difference(_searchStartTime).inSeconds >= 12) {
      if (now.difference(_lastScanRoomPrompt).inSeconds >= 15) {
        _lastScanRoomPrompt = now;
        final scanMsg = _l10n.scanRoom(_lang);
        await _speech.speak(scanMsg);
        if (!mounted) return;
        setState(() => _status = scanMsg);
        return;
      }
    }

    // Acquired / Lost haptics & announcements
    if (tracked != null && !_wasTracking) {
      _wasTracking = true;
      _lastZone = g.zone;
      _lastGuidanceSpoken = now;
      setState(() {
        _tracked = tracked;
        _latest = frame.detections;
        _guidanceState = g;
        _status = _l10n.objectDetected(_targetFriendly, _lang);
      });
      await _haptics.acquired();
      await _speech.speak(
        _l10n.objectDetected(_targetFriendly, _lang),
        urgent: true,
      );
      return;
    } else if (tracked == null && _wasTracking) {
      _wasTracking = false;
      _lastZone = null;
      setState(() {
        _tracked = null;
        _latest = frame.detections;
        _guidanceState = g;
        _status = _l10n.objectLost(_lang);
      });
      await _haptics.lost();
      await _speech.speak(_l10n.objectLost(_lang), urgent: true);
      return;
    }
    _wasTracking = tracked != null;

    // Found state
    if (g.isFound && !_foundHandled) {
      _foundHandled = true;
      setState(() {
        _tracked = tracked;
        _latest = frame.detections;
        _guidanceState = g;
        _status = g.phrase;
      });

      // Stage 2: safe reach. One calm sequence, long gentle haptic, no repeats.
      _haptics.safeReachPattern();
      final spoken = g.reachPhrases.isEmpty ? [g.phrase] : g.reachPhrases;
      for (final p in spoken) {
        if (!mounted) return;
        await _speech.speak(p, urgent: true, calm: true);
      }

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FoundScreen(targetFriendly: _targetFriendly),
          ),
        );
      });
      return;
    }

    // Proximity haptics
    if (tracked != null && _settings.hapticFeedback) {
      final int intervalMs = switch (g.proximity) {
        Proximity.far => 1400,
        Proximity.approaching => 750,
        Proximity.close => 380,
        Proximity.veryClose => 220,
      };

      if (now.difference(_lastHaptic).inMilliseconds > intervalMs) {
        _lastHaptic = now;
        _haptics.proximityTick(g.proximity);
      }
    }

    // Uncertainty voice prompt
    if (isUncertain && now.difference(_lastUncertainSpoken).inSeconds > 6) {
      _lastUncertainSpoken = now;
      await _speech.speak(g.phrase);
    }

    // Directional voice guidance
    if (tracked != null && !g.isFound) {
      final zoneChanged = _lastZone != g.zone;
      final stateProgressed =
          g.state == GuidanceState.closer || g.state == GuidanceState.near;
      final periodicReminder =
          now.difference(_lastGuidanceSpoken).inSeconds >= 5;

      if (zoneChanged || stateProgressed || periodicReminder) {
        _lastZone = g.zone;
        _lastGuidanceSpoken = now;
        await _speech.speak(g.phrase);
      }
    }

    if (!mounted) return;
    setState(() {
      _latest = frame.detections;
      _tracked = tracked;
      _guidanceState = g;
      _status = g.phrase;
    });
  }

  void _stopAndExit() {
    _speech.stop();
    Navigator.of(context).pop();
  }

  void _toggleScanning() {
    if (_scanning) {
      setState(() {
        _scanning = false;
        _status = 'Scanning paused.';
      });
      _speech.speak('Scanning paused.');
    } else {
      _tracker.reset();
      _guidance?.reset();
      _foundHandled = false;
      _wasTracking = false;
      _lastZone = null;
      _searchStartTime = DateTime.now();
      setState(() {
        _scanning = true;
        _status = _l10n.searchingTarget(_targetFriendly, _lang);
      });
      _speech.speak(_l10n.searchingTarget(_targetFriendly, _lang));
    }
  }

  void _selectTarget(String friendly) {
    if (_targetFriendly == friendly) return;
    setState(() {
      _targetFriendly = friendly;
      _guidance = GuidanceEngine(targetFriendlyName: friendly, language: _lang);
      _tracker.reset();
      _tracked = null;
      _wasTracking = false;
      _foundHandled = false;
      _lastZone = null;
      _searchStartTime = DateTime.now();
      _status = _l10n.searchingTarget(friendly, _lang);
    });
    _speech.speak(_l10n.searchingTarget(friendly, _lang), urgent: true);
  }

  void _openSelectionScreen() {
    _speech.stop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ObjectSelectionScreen()),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _camera?.stopImageStream().catchError((_) {});
    _camera?.dispose();
    _detections.dispose();
    _speech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    final g = _guidanceState;
    final targetIcon = TargetObjects.iconFor(_targetFriendly);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          tooltip: 'Back to home',
          onPressed: _stopAndExit,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(targetIcon, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finding ${_capitalize(_localizedTargetName)}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _scanning ? 'Active Camera Tracking' : 'Paused',
                    style: TextStyle(
                      color: _scanning ? AppTheme.success : AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.swap_horiz_rounded,
              color: AppTheme.primary,
              size: 28,
            ),
            tooltip: 'Change target object',
            onPressed: _openSelectionScreen,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _failed
          ? _errorBody()
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Camera Preview + High-Contrast HUD Stack
                  Expanded(
                    flex: 6,
                    child: camera == null || !camera.value.isInitialized
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                              strokeWidth: 4,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(camera),

                                // Real-time reticle overlay
                                DetectionOverlay(
                                  detections: _tracked == null
                                      ? _latest
                                      : [
                                          _tracked!,
                                          ..._latest.where(
                                            (d) => d.label != _targetModelLabel,
                                          ),
                                        ],
                                  targetModelLabel: _targetModelLabel,
                                  isTargetLocked: _tracked != null,
                                ),

                                // Top Telemetry Pill (Status + Zone)
                                Positioned(
                                  top: 14,
                                  left: 14,
                                  right: 14,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // State Pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.background.withValues(
                                            alpha: 0.88,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusFull,
                                          ),
                                          border: Border.all(
                                            color: _tracked != null
                                                ? AppTheme.success
                                                : AppTheme.borderSubtle,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: _tracked != null
                                                    ? AppTheme.success
                                                    : AppTheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              g.state.name.toUpperCase(),
                                              style: TextStyle(
                                                color: _tracked != null
                                                    ? AppTheme.success
                                                    : AppTheme.textPrimary,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Distance / FPS pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.background.withValues(
                                            alpha: 0.88,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusFull,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.borderSubtle,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.sensors_rounded,
                                              size: 15,
                                              color: AppTheme.telemetry,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _tracked != null
                                                  ? '${(_tracked!.confidence * 100).round()}% MATCH'
                                                  : 'SCANNING',
                                              style: const TextStyle(
                                                color: AppTheme.telemetry,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Visual Directional Cue (Arrow Indicator for Panning)
                                if (_tracked != null && !g.isFound)
                                  _buildDirectionalArrow(g.zone),

                                // Debug stats HUD (if enabled in settings)
                                if (_settings.showDebugStats)
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.85,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppTheme.success,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Latency: ${_lastInferenceMs}ms',
                                            style: const TextStyle(
                                              color: AppTheme.success,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Target: $_targetModelLabel',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (_tracked != null)
                                            Text(
                                              'Area: ${(_tracked!.area * 100).toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                color: AppTheme.primary,
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),

                  // Large High-Contrast Spoken Guidance Card
                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _foundHandled
                            ? AppTheme.success
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(
                          color: _foundHandled
                              ? AppTheme.success
                              : _tracked != null
                              ? AppTheme.primary
                              : AppTheme.borderSubtle,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _status,
                              style: TextStyle(
                                color: _foundHandled
                                    ? Colors.black
                                    : AppTheme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_scanning && !_foundHandled && _tracked != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.vibration_rounded,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _proximityLabel(g.proximity),
                                  style: const TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Controls Tray (Large STOP Button & Quick Targets)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    color: Colors.black,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            // Massive, Unmistakable STOP Action
                            Expanded(
                              flex: 3,
                              child: Semantics(
                                button: true,
                                label: 'Stop finding and return home',
                                child: ElevatedButton.icon(
                                  onPressed: _stopAndExit,
                                  icon: const Icon(
                                    Icons.stop_circle_rounded,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                  label: Text(_l10n.stop(_lang).toUpperCase()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.error,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: AppTheme.error.withValues(
                                      alpha: 0.4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd,
                                      ),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Pause / Resume Scanning
                            Expanded(
                              flex: 2,
                              child: Semantics(
                                button: true,
                                label: _scanning
                                    ? 'Pause scanning'
                                    : 'Resume scanning',
                                child: OutlinedButton.icon(
                                  onPressed: camera == null
                                      ? null
                                      : _toggleScanning,
                                  icon: Icon(
                                    _scanning
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 24,
                                    color: AppTheme.primary,
                                  ),
                                  label: Text(_scanning ? 'PAUSE' : 'RESUME'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    side: const BorderSide(
                                      color: AppTheme.primary,
                                      width: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd,
                                      ),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Quick Target Switch Bar
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: TargetObjects.supported.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final name = TargetObjects.supported.keys
                                  .elementAt(i);
                              final localized = _l10n.objectName(name, _lang);
                              final isSelected = name == _targetFriendly;
                              return ChoiceChip(
                                label: Text(
                                  localized[0].toUpperCase() +
                                      localized.substring(1),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.black
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppTheme.primary,
                                backgroundColor: AppTheme.surfaceElevated,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.borderSubtle,
                                ),
                                onSelected: (_) => _selectTarget(name),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDirectionalArrow(HorizontalZone zone) {
    if (zone == HorizontalZone.center) {
      return Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 24),
              SizedBox(width: 6),
              Text(
                'STRAIGHT AHEAD',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isLeft =
        zone == HorizontalZone.left || zone == HorizontalZone.slightlyLeft;
    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.5),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isLeft ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
          color: Colors.black,
          size: 36,
        ),
      ),
    );
  }

  String _proximityLabel(Proximity p) => switch (p) {
    Proximity.far => 'Far away • Pan around slowly',
    Proximity.approaching => 'Getting closer • Keep phone steady',
    Proximity.close => 'Very close • Reach out gently',
    Proximity.veryClose => 'Right in front of your hands!',
  };

  Widget _errorBody() {
    final lang = _lang;
    final canOpenSettings = StartupGuard.offersSettingsButton(_failure);
    final canRetry = StartupGuard.offersRetry(_failure);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                _status,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            if (canOpenSettings) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings_rounded),
                  label: Text(_l10n.openAppSettings(lang)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (canRetry) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_l10n.tryAgain(lang)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('BACK TO HOME'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
