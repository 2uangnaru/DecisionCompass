// ignore_for_file: avoid_print
//
// The held-out simulation for the v9.1 experimental scoring system.
//
//   dart run tool/simulate_v91.dart [--profiles 210] [--days 28] [--seed 77213]
//
// This runs in Dart rather than in the Node reference engine on purpose: the
// two produce identical readings (see
// `test/local_engine/golden_reading_parity_test.dart`), but the Node engine's
// third-party Zi Wei provider is roughly three hundred times slower, which
// makes a cohort of this size impractical there. Dart is also the engine that
// actually ships.
//
// The cohort is generated from a seed that is *not* the calibration seed, so
// these profiles never contributed to the normalization scales.
//
// Everything reported here is an observation about the software. None of it is
// evidence that a percentage predicts anything about the world, and none of the
// numbers is a target: the run reports what the system does, including where it
// does badly.

import 'dart:math' as math;

import '../lib/local_engine/local_reading_engine.dart';

// --- the cohort ------------------------------------------------------------

/// Mulberry32, matching `calculation-engine/scripts/cohort.mjs` step for step
/// so the same seed yields the same cohort in either language.
///
/// JavaScript does this arithmetic on 32-bit views of ordinary numbers; Dart
/// integers are 64-bit, so every step is masked back to 32 bits explicitly.
class Rng {
  Rng(this._a);

  int _a;

  double next() {
    _a = (_a + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _imul(_a ^ (_a >> 15), 1 | _a);
    t = ((t + _imul(t ^ (t >> 7), 61 | t)) ^ t) & 0xFFFFFFFF;
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296;
  }

  /// `Math.imul`: the low 32 bits of the product.
  static int _imul(int a, int b) =>
      ((a & 0xFFFFFFFF) * (b & 0xFFFFFFFF)) & 0xFFFFFFFF;
}

T pick<T>(Rng rng, List<T> list) => list[(rng.next() * list.length).floor()];

const countries = <String>[
  'VN',
  'JP',
  'CN',
  'IN',
  'TH',
  'ES',
  'US',
  'AU',
  'BR',
  'NP',
  'IR',
  'NZ',
  'GB',
  'DE',
  'MX',
  'ZA',
  'EG',
  'RU',
  'KR',
  'ID',
  'PH',
  'CA',
  'AR',
  'NG',
];

const zones = <String>[
  'Asia/Ho_Chi_Minh',
  'Asia/Tokyo',
  'Asia/Shanghai',
  'Asia/Kolkata',
  'Asia/Bangkok',
  'Europe/Madrid',
  'America/New_York',
  'America/Los_Angeles',
  'Australia/Sydney',
  'Australia/Lord_Howe',
  'America/Sao_Paulo',
  'Asia/Kathmandu',
  'Asia/Tehran',
  'Pacific/Auckland',
  'Europe/London',
  'Africa/Cairo',
  'America/Mexico_City',
  'Asia/Seoul',
  'Europe/Berlin',
  'Pacific/Chatham',
];

const allCategories = <String>[
  'general',
  'love',
  'career',
  'money',
  'study',
  'friends',
  'other',
];

const allModes = <String>[
  'yes_no',
  'act_wait',
  'advance_retreat',
  'stay_go',
  'keep_let_go',
  'commit_withdraw',
  'left_right',
];

const conventions = <String>['male', 'female', 'unspecified'];

/// The scoring this release replaced, so the same cohort can be measured both
/// ways in one run.
///
/// Ruleset v8 projected the fused `action`/`change` pair onto seven fixed
/// lines and displayed `floor(500 + 400 * sign * |s|^0.65 + 0.5)` tenths. The
/// engine still reports that fused pair unchanged in `axisScores`, so the old
/// result is recoverable exactly rather than estimated. `forward_backward` is
/// listed under the mode that replaced it purely so the two tables line up;
/// they are different questions.
const legacyProjections = <String, (double, double, int)>{
  'yes_no': (1.0, 0.0, 1),
  'act_wait': (0.85, 0.15, 1),
  'advance_retreat': (0.55, 0.45, 1),
  'stay_go': (0.0, 1.0, -1),
  'keep_let_go': (-0.3, 0.7, -1),
  'commit_withdraw': (0.25, 0.75, 1),
  'left_right': (0.7, -0.3, -1),
};

/// The v8 winning percentage for one reading, from its own reported axes.
(double, bool) legacyResult(String mode, double action, double change) {
  final (a, c, sign) = legacyProjections[mode]!;
  final score = (sign * (a * action + c * change)).clamp(-1.0, 1.0);
  final s = score < 0
      ? -1
      : score > 0
      ? 1
      : 0;
  final tenths =
      (500 +
              400 *
                  (s * math.pow(score.abs(), 0.65)).toDouble().clamp(
                    -1.0,
                    1.0,
                  ) +
              0.5)
          .floor();
  final winning = tenths >= 500 ? tenths / 10 : (1000 - tenths) / 10;
  return (winning, tenths == 500);
}

String pad(int n) => n.toString().padLeft(2, '0');

class Subject {
  Subject(this.profile, this.zone, this.category, this.knowsHour);

  final Map<String, Object?> profile;
  final String zone;
  final String category;
  final bool knowsHour;
}

/// Stratified so every category gets the same number of profiles, and roughly
/// a third of them have no birth hour.
List<Subject> buildCohort(int seed, int size) {
  final rng = Rng(seed);
  return List<Subject>.generate(size, (i) {
    final year = 1940 + (rng.next() * 71).floor();
    final month = 1 + (rng.next() * 12).floor();
    final day = 1 + (rng.next() * 28).floor();
    final knowsHour = rng.next() > 0.32;
    final hour = (rng.next() * 24).floor();
    final minute = (rng.next() * 60).floor();
    final country = pick(rng, countries);
    final convention = pick(rng, conventions);
    final zone = pick(rng, zones);
    return Subject(
      <String, Object?>{
        'birthDate': '$year-${pad(month)}-${pad(day)}',
        'birthTime': knowsHour ? '${pad(hour)}:${pad(minute)}' : null,
        'birthCountry': country,
        'traditionalProfile': convention,
        'revision': 1,
      },
      zone,
      allCategories[i % allCategories.length],
      knowsHour,
    );
  });
}

// --- tallies ---------------------------------------------------------------

/// The four bands the brief asks about, plus a below-50 guard that should
/// never fire: the winning side is by definition at or above 50.
class Bands {
  int b50 = 0; // 50.0 – 54.9
  int b55 = 0; // 55.0 – 59.9
  int b60 = 0; // 60.0 – 79.9
  int b80 = 0; // 80.0 and above
  int balanced = 0;
  int other = 0;

  int get total => b50 + b55 + b60 + b80 + balanced + other;

  void add(double winning, bool isBalanced) {
    if (isBalanced) {
      balanced++;
    } else if (winning >= 80.0) {
      b80++;
    } else if (winning >= 60.0) {
      b60++;
    } else if (winning >= 55.0) {
      b55++;
    } else if (winning >= 50.0) {
      b50++;
    } else {
      other++;
    }
  }

  String percent(int n) => total == 0
      ? '   -  '
      : '${(n / total * 100).toStringAsFixed(1).padLeft(5)}%';

  String get row =>
      '${percent(b50)} ${percent(b55)} ${percent(b60)} ${percent(b80)}';
}

class Tally {
  final Bands bands = Bands();
  int adjacentRepeats = 0;
  int adjacentPairs = 0;
  int sevenDayRuns = 0;
  int sevenDayWindows = 0;
  int readings = 0;
  double coverageSum = 0;
  int unknownHourReadings = 0;
  double unknownHourCoverageSum = 0;
  double winningSum = 0;
}

int arg(List<String> args, String name, int fallback) {
  final at = args.indexOf('--$name');
  return at > -1 && at + 1 < args.length ? int.parse(args[at + 1]) : fallback;
}

void main(List<String> args) {
  final profileCount = arg(args, 'profiles', 210);
  final days = arg(args, 'days', 28);
  final seed = arg(args, 'seed', 77213);

  final cohort = buildCohort(seed, profileCount);
  final byMode = <String, Tally>{for (final m in allModes) m: Tally()};
  final byCategory = <String, Tally>{for (final c in allCategories) c: Tally()};
  final overall = Tally();
  final legacyByMode = <String, Tally>{for (final m in allModes) m: Tally()};
  final legacyOverall = Tally();
  var failures = 0;
  var elapsed = 0;

  final stopwatch = Stopwatch()..start();
  var done = 0;

  for (final subject in cohort) {
    ReadingCalculator calculator;
    try {
      calculator = ReadingCalculator(subject.profile);
    } catch (_) {
      failures++;
      continue;
    }
    for (final mode in allModes) {
      final winners = <String?>[];
      final shown = <double?>[];
      for (var d = 0; d < days; d++) {
        // 09:00 local on consecutive civil dates, stepped in UTC and read in
        // the subject's own zone; a DST shift moves the wall clock by an hour
        // and the engine is expected to cope rather than the harness.
        final instant = DateTime.utc(
          2026,
          3,
          1,
          2,
          0,
        ).add(Duration(days: d)).toIso8601String();
        Map<String, Object?> reading;
        try {
          reading = calculator.calculate(
            context: <String, Object?>{
              'instantUtc': instant,
              'deviceTimezone': subject.zone,
            },
            mode: mode,
            period: 'now',
            category: subject.category,
          );
        } catch (_) {
          failures++;
          winners.add(null);
          shown.add(null);
          continue;
        }
        final status = reading['status'] as String;
        if (status == 'period_elapsed' || status == 'insufficient_data') {
          elapsed++;
          winners.add(null);
          shown.add(null);
          continue;
        }
        final percentages = (reading['percentages']! as Map<String, Object?>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
        final winner = reading['winner'] as String?;
        final winning = percentages.values.reduce(math.max);
        final coverage = (reading['dataCoverage']! as num).toDouble();

        for (final tally in <Tally>[
          byMode[mode]!,
          byCategory[subject.category]!,
          overall,
        ]) {
          tally.bands.add(winning, winner == null);
          tally.readings++;
          tally.coverageSum += coverage;
          tally.winningSum += winning;
          if (!subject.knowsHour) {
            tally.unknownHourReadings++;
            tally.unknownHourCoverageSum += coverage;
          }
        }
        // The same reading measured the way ruleset v8 would have shown it.
        final axes = reading['axisScores']! as Map<String, Object?>;
        final (legacyWinning, legacyBalanced) = legacyResult(
          mode,
          (axes['action']! as num).toDouble(),
          (axes['change']! as num).toDouble(),
        );
        for (final tally in <Tally>[legacyByMode[mode]!, legacyOverall]) {
          tally.bands.add(legacyWinning, legacyBalanced);
          tally.readings++;
          tally.winningSum += legacyWinning;
        }

        winners.add(winner);
        shown.add(winning);
      }

      // Adjacent exact repeats: consecutive local dates that printed the very
      // same winning percentage for the same question.
      for (var i = 1; i < shown.length; i++) {
        if (shown[i] == null || shown[i - 1] == null) continue;
        for (final tally in <Tally>[
          byMode[mode]!,
          byCategory[subject.category]!,
          overall,
        ]) {
          tally.adjacentPairs++;
          if (shown[i] == shown[i - 1] && winners[i] == winners[i - 1]) {
            tally.adjacentRepeats++;
          }
        }
      }

      // Seven consecutive local dates that all named the same side.
      for (var i = 0; i + 7 <= winners.length; i++) {
        final window = winners.sublist(i, i + 7);
        if (window.any((w) => w == null)) continue;
        for (final tally in <Tally>[
          byMode[mode]!,
          byCategory[subject.category]!,
          overall,
        ]) {
          tally.sevenDayWindows++;
          if (window.every((w) => w == window.first)) tally.sevenDayRuns++;
        }
      }
    }
    done++;
    if (done % 20 == 0) {
      print(
        '  ... $done/${cohort.length} profiles '
        '(${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(0)}s)',
      );
    }
  }
  stopwatch.stop();

  void header(String title) {
    print('');
    print(title);
    print(
      '${'name'.padRight(18)}      n  50-54.9 55-59.9 60-79.9   80+  '
      'adj.repeat  7-day run  mean%  coverage',
    );
  }

  void row(String name, Tally t) {
    final repeats = t.adjacentPairs == 0
        ? '     -'
        : '${(t.adjacentRepeats / t.adjacentPairs * 100).toStringAsFixed(1).padLeft(5)}%';
    final runs = t.sevenDayWindows == 0
        ? '     -'
        : '${(t.sevenDayRuns / t.sevenDayWindows * 100).toStringAsFixed(1).padLeft(5)}%';
    final mean = t.readings == 0
        ? '   -'
        : (t.winningSum / t.readings).toStringAsFixed(1).padLeft(5);
    final coverage = t.readings == 0
        ? '   -'
        : (t.coverageSum / t.readings).toStringAsFixed(3).padLeft(8);
    print(
      '${name.padRight(18)}${t.readings.toString().padLeft(7)}  '
      '${t.bands.row}  $repeats     $runs  $mean  $coverage',
    );
  }

  print('');
  print('v9.1 held-out simulation');
  print(
    '  ${cohort.length} profiles x ${allModes.length} modes x $days '
    'consecutive local dates',
  );
  print(
    '  seed $seed (not the calibration seed), 20 timezones, '
    '${allCategories.length} categories',
  );
  print(
    '  ${overall.readings} scored readings in '
    '${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s '
    '($elapsed unscored, $failures rejected)',
  );
  print(
    '  Percentages are symbolic alignment, never a probability of success.',
  );

  header('By decision mode');
  for (final mode in allModes) row(mode, byMode[mode]!);

  header('By category');
  for (final category in allCategories) row(category, byCategory[category]!);

  header('Overall');
  row('all', overall);

  print('');
  print('The same cohort under the scoring v9.1 replaced (ruleset v8),');
  print("recovered exactly from each reading's own unchanged fused axes.");
  print(
    '${'name'.padRight(18)}      n  50-54.9 55-59.9 60-79.9   80+  '
    '                    mean%',
  );
  for (final mode in allModes) {
    final t = legacyByMode[mode]!;
    print(
      '${mode.padRight(18)}${t.readings.toString().padLeft(7)}  '
      '${t.bands.row}                       '
      '${(t.winningSum / math.max(1, t.readings)).toStringAsFixed(1).padLeft(5)}',
    );
  }
  final l = legacyOverall;
  print(
    '${'all'.padRight(18)}${l.readings.toString().padLeft(7)}  '
    '${l.bands.row}                       '
    '${(l.winningSum / math.max(1, l.readings)).toStringAsFixed(1).padLeft(5)}',
  );
  final before = (l.bands.b50 + l.bands.b55) / math.max(1, l.bands.total) * 100;
  final after =
      (overall.bands.b50 + overall.bands.b55) /
      math.max(1, overall.bands.total) *
      100;
  print('');
  print(
    'Winners in 50-59.9%: v8 ${before.toStringAsFixed(1)}% -> '
    'v9.1 ${after.toStringAsFixed(1)}%',
  );
  print(
    'Winners at 80%+:     v8 '
    '${(l.bands.b80 / math.max(1, l.bands.total) * 100).toStringAsFixed(1)}% -> '
    'v9.1 ${(overall.bands.b80 / math.max(1, overall.bands.total) * 100).toStringAsFixed(1)}%',
  );
  print('Neither figure is a target. They describe what the two systems do on');
  print('this cohort, and say nothing about whether either is right.');

  final known = overall.readings - overall.unknownHourReadings;
  print('');
  print('Birth-hour coverage');
  print(
    '  known hour:   ${known.toString().padLeft(7)} readings, '
    'mean coverage ${((overall.coverageSum - overall.unknownHourCoverageSum) / math.max(1, known)).toStringAsFixed(4)}',
  );
  print(
    '  unknown hour: ${overall.unknownHourReadings.toString().padLeft(7)} readings, '
    'mean coverage ${(overall.unknownHourCoverageSum / math.max(1, overall.unknownHourReadings)).toStringAsFixed(4)}',
  );
  print('  An unknown hour must read as less coverage, never as more.');
}
