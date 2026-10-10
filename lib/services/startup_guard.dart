import 'package:flutter/widgets.dart';

/// Why finder startup cannot continue. Pure data so the decisions are testable.
enum StartupFailure {
  none,

  /// Camera permission refused for now; the system dialog can be asked again.
  permissionDenied,

  /// Camera permission refused permanently; only app settings can grant it.
  permissionPermanentlyDenied,

  /// The device reports no camera at all.
  noCamera,

  /// The camera exists but could not be opened or started.
  cameraInit,

  /// The on-device detection model did not load or did not become ready.
  modelLoad,
}

/// What the screen should do when the app moves between foreground and background.
enum LifecycleAction { none, pauseCamera, resumeCamera }

class StartupGuard {
  StartupGuard._();

  /// Maps the permission result to a failure. [isGranted] wins; otherwise a
  /// permanent denial is reported separately because the dialog cannot show again.
  static StartupFailure permissionOutcome({
    required bool isGranted,
    required bool isPermanentlyDenied,
  }) {
    if (isGranted) return StartupFailure.none;
    return isPermanentlyDenied
        ? StartupFailure.permissionPermanentlyDenied
        : StartupFailure.permissionDenied;
  }

  /// Only permission problems can be fixed from the app's settings page.
  static bool offersSettingsButton(StartupFailure failure) =>
      failure == StartupFailure.permissionDenied ||
      failure == StartupFailure.permissionPermanentlyDenied;

  /// Only a denied permission can be solved by asking again.
  static bool offersRetry(StartupFailure failure) =>
      failure == StartupFailure.permissionDenied ||
      failure == StartupFailure.cameraInit ||
      failure == StartupFailure.modelLoad;

  /// Camera must stop while the app is hidden (the OS may take the camera
  /// away) and restart on return. [inactive] counts as hidden: it happens
  /// when a system dialog or the notification shade covers the app.
  static LifecycleAction lifecycleAction(
    AppLifecycleState previous,
    AppLifecycleState next,
  ) {
    final hiddenNow =
        next == AppLifecycleState.paused ||
        next == AppLifecycleState.inactive ||
        next == AppLifecycleState.detached ||
        next == AppLifecycleState.hidden;
    if (hiddenNow) {
      return _wasHidden(previous) ? LifecycleAction.none : LifecycleAction.pauseCamera;
    }
    if (next == AppLifecycleState.resumed && _wasHidden(previous)) {
      return LifecycleAction.resumeCamera;
    }
    return LifecycleAction.none;
  }

  static bool _wasHidden(AppLifecycleState s) =>
      s == AppLifecycleState.paused ||
      s == AppLifecycleState.inactive ||
      s == AppLifecycleState.detached ||
      s == AppLifecycleState.hidden;
}
