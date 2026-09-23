/// Port of `calculation-engine/src/astronomy.js`.
///
/// Turns geocentric ecliptic longitudes into the Western (`W`) and cosmic
/// (`U`) modules. The aspect geometry is fixed; only the body emphasis is
/// category-aware. These weights are symbolic editorial emphases, not
/// validated astrology, and there is no Ascendant or house system because the
/// MVP never asks for an exact birthplace.
library;

import 'dart:math' as math;

import '../core/bounded_cache.dart';
import '../core/core.dart';
import '../core/numbers.dart';
import '../time/local_time.dart' show BirthContext, msPerHour;
import '../time/moment_shim.dart' show toIsoStringUtc;
import 'astronomy_engine.dart';

const Map<String, String> bodies = <String, String>{
  'sun': 'Sun',
  'moon': 'Moon',
  'mercury': 'Mercury',
  'venus': 'Venus',
  'mars': 'Mars',
  'jupiter': 'Jupiter',
  'saturn': 'Saturn',
};

const Map<String, double> _transitWeights = <String, double>{
  'moon': .35,
  'sun': .15,
  'mercury': .1,
  'venus': .1,
  'mars': .1,
  'jupiter': .1,
  'saturn': .1,
};

const Map<String, double> _natalWeights = <String, double>{
  'sun': .3,
  'moon': .3,
  'mercury': .1,
  'venus': .1,
  'mars': .1,
  'jupiter': .05,
  'saturn': .05,
};

/// Body emphasis per category, applied to both sides of the transit/natal
/// grid. `general` and `other` keep the verified default pair rather than a
/// category profile.
const Map<String, Map<String, double>> westernCategoryProfiles =
    <String, Map<String, double>>{
      'love': <String, double>{
        'sun': .10,
        'moon': .25,
        'mercury': .15,
        'venus': .30,
        'mars': .08,
        'jupiter': .07,
        'saturn': .05,
      },
      'career': <String, double>{
        'sun': .20,
        'moon': .05,
        'mercury': .15,
        'venus': .05,
        'mars': .15,
        'jupiter': .15,
        'saturn': .25,
      },
      'money': <String, double>{
        'sun': .10,
        'moon': .05,
        'mercury': .15,
        'venus': .20,
        'mars': .05,
        'jupiter': .20,
        'saturn': .25,
      },
      'study': <String, double>{
        'sun': .10,
        'moon': .10,
        'mercury': .30,
        'venus': .05,
        'mars': .05,
        'jupiter': .20,
        'saturn': .20,
      },
      'friends': <String, double>{
        'sun': .10,
        'moon': .15,
        'mercury': .25,
        'venus': .20,
        'mars': .05,
        'jupiter': .15,
        'saturn': .10,
      },
    };

/// Validated at startup, as the Node engine validates at module load.
void validateWesternProfiles() {
  for (final entry in westernCategoryProfiles.entries) {
    final profile = entry.value;
    if (profile.length != bodies.length ||
        profile.keys.any((name) => !bodies.containsKey(name))) {
      throw EngineFailure('WESTERN_PROFILE_BODIES:${entry.key}');
    }
    if (!profile.values.every((w) => w.isFinite && w >= 0)) {
      throw EngineFailure('WESTERN_PROFILE_VALUE:${entry.key}');
    }
    final total = profile.values.fold<double>(0, (s, w) => s + w);
    if ((total - 1).abs() > 1e-9) {
      throw EngineFailure('WESTERN_PROFILE_NOT_NORMALIZED:${entry.key}');
    }
  }
}

const Map<String, double> _conjunction = <String, double>{
  'moon': 0,
  'sun': .1,
  'mercury': .2,
  'venus': -.1,
  'mars': .4,
  'jupiter': .3,
  'saturn': -.4,
};

const Map<int, List<double>> _aspects = <int, List<double>>{
  60: <double>[.5, .2],
  90: <double>[-.5, .3],
  120: <double>[.6, -.3],
  180: <double>[-.6, .3],
};

final BoundedCache<double, Sky> _skyCache = BoundedCache<double, Sky>(512);

double _signedAngle(double x) => jsModDouble(x + 180, 360) - 180;

/// Geocentric true-ecliptic longitude of a body, in degrees.
double longitudeOf(String body, double ms) {
  final time = AstroTime.fromUnixMs(ms);
  return eclipticLongitude(geoVector(bodies[body] ?? body, time), time);
}

/// The sky at one instant: seven longitudes plus Mercury's apparent speed.
class Sky {
  const Sky(this.positions, this.mercurySpeed, this.evaluatedAtUtc);

  final Map<String, double> positions;
  final double mercurySpeed;
  final String evaluatedAtUtc;
}

Sky skyAt(double ms) {
  final cached = _skyCache.get(ms);
  if (cached != null) return cached;
  final positions = <String, double>{
    for (final body in bodies.keys) body: longitudeOf(body, ms),
  };
  final mercurySpeed =
      _signedAngle(
        longitudeOf('mercury', ms + msPerHour) -
            longitudeOf('mercury', ms - msPerHour),
      ) *
      12;
  return _skyCache.set(ms, Sky(positions, mercurySpeed, toIsoStringUtc(ms)));
}

/// The natal sky, reduced to the features that stay stable across every
/// possible birth instant when the birth time is not known exactly.
class NatalSky {
  const NatalSky({
    required this.positions,
    required this.ranges,
    required this.status,
    this.sampleCount,
    required this.method,
    this.maxAcceptedSpanDegrees,
  });

  final Map<String, double> positions;
  final Map<String, Map<String, Object?>> ranges;
  final String status;
  final int? sampleCount;
  final String method;
  final double? maxAcceptedSpanDegrees;
}

NatalSky natalSky(BirthContext birth) {
  if (birth.intervals.isEmpty) {
    return NatalSky(
      positions: const <String, double>{},
      ranges: const <String, Map<String, Object?>>{},
      status: birth.status,
      method: 'no_birth_instant_available',
    );
  }

  final points = <double>{};
  for (final interval in birth.intervals) {
    points.add(interval.start);
    points.add(interval.end);
    for (
      var t = interval.start + 3 * msPerHour;
      t < interval.end;
      t += 3 * msPerHour
    ) {
      points.add(t);
    }
  }
  final sorted = points.toList()..sort();
  final positions = <String, double>{};
  final ranges = <String, Map<String, Object?>>{};

  for (final body in bodies.keys) {
    final values = sorted.map((t) => longitudeOf(body, t)).toList();
    final base = values[0];
    final delta = values.map((v) => _signedAngle(v - base)).toList();
    final lo = delta.reduce(math.min);
    final hi = delta.reduce(math.max);
    final span = hi - lo;
    // A 0.02° guard for interpolation between three-hour samples: a model
    // tolerance, not a confidence. An unknown-time Moon is normally excluded.
    final stable = birth.exact || span + .02 <= .5;
    ranges[body] = <String, Object?>{
      'minLongitude': jsModDouble(base + lo, 360),
      'maxLongitude': jsModDouble(base + hi, 360),
      'spanDegrees': span,
      'stable': stable,
    };
    if (stable) positions[body] = jsModDouble(base + (lo + hi) / 2, 360);
  }

  return NatalSky(
    positions: positions,
    ranges: ranges,
    status: birth.exact ? 'exact' : 'stable_features_only',
    sampleCount: sorted.length,
    method: birth.exact ? 'birth_utc' : 'uncertain_birth_interval_sampled_3h',
    maxAcceptedSpanDegrees: .5,
  );
}

/// One transit-to-natal aspect: the nearest classical angle and its strength.
class Aspect {
  const Aspect(this.angle, this.strength, this.a, this.c);

  final int angle;
  final double strength;
  final double a;
  final double c;
}

Aspect aspect(double transit, double natal, String body) {
  final distance = _signedAngle(transit - natal).abs();
  const angles = <int>[0, 60, 90, 120, 180];
  var angle = angles[0];
  for (final candidate in angles) {
    if ((distance - candidate).abs() < (distance - angle).abs())
      angle = candidate;
  }
  final strength = math.max(0.0, 1 - (distance - angle).abs() / 3);
  final v = angle == 0 ? <double>[0, _conjunction[body]!] : _aspects[angle]!;
  return Aspect(angle, strength, strength * v[0], strength * v[1]);
}

ModuleResult western(Sky sky, NatalSky natal, [String category = 'general']) {
  // Aspect geometry is untouched; only the body emphasis is category-aware.
  final profile = westernCategoryProfiles[category];
  final transitWeights = profile ?? _transitWeights;
  final natalWeights = profile ?? _natalWeights;

  var a = 0.0;
  var c = 0.0;
  var q = 0.0;
  final aspects = <Map<String, Object?>>[];

  for (final transit in transitWeights.entries) {
    for (final natalEntry in natalWeights.entries) {
      final natalPosition = natal.positions[natalEntry.key];
      if (natalPosition == null) continue;
      final w = transit.value * natalEntry.value;
      final hit = aspect(
        sky.positions[transit.key]!,
        natalPosition,
        transit.key,
      );
      q += w;
      a += w * hit.a;
      c += w * hit.c;
      if (hit.strength > 0) {
        aspects.add(<String, Object?>{
          'transit': transit.key,
          'natal': natalEntry.key,
          'angle': hit.angle,
          'strength': hit.strength,
        });
      }
    }
  }

  return ModuleResult(
    q != 0
        ? Evidence(clampUnit(3 * a / q), clampUnit(3 * c / q), q < 1 ? q : 1)
        : Evidence(),
    <String, Object?>{
      'aspects': aspects,
      'houseSystem': null,
      'categoryProfile': profile != null ? category : 'default_transit_natal',
    },
  );
}

/// Lunar phase plus Mercury's direct / stationary / retrograde signal.
ModuleResult cosmic(Sky sky) {
  final phi = jsModDouble(sky.positions['moon']! - sky.positions['sun']!, 360);
  final rad = phi * math.pi / 180;
  final motion = clampUnit(sky.mercurySpeed / .10);
  return ModuleResult(
    Evidence(
      .8 * .35 * math.sin(rad) + .2 * .15 * motion,
      .8 * .25 * math.cos(rad) + .2 * .10 * motion,
      1,
    ),
    <String, Object?>{
      'elongationDegrees': phi,
      'illuminationApprox': (1 - math.cos(rad)) / 2,
      'mercurySpeed': sky.mercurySpeed,
      'mercuryMotion': sky.mercurySpeed.abs() <= .01
          ? 'stationary'
          : sky.mercurySpeed < 0
          ? 'retrograde'
          : 'direct',
    },
  );
}
