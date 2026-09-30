import '../local_engine/time/local_time.dart';
import '../models.dart';

/// Why a period cannot be chosen right now.
enum PeriodStatus {
  /// Selectable. Either it has not started yet, or enough of it is left.
  available,

  /// Still running, but too little of it remains to be worth a reading.
  ///
  /// Distinct from [passed] on purpose: the clock has not run out, so calling
  /// it "Passed" would be false.
  tooLittleTime,

  /// Over. Its local end is behind the reader.
  passed,
}

/// How much of a period is left, and whether that is enough.
class PeriodAvailability {
  const PeriodAvailability({required this.status, required this.remaining});

  final PeriodStatus status;

  /// Time from now to the period's local end. Negative once it is over, and
  /// null for NOW, which has no end.
  final Duration? remaining;

  bool get selectable => status == PeriodStatus.available;
}

/// How little may remain before a period stops being offered.
///
/// A reading is a considered thing — the ritual alone runs four to five
/// seconds, and a future-period reading exists to point at windows inside that
/// period. Offering a period with twenty minutes left produces a reading whose
/// own windows are mostly behind the reader by the time they read it.
///
/// Midday is the short one, two hours against the others' four and six, so it
/// gets a shorter cutoff rather than being unofferable for half its length.
const Map<TimePeriod, Duration> periodCutoffs = <TimePeriod, Duration>{
  TimePeriod.morning: Duration(minutes: 90),
  TimePeriod.midday: Duration(minutes: 60),
  TimePeriod.afternoon: Duration(minutes: 90),
  TimePeriod.evening: Duration(minutes: 90),
};

/// The instant a local wall hour occurs on [date] in [zone], or null when a
/// DST jump means it never happens that day.
///
/// The earliest candidate, so an hour repeated by a fall-back transition is
/// read as the first time it happens. That is the conservative reading for a
/// boundary: it makes a period end sooner, never later.
double? _instantAtLocalHour(String date, int hour, String zone) {
  final candidates = localCandidates(
    date,
    '${hour.toString().padLeft(2, '0')}:00',
    zone,
  );
  return candidates.isEmpty ? null : candidates.first;
}

/// The instant a local civil date begins in [zone].
///
/// Usually local midnight. A handful of zones have moved their clocks at
/// midnight itself, skipping it, so the first hour that actually exists on
/// that date is used instead of pretending 00:00 happened.
double _startOfCivilDate(String date, String zone) {
  for (var hour = 0; hour < 24; hour++) {
    final ms = _instantAtLocalHour(date, hour, zone);
    if (ms != null) return ms;
  }
  throw EngineError('NO_LOCAL_HOURS_ON_DATE:$date');
}

/// The instant [period] ends on the local date [date] in [zone].
///
/// Evening ends at the start of the next local date rather than at "24:00",
/// so a 23-hour or 25-hour day is exactly as long as it really was.
double periodEndInstant(String date, TimePeriod period, String zone) {
  final hours = period.localHours;
  if (hours == null) {
    throw const EngineError('NOW_HAS_NO_END');
  }
  final end = hours.$2;
  if (end >= 24) return _startOfCivilDate(civilDateShift(date, 1), zone);
  // If the end hour itself was skipped by a spring-forward, the period runs
  // until the next hour that did happen.
  for (var hour = end; hour < 24; hour++) {
    final ms = _instantAtLocalHour(date, hour, zone);
    if (ms != null) return ms;
  }
  return _startOfCivilDate(civilDateShift(date, 1), zone);
}

/// Whether [period] can be chosen at [instantUtc], in the reader's own
/// resolved [timezone].
///
/// [timezone] is the IANA zone the engine would resolve for a reading taken
/// now — not the host machine's. On a device they are normally the same; on a
/// test runner, a rooted phone or a traveller's handset they are not, and a
/// period muted by the wrong clock is a period the reader cannot use and
/// cannot explain.
PeriodAvailability periodAvailability(
  TimePeriod period, {
  required DateTime instantUtc,
  required String timezone,
}) {
  // NOW is the instant of the tap. It cannot run out.
  if (period.localHours == null) {
    return const PeriodAvailability(
      status: PeriodStatus.available,
      remaining: null,
    );
  }
  final nowMs = instantUtc.toUtc().millisecondsSinceEpoch.toDouble();
  final date = localAt(nowMs, timezone).date;
  final endMs = periodEndInstant(date, period, timezone);
  final remaining = Duration(milliseconds: (endMs - nowMs).round());

  if (remaining <= Duration.zero) {
    return PeriodAvailability(
      status: PeriodStatus.passed,
      remaining: remaining,
    );
  }
  // At exactly the cutoff the period is already closed, so the boundary is
  // `<=`. A period that has not started yet is always further from its end
  // than its cutoff, so it needs no separate case.
  if (remaining <= periodCutoffs[period]!) {
    return PeriodAvailability(
      status: PeriodStatus.tooLittleTime,
      remaining: remaining,
    );
  }
  return PeriodAvailability(
    status: PeriodStatus.available,
    remaining: remaining,
  );
}

/// The next instant at which any period's availability changes, after
/// [instantUtc].
///
/// Every period contributes two moments — the one where it drops under its
/// cutoff, and the one where it ends — so a screen left open re-renders
/// exactly when something actually changed, rather than on a poll.
DateTime? nextAvailabilityChange({
  required DateTime instantUtc,
  required String timezone,
}) {
  final nowMs = instantUtc.toUtc().millisecondsSinceEpoch.toDouble();
  final date = localAt(nowMs, timezone).date;
  double? soonest;
  for (final period in TimePeriod.values) {
    if (period.localHours == null) continue;
    final endMs = periodEndInstant(date, period, timezone);
    for (final ms in <double>[
      endMs - periodCutoffs[period]!.inMilliseconds,
      endMs,
    ]) {
      if (ms <= nowMs) continue;
      if (soonest == null || ms < soonest) soonest = ms;
    }
  }
  // Past the last period's end, the next thing that changes is the date
  // itself, which re-opens every period.
  soonest ??= _startOfCivilDate(civilDateShift(date, 1), timezone);
  return DateTime.fromMillisecondsSinceEpoch(soonest.round(), isUtc: true);
}
