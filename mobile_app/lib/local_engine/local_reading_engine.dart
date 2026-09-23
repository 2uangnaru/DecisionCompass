/// Port of `calculation-engine/src/index.js` — the offline reading engine.
///
/// Compiles the birth-dependent charts once per profile, then evaluates a
/// reading entirely on the device. There is no AI, no network call, no paid
/// API and no random value anywhere in the result path; a reading depends only
/// on the profile, the captured instant, the timezone, the mode, the period
/// and the category.
///
/// The output is the same JSON shape `src/index.d.ts` declares, so the existing
/// `ReadingResponse` DTO parses it unchanged.
library;

import 'dart:convert';

import 'astronomy/astronomy.dart';
import 'bazi/bazi.dart';
import 'calendar/calendar.dart';
import 'core/bounded_cache.dart';
import 'core/core.dart';
import 'core/numbers.dart';
import 'core/sha256.dart';
import 'location/location.dart';
import 'numerology/numerology.dart';
import 'time/local_time.dart';
import 'ziwei/ziwei.dart';

/// Provider versions, reported verbatim so a saved reading records exactly
/// which datasets produced it.
///
/// `geoTz` is still named because the contract lists it and because the
/// coordinate-to-zone dataset it refers to is the one this build deliberately
/// does not bundle — see `location/location.dart`.
const Map<String, String> providers = <String, String>{
  'lunarJavascript': '1.7.7',
  'iztro': '2.6.1',
  'astronomyEngine': '2.1.19',
  'geoTz': '8.1.9',
  'momentTimezone': '0.6.4',
};

const List<String> _colors = <String>[
  'sage',
  'coral',
  'sand',
  'pearl',
  'ocean_blue',
];

/// A validated birth profile.
class EngineProfile {
  const EngineProfile({
    required this.birthDate,
    required this.birthTime,
    required this.birthCountry,
    required this.birthTimezone,
    required this.traditionalProfile,
    required this.revision,
  });

  final String birthDate;
  final String? birthTime;
  final String? birthCountry;
  final String? birthTimezone;

  /// `male`, `female` or null. Never inferred from a name or a country.
  final String? traditionalProfile;

  final int revision;

  /// The exact shape and key order the Node engine snapshots and hashes.
  Map<String, Object?> toJson() => <String, Object?>{
    'birthDate': birthDate,
    'birthTime': birthTime,
    'birthCountry': birthCountry,
    'birthTimezone': birthTimezone,
    'traditionalProfile': traditionalProfile,
    'revision': revision,
  };
}

const Map<String, String?> _conventions = <String, String?>{
  'male': 'male',
  'female': 'female',
  'male_convention': 'male',
  'female_convention': 'female',
  'unspecified': null,
};

EngineProfile normalizeProfile(Map<String, Object?> input) {
  final birthDate = parseBirthDate(input['birthDate']);
  final birthTime = parseBirthTime(input['birthTime']);

  final rawConvention = input['traditionalProfile'];
  if (rawConvention != null && !_conventions.containsKey(rawConvention)) {
    throw const EngineFailure('INVALID_TRADITIONAL_PROFILE');
  }
  final rawCountry = input['birthCountry'];
  if (rawCountry != null && rawCountry is! String) {
    throw const EngineFailure('INVALID_BIRTH_COUNTRY');
  }
  final rawRevision = input['revision'];
  if (rawRevision != null && (rawRevision is! int || rawRevision < 1)) {
    throw const EngineFailure('INVALID_PROFILE_REVISION');
  }
  final rawTimezone = input['birthTimezone'];

  return EngineProfile(
    birthDate: birthDate,
    birthTime: birthTime,
    birthCountry: (rawCountry as String?)?.toUpperCase(),
    birthTimezone: rawTimezone as String?,
    traditionalProfile: rawConvention == null
        ? null
        : _conventions[rawConvention as String],
    revision: (rawRevision as int?) ?? 1,
  );
}

/// One evaluated instant: the calendar view, the six modules and their fusion.
class _Evaluated {
  const _Evaluated(this.calendar, this.modules, this.evidence);

  final CalendarAt calendar;
  final Map<String, ModuleResult> modules;
  final Evidence evidence;
}

/// The reading calculator for one profile.
///
/// Building it is the expensive step — the natal BaZi, the Zi Wei charts and
/// the natal sky are all computed here — and every later reading for the same
/// profile reuses them.
class ReadingCalculator {
  ReadingCalculator._(
    this._profile,
    this._birth,
    this._baZi,
    this._ziWei,
    this._natal,
  );

  factory ReadingCalculator(Map<String, Object?> rawProfile) {
    validateCategoryProfiles();
    validateWesternProfiles();
    validateZiweiTargets();

    final profile = normalizeProfile(rawProfile);
    final birth = birthContext(
      birthDate: profile.birthDate,
      birthTime: profile.birthTime,
      birthCountry: profile.birthCountry,
      birthTimezone: profile.birthTimezone,
    );
    return ReadingCalculator._(
      profile,
      birth,
      buildBaZi(birth, profile.traditionalProfile),
      buildZiWei(birth, profile.traditionalProfile),
      natalSky(birth),
    );
  }

  final EngineProfile _profile;
  final BirthContext _birth;
  final BaZiChart _baZi;
  final BuiltZiWei _ziWei;
  final NatalSky _natal;

  final BoundedCache<String, _Evaluated> _cache =
      BoundedCache<String, _Evaluated>(256);

  _Evaluated _evaluate(double ms, String zone, String category) {
    // Category changes Zi Wei targets, Western body emphasis and fusion
    // weights, so it is part of the cache identity.
    final key = '$ms|$zone|$category';
    final cached = _cache.get(key);
    if (cached != null) return cached;

    final calendar = calendarAt(ms, zone);
    final sky = skyAt(ms);
    final modules = <String, ModuleResult>{
      'B': scoreBaZi(_baZi, calendar, ms),
      'Z': scoreZiWei(_ziWei, calendar, category),
      'T': almanac(calendar),
      'W': western(sky, _natal, category),
      'N': numerology(_profile.birthDate, calendar.local.date),
      'U': cosmic(sky),
    };
    return _cache.set(
      key,
      _Evaluated(calendar, modules, combine(modules, category)),
    );
  }

  /// Calculates one reading and returns it as the engine's own JSON shape.
  Map<String, Object?> calculate({
    required Map<String, Object?> context,
    String period = 'now',
    String mode = 'yes_no',
    String category = 'general',
    bool diagnostics = false,
    Object? space,
    ZoneGeometryResolver? geometry,
  }) {
    if (!modes.containsKey(mode))
      throw const EngineFailure('INVALID_DECISION_MODE');
    if (!categories.contains(category))
      throw const EngineFailure('INVALID_CATEGORY');
    // Spatial feng shui is out of scope, and asking for it must fail loudly
    // rather than quietly return a reading that ignored the request.
    if (space != null)
      throw const EngineFailure('SPATIAL_FENG_SHUI_OUT_OF_SCOPE');

    final rawLocation = context['location'];
    final resolved = resolveCurrentContext(
      instantUtc: context['instantUtc'],
      deviceTimezone: context['deviceTimezone'] as String?,
      location: rawLocation == null
          ? null
          : _fixFrom(rawLocation as Map<String, Object?>),
      geometry: geometry,
    );

    final now = resolved.instantMs;
    final zone = resolved.timezone;
    if (_profile.birthDate.compareTo(resolved.localDate) > 0) {
      throw const EngineFailure('BIRTH_DATE_IN_FUTURE');
    }
    if (_birth.exact && _birth.intervals[0].start > now) {
      throw const EngineFailure('BIRTH_INSTANT_IN_FUTURE');
    }

    // Luck-cycle boundaries can fall inside an earthly-branch hour.
    final extra = <double>[...nearbyBoundaries(now)];
    if (_baZi.decade != null) {
      for (final t in decadeBoundaries(_baZi)) {
        if ((t - now).abs() < 3 * msPerDay) extra.add(t);
      }
    }

    final segments = segmentsForDay(now, zone, extra);
    final selected = periodSegments(segments, now, period);

    final warnings = <String>[
      if (_birth.status != 'exact') _birth.status,
      if (_profile.birthTime == null) 'unknown_birth_time',
      if (_profile.traditionalProfile == null)
        'unspecified_traditional_convention',
      if (resolved.locationStatus == 'ambiguous_zone')
        'location_timezone_ambiguous_using_device',
      if (resolved.locationStatus == zoneLookupUnavailable)
        zoneLookupUnavailableWarning,
    ];

    final resolvedProviders = <String, String>{
      ...providers,
      'tzdb': resolved.tzdbVersion,
    };

    final base = <String, Object?>{
      'engineVersion': engineVersion,
      'rulesetVersion': rulesetVersion,
      'providers': resolvedProviders,
      'mode': mode,
      'period': period,
      'category': category,
      'context': resolved.toJson(),
      'birthData': <String, Object?>{
        'status': _birth.status,
        'timeKnown': _birth.clock != null,
        'timezoneSource': _birth.zoneSource,
        'timezoneCandidates': _birth.zones,
      },
      'warnings': warnings,
      'inputSnapshot': <String, Object?>{
        'profile': _profile.toJson(),
        'context': <String, Object?>{
          'instantUtc': resolved.instantUtc,
          'timezone': zone,
          'zoneSource': resolved.zoneSource,
        },
        'period': period,
        'mode': mode,
        'category': category,
      },
    };

    if (selected.isEmpty) {
      return <String, Object?>{
        ...base,
        'status': 'period_elapsed',
        'winner': null,
        'percentages': null,
        'luckyWindows': const <Object?>[],
        'consumeUnlock': false,
      };
    }

    final evaluated = <({DaySegment segment, _Evaluated value})>[
      for (final s in selected)
        (segment: s, value: _evaluate(s.start, zone, category)),
    ];

    double duration(DaySegment s) => (s.end - s.includedFrom) / 1000;

    final fused = period == 'now'
        ? evaluated[0].value.evidence
        : weightedTimeAverage(<({double duration, Evidence evidence})>[
            for (final e in evaluated)
              (duration: duration(e.segment), evidence: e.value.evidence),
          ]);

    // A window must be at least fifteen minutes long to be worth offering.
    final windows = <Map<String, Object?>>[];
    if (period != 'now') {
      for (final e in evaluated) {
        if (duration(e.segment) < 900) continue;
        final s = e.segment;
        windows.add(<String, Object?>{
          'startUtc': toIsoStringUtc(s.includedFrom),
          'endUtc': toIsoStringUtc(s.end),
          'startLocal': localAt(s.includedFrom, zone).iso,
          'endLocal': localAt(s.end, zone).iso,
          'score': percent(scoreForMode(e.value.evidence, mode)),
          'dataCoverage': jsNumber(roundTen(e.value.evidence.coverage)),
          'hourBranch': s.hourBranchIndex,
          'meaning': 'symbolic_timing_score_not_probability',
        });
      }
      windows.sort((a, b) {
        final byScore = (b['score']! as int).compareTo(a['score']! as int);
        if (byScore != 0) return byScore;
        return (a['startUtc']! as String).compareTo(b['startUtc']! as String);
      });
      if (windows.length > 2) windows.removeRange(2, windows.length);
    }

    final first = evaluated[0].value;
    final briefNumber = first.modules['N']!.diagnostics['personalDay']! as int;

    final readingKey = _hash(<String, Object?>{
      'profile': _profile.toJson(),
      'rules': rulesetVersion,
      'providers': resolvedProviders,
      'zone': zone,
      'period': period,
      'category': category,
      'segments': <Object?>[
        for (final e in evaluated)
          <Object?>[
            jsNumber(e.segment.start),
            jsNumber(e.segment.end),
            period == 'now' ? null : jsNumber(e.segment.includedFrom),
          ],
      ],
    });

    final result = decision(fused, mode);

    return <String, Object?>{
      ...base,
      'status': result.status,
      'winner': result.winner,
      'percentages': result.percentages,
      if (result.dataCoverage != null)
        'dataCoverage': jsNumber(result.dataCoverage!),
      if (result.modeScore != null) 'modeScore': jsNumber(result.modeScore!),
      if (result.modeBasis != null) 'modeBasis': result.modeBasis,
      if (result.meaning != null) 'meaning': result.meaning,
      'readingKey': readingKey,
      'axisScores': <String, Object?>{
        'action': jsNumber(roundTen(fused.a)),
        'change': jsNumber(roundTen(fused.c)),
        'selected': jsNumber(roundTen(scoreForMode(fused, mode))),
      },
      'evaluatedAtUtc': toIsoStringUtc(evaluated[0].segment.start),
      'luckyWindows': windows,
      'windowStatus': period == 'now'
          ? 'not_applicable'
          : windows.length == 2
          ? 'two_available'
          : windows.length == 1
          ? 'one_remaining'
          : 'no_15_minute_window',
      'dailyBrief': <String, Object?>{
        'luckyNumber': briefNumber,
        'colorInspiration': _colors[first.calendar.day.stem ~/ 2],
      },
      'segments': <Object?>[
        for (final e in evaluated)
          <String, Object?>{
            'startUtc': toIsoStringUtc(e.segment.start),
            'endUtc': toIsoStringUtc(e.segment.end),
            'includedFromUtc': toIsoStringUtc(e.segment.includedFrom),
            'durationSeconds': jsNumber(duration(e.segment)),
            'modules': _moduleSummary(e.value.modules, diagnostics, category),
          },
      ],
      'monetizationHandledByApp': true,
    };
  }

  /// The birth charts, for audit. Never sent to analytics.
  Map<String, Object?> inspectBirthCharts() => <String, Object?>{
    'profile': _profile.toJson(),
    'birth': <String, Object?>{
      'date': _birth.date,
      'clock': _birth.clock,
      'zones': _birth.zones,
      'zoneSource': _birth.zoneSource,
      'exact': _birth.exact,
      'status': _birth.status,
    },
    'baZi': <String, Object?>{
      'pillars': <Object?>[for (final p in _baZi.pillars) p?.text],
      'coverage': jsNumber(_baZi.coverage),
      'missing': _baZi.missing,
      'traditionalYongShen': null,
      'traditionalXiShen': null,
    },
    'ziWei': <String, Object?>{
      'scenarioCount': _ziWei.charts.length,
      'unknownHour': _ziWei.unknownHour,
      'unknownConvention': _ziWei.unknownConvention,
    },
    'western': <String, Object?>{
      'status': _natal.status,
      'method': _natal.method,
      'stableBodies': _natal.positions.keys.toList(),
    },
  };
}

LocationFixInput _fixFrom(Map<String, Object?> raw) => LocationFixInput(
  latitude: (raw['latitude'] as num?)?.toDouble() ?? double.nan,
  longitude: (raw['longitude'] as num?)?.toDouble() ?? double.nan,
  accuracyMeters: (raw['accuracyMeters'] as num?)?.toDouble() ?? double.nan,
  capturedAtUtc: raw['capturedAtUtc'] is String
      ? raw['capturedAtUtc']! as String
      : '',
);

Map<String, Object?> _moduleSummary(
  Map<String, ModuleResult> modules,
  bool diagnostics,
  String category,
) {
  final weights = weightsFor(category);
  return <String, Object?>{
    for (final entry in modules.entries)
      entry.key: <String, Object?>{
        'status': entry.value.status,
        'coverage': jsNumber(roundTen(entry.value.evidence.coverage)),
        'a': jsNumber(roundTen(entry.value.evidence.a)),
        'c': jsNumber(roundTen(entry.value.evidence.c)),
        'weight': jsNumber(roundTen(weights[entry.key]!)),
        'contribution': <String, Object?>{
          'a': jsNumber(
            roundTen(
              weights[entry.key]! *
                  entry.value.evidence.coverage *
                  entry.value.evidence.a,
            ),
          ),
          'c': jsNumber(
            roundTen(
              weights[entry.key]! *
                  entry.value.evidence.coverage *
                  entry.value.evidence.c,
            ),
          ),
        },
        if (diagnostics) 'diagnostics': entry.value.diagnostics,
      },
  };
}

/// `sha256(JSON.stringify(value))`, with the same key order the Node engine
/// builds. `jsonEncode` preserves insertion order and formats integral doubles
/// as integers once [jsNumber] has typed them, which is what makes the digest
/// match.
String _hash(Map<String, Object?> value) => sha256Hex(jsonEncode(value));

/// One-shot convenience entry point, mirroring the engine's `calculate`.
Map<String, Object?> calculateReading({
  required Map<String, Object?> profile,
  required Map<String, Object?> context,
  String period = 'now',
  String mode = 'yes_no',
  String category = 'general',
  bool diagnostics = false,
  Object? space,
  ZoneGeometryResolver? geometry,
}) {
  return ReadingCalculator(profile).calculate(
    context: context,
    period: period,
    mode: mode,
    category: category,
    diagnostics: diagnostics,
    space: space,
    geometry: geometry,
  );
}
