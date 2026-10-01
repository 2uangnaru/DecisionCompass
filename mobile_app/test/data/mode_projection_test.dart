import 'dart:math' as math;

import 'package:decision_compass/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_loader.dart';

/// Mirrors `MODE_SIGNALS` in `calculation-engine/src/scoring.js`: the weights
/// each mode mixes its normalized signals with.
///
/// Duplicated here deliberately, as a tripwire — if a mixture ever changes,
/// this table and the fixtures have to move together and this test fails
/// loudly. It is *not* the authoritative check:
/// `node scripts/mobile-fixtures.mjs --check` validates fixtures against the
/// engine's own scoring module, without re-implementing anything.
const mixtures = <DecisionMode, Map<String, double>>{
  DecisionMode.yesNo: {'P': 0.45, 'C': 0.20, 'L': 0.35},
  DecisionMode.actWait: {'P': 0.30, 'C': 0.10, 'T': 0.30, 'L': 0.30},
  DecisionMode.advanceRetreat: {'P': 0.25, 'M': 0.60, 'L': 0.15},
  DecisionMode.stayGo: {'G': 0.70, 'P': 0.20, 'L': 0.10},
  DecisionMode.keepLetGo: {'R': 0.70, 'P': 0.20, 'L': 0.10},
  // v9.4 moved these two, and only these two. The tripwire fired on all nine
  // affected fixtures, which is what it is for.
  DecisionMode.commitWithdraw: {'H': 0.60, 'R': 0.25, 'P': 0.10, 'L': 0.05},
  DecisionMode.leftRight: {'Y': 0.50, 'P': 0.35, 'L': 0.15},
};

/// The two English labels each mode's percentages are keyed by.
const labels = <DecisionMode, (String, String)>{
  DecisionMode.yesNo: ('YES', 'NO'),
  DecisionMode.actWait: ('ACT', 'WAIT'),
  DecisionMode.advanceRetreat: ('ADVANCE', 'RETREAT'),
  DecisionMode.stayGo: ('STAY', 'GO'),
  DecisionMode.keepLetGo: ('KEEP', 'LET GO'),
  DecisionMode.commitWithdraw: ('COMMIT', 'WITHDRAW'),
  DecisionMode.leftRight: ('LEFT', 'RIGHT'),
  DecisionMode.forwardBackward: ('FORWARD', 'BACKWARD'),
};

/// The first option's score, mixed from the signals the reading reported.
///
/// The mixture is divided by `sqrt(sum of w squared)`, mirroring `MODE_GAIN`
/// in `calculation-engine/src/scoring.js`. Without it a four-signal mode would
/// read structurally milder than a one-signal mode purely because averaging
/// more terms narrows the spread — the imbalance v9.2 exists to remove.
double mixedScore(DecisionMode mode, Map<String, double> normalized) {
  final mixture = mixtures[mode]!;
  var score = 0.0;
  var squares = 0.0;
  mixture.forEach((name, weight) {
    expect(
      normalized[name],
      isNotNull,
      reason: '${mode.wireValue} mixes $name but the reading did not report it',
    );
    score += weight * normalized[name]!;
    squares += weight * weight;
  });
  return (score / math.sqrt(squares)).clamp(-1.0, 1.0);
}

/// `displayTenths()` in `calculation-engine/src/scoring.js`: the display band
/// in integer tenths of a percent, so the pair is exact.
int displayTenthsFor(double score) {
  final s = score.clamp(-1.0, 1.0);
  final sign = s < 0
      ? -1
      : s > 0
      ? 1
      : 0;
  final expanded = (sign * math.pow(s.abs(), 0.55)).toDouble();
  return (500 + 400 * expanded.clamp(-1.0, 1.0) + 0.5).floor();
}

/// The `scoring` block is engine output the app deliberately does not parse:
/// nothing on screen needs it, and leaving it out of the DTO keeps a saved
/// snapshot small. Tests read it straight from the fixture JSON.
Map<String, double>? normalizedSignals(JsonMap fixture) {
  final scoring = fixture['scoring'];
  if (scoring is! JsonMap) return null;
  final normalized = scoring['normalized'];
  if (normalized is! JsonMap) return null;
  return {
    for (final entry in normalized.entries)
      entry.key: (entry.value as num).toDouble(),
  };
}

void main() {
  final fixtures = readAllFixtures();

  final scored = <String, (ReadingResponse, Map<String, double>)>{};
  for (final entry in fixtures.entries) {
    final signals = normalizedSignals(entry.value);
    final response = ReadingResponse.fromJson(entry.value);
    if (signals != null && response.modeScore != null) {
      scored[entry.key] = (response, signals);
    }
  }

  test('the mixture table covers every mode a reader can choose', () {
    expect(mixtures.keys.toSet(), equals(DecisionMode.selectable.toSet()));
    // The retired mode has no mixture: v9.1 does not score it at all.
    expect(mixtures.containsKey(DecisionMode.forwardBackward), isFalse);
    for (final mixture in mixtures.values) {
      final total = mixture.values.fold<double>(0, (s, w) => s + w);
      expect(total, closeTo(1, 1e-9));
    }
  });

  test('every selectable mode has at least one scored fixture', () {
    expect(
      scored.values.map((pair) => pair.$1.mode).toSet(),
      equals(DecisionMode.selectable.toSet()),
      reason: 'a mode with no scored fixture is not signal-tested',
    );
  });

  group('scoring consistency', () {
    for (final entry in scored.entries) {
      final name = entry.key;
      final (response, normalized) = entry.value;

      test('$name (${response.mode.wireValue}) is internally consistent', () {
        final raw = (fixtures[name]!['scoring']! as JsonMap);
        final rawModeScore = (raw['rawModeScore']! as num).toDouble();
        expect(
          mixedScore(response.mode, normalized),
          closeTo(rawModeScore, 1e-9),
          reason: '$name: rawModeScore is not the mixture of its own signals',
        );

        // The displayed score is the raw one pushed away from the reader's
        // own fortnight, so it is allowed to differ — but only that way.
        final median = raw['priorMedian'];
        if (median is num) {
          final pushed = (rawModeScore + 0.5 * (rawModeScore - median)).clamp(
            -1.0,
            1.0,
          );
          expect(
            response.modeScore,
            closeTo(pushed, 1e-9),
            reason:
                '$name: modeScore is not the fortnight push of rawModeScore',
          );
        }

        final percentages = response.percentages;
        if (percentages == null) return;

        final (first, second) = labels[response.mode]!;
        final tenths = displayTenthsFor(response.modeScore!);
        expect(
          percentages.tenths[first],
          tenths,
          reason:
              '$name: percentages.$first must be '
              'floor(500 + 400 * sign * |modeScore|^0.55 + 0.5) tenths',
        );
        expect(percentages.tenths[second], 1000 - tenths);
        expect(
          response.winner,
          tenths == 500 ? isNull : (tenths > 500 ? first : second),
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
    expect(displayTenthsFor(response.modeScore!), 500);
  });

  test('each mode reads a different mixture of the same signals', () {
    // One synthetic signal set, mixed seven ways. A fixture only carries the
    // signals its own mode asked for, and comparing two fixtures would compare
    // two different instants, so the mixtures are isolated from the moment.
    const normalized = <String, double>{
      'P': 0.21,
      'C': -0.34,
      'L': 0.12,
      'T': 0.47,
      'M': -0.18,
      'R': 0.09,
      'G': -0.07,
      'H': 0.15,
      'Y': 0.52,
    };
    final scores = <DecisionMode, double>{
      for (final mode in DecisionMode.selectable)
        mode: mixedScore(mode, normalized),
    };
    expect(scores.length, 7);
    expect(
      scores.values.toSet().length,
      scores.length,
      reason: 'two modes collapsed onto the same score: one is redundant',
    );
  });

  test('a retired reading keeps the numbers it was calculated with', () {
    // Under the old ruleset the display curve had a different exponent, so
    // re-deriving this fixture's percentage today would change it. The point
    // of keeping it is that nothing re-derives it.
    final fixture = fixtures['legacy_forward_backward_reading.json']!;
    final response = ReadingResponse.fromJson(fixture);
    expect(response.mode, DecisionMode.forwardBackward);
    expect(response.mode.legacy, isTrue);
    expect(fixture['scoring'], isNull, reason: 'it predates v9.1 scoring');

    final (first, second) = labels[DecisionMode.forwardBackward]!;
    final shown = response.percentages!.tenths;
    expect(shown.keys, containsAll(<String>[first, second]));
    expect(shown[first]! + shown[second]!, 1000);
    // Its own stored percentage, not one recomputed under v9.1.
    expect(shown[first], isNot(displayTenthsFor(response.modeScore!)));
  });
}
