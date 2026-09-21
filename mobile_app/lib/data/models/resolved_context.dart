import 'json_types.dart';
import 'zone_source.dart';

/// The context the engine actually evaluated against, after resolving
/// timezone/region from device and optional location data. Mirrors
/// `ResolvedContext` in `calculation-engine/src/index.d.ts`.
class ResolvedContext {
  ResolvedContext({
    required this.instantMs,
    required this.instantUtc,
    required this.timezone,
    required this.zoneSource,
    required this.offsetSeconds,
    required this.localDate,
    required this.region,
    required List<String> countryCandidates,
    required this.locationStatus,
    required List<String> locationZoneCandidates,
    required this.tzdbVersion,
  }) : countryCandidates = List.unmodifiable(countryCandidates),
       locationZoneCandidates = List.unmodifiable(locationZoneCandidates);

  final int instantMs;
  final String instantUtc;
  final String timezone;
  final ZoneSource zoneSource;
  final int offsetSeconds;
  final String localDate;
  final String region;
  final List<String> countryCandidates;
  final String locationStatus;
  final List<String> locationZoneCandidates;
  final String tzdbVersion;

  factory ResolvedContext.fromJson(JsonMap json) {
    const context = 'ResolvedContext';
    return ResolvedContext(
      instantMs: requireInt(json, 'instantMs', context),
      instantUtc: requireField<String>(json, 'instantUtc', context),
      timezone: requireField<String>(json, 'timezone', context),
      zoneSource: ZoneSource.fromWire(
        requireField<String>(json, 'zoneSource', context),
        context: context,
      ),
      offsetSeconds: requireInt(json, 'offsetSeconds', context),
      localDate: requireField<String>(json, 'localDate', context),
      region: requireField<String>(json, 'region', context),
      countryCandidates: requireStringList(json, 'countryCandidates', context),
      locationStatus: requireField<String>(json, 'locationStatus', context),
      locationZoneCandidates: requireStringList(
        json,
        'locationZoneCandidates',
        context,
      ),
      tzdbVersion: requireField<String>(json, 'tzdbVersion', context),
    );
  }

  JsonMap toJson() => {
    'instantMs': instantMs,
    'instantUtc': instantUtc,
    'timezone': timezone,
    'zoneSource': zoneSource.toJson(),
    'offsetSeconds': offsetSeconds,
    'localDate': localDate,
    'region': region,
    'countryCandidates': countryCandidates,
    'locationStatus': locationStatus,
    'locationZoneCandidates': locationZoneCandidates,
    'tzdbVersion': tzdbVersion,
  };
}
