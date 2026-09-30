/// Port of `calculation-engine/src/scoring.js` — the v9.1 experimental
/// symbolic scoring system.
///
/// The older scoring projected one fused pair of axes onto seven fixed lines,
/// so every mode read the same instant from a slightly different angle and the
/// results clustered near the middle. v9.1 extracts nine named signals,
/// several of which look at other days, and gives each mode its own mixture of
/// them.
///
/// Everything here is deterministic: no random value, no daily alternation, no
/// minimum percentage and no per-user learning. The normalization scales are
/// fixed constants produced once, offline, by the engine's calibration script
/// and copied here verbatim.
///
/// A percentage produced here is symbolic alignment. It is not the probability
/// that a real-world decision will succeed.
library;

import 'dart:math' as math;

import 'core.dart';
import 'numbers.dart';

/// Identifies the scoring system itself, independently of the engine build.
const String scoringVersion = 'v9.2-experimental';

/// The nine signals, in the order the Node engine lists them.
const List<String> signalNames = <String>[
  'P',
  'C',
  'L',
  'T',
  'M',
  'R',
  'G',
  'H',
  'Y',
];

/// `P` reads only the three personal-chart modules.
const List<String> _prospectModules = <String>['B', 'Z', 'W'];

/// `L` reads the almanac, the Vedic transit and numerology, in that order.
const List<(String, double)> _luckParts = <(String, double)>[
  ('T', 0.50),
  ('V', 0.30),
  ('N', 0.20),
];

/// Subtracted from `L` in proportion to the coverage behind it, so an ordinary
/// day does not read as lucky merely because the sources exist.
const double scoringLuckBaseline = 0.05;

/// The spread, in raw `Q` units, that saturates the timing signal.
const double _timingSpread = 0.40;

/// How far the fourteen-day median pushes today away from itself.
const double medianPush = 0.5;

/// The display curve's exponent: flatter than the old 0.65, so a real lean shows.
const double displayExponent = 0.55;

/// Identifies the cohort the scales below were measured on.
///
/// Measured by `node scripts/calibrate-v91.mjs --profiles 120 --seed 20260930`
/// in the reference engine: 374 readings from 120 synthetic profiles across
/// seven categories, four periods and twenty timezones, with roughly a third
/// of the profiles having no birth hour. Copied here verbatim — the two
/// engines must normalize identically or the same reading would show a
/// different percentage depending on where it was calculated.
const String scaleVersion = 'v9.2-cohort-2026-09-30';

/// Normalization scales, one per signal, each four times the 75th percentile
/// of that signal's absolute raw value across the calibration cohort.
///
/// Constants on purpose: nothing at runtime may learn, tune or per-user adjust
/// them, or two readers would stop being comparable and a saved reading would
/// stop reproducing from its snapshot.
const Map<String, double> scales = <String, double>{
  'P': 0.1650744988,
  'C': 0.3025025936,
  'L': 0.7610000000,
  'T': 0.5170646117,
  'M': 0.3683472651,
  'R': 0.1269505512,
  'G': 0.1432921879,
  'H': 0.1769609522,
  'Y': 0.8748830544,
};

/// Which signals each mode mixes, and in what proportion.
///
/// LEFT / RIGHT gained a personal share in v9.2. Under v9.1 it was `Y` alone,
/// which made it the only mode that read nothing about the person: two readers
/// on the same date with the same hour branch got the same polarity. It also
/// made it by far the most extreme mode, because `Y` carries half its weight
/// on three terms that are each exactly +1 or -1. It keeps the largest share,
/// so the polarity convention still decides it.
const Map<String, Map<String, double>> modeSignals =
    <String, Map<String, double>>{
      'yes_no': <String, double>{'P': 0.45, 'C': 0.20, 'L': 0.35},
      'act_wait': <String, double>{'P': 0.30, 'C': 0.10, 'T': 0.30, 'L': 0.30},
      'advance_retreat': <String, double>{'P': 0.25, 'M': 0.60, 'L': 0.15},
      'stay_go': <String, double>{'G': 0.70, 'P': 0.20, 'L': 0.10},
      'keep_let_go': <String, double>{'R': 0.70, 'P': 0.20, 'L': 0.10},
      'commit_withdraw': <String, double>{'H': 0.80, 'P': 0.15, 'L': 0.05},
      'left_right': <String, double>{'Y': 0.70, 'P': 0.20, 'L': 0.10},
    };

/// What each mixture is divided by, so that the seven modes read on one scale.
///
/// A weighted average of several roughly independent signals is narrower than
/// any one of them: with weights summing to one, the spread shrinks by
/// `sqrt(sum of w squared)`. Under v9.1 that made a four-signal mode
/// structurally milder than a one-signal mode, and the held-out simulation
/// showed it plainly — LEFT / RIGHT reached 80%+ on 24.6% of readings while
/// YES / NO never reached it at all. The percentage therefore meant something
/// different depending on which question had been asked.
///
/// Dividing by that same `sqrt(sum of w squared)` restores a common footing.
/// It is derived from the weights alone — no cohort, no per-user value,
/// nothing fitted — and it is strictly positive, so it can never change which
/// side a mode names, only how far from the middle it reads.
///
/// The cost is real and is recorded in `VERIFICATION.md`: a mixture that
/// averages away more of its evidence is no longer shown as correspondingly
/// less certain.
final Map<String, double> modeGain = <String, double>{
  for (final entry in modeSignals.entries)
    entry.key:
        1 /
        math.sqrt(entry.value.values.fold<double>(0, (sum, w) => sum + w * w)),
};

/// Validated once, as the Node engine does at module load: a mixture that does
/// not sum to one would quietly rescale a whole mode.
void validateModeSignals() {
  for (final entry in modeSignals.entries) {
    final mixture = entry.value;
    if (mixture.keys.any((name) => !signalNames.contains(name))) {
      throw EngineFailure('MODE_SIGNAL_UNKNOWN:${entry.key}');
    }
    if (!mixture.values.every((w) => w.isFinite && w > 0)) {
      throw EngineFailure('MODE_SIGNAL_VALUE:${entry.key}');
    }
    final total = mixture.values.fold<double>(0, (s, w) => s + w);
    if ((total - 1).abs() > 1e-9) {
      throw EngineFailure('MODE_SIGNAL_NOT_NORMALIZED:${entry.key}');
    }
  }
  for (final name in signalNames) {
    final scale = scales[name];
    if (scale == null || !scale.isFinite || scale <= 0) {
      throw EngineFailure('SCALE_INVALID:$name');
    }
  }
}

/// Which signals a mode needs, so a reading only pays for the days it reads.
List<String> signalsNeededBy(String mode) {
  final mixture = modeSignals[mode];
  if (mixture == null) throw const EngineFailure('INVALID_DECISION_MODE');
  return mixture.keys.toList(growable: false);
}

// ---------------------------------------------------------------------------
// Signals that need only the anchor instant
// ---------------------------------------------------------------------------

double _cov(Map<String, ModuleResult> m, String id) => m[id]!.evidence.coverage;
double _a(Map<String, ModuleResult> m, String id) => m[id]!.evidence.a;
double _c(Map<String, ModuleResult> m, String id) => m[id]!.evidence.c;

/// `P` — prospect.
///
/// The denominator is the sum of the three modules' *weights*, never the sum
/// of the weights that happened to have coverage, so a missing chart pulls `P`
/// toward zero instead of handing its share to the survivors.
double prospect(
  Map<String, ModuleResult> modules,
  Map<String, double> weights,
) {
  var numerator = 0.0;
  var denominator = 0.0;
  for (final id in _prospectModules) {
    final weight = weights[id]!;
    denominator += weight;
    numerator += weight * _cov(modules, id) * _a(modules, id);
  }
  return denominator > 0 ? numerator / denominator : 0.0;
}

/// `C` — change pressure, across every module, coverage applied once.
double changePressure(
  Map<String, ModuleResult> modules,
  Map<String, double> weights,
) {
  var sum = 0.0;
  for (final id in weights.keys) {
    sum += weights[id]! * _cov(modules, id) * _c(modules, id);
  }
  return sum;
}

/// `L` — the moment's own auspiciousness, less the coverage-scaled baseline.
double luck(Map<String, ModuleResult> modules) {
  var sum = 0.0;
  var base = 0.0;
  for (final (id, weight) in _luckParts) {
    sum += weight * _cov(modules, id) * _a(modules, id);
    base += weight * _cov(modules, id);
  }
  return sum - scoringLuckBaseline * base;
}

/// `Q` — the blended alignment of one moment, used by `T` and by windows.
double alignment(double p, double l) => 0.70 * p + 0.30 * l;

/// `R` — release: support, minus pressure, with Zi Wei casting the last vote.
double release(double p, double c, double ziWeiSupport) =>
    0.50 * p - 0.35 * c + 0.15 * ziWeiSupport;

/// Even is yang (+1), odd is yin (−1), on the engine's own zero-based stem and
/// branch indices and on the one-based personal day.
///
/// A stated symbolic convention, not a discovered fact. Positive `Y` selects
/// LEFT, and it is never advice about traffic, driving or any physical
/// direction.
int parity(int n) => n % 2 == 0 ? 1 : -1;

/// `Y` — symbolic polarity.
double polarity({
  required int dayStem,
  required int hourBranch,
  required int personalDay,
  required double ziWeiChange,
  required double westernChange,
  required double baZiChange,
}) =>
    0.20 * parity(dayStem) +
    0.15 * parity(hourBranch) +
    0.15 * parity(personalDay) +
    0.25 * ziWeiChange -
    0.15 * westernChange +
    0.10 * baZiChange;

/// Every quantity one evaluated instant contributes to a score.
class MomentSignals {
  const MomentSignals({
    required this.p,
    required this.c,
    required this.l,
    required this.q,
    required this.r,
    required this.y,
    required this.ziWeiSupport,
    required this.baZiSupport,
  });

  final double p;
  final double c;
  final double l;
  final double q;
  final double r;
  final double y;

  /// Coverage-scaled module support axes, kept so `H` never re-opens a module.
  final double ziWeiSupport;
  final double baZiSupport;
}

MomentSignals momentSignals(
  Map<String, ModuleResult> modules,
  Map<String, double> weights, {
  required int dayStem,
  required int hourBranch,
}) {
  final p = prospect(modules, weights);
  final c = changePressure(modules, weights);
  final l = luck(modules);
  final ziWeiSupport = _cov(modules, 'Z') * _a(modules, 'Z');
  final baZiSupport = _cov(modules, 'B') * _a(modules, 'B');
  return MomentSignals(
    p: p,
    c: c,
    l: l,
    q: alignment(p, l),
    ziWeiSupport: ziWeiSupport,
    baZiSupport: baZiSupport,
    r: release(p, c, ziWeiSupport),
    y: polarity(
      dayStem: dayStem,
      hourBranch: hourBranch,
      personalDay: modules['N']!.diagnostics['personalDay']! as int,
      ziWeiChange: _cov(modules, 'Z') * _c(modules, 'Z'),
      westernChange: _cov(modules, 'W') * _c(modules, 'W'),
      baZiChange: _cov(modules, 'B') * _c(modules, 'B'),
    ),
  );
}

// ---------------------------------------------------------------------------
// Signals that read other moments
// ---------------------------------------------------------------------------

/// `T` — where this moment sits against the rest of today.
///
/// With nothing left in the day the signal is zero rather than an invented
/// advantage.
double timing(double selectedQ, List<double> laterQs) {
  if (laterQs.isEmpty) return 0;
  final mean = laterQs.fold<double>(0, (s, x) => s + x) / laterQs.length;
  return clampUnit((selectedQ - mean) / _timingSpread);
}

/// `M` — today's change pressure against the previous three local dates.
double momentum(double todayC, List<double> priorCs) {
  if (priorCs.isEmpty) return 0;
  return todayC - priorCs.fold<double>(0, (s, x) => s + x) / priorCs.length;
}

/// `G` — grounding: support minus pressure, penalised by however much better
/// the far end of the week looks.
double grounding(double p, double c, double? horizonEndP) =>
    0.35 * p - 0.45 * c - 0.20 * ((horizonEndP ?? p) - p);

/// The middle value; the mean of the two middles for an even count.
double median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = List<double>.of(values)..sort();
  final mid = sorted.length >> 1;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// `H` — the durable middle of today plus the seven days after it.
///
/// Medians rather than means on purpose: one extraordinary day should not
/// carry a week, which is also why COMMIT/WITHDRAW does not flip daily.
double horizon(List<MomentSignals> series) =>
    0.50 * median(<double>[for (final x in series) x.p]) +
    0.30 * median(<double>[for (final x in series) x.ziWeiSupport]) +
    0.20 * median(<double>[for (final x in series) x.baZiSupport]);

// ---------------------------------------------------------------------------
// Normalization, mode score and display
// ---------------------------------------------------------------------------

/// `exp(y) - 1` for small `y`, without the cancellation `exp(y) - 1` suffers.
///
/// `dart:math` has no `expm1`. Maclaurin converges quickly over the only range
/// this is called with, `|y| <= 0.25`: the last term kept is below 1e-22.
double _expm1Small(double y) {
  var term = y;
  var sum = y;
  for (var n = 2; n <= 18; n++) {
    term *= y / n;
    sum += term;
  }
  return sum;
}

/// `Math.tanh`, to within about one unit in the last place.
///
/// `dart:math` has no `tanh`, and the two engines have to normalize
/// identically or the same reading would show a different percentage depending
/// on where it was calculated. This follows the same shape as the C library
/// the Node engine ends up in: an `expm1` form near zero, where `1 - exp(-2x)`
/// would cancel away most of its significant digits, and the direct
/// exponential form elsewhere. `test/local_engine/scoring_test.dart` checks it
/// against known values, and `golden_reading_parity_test.dart` checks whole
/// readings against the Node engine's own output.
double jsTanh(double x) {
  if (x.isNaN) return x;
  if (x == 0) return x;
  if (x.isInfinite) return x.isNegative ? -1.0 : 1.0;
  final ax = x.abs();
  // Below this, `tanh(x)` and `x` are the same double.
  if (ax < 1e-9) return x;
  // Above this, `tanh(x)` is 1.0 to the last bit.
  if (ax > 20) return x.isNegative ? -1.0 : 1.0;
  final double z;
  if (ax < 0.125) {
    final t = _expm1Small(-2 * ax);
    z = -t / (t + 2);
  } else {
    final e = math.exp(-2 * ax);
    z = (1 - e) / (1 + e);
  }
  return x.isNegative ? -z : z;
}

/// `tanh(raw / scale)` against the fixed, versioned scale for that signal.
double normalizeSignal(String name, double raw) {
  final scale = scales[name];
  if (scale == null) throw EngineFailure('UNKNOWN_SIGNAL:$name');
  if (!raw.isFinite) throw EngineFailure('SIGNAL_NOT_FINITE:$name');
  return jsTanh(raw / scale);
}

/// Every named raw signal, normalized.
Map<String, double> normalizeAll(Map<String, double> raw) => <String, double>{
  for (final entry in raw.entries)
    entry.key: normalizeSignal(entry.key, entry.value),
};

/// The first option's raw score for one mode, from normalized signals.
///
/// Raw here means "before the fourteen-day median adjustment"; it is the value
/// the prior dates contribute to that median.
double modeScore(String mode, Map<String, double> normalized) {
  final mixture = modeSignals[mode];
  if (mixture == null) throw const EngineFailure('INVALID_DECISION_MODE');
  var score = 0.0;
  for (final entry in mixture.entries) {
    final value = normalized[entry.key];
    if (value == null) throw EngineFailure('MISSING_SIGNAL:$mode:${entry.key}');
    score += entry.value * value;
  }
  return clampUnit(score * modeGain[mode]!);
}

/// Push today away from its own fortnight.
///
/// A day that reads like every other day of the last two weeks stays where it
/// is; a day that genuinely departs from them is allowed to say so. A contrast
/// term, not a guaranteed flip and not a minimum.
double adjustAgainstHistory(double todayScore, List<double> prior14) {
  if (prior14.isEmpty) return clampUnit(todayScore);
  return clampUnit(todayScore + medianPush * (todayScore - median(prior14)));
}

/// The display band, in tenths of a percent so the pair sums to exactly 100.0.
///
/// `50 + 40 · sign(s) · |s|^0.55`, so a full-scale score shows 90.0 / 10.0 and
/// a genuinely neutral one shows 50.0 / 50.0.
int displayTenths(double score) {
  final s = clampUnit(score);
  final sign = s < 0
      ? -1
      : s > 0
      ? 1
      : 0;
  final expanded = (sign * math.pow(s.abs(), displayExponent)).toDouble();
  return (500 + 400 * clampUnit(expanded) + .5).floor();
}

/// The same band as a whole percent, used where a window shows one number.
int displayPercent(double score) => jsRound(displayTenths(score) / 10).toInt();
