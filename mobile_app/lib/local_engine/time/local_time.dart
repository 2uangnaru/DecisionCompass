/// Port of `calculation-engine/src/time.js`.
///
/// Timezone handling, local-day segmentation and birth-instant resolution.
/// Every rule here mirrors the Node engine line for line, including the
/// explicit enumeration of candidate offsets that preserves DST folds and
/// rejects DST gaps instead of silently moving a reading.
library;

import '../core/bounded_cache.dart';
import '../core/numbers.dart';
import 'moment_shim.dart';
import 'tzdb.dart';

export 'moment_shim.dart' show EngineError, msPerDay, msPerHour, toIsoStringUtc;

/// Local-period boundaries in local wall-clock hours, from `src/time.js`.
const Map<String, List<int>> periods = <String, List<int>>{
  'morning': <int>[6, 12],
  'midday': <int>[12, 14],
  'afternoon': <int>[14, 18],
  'evening': <int>[18, 24],
};

bool validZone(String? zone) => zone != null && isValidZone(zone);

String requireZone(String? zone) {
  if (!validZone(zone)) throw const EngineError('INVALID_IANA_TIMEZONE');
  return zone!;
}

TzZone _zoneOrThrow(String zone) {
  final resolved = lookupZone(zone);
  if (resolved == null) throw const EngineError('INVALID_IANA_TIMEZONE');
  return resolved;
}

final RegExp _offsetSuffix = RegExp(r'(Z|[+-]\d{2}:\d{2})$');

/// `parseInstant`: an explicit UTC or offset suffix is mandatory, and the
/// supported range is checked against the year *as written*, which is what
/// `moment.parseZone(...).year()` reports.
double parseInstant(Object? value) {
  if (value is! String) throw const EngineError('UTC_OR_OFFSET_REQUIRED');
  if (!_offsetSuffix.hasMatch(value)) {
    throw const EngineError('UTC_OR_OFFSET_REQUIRED');
  }
  final parsed = parseZonedIso(value);
  if (parsed == null) throw const EngineError('INVALID_INSTANT');
  final year = parsed.localFields.year;
  if (year < 1900 || year > 2099) {
    throw const EngineError('SUPPORTED_READING_YEARS_1900_2099');
  }
  return parsed.utcMs;
}

final RegExp _birthDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp _birthTimePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

String parseBirthDate(Object? value) {
  if (value is! String || !_birthDatePattern.hasMatch(value)) {
    throw const EngineError('INVALID_BIRTH_DATE');
  }
  final parsed = parseStrictUtcDate(value);
  if (parsed == null)
    throw const EngineError('SUPPORTED_BIRTH_YEARS_1900_2099');
  final year = int.parse(value.substring(0, 4));
  if (year < 1900 || year > 2099) {
    throw const EngineError('SUPPORTED_BIRTH_YEARS_1900_2099');
  }
  return value;
}

String? parseBirthTime(Object? value) {
  if (value == null || value == 'unknown') return null;
  if (value is! String || !_birthTimePattern.hasMatch(value)) {
    throw const EngineError('INVALID_BIRTH_TIME');
  }
  return value;
}

/// The local view of an instant, mirroring the object `localAt` returns.
class LocalTime {
  const LocalTime({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
    required this.date,
    required this.clock,
    required this.offsetSeconds,
    required this.iso,
    required this.zone,
  });

  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
  final String date;
  final String clock;
  final double offsetSeconds;
  final String iso;
  final String zone;
}

LocalTime localAt(double ms, String zone) {
  final resolved = _zoneOrThrow(requireZone(zone));
  final moment = ZonedMoment.at(resolved, ms);
  final fields = moment.fields;
  return LocalTime(
    year: fields.year,
    month: fields.month,
    day: fields.day,
    hour: fields.hour,
    minute: fields.minute,
    second: fields.second,
    date: formatCivilDate(fields),
    clock: formatCivilClock(fields),
    offsetSeconds: moment.offsetMinutes * 60,
    iso:
        '${formatCivilDate(fields)}T${formatCivilClock(fields)}'
        '${formatOffsetToken(moment.offsetMinutes)}',
    zone: zone,
  );
}

/// The earthly-branch index of a local hour: 23:00–00:59 is 子 (0).
int hourBranch(int hour) => ((hour + 1) ~/ 2) % 12;

/// `moment.tz(ms, zone).format('YYYY-MM-DDTHH:mm:ss')`.
String _wallLabel(TzZone zone, double ms) {
  final fields = ZonedMoment.at(zone, ms).fields;
  return '${formatCivilDate(fields)}T${formatCivilClock(fields)}';
}

/// Every instant in [zone] whose wall clock reads [date] at [clock].
///
/// Empty during a DST gap; two entries during a fold. Enumerating the zone's
/// own offsets is what makes both cases explicit instead of silently resolved.
List<double> localCandidates(String date, String clock, String zone) {
  final resolved = _zoneOrThrow(requireZone(zone));
  final label = '${date}T${clock.length == 5 ? '$clock:00' : clock}';
  final civil = _parseStrictCivil(label);
  if (civil == null) throw const EngineError('INVALID_LOCAL_DATETIME');
  final wanted = _wallLabelFromMs(civil);

  final seen = <double>{};
  for (final offset in resolved.offsets.toSet()) {
    final candidate = civil + offset * 60000;
    if (_wallLabel(resolved, candidate) == wanted) seen.add(candidate);
  }
  final result = seen.toList()..sort();
  return result;
}

String _wallLabelFromMs(double ms) {
  final fields = civilFromUtcMs(ms);
  return '${formatCivilDate(fields)}T${formatCivilClock(fields)}';
}

final RegExp _strictCivilPattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$',
);

double? _parseStrictCivil(String label) {
  final match = _strictCivilPattern.firstMatch(label);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6)!);
  if (month < 1 || month > 12) return null;
  if (day < 1 || day > daysInMonth(year, month - 1)) return null;
  if (hour > 23 || minute > 59 || second > 59) return null;
  return utcMsFromCivil(year, month, day, hour, minute, second);
}

/// One contiguous range of instants that could be the birth moment.
class BirthInterval {
  const BirthInterval(this.start, this.end, this.zone);

  final double start;
  final double end;
  final String zone;
}

/// Everything the engine knows about when and where the person was born.
class BirthContext {
  const BirthContext({
    required this.date,
    required this.clock,
    required this.zones,
    required this.zoneSource,
    required this.intervals,
    required this.exact,
    required this.status,
    required this.nonexistentZones,
  });

  final String date;
  final String? clock;
  final List<String> zones;
  final String zoneSource;
  final List<BirthInterval> intervals;
  final bool exact;
  final String status;
  final List<String> nonexistentZones;
}

/// Resolves the birth instant (or the set of possible instants) from the
/// profile. The current location is never consulted here.
BirthContext birthContext({
  required String birthDate,
  String? birthTime,
  String? birthCountry,
  String? birthTimezone,
}) {
  final date = parseBirthDate(birthDate);
  final clock = parseBirthTime(birthTime);

  var zones = <String>[];
  var source = 'unresolved';
  if (birthTimezone != null) {
    zones = <String>[requireZone(birthTimezone)];
    source = 'explicit_birth_timezone';
  } else if (birthCountry != null) {
    final code = birthCountry.toUpperCase();
    if (!tzdbCountries().contains(code)) {
      throw const EngineError('INVALID_BIRTH_COUNTRY');
    }
    zones = zonesForCountry(code) ?? <String>[];
    source = zones.length == 1
        ? 'single_zone_birth_country'
        : 'birth_country_zone_candidates';
  }

  final intervals = <BirthInterval>[];
  final nonexistentZones = <String>[];
  for (final zone in zones) {
    if (clock != null) {
      final instants = localCandidates(date, clock, zone);
      if (instants.isEmpty) nonexistentZones.add(zone);
      for (final instant in instants) {
        intervals.add(BirthInterval(instant, instant, zone));
      }
    } else {
      final wallStart = parseStrictUtcDate(date)!;
      final wallEnd = wallStart + msPerDay;
      // Intersect every UTC offset era with the desired civil date. Handles
      // 23/25-hour dates and completely skipped dates without pretending noon
      // was observed.
      final z = _zoneOrThrow(zone);
      for (var i = 0; i < z.untils.length; i++) {
        final lower = i > 0 ? z.untils[i - 1] : double.negativeInfinity;
        final start = _max(lower, wallStart + z.offsets[i] * 60000);
        final end = _min(z.untils[i], wallEnd + z.offsets[i] * 60000);
        if (end > start) intervals.add(BirthInterval(start, end - 1, zone));
      }
      if (!intervals.any((x) => x.zone == zone)) nonexistentZones.add(zone);
    }
  }

  // Distinct timezone ids can name the same birth instant (a country whose
  // regions only differed before the entered birth year).
  final exact =
      clock != null &&
      intervals.isNotEmpty &&
      intervals.map((x) => x.start).toSet().length == 1 &&
      intervals.every((x) => x.start == x.end) &&
      nonexistentZones.isEmpty;

  return BirthContext(
    date: date,
    clock: clock,
    zones: zones,
    zoneSource: source,
    intervals: intervals,
    exact: exact,
    status: zones.isEmpty
        ? 'birth_timezone_unresolved'
        : intervals.isEmpty
        ? 'birth_time_nonexistent'
        : exact
        ? 'exact'
        : 'uncertain',
    nonexistentZones: nonexistentZones,
  );
}

double _max(double a, double b) => a > b ? a : b;
double _min(double a, double b) => a < b ? a : b;

final BoundedCache<String, List<double>> _boundaryCache =
    BoundedCache<String, List<double>>(64);

const List<int> _boundaryHours = <int>[
  0,
  1,
  3,
  5,
  6,
  7,
  9,
  11,
  12,
  13,
  14,
  15,
  17,
  18,
  19,
  21,
  23,
];

/// Candidate segment boundaries around a local civil date: every earthly-branch
/// hour start plus every zone transition in the surrounding days.
List<double> civilBoundaries(String date, String zone) {
  final key = '$date|$zone';
  final cached = _boundaryCache.get(key);
  if (cached != null) return cached;

  final boundaries = <double>{};
  final dayMs = parseStrictUtcDate(date);
  if (dayMs == null) throw const EngineError('INVALID_LOCAL_DATETIME');

  for (var delta = -1; delta <= 2; delta++) {
    final shifted = civilFromUtcMs(dayMs + delta * msPerDay.toDouble());
    final d = formatCivilDate(shifted);
    for (final h in _boundaryHours) {
      final clock = '${h.toString().padLeft(2, '0')}:00';
      boundaries.addAll(localCandidates(d, clock, zone));
    }
  }
  for (final until in _zoneOrThrow(zone).untils) {
    if (until >= dayMs - 2 * msPerDay && until <= dayMs + 4 * msPerDay) {
      boundaries.add(until);
    }
  }
  final sorted = boundaries.toList()..sort();
  return _boundaryCache.set(key, sorted);
}

/// One evaluable slice of the local day.
class DaySegment {
  const DaySegment({
    required this.start,
    required this.end,
    required this.local,
    required this.hourBranchIndex,
    this.candidateStart,
  });

  final double start;
  final double end;
  final LocalTime local;
  final int hourBranchIndex;

  /// Set by [periodSegments] when a future period is partly in the past.
  final double? candidateStart;

  DaySegment withCandidateStart(double value) => DaySegment(
    start: start,
    end: end,
    local: local,
    hourBranchIndex: hourBranchIndex,
    candidateStart: value,
  );

  /// The instant the segment is counted from, matching the engine's
  /// `candidateStart ?? start`.
  double get includedFrom => candidateStart ?? start;
}

List<DaySegment> segmentsForDay(
  double ms,
  String zone, [
  List<double> extraBoundaries = const <double>[],
]) {
  final date = localAt(ms, zone).date;
  final points = <double>{
    ...civilBoundaries(date, zone),
    ...extraBoundaries,
  }.toList()..sort();
  final result = <DaySegment>[];
  for (var i = 0; i < points.length - 1; i++) {
    final start = points[i];
    final end = points[i + 1];
    final local = localAt(start, zone);
    if (local.date != date) continue;
    result.add(
      DaySegment(
        start: start,
        end: end,
        local: local,
        hourBranchIndex: hourBranch(local.hour),
      ),
    );
  }
  return result;
}

List<DaySegment> periodSegments(
  List<DaySegment> segments,
  double now,
  String period,
) {
  if (period == 'now') {
    return segments.where((s) => s.start <= now && now < s.end).toList();
  }
  final bounds = periods[period];
  if (bounds == null) throw const EngineError('INVALID_PERIOD');
  final lo = bounds[0];
  final hi = bounds[1];
  return segments
      .where((s) => s.local.hour >= lo && s.local.hour < hi && s.end > now)
      .map((s) => s.withCandidateStart(now > s.start ? now : s.start))
      .toList();
}

double addCivil(
  double ms,
  String zone,
  int years, [
  int months = 0,
  int days = 0,
  int hours = 0,
]) {
  return momentAddCivil(
    _zoneOrThrow(requireZone(zone)),
    ms,
    years: years,
    months: months,
    days: days,
    hours: hours,
  );
}

/// The index of a stem/branch pair in the 60-term sexagenary cycle.
int cyclical(int stem, int branch) {
  for (var i = 0; i < 60; i++) {
    if (jsMod(i, 10) == stem && jsMod(i, 12) == branch) return i;
  }
  throw const EngineError('INVALID_PILLAR');
}
