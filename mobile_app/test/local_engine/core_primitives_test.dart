import 'dart:math' as math;

import 'package:decision_compass/local_engine/core/core.dart';
import 'package:decision_compass/local_engine/core/numbers.dart';
import 'package:decision_compass/local_engine/core/scoring.dart';
import 'package:decision_compass/local_engine/core/sha256.dart';
import 'package:decision_compass/local_engine/numerology/numerology.dart';
import 'package:flutter_test/flutter_test.dart';

/// The small primitives the whole engine rests on, checked directly so a break
/// here is reported here rather than as a mysterious score difference.
void main() {
  group('SHA-256', () {
    test('matches the published test vectors', () {
      expect(
        sha256Hex(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        sha256Hex('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(
        sha256Hex('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });

    test('hashes multi-byte text as UTF-8, like Node', () {
      // 紫微 is what a Zi Wei diagnostic would carry; the digest must not
      // depend on how Dart stores the string.
      expect(
        sha256Hex('紫微'),
        sha256Hex(String.fromCharCodes(<int>[0x7d2b, 0x5fae])),
      );
      expect(sha256Hex('紫微').length, 64);
    });
  });

  group('JavaScript number semantics', () {
    test('Math.round sends halves toward positive infinity', () {
      expect(jsRound(0.5), 1);
      expect(jsRound(1.5), 2);
      expect(jsRound(-0.5), 0);
      expect(jsRound(-1.5), -1);
      expect(jsRound(-2.5), -2);
    });

    test(
      'an integral double encodes as an integer, as JSON.stringify does',
      () {
        expect(jsNumber(25200), isA<int>());
        expect(jsNumber(25200), 25200);
        expect(jsNumber(-0.0), 0);
        expect(jsNumber(0.5), 0.5);
        expect(jsNumber(0.5), isA<double>());
      },
    );

    test('mod is never negative and clamping stays inside the unit range', () {
      expect(jsMod(-1, 12), 11);
      expect(jsMod(13, 12), 1);
      expect(jsModDouble(-30, 360), 330);
      expect(clampUnit(2), 1);
      expect(clampUnit(-2), -1);
      expect(clampUnit(0.25), 0.25);
    });

    test('rounding to ten places matches the engine', () {
      expect(roundTen(0.12345678901234), 0.123456789);
      expect(roundTen(1), 1);
    });
  });

  group('decision projections', () {
    test('the display band is 10–90, centred on 50', () {
      expect(displayPercent(0), 50);
      expect(displayPercent(1), 90);
      expect(displayPercent(-1), 10);
      expect(displayPercent(2), 90);
      expect(displayPercent(-2), 10);
    });

    test('each mode mixes its own set of signals', () {
      // One raw signal set, read by all seven mixtures. Two modes agreeing
      // here by coincidence would mean one of them is redundant.
      final raw = <String, double>{
        'P': 0.18,
        'C': -0.22,
        'L': 0.09,
        'T': 0.31,
        'M': -0.14,
        'R': 0.07,
        'G': -0.05,
        'H': 0.12,
        'Y': 0.44,
      };
      final normalized = normalizeAll(raw);
      final scores = <String, double>{
        for (final mode in modes.keys) mode: modeScore(mode, normalized),
      };

      for (final entry in modeSignals.entries) {
        var expected = 0.0;
        var squares = 0.0;
        for (final part in entry.value.entries) {
          expected += part.value * normalized[part.key]!;
          squares += part.value * part.value;
        }
        // Divided by sqrt(sum of w squared) so a four-signal mode is not
        // structurally milder than a one-signal mode.
        expect(
          scores[entry.key],
          closeTo(expected / math.sqrt(squares), 1e-12),
          reason: entry.key,
        );
      }
      expect(scores.values.toSet().length, modes.length);
    });

    test('a legacy mode is refused rather than silently relabelled', () {
      expect(
        () => requireCurrentMode('forward_backward'),
        throwsA(
          isA<EngineFailure>().having(
            (e) => e.code,
            'code',
            'LEGACY_DECISION_MODE:forward_backward',
          ),
        ),
      );
      // Its identity is still readable, so history can render it.
      expect(modeIdentity('forward_backward')!.labels, <String>[
        'FORWARD',
        'BACKWARD',
      ]);
      expect(modeIdentity('forward_backward')!.replacedBy, 'commit_withdraw');
    });

    test('zero coverage is insufficient data, never a fabricated 50/50', () {
      final result = decision('yes_no', 0, 0, displayTenths(0));
      expect(result.status, 'insufficient_data');
      expect(result.winner, isNull);
      expect(result.percentages, isNull);
      expect(result.dataCoverage, isNull);
    });

    test('an exactly centred score is balanced with no winner', () {
      final result = decision('yes_no', 0, 1, displayTenths(0));
      expect(result.status, 'balanced');
      expect(result.winner, isNull);
      // Tenths now, so the balance point is 500 on each side.
      expect(result.percentages, <String, int>{'YES': 500, 'NO': 500});
    });

    test('out-of-range evidence is refused rather than clipped silently', () {
      expect(() => Evidence(2, 0, 1), throwsA(isA<EngineFailure>()));
      expect(() => Evidence(0, 0, 2), throwsA(isA<EngineFailure>()));
      expect(() => Evidence(double.nan, 0, 1), throwsA(isA<EngineFailure>()));
    });

    test('category weight profiles are complete and normalized', () {
      validateCategoryProfiles();
      for (final category in categories) {
        final weights = weightsFor(category);
        expect(
          weights.keys.toSet(),
          defaultWeights.keys.toSet(),
          reason: category,
        );
      }
      // `other` deliberately reuses the general formula.
      expect(weightsFor('other'), weightsFor('general'));
    });
  });

  group('numerology', () {
    test('reduces to 1–9 and reports the numbers it used', () {
      final module = numerology('1998-06-21', '2026-09-18');
      expect(module.status, 'calculated');
      expect(module.evidence.coverage, 1);
      for (final key in <String>[
        'lifePath',
        'personalYear',
        'personalMonth',
        'personalDay',
      ]) {
        final value = module.diagnostics[key]! as int;
        expect(value, inInclusiveRange(1, 9), reason: key);
      }
      // Master numbers are deliberately not treated specially, and say so.
      expect(module.diagnostics['masterNumbers'], false);
    });

    test('refuses a birth date after the reading date', () {
      expect(
        () => numerology('2030-01-01', '2026-09-18'),
        throwsA(isA<EngineFailure>()),
      );
    });
  });
}
