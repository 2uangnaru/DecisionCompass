/// Port of `calculation-engine/src/ziwei.js`.
///
/// Scores the natal chart and five time layers against the palaces the chosen
/// category cares about. When the birth hour or the traditional convention is
/// unknown, every possible chart is built and the *conservative* agreement
/// across them is taken, with an explicit coverage penalty — the engine never
/// picks a likely hour or infers a convention from a name.
library;

import '../core/bounded_cache.dart';
import '../core/core.dart';
import '../core/numbers.dart';
import '../calendar/calendar.dart';
import '../time/local_time.dart' show BirthContext, hourBranch;
import 'ziwei_chart.dart';

const Map<String, List<double>> _majorStars = <String, List<double>>{
  '紫微': <double>[.2, -.2],
  '天机': <double>[.1, .5],
  '太阳': <double>[.3, .2],
  '武曲': <double>[.25, -.2],
  '天同': <double>[-.1, -.35],
  '廉贞': <double>[.1, .25],
  '天府': <double>[.2, -.5],
  '太阴': <double>[-.1, -.25],
  '贪狼': <double>[.15, .5],
  '巨门': <double>[-.15, .2],
  '天相': <double>[.15, -.4],
  '天梁': <double>[.1, -.45],
  '七杀': <double>[.1, .55],
  '破军': <double>[-.1, .65],
};

const Map<String, List<double>> _auxiliaryStars = <String, List<double>>{
  '左辅': <double>[.2, -.1],
  '右弼': <double>[.2, -.1],
  '文昌': <double>[.2, 0],
  '文曲': <double>[.2, 0],
  '天魁': <double>[.2, -.1],
  '天钺': <double>[.2, -.1],
  '擎羊': <double>[-.25, .2],
  '陀罗': <double>[-.25, -.1],
  '火星': <double>[-.25, .2],
  '铃星': <double>[-.25, .15],
  '地空': <double>[-.25, .3],
  '地劫': <double>[-.25, .3],
};

const Map<String, double> _brightnessWeights = <String, double>{
  '庙': 1,
  '旺': .95,
  '得': .85,
  '利': .8,
  '平': .7,
  '不': .6,
  '陷': .5,
};

const Map<String, List<double>> _transforms = <String, List<double>>{
  '禄': <double>[.35, -.1],
  '权': <double>[.2, .2],
  '科': <double>[.25, -.2],
  '忌': <double>[-.45, .15],
};

const Map<String, double> _layers = <String, double>{
  'natal': .15,
  'decadal': .15,
  'yearly': .15,
  'monthly': .10,
  'daily': .20,
  'hourly': .25,
};

double _proximity(int palace, int target) {
  final offset = jsMod(palace - target, 12);
  return switch (offset) {
    0 => 1,
    4 => .6,
    8 => .6,
    6 => .5,
    _ => 0,
  };
}

/// One category target: the palace names it accepts (provider aliases listed
/// together) and how much of the reading it carries.
class ZiweiTarget {
  const ZiweiTarget(this.palaces, this.weight);

  final List<String> palaces;
  final double weight;
}

/// Category selects which palace(s) the reading is measured against, replacing
/// a single hard-coded 命宫 target. Symbolic editorial emphases, not a claim
/// about another person.
const Map<String, List<ZiweiTarget>> ziweiCategoryTargets =
    <String, List<ZiweiTarget>>{
      'general': <ZiweiTarget>[
        ZiweiTarget(<String>['命宫'], 1),
      ],
      'other': <ZiweiTarget>[
        ZiweiTarget(<String>['命宫'], 1),
      ],
      'love': <ZiweiTarget>[
        ZiweiTarget(<String>['夫妻'], .75),
        ZiweiTarget(<String>['福德'], .25),
      ],
      'career': <ZiweiTarget>[
        ZiweiTarget(<String>['官禄'], .80),
        ZiweiTarget(<String>['迁移'], .20),
      ],
      'money': <ZiweiTarget>[
        ZiweiTarget(<String>['财帛'], .75),
        ZiweiTarget(<String>['田宅'], .25),
      ],
      'study': <ZiweiTarget>[
        ZiweiTarget(<String>['官禄'], .45),
        ZiweiTarget(<String>['父母'], .30),
        ZiweiTarget(<String>['福德'], .25),
      ],
      'friends': <ZiweiTarget>[
        ZiweiTarget(<String>['仆役', '交友'], .65),
        ZiweiTarget(<String>['兄弟'], .35),
      ],
    };

/// Validated at startup, as the Node engine validates at module load.
void validateZiweiTargets() {
  for (final entry in ziweiCategoryTargets.entries) {
    final spec = entry.value;
    if (spec.isEmpty) throw EngineFailure('ZIWEI_TARGETS_EMPTY:${entry.key}');
    if (!spec.every(
      (t) => t.palaces.isNotEmpty && t.weight.isFinite && t.weight > 0,
    )) {
      throw EngineFailure('ZIWEI_TARGET_VALUE:${entry.key}');
    }
    final total = spec.fold<double>(0, (s, t) => s + t.weight);
    if ((total - 1).abs() > 1e-9) {
      throw EngineFailure('ZIWEI_TARGETS_NOT_NORMALIZED:${entry.key}');
    }
  }
}

class _ResolvedTarget {
  const _ResolvedTarget(this.palace, this.aliases, this.index, this.weight);

  final String palace;
  final List<String> aliases;
  final int index;
  final double weight;
}

/// Resolves each target to a palace index, failing loudly when a palace is
/// absent rather than silently scoring against the wrong one.
List<_ResolvedTarget> _resolveTargets(ZiweiAstrolabe chart, String category) {
  final spec = ziweiCategoryTargets[category];
  if (spec == null) throw const EngineFailure('INVALID_CATEGORY');
  return <_ResolvedTarget>[
    for (final target in spec)
      () {
        final index = chart.palaces.indexWhere(
          (p) => target.palaces.contains(p.name),
        );
        if (index < 0) {
          throw EngineFailure(
            'ZIWEI_PALACE_UNRESOLVED:${target.palaces.join('/')}',
          );
        }
        return _ResolvedTarget(
          chart.palaces[index].name,
          target.palaces,
          index,
          target.weight,
        );
      }(),
  ];
}

double _weightedProximity(int palaceIndex, List<_ResolvedTarget> targets) =>
    targets.fold<double>(
      0,
      (sum, t) => sum + t.weight * _proximity(palaceIndex, t.index),
    );

final BoundedCache<String, ZiweiAstrolabe> _chartCache =
    BoundedCache<String, ZiweiAstrolabe>(256);

ZiweiAstrolabe _chartFor(String date, int index, String gender) {
  final key = '$date|$index|$gender';
  final cached = _chartCache.get(key);
  if (cached != null) return cached;
  return _chartCache.set(
    key,
    buildAstrolabe(solarDate: date, timeIndex: index, gender: gender),
  );
}

/// Every chart that could describe this birth, given what is known.
class BuiltZiWei {
  const BuiltZiWei({
    required this.charts,
    required this.unknownHour,
    required this.unknownConvention,
    this.reason,
  });

  final List<({int index, String gender, ZiweiAstrolabe chart})> charts;
  final bool unknownHour;
  final bool unknownConvention;
  final String? reason;
}

BuiltZiWei buildZiWei(BirthContext birth, String? traditionalProfile) {
  final clock = birth.clock;
  if (birth.status == 'birth_time_nonexistent') {
    return BuiltZiWei(
      charts: const <({int index, String gender, ZiweiAstrolabe chart})>[],
      unknownHour: clock == null,
      unknownConvention: false,
      reason: birth.status,
    );
  }
  final indexes = clock != null
      ? <int>[hourBranch(int.parse(clock.substring(0, 2)))]
      : <int>[for (var i = 0; i < 12; i++) i];
  // An unknown convention is modelled as alternatives, never inferred from a
  // name.
  final genders =
      (traditionalProfile == 'male' || traditionalProfile == 'female')
      ? <String>[traditionalProfile!]
      : <String>['male', 'female'];

  return BuiltZiWei(
    charts: <({int index, String gender, ZiweiAstrolabe chart})>[
      for (final index in indexes)
        for (final gender in genders)
          (
            index: index,
            gender: gender,
            chart: _chartFor(birth.date, index, gender),
          ),
    ],
    unknownHour: clock == null,
    unknownConvention: genders.length > 1,
  );
}

class _ChartScore {
  const _ChartScore(this.evidence, this.targets);

  final Evidence evidence;
  final List<_ResolvedTarget> targets;
}

_ChartScore _scoreChart(
  ZiweiAstrolabe chart,
  String date,
  int timeIndex,
  String category,
) {
  final targets = _resolveTargets(chart, category);
  final stars = chart.stars;
  final parts = <(double, Evidence)>[];

  for (final spec in <(double, Map<String, List<double>>, double, bool)>[
    (.45, _majorStars, 4, true),
    (.20, _auxiliaryStars, 3, false),
  ]) {
    final weight = spec.$1;
    final catalog = spec.$2;
    final divisor = spec.$3;
    final requireBrightness = spec.$4;
    final selected = stars.where((s) => catalog.containsKey(s.name)).toList();
    if (selected.length != catalog.length ||
        selected.map((s) => s.name).toSet().length != selected.length) {
      throw const EngineFailure('ZIWEI_STAR_CATALOG_MISMATCH');
    }
    final values = <double>[
      for (var k = 0; k < 2; k++)
        selected.fold<double>(0, (sum, s) {
          if (requireBrightness &&
              !_brightnessWeights.containsKey(s.brightness)) {
            throw const EngineFailure('ZIWEI_MAJOR_BRIGHTNESS_MISSING');
          }
          return sum +
              catalog[s.name]![k] *
                  (_brightnessWeights[s.brightness] ?? 1) *
                  _weightedProximity(s.palace, targets) /
                  divisor;
        }),
    ];
    parts.add((
      weight,
      Evidence(clampUnit(values[0]), clampUnit(values[1]), 1),
    ));
  }

  final transformed = <(double, Evidence)>[];
  final natalEvents = <({String kind, int palace})>[
    for (final s in stars)
      if (_transforms.containsKey(s.mutagen))
        (kind: s.mutagen, palace: s.palace),
  ];
  final horoscope = horoscopeFor(chart, date, timeIndex);

  for (final entry in _layers.entries) {
    final layer = entry.key;
    final data = horoscope[layer];
    final index = layer == 'natal' ? null : data!.index;
    if (index != null && index < 0) continue;

    final events = layer == 'natal'
        ? natalEvents
        : <({String kind, int palace})>[
            for (var i = 0; i < data!.mutagen.length; i++)
              (
                kind: _mutagenKinds[i],
                palace: _palaceOfStar(stars, data.mutagen[i]),
              ),
          ];
    if (events.length != 4 ||
        events.any((e) => e.palace < 0) ||
        events.map((e) => e.kind).toSet().length != 4) {
      throw const EngineFailure('ZIWEI_TRANSFORM_CATALOG_MISMATCH');
    }

    // The natal layer is measured against the category's target palaces; the
    // time layers keep their own horoscope palace.
    double reach(({String kind, int palace}) e) => index == null
        ? _weightedProximity(e.palace, targets)
        : _proximity(e.palace, index);

    final v = <double>[
      for (var k = 0; k < 2; k++)
        clampUnit(
          events.fold<double>(
            0,
            (sum, e) => sum + reach(e) * _transforms[e.kind]![k] / 2,
          ),
        ),
    ];
    transformed.add((entry.value, Evidence(v[0], v[1], 1)));
  }

  parts.add((.35, blend(transformed)));
  return _ChartScore(blend(parts), targets);
}

/// The four transformation kinds, in 禄权科忌 order.
const List<String> _mutagenKinds = <String>['禄', '权', '科', '忌'];

/// The palace a named star sits in, or -1 when the chart does not carry it.
int _palaceOfStar(List<ZiweiStar> stars, String name) {
  for (final star in stars) {
    if (star.name == name) return star.palace;
  }
  return -1;
}

ModuleResult scoreZiWei(
  BuiltZiWei built,
  CalendarAt cal, [
  String category = 'general',
]) {
  if (built.charts.isEmpty) {
    return ModuleResult(Evidence(), <String, Object?>{
      'reason': built.reason,
      'category': category,
    });
  }

  final results =
      <({Evidence evidence, int birthHourIndex, String convention})>[
        for (final entry in built.charts)
          (
            evidence: _scoreChart(
              entry.chart,
              cal.local.date,
              cal.hour.branch,
              category,
            ).evidence,
            birthHourIndex: entry.index,
            convention: entry.gender,
          ),
      ];

  if (results.length == 1) {
    return ModuleResult(results[0].evidence, <String, Object?>{
      'category': category,
      'scenarioCount': 1,
      'method': 'single_chart',
    });
  }

  double minOf(double Function(Evidence) pick) =>
      results.map((r) => pick(r.evidence)).reduce((a, b) => a < b ? a : b);
  double maxOf(double Function(Evidence) pick) =>
      results.map((r) => pick(r.evidence)).reduce((a, b) => a > b ? a : b);

  double conservative(double Function(Evidence) pick) {
    final low = minOf(pick);
    final high = maxOf(pick);
    if (low > 0) return low;
    if (high < 0) return high;
    return 0;
  }

  // Missing birth inputs and cross-scenario agreement are separate quantities.
  // The cap is explicit product policy, NOT a likelihood of any birth hour.
  final inputFactor =
      (built.unknownHour ? .75 : 1) * (built.unknownConvention ? .75 : 1);
  final q = minOf((e) => e.coverage) * inputFactor;

  return ModuleResult(
    Evidence(conservative((e) => e.a), conservative((e) => e.c), q),
    <String, Object?>{
      'method': 'conservative_across_possible_charts',
      'scenarioCount': results.length,
      'unknownBirthHour': built.unknownHour,
      'unknownConvention': built.unknownConvention,
      'inputCoverageFactor': inputFactor,
      'category': category,
    },
    'scenario_analysis',
  );
}
