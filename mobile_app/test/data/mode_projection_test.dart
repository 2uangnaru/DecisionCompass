import 'dart:math' as math;

import 'package:decision_compass/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_loader.dart';

typedef Projection = ({
  double a,
  double c,
  int sign,
  String first,
  String second,
});

/// Mirrors `MODES` in `calculation-engine/src/core.js`: the first label's score
/// is `clamp(sign * (a * action + c * change))`.
///
/// These weights are duplicated here deliberately, as a tripwire — if the
/// engine's projection ever changes, this table and the fixtures have to move
/// together and this test fails loudly. It is *not* the authoritative check:
/// `node scripts/mobile-fixtures.mjs --check` validates fixtures against the
/// engine's own `scoreForMode`/`percent`, without re-implementing anything.
const projections = <DecisionMode, Projection>{
  DecisionMode.yesNo: (a: 1.0, c: 0.0, sign: 1, first: 'YES', second: 'NO'),
  DecisionMode.actWait: (
    a: 0.85,
    c: 0.15,
    sign: 1,
    first: 'ACT',
    second: 'WAIT',
  ),
  DecisionMode.advanceRetreat: (
    a: 0.55,
    c: 0.45,
    sign: 1,
    first: 'ADVANCE',
    second: 'RETREAT',
  ),
  DecisionMode.stayGo: (a: 0.0, c: 1.0, sign: -1, first: 'STAY', second: 'GO'),
  DecisionMode.keepLetGo: (
    a: -0.3,
    c: 0.7,
    sign: -1,
    first: 'KEEP',
    second: 'LET GO',
  ),
  DecisionMode.forwardBackward: (
    a: 0.25,
    c: 0.75,
    sign: 1,
    first: 'FORWARD',
    second: 'BACKWARD',
  ),
  DecisionMode.leftRight: (
    a: 0.7,
    c: -0.3,
    sign: -1,
    first: 'LEFT',
    second: 'RIGHT',
  ),
};

double projectedScore(DecisionMode mode, AxisScores axes) {
  final projection = projections[mode]!;
  final raw =
      projection.sign *
      (projection.a * axes.action + projection.c * axes.change);
  return raw.clamp(-1.0, 1.0);
}

/// `percentTenths()` in `calculation-engine/src/core.js`: the display band in
/// integer tenths of a percent, so the pair is exact.
int percentTenthsFor(double score) {
  final s = score.clamp(-1.0, 1.0);
  final sign = s < 0 ? -1 : s > 0 ? 1 : 0;
  final expanded = (sign * math.pow(s.abs(), 0.65)).toDouble();
  return (500 + 400 * expanded.clamp(-1.0, 1.0) + 0.5).floor();
}

int percentFor(double score) => ((percentTenthsFor(score) + 5) / 10).floor();

void main() {
  final fixtures = readAllFixtures();

  final scored = <String, ReadingResponse>{};
  for (final entry in fixtures.entries) {
    final response = ReadingResponse.fromJson(entry.value);
    if (response.axisScores != null && response.modeScore != null) {
      scored[entry.key] = response;
    }
  }

  test('the projection table matches the seven documented decision modes', () {
    expect(projections.keys.toSet(), equals(DecisionMode.values.toSet()));
  });

  test('every DecisionMode has at least one scored fixture', () {
    expect(
      scored.values.map((r) => r.mode).toSet(),
      equals(DecisionMode.values.toSet()),
      reason: 'a mode with no scored fixture is not projection-tested',
    );
  });

  group('projection consistency', () {
    for (final entry in scored.entries) {
      final name = entry.key;
      final response = entry.value;

      test('$name (${response.mode.wireValue}) is internally consistent', () {
        final axes = response.axisScores!;
        final expected = projectedScore(response.mode, axes);

        expect(
          axes.selected,
          closeTo(expected, 1e-9),
          reason:
              '$name: axisScores.selected is not the mode projection of '
              'action/change',
        );
        expect(
          response.modeScore,
          closeTo(axes.selected, 1e-9),
          reason: '$name: modeScore must equal axisScores.selected',
        );

        final percentages = response.percentages;
        if (percentages == null) return;

        final projection = projections[response.mode]!;
        final first = percentTenthsFor(response.modeScore!);
        expect(
          percentages.tenths[projection.first],
          first,
          reason:
              '$name: percentages.${projection.first} must be '
              'floor(500 + 400 * modeScore + 0.5) tenths',
        );
        expect(percentages.tenths[projection.second], 1000 - first);
        expect(
          response.winner,
          first == 500
              ? isNull
              : (first > 500 ? projection.first : projection.second),
          reason: '$name: winner must follow the percentages',
        );
      });
    }
  });

  test('balanced means exactly 50/50 with no winner', () {
    final response = ReadingResponse.fromJson(
      fixtures['synthetic_balanced.json']!,
    );
    expect(response.status, ReadingStatus.balanced);
    expect(response.winner, isNull);
    expect(percentTenthsFor(response.modeScore!), 500);
  });

  test('LEFT/RIGHT and FORWARD/BACKWARD are not relabelled YES/NO', () {
    // Each fixture is generated at its own instant, so comparing two fixtures
    // would compare different axes. Re-project one fixture's own axes through
    // the other modes instead: that isolates the projection from the reading.
    final leftRight = ReadingResponse.fromJson(
      fixtures['ready_left_right.json']!,
    );
    final axes = leftRight.axisScores!;

    final asYesNo = projectedScore(DecisionMode.yesNo, axes);
    final asForwardBackward = projectedScore(
      DecisionMode.forwardBackward,
      axes,
    );

    expect(leftRight.modeScore, isNot(closeTo(asYesNo, 1e-9)));
    expect(asForwardBackward, isNot(closeTo(asYesNo, 1e-9)));
    expect(
      percentTenthsFor(leftRight.modeScore!),
      isNot(percentTenthsFor(asYesNo)),
    );
  });
}
