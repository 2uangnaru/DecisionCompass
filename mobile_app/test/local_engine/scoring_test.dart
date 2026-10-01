import 'package:decision_compass/local_engine/core/core.dart';
import 'package:decision_compass/local_engine/core/scoring.dart';
import 'package:decision_compass/local_engine/local_reading_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// The v9.1 scoring primitives on the Dart side.
///
/// Numerical agreement with the Node engine is established by
/// `golden_reading_parity_test.dart`, which reproduces whole readings from
/// Node-generated fixtures. This file checks the things a fixture cannot: the
/// shape of each signal, and the behaviour at the edges a fixture would have
/// to be hand-built to reach.
void main() {
  const profile = <String, Object?>{
    'birthDate': '1998-06-21',
    'birthTime': '14:30',
    'birthCountry': 'VN',
    'traditionalProfile': 'male',
    'revision': 1,
  };

  group('tanh', () {
    test('matches the identities the normalization relies on', () {
      expect(jsTanh(0), 0.0);
      expect(
        jsTanh(-0.0).isNegative,
        isTrue,
        reason: 'the sign of zero is kept',
      );
      expect(jsTanh(1), closeTo(0.7615941559557649, 1e-15));
      expect(jsTanh(-1), closeTo(-0.7615941559557649, 1e-15));
      expect(jsTanh(0.5), closeTo(0.46211715726000974, 1e-15));
      expect(jsTanh(3), closeTo(0.9950547536867305, 1e-15));
      // Small values, where the naive (e^2x-1)/(e^2x+1) form loses most of
      // its significant digits. The expected value is the series, not `x`:
      // tanh(1e-7) is 1e-7 - 1e-21/3, and the tolerance is about one ulp.
      expect(jsTanh(1e-7), closeTo(1e-7 - 1e-21 / 3, 2e-23));
      expect(jsTanh(1e-5), closeTo(1e-5 - 1e-15 / 3, 2e-21));
      // Below the cubic term's reach, tanh(x) and x are the same double.
      expect(jsTanh(1e-12), 1e-12);
      // Odd, monotone and bounded, which is what keeps coverage effects.
      for (final x in <double>[0.01, 0.1, 0.4, 0.9, 2.5]) {
        expect(jsTanh(-x), closeTo(-jsTanh(x), 1e-18));
        expect(jsTanh(x).abs(), lessThan(1));
      }
      expect(jsTanh(50), 1.0);
      expect(jsTanh(-50), -1.0);
    });
  });

  group('signals', () {
    test('the mixtures are complete, normalized and distinct', () {
      validateModeSignals();
      expect(modeSignals.keys.toSet(), modes.keys.toSet());
      const raw = <String, double>{
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
      final scores = <double>[
        for (final mode in modes.keys) modeScore(mode, normalized),
      ];
      expect(scores.toSet().length, scores.length);
    });

    test('the cross-day signals refuse to invent a missing day', () {
      expect(timing(0.5, const <double>[]), 0);
      expect(momentum(0.5, const <double>[]), 0);
      expect(grounding(0.2, 0.1, null), grounding(0.2, 0.1, 0.2));
      expect(median(const <double>[]), 0);
      expect(median(const <double>[1, 2, 3, 4]), closeTo(2.5, 1e-12));
    });

    test('the fortnight push is a contrast, not a flip or a floor', () {
      expect(adjustAgainstHistory(0.2, const <double>[0.2, 0.2]), 0.2);
      expect(adjustAgainstHistory(0.2, const <double>[]), 0.2);
      expect(
        adjustAgainstHistory(0.3, const <double>[0.1]),
        closeTo(0.3 + medianPush * 0.2, 1e-12),
      );
      expect(adjustAgainstHistory(1, const <double>[-1]), 1);
      expect(adjustAgainstHistory(-1, const <double>[1]), -1);
      expect(adjustAgainstHistory(0.01, const <double>[0]), greaterThan(0));
    });

    test('the display band is 10 to 90, in exact tenths', () {
      expect(displayTenths(0), 500);
      expect(displayTenths(1), 900);
      expect(displayTenths(-1), 100);
      expect(displayTenths(5), 900);
      expect(displayPercent(0), 50);
      for (final score in <double>[-1, -0.73, -0.2, 0, 0.2, 0.73, 1]) {
        final tenths = displayTenths(score);
        expect(tenths, inInclusiveRange(100, 900));
        expect(displayTenths(-score), 1000 - tenths);
      }
    });
  });

  group('whole readings', () {
    test('a retired mode is refused, with its own code', () {
      expect(
        () => calculateReading(
          profile: profile,
          context: const <String, Object?>{
            'instantUtc': '2026-09-18T08:30:00Z',
            'deviceTimezone': 'Asia/Ho_Chi_Minh',
          },
          mode: 'forward_backward',
        ),
        throwsA(
          isA<EngineFailure>().having(
            (e) => e.code,
            'code',
            'LEGACY_DECISION_MODE:forward_backward',
          ),
        ),
      );
    });

    test('a reading reports signals that reproduce its own score', () {
      final calculator = ReadingCalculator(profile);
      for (final mode in modes.keys) {
        final reading = calculator.calculate(
          context: const <String, Object?>{
            'instantUtc': '2026-09-18T08:30:00Z',
            'deviceTimezone': 'Asia/Ho_Chi_Minh',
          },
          mode: mode,
          period: 'now',
          category: 'general',
        );
        final scoring = reading['scoring']! as Map<String, Object?>;
        final normalized = (scoring['normalized']! as Map<String, Object?>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
        expect(
          normalized.keys.toSet(),
          signalsNeededBy(mode).toSet(),
          reason: '$mode reported the wrong signal set',
        );
        expect(
          modeScore(mode, normalized),
          closeTo((scoring['rawModeScore']! as num).toDouble(), 1e-9),
          reason: '$mode: the reported signals do not remix to its own score',
        );
        expect(scoring['system'], scoringVersion);
        expect(scoring['scaleVersion'], scaleVersion);
      }
    });

    test('a local date whose anchor hour does not exist is dropped', () {
      // Pacific/Chatham springs forward 02:45 -> 03:45 on 2026-09-27, so
      // 03:00 never happens there that day. A reading anchored at 03:00 a week
      // later reaches that date in its fortnight and must leave it out rather
      // than sliding to a neighbouring hour.
      final reading = calculateReading(
        profile: const <String, Object?>{
          'birthDate': '1990-03-14',
          'birthTime': '08:25',
          'birthCountry': 'NZ',
          'traditionalProfile': 'female',
          'revision': 1,
        },
        context: const <String, Object?>{
          'instantUtc': '2026-10-04T14:00:00Z',
          'deviceTimezone': 'Pacific/Chatham',
        },
        mode: 'yes_no',
        period: 'now',
      );
      final scoring = reading['scoring']! as Map<String, Object?>;
      expect(scoring['anchorLocal'], '2026-10-05T03:00');
      expect(scoring['priorDatesUsed'], 13);
      expect(reading['status'], 'ready');
    });

    test('a window is scored at its own moment, timing included', () {
      final reading = ReadingCalculator(profile).calculate(
        context: const <String, Object?>{
          'instantUtc': '2026-09-18T08:30:00Z',
          'deviceTimezone': 'Asia/Ho_Chi_Minh',
        },
        mode: 'act_wait',
        period: 'evening',
      );
      final windows = reading['luckyWindows']! as List<Object?>;
      expect(windows.length, greaterThanOrEqualTo(2));

      // Under the scoring this replaced, every window reused the headline's
      // timing signal. An evening reading is the sharpest case: no period
      // starts after 18:00, so that shared value was exactly zero.
      final scoring = reading['scoring']! as Map<String, Object?>;
      expect(
        (scoring['signals']! as Map<String, Object?>)['T'],
        isNot(0),
        reason: 'an evening ACT/WAIT reading still has no timing signal',
      );

      final scores = <Object?>[
        for (final w in windows) (w! as Map<String, Object?>)['score'],
      ];
      expect(
        scores.toSet().length,
        scores.length,
        reason:
            'the windows all scored the same, so timing is not reaching them',
      );
    });

    test('timing is what re-orders the same candidate slots', () {
      List<String> order(String mode) {
        final reading = ReadingCalculator(profile).calculate(
          context: const <String, Object?>{
            'instantUtc': '2026-09-18T08:30:00Z',
            'deviceTimezone': 'Asia/Ho_Chi_Minh',
          },
          mode: mode,
          period: 'evening',
        );
        return <String>[
          for (final w in reading['luckyWindows']! as List<Object?>)
            (w! as Map<String, Object?>)['startLocal']! as String,
        ];
      }

      // YES / NO reads no timing at all; ACT / WAIT is mostly timing. Same
      // profile, instant and period, so any change of order is the timing.
      final timed = order('act_wait');
      final untimed = order('yes_no');
      expect(
        List<String>.of(timed)..sort(),
        List<String>.of(untimed)..sort(),
        reason: 'the two modes did not consider the same candidate slots',
      );
      expect(
        timed,
        isNot(untimed),
        reason: 'the timing signal did not change the ranking of the slots',
      );
    });

    test('the requested signal set is part of the score cache identity', () {
      Map<String, Object?> signalsOf(Map<String, Object?> reading) =>
          (reading['scoring']! as Map<String, Object?>)['signals']!
              as Map<String, Object?>;
      const context = <String, Object?>{
        'instantUtc': '2026-09-18T08:30:00Z',
        'deviceTimezone': 'Asia/Ho_Chi_Minh',
      };

      final normalThenProbe = ReadingCalculator(profile);
      final normalFirst = normalThenProbe.calculate(
        context: context,
        mode: 'yes_no',
        period: 'now',
      );
      final probeSecond = normalThenProbe.calculate(
        context: context,
        mode: 'yes_no',
        period: 'now',
        probeAllSignals: true,
      );

      final probeThenNormal = ReadingCalculator(profile);
      final probeFirst = probeThenNormal.calculate(
        context: context,
        mode: 'yes_no',
        period: 'now',
        probeAllSignals: true,
      );
      final normalSecond = probeThenNormal.calculate(
        context: context,
        mode: 'yes_no',
        period: 'now',
      );

      expect(signalsOf(probeSecond).keys.toSet(), signalNames.toSet());
      expect(signalsOf(probeFirst).keys.toSet(), signalNames.toSet());
      expect(signalsOf(normalFirst).keys.toSet(), <String>{'P', 'C', 'L'});
      expect(signalsOf(normalSecond).keys.toSet(), <String>{'P', 'C', 'L'});
      expect(normalSecond['percentages'], normalFirst['percentages']);
      expect(probeSecond['modeScore'], normalFirst['modeScore']);
    });

    /// A NOW reading at [localHour] on 18 September 2026 in Ho Chi Minh City.
    Map<String, Object?> nowAt(int localHour) =>
        ReadingCalculator(profile).calculate(
          context: <String, Object?>{
            'instantUtc': DateTime.utc(
              2026,
              9,
              18,
              localHour - 7,
            ).toIso8601String(),
            'deviceTimezone': 'Asia/Ho_Chi_Minh',
          },
          mode: 'act_wait',
          period: 'now',
        );

    /// `jsNumber` types an integral value as an `int`, so a timing of exactly
    /// zero arrives as `0` rather than `0.0`.
    double timingOf(Map<String, Object?> reading) =>
        (((reading['scoring']! as Map<String, Object?>)['signals']!
                    as Map<String, Object?>)['T']!
                as num)
            .toDouble();

    test('NOW reads the rest of the day, not only the periods to come', () {
      // The defect: NOW compared itself only against periods that had not
      // begun, so after 18:00 nothing was left and the signal was zero all
      // evening.
      for (final hour in <int>[7, 9, 11, 13, 15, 17, 19, 21]) {
        expect(
          timingOf(nowAt(hour)),
          isNot(0),
          reason: 'a NOW reading at $hour:00 has no timing signal',
        );
      }
    });

    test('the last hour of the day has nothing left to compare against', () {
      // Zero here is the honest answer rather than the bug above: 23:00 is the
      // final segment of the local date.
      expect(timingOf(nowAt(23)), 0);
    });

    test('midnight compares against the whole day ahead', () {
      expect(timingOf(nowAt(0)), isNot(0));
      expect(timingOf(nowAt(0)).abs(), lessThanOrEqualTo(1));
    });

    test('every named period keeps a timing signal too', () {
      for (final period in <String>[
        'morning',
        'midday',
        'afternoon',
        'evening',
      ]) {
        final reading = ReadingCalculator(profile).calculate(
          // 05:00 local, so none of them has started or elapsed.
          context: const <String, Object?>{
            'instantUtc': '2026-09-17T22:00:00Z',
            'deviceTimezone': 'Asia/Ho_Chi_Minh',
          },
          mode: 'act_wait',
          period: period,
        );
        expect(reading['status'], 'ready', reason: period);
        expect(timingOf(reading), isNot(0), reason: period);
      }
    });

    test('the timing signal survives a daylight-saving transition', () {
      // New York loses an hour on 2026-03-08 and gains one on 2026-11-01. The
      // comparison set is built from the hours that actually exist.
      for (final instant in <String>[
        '2026-03-08T14:00:00Z',
        '2026-11-01T15:00:00Z',
      ]) {
        final reading = calculateReading(
          profile: const <String, Object?>{
            'birthDate': '1990-03-14',
            'birthTime': '08:25',
            'birthCountry': 'US',
            'traditionalProfile': 'female',
            'revision': 1,
          },
          context: <String, Object?>{
            'instantUtc': instant,
            'deviceTimezone': 'America/New_York',
          },
          mode: 'act_wait',
          period: 'now',
        );
        expect(reading['status'], 'ready', reason: instant);
        expect(timingOf(reading).isFinite, isTrue, reason: instant);
        expect(timingOf(reading).abs(), lessThanOrEqualTo(1), reason: instant);
      }
    });

    test('ACT can win while its own timing signal is negative', () {
      // Why the result guidance may not claim "the most aligned moment"
      // merely because ACT won: the mixture also reads prospect, change
      // pressure and luck, and they can outweigh a negative timing.
      final found = <int>[7, 8, 9, 10, 11, 12, 13]
          .map(nowAt)
          .where(
            (reading) => timingOf(reading) < 0 && reading['winner'] == 'ACT',
          )
          .toList();
      expect(
        found,
        isNotEmpty,
        reason: 'no instant produced an ACT win on a negative timing signal',
      );
    });

    test(
      'an elapsed period refuses to score rather than borrowing another',
      () {
        final reading = calculateReading(
          profile: profile,
          context: const <String, Object?>{
            'instantUtc': '2026-09-18T08:30:00Z',
            'deviceTimezone': 'Asia/Ho_Chi_Minh',
          },
          mode: 'act_wait',
          period: 'morning',
        );
        expect(reading['status'], 'period_elapsed');
        expect(reading['percentages'], isNull);
        expect(reading['winner'], isNull);
        expect(reading['scoring'], isNull);
      },
    );
  });
}
