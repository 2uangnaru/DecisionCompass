/// Port of `calculation-engine/src/location.js`.
///
/// Resolves the *current* context only: the instant, the timezone in force and
/// the region. The mobile shell owns permissions; nothing here prompts, tracks
/// or reaches the network, and a current position is never used as a birth
/// location or a birth timezone.
///
/// ## One deliberate gap: coordinate-to-zone geometry
///
/// The Node engine narrows the timezone from a fresh position fix using
/// `geo-tz`, whose dataset is a 30 MB ODbL extract of
/// timezone-boundary-builder. That dataset is not bundled here (see
/// `mobile_app/lib/local_engine/LICENSES.md` for the size and licensing
/// reasons), so an offline build has no geometry to consult.
///
/// Rather than guess a zone or quietly pretend the fix was ambiguous, a valid
/// fresh fix with no [ZoneGeometryResolver] installed reports
/// `zone_lookup_unavailable` and falls back to the device timezone, and the
/// reading carries the matching warning. Every other branch — an invalid fix,
/// a stale fix, no fix at all — behaves exactly as the Node engine does.
library;

import 'dart:math' as math;

import '../core/numbers.dart';
import '../time/local_time.dart';
import '../time/tzdb.dart';

/// Status reported when a fix was usable but no geometry dataset is installed.
const String zoneLookupUnavailable = 'zone_lookup_unavailable';

/// Warning added to a reading whose position fix could not be resolved.
const String zoneLookupUnavailableWarning =
    'location_zone_lookup_unavailable_using_device';

/// A one-shot current position, exactly as the contract defines it.
class LocationFixInput {
  const LocationFixInput({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAtUtc,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String capturedAtUtc;
}

/// Maps a coordinate to the IANA zones covering it.
///
/// Intentionally has no bundled implementation. A build that wants the Node
/// engine's `resolved` / `ambiguous_zone` behaviour must supply the
/// timezone-boundary-builder geometry itself and honour its ODbL terms.
abstract interface class ZoneGeometryResolver {
  List<String> zonesAt(double latitude, double longitude);
}

/// The resolved current context, mirroring `ResolvedContext` in `index.d.ts`.
class ResolvedCurrentContext {
  const ResolvedCurrentContext({
    required this.instantMs,
    required this.instantUtc,
    required this.timezone,
    required this.zoneSource,
    required this.offsetSeconds,
    required this.localDate,
    required this.region,
    required this.countryCandidates,
    required this.locationStatus,
    required this.locationZoneCandidates,
    required this.tzdbVersion,
  });

  final double instantMs;
  final String instantUtc;
  final String timezone;
  final String zoneSource;
  final double offsetSeconds;
  final String localDate;
  final String region;
  final List<String> countryCandidates;
  final String locationStatus;
  final List<String> locationZoneCandidates;
  final String tzdbVersion;

  Map<String, Object?> toJson() => <String, Object?>{
    'instantMs': jsNumber(instantMs),
    'instantUtc': instantUtc,
    'timezone': timezone,
    'zoneSource': zoneSource,
    'offsetSeconds': jsNumber(offsetSeconds),
    'localDate': localDate,
    'region': region,
    'countryCandidates': countryCandidates,
    'locationStatus': locationStatus,
    'locationZoneCandidates': locationZoneCandidates,
    'tzdbVersion': tzdbVersion,
  };
}

/// Resolves the reading's current context from the instant, the device zone
/// and — only when the user opted in — a one-shot position fix.
ResolvedCurrentContext resolveCurrentContext({
  required Object? instantUtc,
  String? deviceTimezone,
  LocationFixInput? location,
  ZoneGeometryResolver? geometry,
}) {
  final ms = parseInstant(instantUtc);
  var zone = validZone(deviceTimezone) ? deviceTimezone : null;
  var source = 'device';
  var locationStatus = 'not_provided';
  var candidates = <String>[];

  final fix = location;
  if (fix != null) {
    final coordsValid =
        fix.latitude.isFinite &&
        fix.latitude.abs() <= 90 &&
        fix.longitude.isFinite &&
        fix.longitude.abs() <= 180;
    final accuracyValid =
        fix.accuracyMeters.isFinite &&
        fix.accuracyMeters >= 0 &&
        fix.accuracyMeters <= 25000;
    double? timestamp;
    try {
      timestamp = parseInstant(fix.capturedAtUtc);
    } on EngineError {
      timestamp = null; // an invalid fix falls back
    }

    if (!coordsValid || !accuracyValid || timestamp == null) {
      locationStatus = 'invalid_fix';
    } else if (timestamp > ms + 60000 || ms - timestamp > 15 * 60000) {
      locationStatus = 'stale_fix';
    } else if (geometry == null) {
      // No geometry dataset is bundled; the reading keeps the device timezone
      // and says so rather than inventing a zone.
      locationStatus = zoneLookupUnavailable;
    } else {
      candidates = _sampleZones(geometry, fix);
      if (candidates.length == 1 && validZone(candidates[0])) {
        zone = candidates[0];
        source = 'location';
        locationStatus = 'resolved';
      } else {
        locationStatus = 'ambiguous_zone';
      }
    }
  }

  if (zone == null) throw const EngineError('CURRENT_TIMEZONE_UNAVAILABLE');

  final local = localAt(ms, zone);
  final countries = <String>[
    for (final code in tzdbCountries())
      if (zonesForCountry(code)?.contains(zone) ?? false) code,
  ];

  return ResolvedCurrentContext(
    instantMs: ms,
    instantUtc: toIsoStringUtc(ms),
    timezone: zone,
    zoneSource: source,
    offsetSeconds: local.offsetSeconds,
    localDate: local.date,
    region: zone.split('/')[0],
    countryCandidates: countries,
    locationStatus: locationStatus,
    locationZoneCandidates: candidates,
    tzdbVersion: tzdbVersion,
  );
}

/// The conservative border sampling the Node engine uses: at least a 1 km
/// buffer around the fix, even for a nominally precise one. It is a heuristic,
/// not a geometric proof.
List<String> _sampleZones(ZoneGeometryResolver geometry, LocationFixInput fix) {
  final zones = <String>{...geometry.zonesAt(fix.latitude, fix.longitude)};
  final radius =
      (fix.accuracyMeters > 1000 ? fix.accuracyMeters : 1000.0) / 6371008.8;
  final lat = fix.latitude * math.pi / 180;
  final lon = fix.longitude * math.pi / 180;
  for (var i = 0; i < 16; i++) {
    final bearing = i * 2 * math.pi / 16;
    final lat2 = math.asin(
      math.sin(lat) * math.cos(radius) +
          math.cos(lat) * math.sin(radius) * math.cos(bearing),
    );
    final lon2 =
        lon +
        math.atan2(
          math.sin(bearing) * math.sin(radius) * math.cos(lat),
          math.cos(radius) - math.sin(lat) * math.sin(lat2),
        );
    final longitude = ((lon2 * 180 / math.pi + 540) % 360) - 180;
    zones.addAll(geometry.zonesAt(lat2 * 180 / math.pi, longitude));
  }
  return zones.toList()..sort();
}
