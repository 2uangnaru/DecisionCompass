import 'package:decision_compass/local_engine/core/core.dart';
import 'package:decision_compass/local_engine/core/numbers.dart';
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
      expect(percent(0), 50);
      expect(percent(1), 90);
      expect(percent(-1), 10);
      expect(percent(2), 90);
      expect(percent(-2), 10);
    });

    test('each mode projects the two axes its own way', () {
      final evidence = Evidence(0.5, -0.25, 1);
      final scores = <String, double>{
        for (final mode in modes.keys) mode: scoreForMode(evidence, mode),
      };

      expect(scores['yes_no'], closeTo(0.5, 1e-12));
      expect(scores['act_wait'], closeTo(.85 * 0.5 + .15 * -0.25, 1e-12));
      expect(
        scores['advance_retreat'],
        closeTo(.55 * 0.5 + .45 * -0.25, 1e-12),
      );
      expect(scores['stay_go'], closeTo(-1 * (1 * -0.25), 1e-12));
      expect(
        scores['keep_let_go'],
        closeTo(-1 * (-.3 * 0.5 + .7 * -0.25), 1e-12),
      );
      expect(
        scores['forward_backward'],
        closeTo(.25 * 0.5 + .75 * -0.25, 1e-12),
      );
      expect(
        scores['left_right'],
        closeTo(-1 * (.7 * 0.5 + -.3 * -0.25), 1e-12),
      );

      // No two modes may collapse into the same projection.
      expect(scores.values.toSet().length, modes.length);
    });

    test('zero coverage is insufficient data, never a fabricated 50/50', () {
      final result = decision(Evidence(), 'yes_no');
      expect(result.status, 'insufficient_data');
      expect(result.winner, isNull);
      expect(result.percentages, isNull);
      expect(result.dataCoverage, isNull);
    });

    test('an exactly centred score is balanced with no winner', () {
      final result = decision(Evidence(0, 0, 1), 'yes_no');
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
