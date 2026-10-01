import 'package:flutter_timezone/flutter_timezone.dart';

import 'location_gateway.dart';
import 'models/models.dart';

/// Captures the "now" half of a reading: the instant Reveal was tapped, the
/// device's IANA timezone, and — only when the user explicitly asked for it and
/// a usable fresh fix arrives — the current position.
///
/// Implementations must never throw and never block a reading: a failed
/// timezone lookup or location attempt degrades to `location: null` while
/// keeping a valid `deviceTimezone`. They must never log or report coordinates.
///
/// Any captured location describes the *current* position only. Birth country
/// and birth timezone are never derived from it.
abstract interface class CurrentContextProvider {
  /// [instantUtc] is taken by the caller at the moment of the tap, so a slow
  /// timezone or location lookup cannot move the reading's moment.
  ///
  /// [includeLocation] is the user's explicit, current choice from the
  /// explainer screen. When it is false the location plugin must not be
  /// consulted at all — not even to read a permission granted in an earlier
  /// session.
  Future<CurrentContext> capture({
    required DateTime instantUtc,
    required bool includeLocation,
  });

  /// Asks the OS for foreground location permission. Called only when the user
  /// chooses "Allow Current Location".
  Future<void> requestLocationAccess();

  /// The IANA timezone a reading taken now would resolve to, without capturing
  /// anything else.
  ///
  /// The ritual screen needs it before Reveal, to work out how much of a local
  /// period is actually left. It deliberately never consults location: a
  /// pre-Reveal screen has no fix, and the device zone is what the engine
  /// would use anyway unless the reader opts into location at the tap itself.
  ///
  /// Separate from [capture] so that asking the time of day is not recorded as
  /// a reading's context capture.
  ///
  /// **Throws when the platform cannot name its zone.** [capture] falls back
  /// to UTC there, because a reading must still be possible; this must not,
  /// because its answer is used to measure the reader's own local periods. A
  /// silent UTC would withdraw periods that are open and offer periods that
  /// are over, and say nothing — the caller needs to know it does not know.
  Future<String> currentTimezone();
}

/// Production provider backed by `flutter_timezone` and a [LocationGateway].
class DeviceCurrentContextProvider implements CurrentContextProvider {
  const DeviceCurrentContextProvider({
    this.gateway = const GeolocatorLocationGateway(),
    this.locationTimeout = const Duration(seconds: 6),
  });

  final LocationGateway gateway;
  final Duration locationTimeout;

  /// Used when the platform cannot name its own zone. The engine requires a
  /// real IANA id, and UTC is the only universally valid fallback.
  static const String fallbackTimezone = 'UTC';

  /// The engine discards a fix older than 15 minutes as stale, so one that old
  /// is dropped here instead of being sent.
  static const Duration maxFixAge = Duration(minutes: 15);

  @override
  Future<String> currentTimezone() async {
    // Deliberately not `_timezone()`: its UTC fallback is for [capture],
    // where a reading has to happen regardless. Here, not knowing has to
    // surface as not knowing.
    final zone = await FlutterTimezone.getLocalTimezone();
    if (zone.identifier.isEmpty) {
      throw StateError('the platform named no local time zone');
    }
    return zone.identifier;
  }

  @override
  Future<CurrentContext> capture({
    required DateTime instantUtc,
    required bool includeLocation,
  }) async {
    final instant = instantUtc.toUtc();
    // The timezone is always resolved; only the location is opt-in.
    final timezone = await _timezone();
    return CurrentContext(
      instantUtc: instant.toIso8601String(),
      deviceTimezone: timezone,
      location: includeLocation ? await _location(instant) : null,
    );
  }

  @override
  Future<void> requestLocationAccess() async {
    try {
      await gateway.requestPermission();
    } catch (_) {
      // A refused or unavailable permission flow is not fatal; the reading
      // falls back to the device timezone.
    }
  }

  Future<CurrentLocation?> _location(DateTime instantUtc) async {
    try {
      // Never prompts here: permission is requested from the explainer screen
      // only, and denied/deniedForever simply means no location.
      if (!await gateway.hasPermission()) return null;
      if (!await gateway.isServiceEnabled()) return null;

      final fix = await gateway.currentFix(locationTimeout);
      return fix == null ? null : _toLocation(fix, instantUtc);
    } catch (_) {
      // Denied, service disabled, timed out or unavailable.
      return null;
    }
  }

  Future<String> _timezone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      return zone.identifier.isEmpty ? fallbackTimezone : zone.identifier;
    } catch (_) {
      return fallbackTimezone;
    }
  }

  CurrentLocation? _toLocation(LocationFix fix, DateTime instantUtc) {
    if (!fix.accuracyMeters.isFinite || fix.accuracyMeters < 0) return null;
    if (!fix.latitude.isFinite || !fix.longitude.isFinite) return null;

    final capturedAt = fix.timestampUtc.toUtc();
    if (instantUtc.difference(capturedAt) > maxFixAge) return null;

    return CurrentLocation(
      latitude: fix.latitude,
      longitude: fix.longitude,
      accuracyMeters: fix.accuracyMeters,
      capturedAtUtc: capturedAt.toIso8601String(),
    );
  }
}

/// Deterministic provider for tests and widget previews. Performs no platform
/// calls, so it is safe in `flutter test`.
class FixedCurrentContextProvider implements CurrentContextProvider {
  FixedCurrentContextProvider({
    this.deviceTimezone = 'Asia/Ho_Chi_Minh',
    this.location,
    this.delay = Duration.zero,
    this.timezoneDelay,
    this.timezoneFailures = 0,
  });

  final String deviceTimezone;

  /// Returned only when a capture asks for location, mirroring the real
  /// provider.
  final CurrentLocation? location;

  final Duration delay;

  /// How long a zone lookup takes, when it should differ from [delay].
  ///
  /// The ritual screen reads the zone on open and reads it again at the tap,
  /// so a test needs to hold the first one open without also slowing the
  /// capture that follows the second.
  final Duration? timezoneDelay;

  /// How many of the next zone lookups throw before one succeeds.
  ///
  /// A platform that cannot name its own zone is the case the screen has to
  /// survive; counting them down is what lets a test prove the retry works.
  int timezoneFailures;

  /// Every capture this provider was asked for, for assertions.
  final List<({DateTime instantUtc, bool includeLocation})> captures = [];

  var locationAccessRequests = 0;

  /// Asking the time of day is not a capture, so it is counted separately.
  var timezoneLookups = 0;

  @override
  Future<String> currentTimezone() async {
    timezoneLookups++;
    final wait = timezoneDelay ?? delay;
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    if (timezoneFailures > 0) {
      timezoneFailures--;
      throw StateError('the platform could not name its time zone');
    }
    return deviceTimezone;
  }

  @override
  Future<CurrentContext> capture({
    required DateTime instantUtc,
    required bool includeLocation,
  }) async {
    captures.add((instantUtc: instantUtc, includeLocation: includeLocation));
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return CurrentContext(
      instantUtc: instantUtc.toUtc().toIso8601String(),
      deviceTimezone: deviceTimezone,
      location: includeLocation ? location : null,
    );
  }

  @override
  Future<void> requestLocationAccess() async => locationAccessRequests++;
}
