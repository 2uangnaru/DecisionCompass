/// Port of `calculation-engine/src/bazi.js`.
///
/// Builds the four pillars, hidden stems, Ten Gods, element distribution and
/// (when the birth instant and convention are both known) the decade cycle,
/// then scores the active time layers against them.
///
/// Two things are deliberately *not* computed: an automatic Yong Shen / Xi Shen
/// and the special chart transformations. The engine emits null for those and
/// reduces coverage instead of inventing a favourable element, and the
/// strength index is labelled a descriptive seasonal index for the same reason.
library;

import '../core/core.dart';
import '../core/numbers.dart';
import '../calendar/calendar.dart';
import '../time/local_time.dart';

/// Hidden stems of each earthly branch, principal stem first.
const List<List<int>> hiddenStems = <List<int>>[
  <int>[9],
  <int>[5, 9, 7],
  <int>[0, 2, 4],
  <int>[1],
  <int>[4, 1, 9],
  <int>[2, 6, 4],
  <int>[3, 5],
  <int>[5, 3, 1],
  <int>[6, 8, 4],
  <int>[7],
  <int>[4, 7, 3],
  <int>[8, 0],
];

const List<List<String>> _godIds = <List<String>>[
  <String>['peer', 'competitor'],
  <String>['expression', 'challenge'],
  <String>['opportunity', 'stewardship'],
  <String>['pressure', 'responsibility'],
  <String>['reflection', 'support'],
];

const Map<String, List<double>> _gods = <String, List<double>>{
  'peer': <double>[.1, -.25],
  'competitor': <double>[.05, .25],
  'expression': <double>[.3, .25],
  'challenge': <double>[.1, .4],
  'opportunity': <double>[.2, .35],
  'stewardship': <double>[.15, -.2],
  'pressure': <double>[-.25, .2],
  'responsibility': <double>[.1, -.15],
  'reflection': <double>[-.2, -.1],
  'support': <double>[.2, -.2],
};

const Map<String, double> _layers = <String, double>{
  'decade': .10,
  'yearly': .15,
  'monthly': .15,
  'daily': .30,
  'hourly': .30,
};

const List<List<int>> _combinations = <List<int>>[
  <int>[0, 1],
  <int>[2, 11],
  <int>[3, 10],
  <int>[4, 9],
  <int>[5, 8],
  <int>[6, 7],
];
const List<List<int>> _harms = <List<int>>[
  <int>[0, 7],
  <int>[1, 6],
  <int>[2, 5],
  <int>[3, 4],
  <int>[8, 11],
  <int>[9, 10],
];
const List<List<int>> _breaks = <List<int>>[
  <int>[0, 9],
  <int>[1, 4],
  <int>[2, 11],
  <int>[3, 6],
  <int>[5, 8],
  <int>[7, 10],
];

bool _inPairs(int a, int b, List<List<int>> rows) => rows.any(
  (row) => (a == row[0] && b == row[1]) || (a == row[1] && b == row[0]),
);

/// Which of the Ten Gods [other] is, seen from day master [day].
String tenGod(int day, int other) =>
    _godIds[jsMod((other ~/ 2) - (day ~/ 2), 5)][day % 2 == other % 2 ? 0 : 1];

/// Every named relation between two earthly branches.
List<String> relations(int a, int b) {
  final result = <String>[];
  if (a == b) result.add('same');
  if (jsMod(a - b, 12) == 6) result.add('clash');
  if (_inPairs(a, b, _combinations)) result.add('combination');
  if (_inPairs(a, b, _harms)) result.add('harm');
  if (_inPairs(a, b, _breaks)) result.add('break');
  if (_inPairs(a, b, const <List<int>>[
    <int>[0, 3],
  ]))
    result.add('punishment');
  if (a == b && const <int>[4, 6, 9, 11].contains(a))
    result.add('self_punishment');
  return result;
}

List<double> _branchVector(int a, int b) {
  // v2 scoring preserved. Additional relations stay diagnostics until they are
  // separately weighted; overlapping relations must not be counted twice.
  if (a == b) return const <double>[.1, -.2];
  if (jsMod(a - b, 12) == 6) return const <double>[-.5, .5];
  if (_inPairs(a, b, _combinations)) return const <double>[.5, -.4];
  return const <double>[0, 0];
}

/// The decade-cycle anchor, present only when the birth instant and the
/// traditional convention are both known.
class DecadeAnchor {
  const DecadeAnchor({
    required this.forward,
    required this.startUtc,
    required this.birthZone,
    required this.startAge,
    required this.referenceTerm,
  });

  final bool forward;
  final double startUtc;
  final String birthZone;
  final Map<String, int> startAge;
  final SolarTerm referenceTerm;
}

/// A built natal BaZi chart.
class BaZiChart {
  BaZiChart({
    required this.pillars,
    required this.tenGods,
    required this.elementDistribution,
    required this.seasonalDistribution,
    required this.supportIndex,
    required this.rootPositions,
    required this.structures,
    required this.pairs,
    required this.coverage,
    required this.missing,
    this.decade,
  });

  final List<Pillar?> pillars;
  final List<Map<String, Object?>?> tenGods;
  final List<double> elementDistribution;
  final List<double> seasonalDistribution;
  final double supportIndex;
  final List<int> rootPositions;
  final List<Map<String, Object?>> structures;
  final List<Map<String, Object?>> pairs;
  final double coverage;
  final List<String> missing;
  DecadeAnchor? decade;

  /// Never inferred: the engine reports the absence rather than guessing.
  Object? get traditionalYongShen => null;
  Object? get traditionalXiShen => null;
}

BaZiChart buildBaZi(BirthContext birth, String? traditionalProfile) {
  final pillars = natalPillars(birth);
  final dayMaster = pillars[2]!.stem;
  final dayMasterElement = dayMaster ~/ 2;

  final mass = List<double>.filled(5, 0);
  const weights = <double>[1, 1.5, 1, 1];
  var present = 0.0;

  final gods = <Map<String, Object?>?>[];
  for (var i = 0; i < pillars.length; i++) {
    final p = pillars[i];
    if (p == null) {
      gods.add(null);
      continue;
    }
    present += weights[i];
    mass[p.stem ~/ 2] += .4 * weights[i];
    for (final s in hiddenStems[p.branch]) {
      mass[s ~/ 2] += .6 * weights[i] / hiddenStems[p.branch].length;
    }
    gods.add(<String, Object?>{
      'visible': tenGod(dayMaster, p.stem),
      'hidden': <Map<String, Object?>>[
        for (final s in hiddenStems[p.branch])
          <String, Object?>{'stem': s, 'god': tenGod(dayMaster, s)},
      ],
    });
  }

  final distribution = mass.map((v) => v / present).toList();
  final branchList = pillars.whereType<Pillar>().map((p) => p.branch).toList();

  final structures = <Map<String, Object?>>[];
  for (final set in const <List<int>>[
    <int>[8, 0, 4],
    <int>[11, 3, 7],
    <int>[2, 6, 10],
    <int>[5, 9, 1],
  ]) {
    if (set.every(branchList.contains)) {
      structures.add(<String, Object?>{
        'type': 'three_harmony',
        'branches': set,
        'transformationConfirmed': false,
      });
    }
  }
  for (final set in const <List<int>>[
    <int>[2, 5, 8],
    <int>[1, 10, 7],
  ]) {
    if (set.every(branchList.contains)) {
      structures.add(<String, Object?>{
        'type': 'three_punishment',
        'branches': set,
      });
    }
  }

  final pairs = <Map<String, Object?>>[];
  for (var i = 0; i < 4; i++) {
    for (var j = i + 1; j < 4; j++) {
      final a = pillars[i];
      final b = pillars[j];
      if (a == null || b == null) continue;
      pairs.add(<String, Object?>{
        'positions': <int>[i, j],
        'branches': relations(a.branch, b.branch),
        'stemCombination': jsMod(a.stem - b.stem, 10) == 5,
        'transformationConfirmed': false,
      });
    }
  }

  // A season-adjusted descriptive index. Do not equate it to a certified
  // Yong Shen.
  final month = pillars[1];
  final seasonal = List<double>.of(distribution);
  if (month != null) {
    final seasonElement = hiddenStems[month.branch][0] ~/ 2;
    const factors = <double>[1, .8, .5, .4, .6];
    for (var e = 0; e < 5; e++) {
      seasonal[e] *= factors[jsMod(e - seasonElement, 5)];
    }
    final total = seasonal.fold<double>(0, (a, b) => a + b);
    for (var e = 0; e < 5; e++) {
      seasonal[e] /= total;
    }
  }

  final chart = BaZiChart(
    pillars: pillars,
    tenGods: gods,
    elementDistribution: distribution,
    seasonalDistribution: seasonal,
    supportIndex:
        seasonal[dayMasterElement] + seasonal[jsMod(dayMasterElement - 1, 5)],
    rootPositions: <int>[
      for (var i = 0; i < pillars.length; i++)
        if (pillars[i] != null &&
            hiddenStems[pillars[i]!.branch].any(
              (s) => s ~/ 2 == dayMasterElement,
            ))
          i,
    ],
    structures: structures,
    pairs: pairs,
    coverage: present / 4.5,
    missing: <String>[
      for (var i = 0; i < pillars.length; i++)
        if (pillars[i] == null)
          const <String>['year', 'month', 'day', 'hour'][i],
    ],
  );

  if (birth.exact &&
      pillars[0] != null &&
      pillars[1] != null &&
      (traditionalProfile == 'male' || traditionalProfile == 'female')) {
    final instant = birth.intervals[0].start;
    final zone = birth.intervals[0].zone;
    final forward =
        (pillars[0]!.stem % 2 == 0) == (traditionalProfile == 'male');
    final terms = termsAround(instant).where((t) => t.monthIndex >= 0).toList();
    final SolarTerm term = forward
        ? terms.firstWhere((t) => t.instant > instant)
        : terms.lastWhere((t) => t.instant <= instant);
    var minutes = ((term.instant - instant).abs() / 60000).floor();
    final years = minutes ~/ 4320;
    minutes %= 4320;
    final months = minutes ~/ 360;
    minutes %= 360;
    final days = minutes ~/ 12;
    final hours = (minutes % 12) * 2;
    chart.decade = DecadeAnchor(
      forward: forward,
      startUtc: addCivil(instant, zone, years, months, days, hours),
      birthZone: zone,
      startAge: <String, int>{
        'years': years,
        'months': months,
        'days': days,
        'hours': hours,
      },
      referenceTerm: term,
    );
  }

  return chart;
}

/// Which decade pillar is active at an instant, or null before the cycle
/// starts / when it could not be computed.
class ActiveDecade {
  const ActiveDecade(this.pillar, this.index, this.startUtc, this.endUtc);

  final Pillar pillar;
  final int index;
  final double startUtc;
  final double endUtc;
}

ActiveDecade? decadeAt(BaZiChart chart, double ms) {
  final d = chart.decade;
  if (d == null || ms < d.startUtc) return null;
  var n = 1;
  while (n < 20 && ms >= addCivil(d.startUtc, d.birthZone, n * 10)) {
    n++;
  }
  final cycle = jsMod(
    cyclical(chart.pillars[1]!.stem, chart.pillars[1]!.branch) +
        (d.forward ? n : -n),
    60,
  );
  return ActiveDecade(
    pillar(cycle % 10, cycle % 12),
    n,
    addCivil(d.startUtc, d.birthZone, (n - 1) * 10),
    addCivil(d.startUtc, d.birthZone, n * 10),
  );
}

/// All decade boundaries, used as extra segment boundaries so a cycle change
/// never lands inside a scored segment.
List<double> decadeBoundaries(BaZiChart chart) {
  final d = chart.decade;
  if (d == null) return const <double>[];
  return <double>[
    for (var i = 0; i < 20; i++) addCivil(d.startUtc, d.birthZone, i * 10),
  ];
}

ModuleResult scoreBaZi(BaZiChart chart, CalendarAt cal, double ms) {
  final dayMaster = chart.pillars[2]!.stem;
  const positionWeights = <double>[.1, .2, .5, .2];
  final known = <({Pillar pillar, double weight})>[
    for (var i = 0; i < chart.pillars.length; i++)
      if (chart.pillars[i] != null)
        (pillar: chart.pillars[i]!, weight: positionWeights[i]),
  ];
  final total = known.fold<double>(0, (s, x) => s + x.weight);
  final decade = decadeAt(chart, ms);

  final timing = <String, Pillar>{
    'yearly': cal.year,
    'monthly': cal.month,
    'daily': cal.day,
    'hourly': cal.hour,
  };
  if (decade != null) timing['decade'] = decade.pillar;

  final parts = <(double, Evidence)>[];
  final layerDiagnostics = <String, Object?>{};

  for (final entry in timing.entries) {
    final p = entry.value;
    final hidden = hiddenStems[p.branch];
    final stems = <(double, int)>[
      (.4, p.stem),
      for (final s in hidden) (.6 / hidden.length, s),
    ];
    final gv = <double>[
      for (var k = 0; k < 2; k++)
        stems.fold<double>(
          0,
          (sum, x) => sum + x.$1 * _gods[tenGod(dayMaster, x.$2)]![k],
        ),
    ];
    final bv = <double>[
      for (var k = 0; k < 2; k++)
        known.fold<double>(
          0,
          (sum, x) =>
              sum +
              x.weight / total * _branchVector(p.branch, x.pillar.branch)[k],
        ),
    ];
    // The 15% favourable-element component stays absent: no manufactured
    // Yong Shen.
    final blended = blend(<(double, Evidence)>[
      (.55, Evidence(gv[0], gv[1], 1)),
      (.30, Evidence(bv[0], bv[1], 1)),
    ]);
    parts.add((
      _layers[entry.key]!,
      Evidence(blended.a, blended.c, blended.coverage * chart.coverage),
    ));
    layerDiagnostics[entry.key] = <String, Object?>{
      'pillar': p.text,
      'relations': <List<String>>[
        for (final x in known) relations(p.branch, x.pillar.branch),
      ],
    };
  }

  return ModuleResult(blend(parts), <String, Object?>{
    'activeDecade': decade == null
        ? null
        : <String, Object?>{
            'pillar': decade.pillar.text,
            'index': decade.index,
          },
    'layers': layerDiagnostics,
    'excludedRules': const <String>[
      'automatic_yong_shen',
      'special_chart_transformations',
    ],
    'method': 'bazi_expanded_v2_generated_inputs',
  });
}
