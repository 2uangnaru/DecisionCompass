/// Port of `calculation-engine/src/core.js`.
///
/// Versions, category weight profiles, the seven decision-mode projections and
/// the evidence algebra that fuses module output into the two axes. These are
/// editorial product rules, not validated predictive weights, and the
/// percentage they produce is a symbolic alignment — never a probability.
library;

import 'dart:math' as math;

import 'numbers.dart';

const String engineVersion = '3.5.0-mvp';
const String rulesetVersion = 'civil-midnight-chinese-calendar-symbolic-v8';

/// Default module weights: BaZi, Zi Wei, almanac, Western, Vedic, numerology, cosmic.
const Map<String, double> defaultWeights = <String, double>{
  'B': .18,
  'Z': .18,
  'T': .10,
  'W': .18,
  'V': .16,
  'N': .15,
  'U': .05,
};

const double luckBaseline = 0.05;

const List<String> categories = <String>[
  'general',
  'love',
  'career',
  'money',
  'study',
  'friends',
  'other',
];

/// Category changes how module evidence is fused, never the decision-mode
/// projections below. `other` deliberately reuses the general formula: an
/// honest fallback beats inventing a profile for "something else".
const Map<String, Map<String, double>> categoryWeights =
    <String, Map<String, double>>{
      'general': defaultWeights,
      'other': defaultWeights,
      'love': <String, double>{
        'B': .16,
        'Z': .24,
        'T': .07,
        'W': .22,
        'V': .16,
        'N': .10,
        'U': .05,
      },
      'career': <String, double>{
        'B': .22,
        'Z': .20,
        'T': .12,
        'W': .15,
        'V': .16,
        'N': .10,
        'U': .05,
      },
      'money': <String, double>{
        'B': .20,
        'Z': .22,
        'T': .13,
        'W': .14,
        'V': .16,
        'N': .10,
        'U': .05,
      },
      'study': <String, double>{
        'B': .18,
        'Z': .15,
        'T': .11,
        'W': .18,
        'V': .15,
        'N': .18,
        'U': .05,
      },
      'friends': <String, double>{
        'B': .15,
        'Z': .20,
        'T': .08,
        'W': .22,
        'V': .15,
        'N': .15,
        'U': .05,
      },
    };

/// Validated once, as the Node engine does at module load: a malformed profile
/// must fail loudly rather than skew a reading silently.
void validateCategoryProfiles() {
  for (final category in categories) {
    final profile = categoryWeights[category];
    if (profile == null)
      throw EngineFailure('CATEGORY_PROFILE_MISSING:$category');
    if (profile.length != defaultWeights.length ||
        profile.keys.any((name) => !defaultWeights.containsKey(name))) {
      throw EngineFailure('CATEGORY_PROFILE_MODULES:$category');
    }
    if (!profile.values.every((w) => w.isFinite && w >= 0)) {
      throw EngineFailure('CATEGORY_PROFILE_VALUE:$category');
    }
    final total = profile.values.fold<double>(0, (s, w) => s + w);
    if ((total - 1).abs() > 1e-9) {
      throw EngineFailure('CATEGORY_PROFILE_NOT_NORMALIZED:$category');
    }
  }
}

/// A deterministic engine failure, carrying the Node engine's own error code.
class EngineFailure implements Exception {
  const EngineFailure(this.code);

  final String code;

  @override
  String toString() => 'EngineFailure($code)';
}

Map<String, double> weightsFor([String category = 'general']) {
  final profile = categoryWeights[category];
  if (profile == null) throw const EngineFailure('INVALID_CATEGORY');
  return profile;
}

/// One decision mode: its two labels and how it projects the two fusion axes.
class ModeDefinition {
  const ModeDefinition({
    required this.labels,
    required this.a,
    required this.c,
    required this.sign,
    required this.basis,
  });

  final List<String> labels;
  final double a;
  final double c;
  final int sign;
  final String basis;
}

/// The seven independent projections. LEFT/RIGHT is symbolic polarity only —
/// receptive/inward versus expressive/outward — and must never be presented as
/// physical navigation.
const Map<String, ModeDefinition> modes = <String, ModeDefinition>{
  'yes_no': ModeDefinition(
    labels: <String>['YES', 'NO'],
    a: 1,
    c: 0,
    sign: 1,
    basis: 'overall_acceptance',
  ),
  'act_wait': ModeDefinition(
    labels: <String>['ACT', 'WAIT'],
    a: .85,
    c: .15,
    sign: 1,
    basis: 'action_timing',
  ),
  'advance_retreat': ModeDefinition(
    labels: <String>['ADVANCE', 'RETREAT'],
    a: .55,
    c: .45,
    sign: 1,
    basis: 'tactical_momentum',
  ),
  'stay_go': ModeDefinition(
    labels: <String>['STAY', 'GO'],
    a: 0,
    c: 1,
    sign: -1,
    basis: 'change_alignment',
  ),
  'keep_let_go': ModeDefinition(
    labels: <String>['KEEP', 'LET GO'],
    a: -.3,
    c: .7,
    sign: -1,
    basis: 'release_alignment',
  ),
  'forward_backward': ModeDefinition(
    labels: <String>['FORWARD', 'BACKWARD'],
    a: .25,
    c: .75,
    sign: 1,
    basis: 'temporal_momentum',
  ),
  'left_right': ModeDefinition(
    labels: <String>['LEFT', 'RIGHT'],
    a: .7,
    c: -.3,
    sign: -1,
    basis: 'symbolic_polarity',
  ),
};

/// Evidence from one module or from the fusion: two axis values plus how much
/// of the module's inputs were actually available.
class Evidence {
  const Evidence._(this.a, this.c, this.coverage);

  factory Evidence([double a = 0, double c = 0, double coverage = 0]) {
    if (!a.isFinite ||
        !c.isFinite ||
        !coverage.isFinite ||
        a.abs() > 1.00000001 ||
        c.abs() > 1.00000001 ||
        coverage < 0 ||
        coverage > 1.00000001) {
      throw const EngineFailure('INVALID_EVIDENCE');
    }
    return Evidence._(clampUnit(a), clampUnit(c), coverage < 1 ? coverage : 1);
  }

  final double a;
  final double c;
  final double coverage;

  double axis(int index) => index == 0 ? a : c;

  Evidence withCoverage(double value) => Evidence(a, c, value);
}

/// Within a module, normalize the available components and keep coverage
/// separate.
Evidence blend(List<(double, Evidence)> parts) {
  final q = parts.fold<double>(0, (s, p) => s + p.$1 * p.$2.coverage);
  if (q == 0) return Evidence();
  final values = <double>[
    for (var k = 0; k < 2; k++)
      clampUnit(
        parts.fold<double>(
              0,
              (s, p) => s + p.$1 * p.$2.coverage * p.$2.axis(k),
            ) /
            q,
      ),
  ];
  return Evidence(values[0], values[1], q);
}

/// At the final boundary coverage is applied exactly once; a missing module is
/// never redistributed across the others, whichever category profile is used.
Evidence combine(
  Map<String, ModuleResult> modules, [
  String category = 'general',
]) {
  final weights = weightsFor(category);
  var a = 0.0;
  var c = 0.0;
  var coverage = 0.0;
  for (final entry in modules.entries) {
    final weight = weights[entry.key];
    if (weight == null) throw EngineFailure('UNKNOWN_MODULE:${entry.key}');
    final e = entry.value.evidence;
    // Re-validated at the boundary, exactly as the Node engine does: a module
    // that produced an out-of-range value must fail the reading, not skew it.
    Evidence(e.a, e.c, e.coverage);
    final w = weight * e.coverage;
    a += w * e.a;
    c += w * e.c;
    coverage += w;
  }
  return Evidence(clampUnit(a), clampUnit(c), coverage < 1 ? coverage : 1);
}

/// The same projection carried to one decimal, as an integer number of tenths.
int percentTenths(double score) {
  final s = clampUnit(score);
  final sign = s < 0 ? -1 : s > 0 ? 1 : 0;
  final expanded = (sign * math.pow(s.abs(), 0.65)).toDouble();
  return (500 + 400 * clampUnit(expanded) + .5).floor();
}

/// Maps a symbolic score in [-1, 1] onto the 10–90 display band.
int percent(double score) => ((percentTenths(score) + 5) / 10).floor();

double scoreForMode(Evidence e, String mode) {
  final definition = modes[mode];
  if (definition == null) throw const EngineFailure('INVALID_DECISION_MODE');
  return clampUnit(definition.sign * (definition.a * e.a + definition.c * e.c));
}

/// The decision block of a reading: status, winner, percentages and the
/// bookkeeping that goes with them.
class Decision {
  const Decision({
    required this.status,
    required this.percentages,
    required this.winner,
    this.dataCoverage,
    this.modeScore,
    this.modeBasis,
    this.meaning,
  });

  final String status;

  /// Integer tenths of a percent, so the pair sums to exactly 1000.
  final Map<String, int>? percentages;
  final String? winner;
  final double? dataCoverage;
  final double? modeScore;
  final String? modeBasis;
  final String? meaning;
}

Decision decision(Evidence e, String mode) {
  final definition = modes[mode];
  if (definition == null) throw const EngineFailure('INVALID_DECISION_MODE');
  if (e.coverage == 0) {
    return const Decision(
      status: 'insufficient_data',
      percentages: null,
      winner: null,
    );
  }
  final first = definition.labels[0];
  final second = definition.labels[1];
  final selectedScore = scoreForMode(e, mode);
  final tenths = percentTenths(selectedScore);
  final balanced = tenths == 500;
  return Decision(
    status: balanced ? 'balanced' : 'ready',
    winner: balanced
        ? null
        : tenths > 500
        ? first
        : second,
    percentages: <String, int>{first: tenths, second: 1000 - tenths},
    dataCoverage: roundTen(e.coverage),
    modeScore: roundTen(selectedScore),
    modeBasis: definition.basis,
    meaning: 'symbolic_alignment_not_success_probability',
  );
}

/// Time-weighted mean across the segments of a future period. Module coverage
/// has already been applied to each value.
Evidence weightedTimeAverage(
  List<({double duration, Evidence evidence})> items,
) {
  final seconds = items.fold<double>(0, (s, x) => s + x.duration);
  if (seconds == 0 ||
      items.any((x) => !x.duration.isFinite || x.duration <= 0)) {
    throw const EngineFailure('INVALID_SEGMENTS');
  }
  final values = <double>[
    for (var k = 0; k < 3; k++)
      items.fold<double>(
            0,
            (s, x) =>
                s +
                x.duration *
                    (k == 2 ? x.evidence.coverage : x.evidence.axis(k)),
          ) /
          seconds,
  ];
  return Evidence(values[0], values[1], values[2]);
}

/// A module's contribution, with the diagnostics the engine exposes only when
/// a caller explicitly asks for them.
class ModuleResult {
  ModuleResult(
    this.evidence, [
    this.diagnostics = const <String, Object?>{},
    String? status,
  ]) : status =
           status ??
           (evidence.coverage == 0
               ? 'unavailable'
               : evidence.coverage < .999999
               ? 'partial'
               : 'calculated');

  final String status;
  final Evidence evidence;
  final Map<String, Object?> diagnostics;
}
