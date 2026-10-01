import 'package:decision_compass/data/period_availability.dart';
import 'package:decision_compass/local_engine/time/local_time.dart';
import 'package:decision_compass/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asia/Ho_Chi_Minh is UTC+7 all year, so a local wall time here is just the
/// UTC instant plus seven hours — which keeps the boundary arithmetic in these
/// tests readable. DST is exercised separately, further down.
const _vn = 'Asia/Ho_Chi_Minh';

DateTime _vnLocal(int hour, int minute) =>
    DateTime.utc(2026, 9, 18, hour, minute).subtract(const Duration(hours: 7));

PeriodStatus _statusAt(
  TimePeriod period,
  int hour,
  int minute, {
  String zone = _vn,
}) => periodAvailability(
  period,
  instantUtc: _vnLocal(hour, minute),
  timezone: zone,
).status;

void main() {
  group('a period closes before it ends', () {
    /// (period, local cutoff, local end). The cutoff is the moment the
    /// remaining time reaches the period's threshold.
    const cases = <(TimePeriod, (int, int), (int, int))>[
      (TimePeriod.morning, (10, 30), (12, 0)),
      (TimePeriod.midday, (13, 0), (14, 0)),
      (TimePeriod.afternoon, (16, 30), (18, 0)),
      (TimePeriod.evening, (22, 30), (24, 0)),
    ];

    for (final (period, cutoff, end) in cases) {
      final name = period.name;
      test('$name is open a minute before its cutoff', () {
        final (hour, minute) = cutoff;
        final before = minute == 0
            ? _statusAt(period, hour - 1, 59)
            : _statusAt(period, hour, minute - 1);
        expect(before, PeriodStatus.available);
      });

      test('$name is closed exactly at its cutoff', () {
        // The specification is explicit that the boundary itself is closed.
        expect(
          _statusAt(period, cutoff.$1, cutoff.$2),
          PeriodStatus.tooLittleTime,
        );
      });

      test('$name is closed a minute after its cutoff', () {
        expect(
          _statusAt(period, cutoff.$1, cutoff.$2 + 1),
          PeriodStatus.tooLittleTime,
        );
      });

      test(
        '$name still says "too little time", not "passed", until it ends',
        () {
          // A minute before the end there is still time on the clock. Calling
          // that "Passed" would be false.
          final (endHour, _) = end;
          expect(
            _statusAt(period, endHour - 1, 59),
            PeriodStatus.tooLittleTime,
          );
        },
      );

      test('$name is passed once its end arrives', () {
        final (endHour, endMinute) = end;
        if (period == TimePeriod.evening) {
          // Evening ends at local midnight, and midnight is also where the
          // local date turns over — so the period that becomes current is the
          // *next* day's evening, a full day away from its own end. The day
          // resetting is the behaviour; there is no moment where evening reads
          // as passed.
          expect(_statusAt(period, endHour, endMinute), PeriodStatus.available);
          expect(
            periodAvailability(
              period,
              instantUtc: _vnLocal(endHour, endMinute),
              timezone: _vn,
            ).remaining,
            const Duration(hours: 24),
          );
          return;
        }
        expect(_statusAt(period, endHour, endMinute), PeriodStatus.passed);
        expect(_statusAt(period, endHour, endMinute + 1), PeriodStatus.passed);
      });
    }

    test('a period that has not started yet is always open', () {
      // 00:30, before any of them begins.
      for (final period in TimePeriod.values) {
        expect(
          _statusAt(period, 0, 30),
          PeriodStatus.available,
          reason: '${period.name} was closed before it had even begun',
        );
      }
      // And the morning is open the moment it opens.
      expect(_statusAt(TimePeriod.morning, 6, 0), PeriodStatus.available);
    });

    test('NOW never closes', () {
      for (final hour in <int>[0, 6, 12, 18, 23]) {
        final availability = periodAvailability(
          TimePeriod.now,
          instantUtc: _vnLocal(hour, 59),
          timezone: _vn,
        );
        expect(availability.status, PeriodStatus.available, reason: '${hour}h');
        expect(availability.remaining, isNull, reason: 'NOW has no end');
      }
    });

    test('the thresholds are the ones the product asked for', () {
      expect(periodCutoffs[TimePeriod.morning], const Duration(minutes: 90));
      expect(periodCutoffs[TimePeriod.midday], const Duration(minutes: 60));
      expect(periodCutoffs[TimePeriod.afternoon], const Duration(minutes: 90));
      expect(periodCutoffs[TimePeriod.evening], const Duration(minutes: 90));
      expect(periodCutoffs.containsKey(TimePeriod.now), isFalse);
    });
  });

  group('the reader\'s own timezone, not the host\'s', () {
    test('one instant reads differently in different zones', () {
      // 04:00 UTC is 16:00 in Auckland, 21:00 the previous day in Los
      // Angeles, and 11:00 in Ho Chi Minh City. A build that reached for the
      // host clock would give all three the same answer.
      final instant = DateTime.utc(2026, 9, 18, 4);
      PeriodStatus status(String zone) => periodAvailability(
        TimePeriod.afternoon,
        instantUtc: instant,
        timezone: zone,
      ).status;

      expect(status('Pacific/Auckland'), PeriodStatus.available);
      expect(status('America/Los_Angeles'), PeriodStatus.passed);
      expect(status('Asia/Ho_Chi_Minh'), PeriodStatus.available);
    });

    test('remaining time is measured to the local end, not a fixed offset', () {
      final instant = DateTime.utc(2026, 9, 18, 4);
      // 16:00 in Auckland leaves two hours of afternoon.
      expect(
        periodAvailability(
          TimePeriod.afternoon,
          instantUtc: instant,
          timezone: 'Pacific/Auckland',
        ).remaining,
        const Duration(hours: 2),
      );
      // 11:00 in Ho Chi Minh City leaves seven.
      expect(
        periodAvailability(
          TimePeriod.afternoon,
          instantUtc: instant,
          timezone: _vn,
        ).remaining,
        const Duration(hours: 7),
      );
    });
  });

  group('across a daylight-saving transition', () {
    /// The length of one local civil date, measured between the instants the
    /// date starts and ends.
    Duration dayLength(String date, String zone) {
      final start = periodEndInstant(
        civilDateShift(date, -1),
        TimePeriod.evening,
        zone,
      );
      final end = periodEndInstant(date, TimePeriod.evening, zone);
      return Duration(milliseconds: (end - start).round());
    }

    test('a short, a long and a half-hour day are all their real length', () {
      // Evening runs to the next local midnight, so its end is the point where
      // a 24-hour assumption would be wrong.
      expect(
        dayLength('2026-03-08', 'America/New_York'),
        const Duration(hours: 23),
      );
      expect(
        dayLength('2026-11-01', 'America/New_York'),
        const Duration(hours: 25),
      );
      expect(
        dayLength('2026-10-04', 'Australia/Lord_Howe'),
        const Duration(hours: 23, minutes: 30),
      );
      expect(
        dayLength('2026-09-27', 'Pacific/Chatham'),
        const Duration(hours: 23),
      );
    });

    test('a transition outside a period does not shorten that period', () {
      // Every one of these zones moves its clock in the small hours, before
      // morning opens, so the named periods keep their full length even on a
      // 23- or 25-hour date.
      for (final (date, zone) in const <(String, String)>[
        ('2026-03-08', 'America/New_York'),
        ('2026-11-01', 'America/New_York'),
        ('2026-10-04', 'Australia/Lord_Howe'),
      ]) {
        final eveningStart = localCandidates(date, '18:00', zone).first;
        final eveningEnd = periodEndInstant(date, TimePeriod.evening, zone);
        expect(
          Duration(milliseconds: (eveningEnd - eveningStart).round()),
          const Duration(hours: 6),
          reason: '$zone $date',
        );
      }
    });

    test('the cutoff still lands 90 minutes before a shifted midnight', () {
      const zone = 'America/New_York';
      const date = '2026-11-01';
      final end = periodEndInstant(date, TimePeriod.evening, zone);
      final justOpen = DateTime.fromMillisecondsSinceEpoch(
        (end - const Duration(minutes: 91).inMilliseconds).round(),
        isUtc: true,
      );
      final justClosed = DateTime.fromMillisecondsSinceEpoch(
        (end - const Duration(minutes: 90).inMilliseconds).round(),
        isUtc: true,
      );
      expect(
        periodAvailability(
          TimePeriod.evening,
          instantUtc: justOpen,
          timezone: zone,
        ).status,
        PeriodStatus.available,
      );
      expect(
        periodAvailability(
          TimePeriod.evening,
          instantUtc: justClosed,
          timezone: zone,
        ).status,
        PeriodStatus.tooLittleTime,
      );
    });
  });

  group('when the screen should wake up', () {
    test('the next change is the soonest cutoff or end still ahead', () {
      // 09:00 local. The next thing to happen is morning reaching its cutoff
      // at 10:30.
      final next = nextAvailabilityChange(
        instantUtc: _vnLocal(9, 0),
        timezone: _vn,
      );
      expect(next, isNotNull);
      expect(
        localAt(next!.millisecondsSinceEpoch.toDouble(), _vn).clock,
        '10:30:00',
      );
    });

    test('after the last period closes, the next change is the new day', () {
      // 23:00 local: evening is already closed and nothing else changes until
      // midnight re-opens the day.
      final next = nextAvailabilityChange(
        instantUtc: _vnLocal(23, 0),
        timezone: _vn,
      );
      expect(next, isNotNull);
      final local = localAt(next!.millisecondsSinceEpoch.toDouble(), _vn);
      expect(local.clock, '00:00:00');
      expect(local.date, '2026-09-19');
    });

    test('every returned moment is strictly in the future', () {
      for (final hour in <int>[0, 6, 10, 13, 16, 22, 23]) {
        final now = _vnLocal(hour, 30);
        final next = nextAvailabilityChange(instantUtc: now, timezone: _vn);
        expect(next!.isAfter(now), isTrue, reason: '${hour}h30');
      }
    });
  });
}
