import '../models/app_language.dart';
import '../models/detection.dart';
import 'localization_service.dart';

/// Where the target is, horizontally, in the camera view.
enum HorizontalZone { left, slightlyLeft, center, slightlyRight, right }

/// How close the target appears, from its relative box size.
/// This is a visual proximity heuristic (bounding box area), not a metric depth sensor.
enum Proximity { far, approaching, close, veryClose }

/// Guidance state machine conforming to PRD Section 14.
enum GuidanceState {
  searching,
  detected,
  tracking,
  guiding,
  closer,
  near,
  found,
  lost,
  reacquiring,
}

/// Two-stage guidance: navigate to the object, then reach for it safely.
enum GuidanceStage { navigation, safeReach }

/// One guidance decision: what to tell the user right now.
class Guidance {
  const Guidance({
    required this.state,
    required this.zone,
    required this.proximity,
    required this.isFound,
    required this.isLost,
    required this.phrase,
    this.isUncertain = false,
    this.stage = GuidanceStage.navigation,
    this.reachPhrases = const [],
  });

  final GuidanceState state;

  /// Stage 1 = navigation, Stage 2 = safe reach (target found).
  final GuidanceStage stage;

  /// Calm spoken phrases for the safe-reach stage, in speaking order.
  /// Non-empty only on the first found frame (no speech spam).
  final List<String> reachPhrases;
  final HorizontalZone zone;
  final Proximity proximity;
  final bool isFound;
  final bool isLost;
  final bool isUncertain;

  /// Spoken guidance phrase (localized).
  final String phrase;

  static const lost = Guidance(
    state: GuidanceState.lost,
    zone: HorizontalZone.center,
    proximity: Proximity.far,
    isFound: false,
    isLost: true,
    phrase: 'I lost the object. Move the camera slowly.',
  );
}

/// Turns a tracked detection box into voice and haptic guidance for blind navigation.
///
/// Implements the full PRD state machine:
/// SEARCHING -> DETECTED -> TRACKING -> GUIDING -> CLOSER -> NEAR -> FOUND
/// and recovery: TRACKING -> LOST -> REACQUIRING -> TRACKING
///
/// Pure Dart — no Flutter dependencies, fully unit-testable.
class GuidanceEngine {
  /// Box area above which the target counts as found (fills a significant chunk
  /// of the frame and is roughly centered).
  static const double foundArea = 0.20;

  /// Per-object FOUND thresholds (fraction of frame area). Small handheld
  /// items fill less of the frame at reach distance; big items fill more.
  static const Map<String, double> foundAreaByObject = {
    'phone': 0.10,
    'remote': 0.10,
    'mouse': 0.10,
    'toothbrush': 0.08,
    'spoon': 0.08,
    'fork': 0.08,
    'knife': 0.08,
    'scissors': 0.10,
    'cup': 0.14,
    'bottle': 0.18,
    'bowl': 0.16,
    'book': 0.20,
    'backpack': 0.28,
    'laptop': 0.28,
    'chair': 0.30,
    'tv': 0.30,
  };

  static double foundAreaFor(String friendlyName) =>
      foundAreaByObject[friendlyName.toLowerCase().trim()] ?? foundArea;

  /// Objects that can fall or spill if the hand knocks them.
  static const Set<String> fragileObjects = {'cup', 'bottle', 'laptop', 'bowl'};

  static bool isFragile(String friendlyName) =>
      fragileObjects.contains(friendlyName.toLowerCase().trim());

  /// Big surfaces/people are always near the target; warning about them is noise.
  static const Set<String> _ignoredNearby = {
    'person',
    'dining table',
    'couch',
    'bed',
    'bench',
  };

  /// Returns the label of another detection whose box overlaps or sits close
  /// to [target] (within [margin] of its box), or null.
  static String? nearbyLabel(
    Detection target,
    Iterable<Detection> others, {
    double margin = 0.05,
  }) {
    for (final o in others) {
      if (o.label == target.label || _ignoredNearby.contains(o.label)) continue;
      final overlaps =
          o.left < target.right + margin &&
          o.right > target.left - margin &&
          o.top < target.bottom + margin &&
          o.bottom > target.top - margin;
      if (overlaps) return o.label;
    }
    return null;
  }

  GuidanceEngine({
    required this.targetFriendlyName,
    this.language = AppLanguage.english,
  });

  final String targetFriendlyName;
  AppLanguage language;
  bool _reachAnnounced = false;

  GuidanceStage get stage => _state == GuidanceState.found
      ? GuidanceStage.safeReach
      : GuidanceStage.navigation;

  GuidanceState _state = GuidanceState.searching;
  Proximity? _previousProximity;
  int _consecutiveTrackedFrames = 0;
  int _consecutiveMissedFrames = 0;

  GuidanceState get currentState => _state;

  void reset() {
    _state = GuidanceState.searching;
    _previousProximity = null;
    _consecutiveTrackedFrames = 0;
    _consecutiveMissedFrames = 0;
    _reachAnnounced = false;
  }

  /// [others] are the other detections in the same frame (used only for the
  /// one-time nearby-object warning when the target becomes found).
  Guidance guide(
    Detection? tracked, {
    bool isCandidateUncertain = false,
    List<Detection> others = const [],
  }) {
    final l10n = LocalizationService.instance;

    // Handle uncertainty: confidence is marginal / ambiguous
    if (isCandidateUncertain && _state != GuidanceState.found) {
      return Guidance(
        state: GuidanceState.searching,
        zone: HorizontalZone.center,
        proximity: Proximity.far,
        isFound: false,
        isLost: false,
        isUncertain: true,
        phrase: l10n.scanningUncertain(targetFriendlyName, language),
      );
    }

    if (tracked == null) {
      _previousProximity = null;
      _consecutiveTrackedFrames = 0;
      _consecutiveMissedFrames++;

      if (_state == GuidanceState.found) {
        // Keep found status once attained
        return Guidance(
          state: GuidanceState.found,
          zone: HorizontalZone.center,
          proximity: Proximity.veryClose,
          isFound: true,
          isLost: false,
          stage: GuidanceStage.safeReach,
          phrase: l10n.stopObjectFound(targetFriendlyName, language),
        );
      }

      // If we were tracking, enter reacquiring first to prevent sudden jarring lost alerts
      if (_state == GuidanceState.tracking ||
          _state == GuidanceState.guiding ||
          _state == GuidanceState.closer ||
          _state == GuidanceState.near ||
          _state == GuidanceState.reacquiring) {
        if (_consecutiveMissedFrames < 3) {
          _state = GuidanceState.reacquiring;
          return Guidance(
            state: GuidanceState.reacquiring,
            zone: HorizontalZone.center,
            proximity: Proximity.far,
            isFound: false,
            isLost: false,
            phrase: l10n.reacquiring(language),
          );
        }
      }

      _state = GuidanceState.lost;
      return Guidance(
        state: GuidanceState.lost,
        zone: HorizontalZone.center,
        proximity: Proximity.far,
        isFound: false,
        isLost: true,
        phrase: l10n.objectLost(language),
      );
    }

    // Detection exists
    _consecutiveMissedFrames = 0;
    _consecutiveTrackedFrames++;

    final cx = tracked.centerX;
    final cy = tracked.centerY;
    final area = tracked.area;

    // Horizontal zone mapping
    final HorizontalZone zone;
    if (cx < 0.28) {
      zone = HorizontalZone.left;
    } else if (cx < 0.42) {
      zone = HorizontalZone.slightlyLeft;
    } else if (cx <= 0.58) {
      zone = HorizontalZone.center;
    } else if (cx <= 0.72) {
      zone = HorizontalZone.slightlyRight;
    } else {
      zone = HorizontalZone.right;
    }

    // Proximity classification based on normalized bounding box area
    final Proximity proximity;
    if (area < 0.025) {
      proximity = Proximity.far;
    } else if (area < 0.07) {
      proximity = Proximity.approaching;
    } else if (area < 0.17) {
      proximity = Proximity.close;
    } else {
      proximity = Proximity.veryClose;
    }

    // State transition progression
    if (_state == GuidanceState.searching ||
        _state == GuidanceState.lost ||
        _state == GuidanceState.reacquiring) {
      _state = GuidanceState.detected;
    } else if (_consecutiveTrackedFrames == 2) {
      _state = GuidanceState.tracking;
    } else {
      _state = GuidanceState.guiding;
    }

    // Found condition: sufficiently large and well-centered in frame
    final isCentered = cx > 0.28 && cx < 0.72 && cy > 0.20 && cy < 0.85;
    if (area >= foundAreaFor(targetFriendlyName) && isCentered) {
      _state = GuidanceState.found;
      _previousProximity = proximity;

      // Stage 2 (safe reach): calm phrases, announced once per found-stage.
      final reach = <String>[];
      if (!_reachAnnounced) {
        _reachAnnounced = true;
        reach.add(l10n.safeReachInstruction(language));
        if (isFragile(targetFriendlyName)) {
          reach.add(l10n.fragileWarning(language));
        }
        final near = nearbyLabel(tracked, others);
        if (near != null) {
          reach.add(l10n.nearbyObjectWarning(near, language));
        }
      }
      return Guidance(
        state: GuidanceState.found,
        zone: zone,
        proximity: proximity,
        isFound: true,
        isLost: false,
        stage: GuidanceStage.safeReach,
        reachPhrases: reach,
        phrase: l10n.stopObjectFound(targetFriendlyName, language),
      );
    }

    // Directional guidance and closer/near progression
    final gettingCloser =
        _previousProximity != null &&
        proximity.index > _previousProximity!.index;
    _previousProximity = proximity;

    final String phrase;
    if (zone == HorizontalZone.center) {
      if (area >= 0.14) {
        _state = GuidanceState.near;
        phrase = l10n.objectIsClose(language);
      } else if (gettingCloser) {
        _state = GuidanceState.closer;
        phrase = l10n.youAreGettingCloser(language);
      } else {
        phrase = l10n.moveForward(language);
      }
    } else if (zone == HorizontalZone.slightlyLeft) {
      phrase = l10n.moveSlightlyLeft(language);
    } else if (zone == HorizontalZone.left) {
      phrase = l10n.moveLeft(language);
    } else if (zone == HorizontalZone.slightlyRight) {
      phrase = l10n.moveSlightlyRight(language);
    } else {
      phrase = l10n.moveRight(language);
    }

    return Guidance(
      state: _state,
      zone: zone,
      proximity: proximity,
      isFound: false,
      isLost: false,
      phrase: phrase,
    );
  }
}
