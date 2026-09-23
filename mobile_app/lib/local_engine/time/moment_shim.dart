/// The handful of moment / moment-timezone behaviours the engine depends on.
///
/// The Node engine formats and parses through moment, so a port that wants
/// bit-identical results has to reproduce moment's own quirks rather than use
/// an idiomatic Dart equivalent: its strict-ISO validity rules, its `Z` offset
/// token, its `~~` truncation, its `absRound` of fractional offsets, and its
/// gap/fold policy (`moveInvalidForward: true`, `moveAmbiguousForward: false`).
///
/// Every instant is a `double`, because in JavaScript every instant is a
/// double. Keeping that representation removes a whole class of divergence
/// around pre-1930 LMT offsets, which are not whole numbers of minutes.
///
/// Nothing here is a general date library. It covers exactly the calls made by
/// `calculation-engine/src/time.js`.
library;

import 'tzdb.dart';

/// Milliseconds in an hour and a day, matching `src/time.js`.
const int msPerHour = 3600000;
const int msPerDay = 24 * msPerHour;

/// Thrown for every input the Node engine rejects, carrying the engine's own
/// error code so the calling layer can map it identically.
class EngineError implements Exception {
  const EngineError(this.code);

  final String code;

  @override
  String toString() => 'EngineError($code)';
}

/// Civil (proleptic Gregorian) date/time fields.
class CivilDateTime {
  const CivilDateTime(
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.second,
    this.millisecond,
  );

  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
  final int millisecond;
}

bool isLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

int _mod(int n, int x) => ((n % x) + x) % x;

/// moment's own `daysInMonth`, including its normalization of an out-of-range
/// month index and its `31 - ((m % 7) % 2)` length trick.
int daysInMonth(int year, int monthIndex) {
  final modMonth = _mod(monthIndex, 12);
  final adjustedYear = year + (monthIndex - modMonth) ~/ 12;
  if (modMonth == 1) return isLeapYear(adjustedYear) ? 29 : 28;
  return 31 - ((modMonth % 7) % 2);
}

/// Days from the epoch for a proleptic-Gregorian date (Howard Hinnant's
/// `days_from_civil`).
int daysFromCivil(int year, int month, int day) {
  final y = month <= 2 ? year - 1 : year;
  final era = (y >= 0 ? y : y - 399) ~/ 400;
  final yoe = y - era * 400;
  final mp = (month + 9) % 12;
  final doy = (153 * mp + 2) ~/ 5 + day - 1;
  final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
  return era * 146097 + doe - 719468;
}

/// Inverse of [daysFromCivil]; returns `[year, month, day]`.
List<int> civilFromDays(int days) {
  final z = days + 719468;
  final era = (z >= 0 ? z : z - 146096) ~/ 146097;
  final doe = z - era * 146097;
  final yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
  final y = yoe + era * 400;
  final doy = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
  final mp = (5 * doy + 2) ~/ 153;
  final d = doy - (153 * mp + 2) ~/ 5 + 1;
  final m = mp < 10 ? mp + 3 : mp - 9;
  return <int>[m <= 2 ? y + 1 : y, m, d];
}

/// Milliseconds since the epoch for civil UTC fields, mirroring
/// `Date.UTC(...)`: out-of-range components roll over rather than throw.
double utcMsFromCivil(
  int year,
  int month,
  int day, [
  int hour = 0,
  int minute = 0,
  int second = 0,
  int millisecond = 0,
]) {
  final monthIndex = month - 1;
  final rolledYear = year + _floorDiv(monthIndex, 12);
  final rolledMonth = _mod(monthIndex, 12) + 1;
  return daysFromCivil(rolledYear, rolledMonth, 1) * msPerDay.toDouble() +
      (day - 1) * msPerDay.toDouble() +
      hour * msPerHour.toDouble() +
      minute * 60000.0 +
      second * 1000.0 +
      millisecond;
}

/// JS `new Date(x)` / `setTime(x)` clipping: truncation toward zero.
int clipTime(double value) {
  if (!value.isFinite) throw const EngineError('INVALID_INSTANT');
  return value.truncate();
}

/// moment's `absRound`: round away from zero for negatives, round for positives.
double absRound(double value) =>
    value < 0 ? -(-value).roundToDouble() : value.roundToDouble();

/// Civil UTC fields for an instant, matching `new Date(ms).getUTC*()`.
CivilDateTime civilFromUtcMs(double ms) {
  final clipped = clipTime(ms);
  // Dart's `%` is already non-negative for a positive divisor; the day index
  // then has to be derived from it so that pre-1970 instants floor correctly
  // instead of truncating toward zero.
  final rest = clipped % msPerDay;
  final days = (clipped - rest) ~/ msPerDay;
  final ymd = civilFromDays(days);
  return CivilDateTime(
    ymd[0],
    ymd[1],
    ymd[2],
    rest ~/ msPerHour,
    (rest ~/ 60000) % 60,
    (rest ~/ 1000) % 60,
    rest % 1000,
  );
}

String _pad(int value, int width) => value.abs().toString().padLeft(width, '0');

String formatCivilDate(CivilDateTime c) =>
    '${_pad(c.year, 4)}-${_pad(c.month, 2)}-${_pad(c.day, 2)}';

String formatCivilClock(CivilDateTime c) =>
    '${_pad(c.hour, 2)}:${_pad(c.minute, 2)}:${_pad(c.second, 2)}';

/// `new Date(ms).toISOString()`.
String toIsoStringUtc(double ms) {
  final c = civilFromUtcMs(ms);
  return '${formatCivilDate(c)}T${formatCivilClock(c)}'
      '.${_pad(c.millisecond, 3)}Z';
}

/// moment's `Z` offset token: sign, then `~~(offset / 60)` and `~~offset % 60`.
String formatOffsetToken(double utcOffsetMinutes) {
  var offset = utcOffsetMinutes;
  var sign = '+';
  if (offset < 0) {
    offset = -offset;
    sign = '-';
  }
  final hours = (offset / 60).truncate();
  final minutes = offset.truncate() % 60;
  return '$sign${_pad(hours, 2)}:${_pad(minutes, 2)}';
}

final RegExp _isoDatePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Strict `YYYY-MM-DD` parse with real calendar validation, mirroring
/// `moment.utc(value, 'YYYY-MM-DD', true)`. Returns null when invalid.
double? parseStrictUtcDate(String value) {
  final match = _isoDatePattern.firstMatch(value);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12) return null;
  if (day < 1 || day > daysInMonth(year, month - 1)) return null;
  return utcMsFromCivil(year, month, day);
}

final RegExp _isoDateTimePattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})'
  r'(?:[T ](\d{2})(?::(\d{2})(?::(\d{2})(?:[.,](\d{1,9}))?)?)?)?$',
);

/// Result of parsing an instant that carries its own UTC offset.
class ParsedInstant {
  const ParsedInstant(this.utcMs, this.offsetMinutes, this.localFields);

  final double utcMs;
  final int offsetMinutes;

  /// The civil fields as written, i.e. in the offset the string carried. This
  /// is what `moment.parseZone(...).year()` reports.
  final CivilDateTime localFields;
}

/// Strict ISO-8601 parse of an instant that ends in `Z` or `±HH:MM`, mirroring
/// `moment.parseZone(value, moment.ISO_8601, true)`. Returns null when moment
/// would consider the value invalid, including calendar overflow such as
/// `2023-02-29`.
ParsedInstant? parseZonedIso(String value) {
  var body = value;
  var offsetMinutes = 0;

  if (body.endsWith('Z') || body.endsWith('z')) {
    body = body.substring(0, body.length - 1);
  } else {
    if (body.length < 6) return null;
    final offsetText = body.substring(body.length - 6);
    final sign = offsetText[0];
    if (sign != '+' && sign != '-') return null;
    if (offsetText[3] != ':') return null;
    body = body.substring(0, body.length - 6);
    final hours = int.tryParse(offsetText.substring(1, 3));
    final minutes = int.tryParse(offsetText.substring(4, 6));
    if (hours == null || minutes == null) return null;
    if (hours > 23 || minutes > 59) return null;
    offsetMinutes = (hours * 60 + minutes) * (sign == '-' ? -1 : 1);
  }

  final match = _isoDateTimePattern.firstMatch(body);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.tryParse(match.group(4) ?? '0') ?? 0;
  final minute = int.tryParse(match.group(5) ?? '0') ?? 0;
  final second = int.tryParse(match.group(6) ?? '0') ?? 0;
  final fractionText = match.group(7);
  final millisecond = fractionText == null
      ? 0
      : int.parse(fractionText.padRight(3, '0').substring(0, 3));

  if (month < 1 || month > 12) return null;
  if (day < 1 || day > daysInMonth(year, month - 1)) return null;
  // moment accepts 24:00 only as an exact end-of-day marker.
  if (hour > 24 ||
      (hour == 24 && (minute != 0 || second != 0 || millisecond != 0))) {
    return null;
  }
  if (minute > 59 || second > 59) return null;

  final localMs = utcMsFromCivil(
    year,
    month,
    day,
    hour,
    minute,
    second,
    millisecond,
  );
  return ParsedInstant(
    localMs - offsetMinutes * 60000,
    offsetMinutes,
    CivilDateTime(year, month, day, hour, minute, second, millisecond),
  );
}

/// A moment bound to a zone: the wall clock and UTC offset moment computes.
class ZonedMoment {
  const ZonedMoment._(this.zone, this.wallMs, this.offsetMinutes);

  /// The equivalent of `moment.tz(ms, zone)`.
  factory ZonedMoment.at(TzZone zone, double ms) {
    final offset = zone.utcOffsetMinutesAt(ms);
    // moment reaches this state via `utcOffset(input)`, which shifts the wall
    // clock by `absRound(input * 60000)`.
    return ZonedMoment._(zone, ms + absRound(offset * 60000), offset);
  }

  final TzZone zone;

  /// moment's internal `_d`: the wall clock rendered as a UTC instant.
  final double wallMs;

  /// Real UTC offset in minutes, possibly fractional for LMT-era offsets.
  final double offsetMinutes;

  /// The instant, i.e. moment's `valueOf()`.
  double get instantMs => wallMs - offsetMinutes * 60000;

  CivilDateTime get fields => civilFromUtcMs(wallMs);
}

/// moment-timezone's `Zone.prototype.parse`: which offset applies to a wall
/// clock reading, with `moveInvalidForward` on and `moveAmbiguousForward` off.
double _zoneParse(TzZone zone, double wallMs) {
  final offsets = zone.offsets;
  final untils = zone.untils;
  final max = untils.length - 1;
  for (var i = 0; i < max; i++) {
    var offset = offsets[i];
    final offsetNext = offsets[i + 1];
    // moveAmbiguousForward is false, so a fold keeps the earlier offset.
    if (offset > offsetNext) offset = offsetNext; // moveInvalidForward
    if (wallMs < untils[i] - offset * 60000) return offsets[i];
  }
  return offsets[max];
}

/// Reproduces `moment.updateOffset(mom, keepTime)` for a zone-bound moment.
ZonedMoment _updateOffset(
  TzZone zone,
  double wallMs,
  double currentOffset,
  bool keepTime,
) {
  var offset = zone.rawOffsetMinutesAt(wallMs - currentOffset * 60000);
  double? normalizedWall;

  if (keepTime) {
    var localTimestamp = wallMs;
    if (zone.rawOffsetMinutesAt(localTimestamp + offset * 60000) != offset) {
      offset = _zoneParse(zone, localTimestamp);
      localTimestamp += offset * 60000;
      offset = zone.rawOffsetMinutesAt(localTimestamp);
      normalizedWall = localTimestamp - offset * 60000;
    }
  }

  if (offset.abs() < 16) offset = offset / 60;
  var input = -offset;
  if (input.abs() < 16) input = input * 60;

  // `utcOffset(input, keepTime)`: without keepTime the wall clock moves so the
  // instant is preserved; with it the wall clock is authoritative.
  var resultWall = wallMs;
  if (!keepTime && input != currentOffset) {
    resultWall = wallMs + absRound((input - currentOffset) * 60000);
  }
  if (normalizedWall != null) resultWall = clipTime(normalizedWall).toDouble();
  return ZonedMoment._(zone, resultWall, input);
}

/// `moment.tz(ms, zone).add(years,'years').add(months,'months')
/// .add(days,'days').add(hours,'hours').valueOf()`.
///
/// moment applies months and days to the wall clock (with end-of-month
/// clamping) and hours to the instant, re-resolving the offset after each step.
double momentAddCivil(
  TzZone zone,
  double ms, {
  int years = 0,
  int months = 0,
  int days = 0,
  int hours = 0,
}) {
  var moment = ZonedMoment.at(zone, ms);
  moment = _addUnits(zone, moment, months: years * 12);
  moment = _addUnits(zone, moment, months: months);
  moment = _addUnits(zone, moment, days: days);
  moment = _addUnits(zone, moment, milliseconds: hours * msPerHour);
  return moment.instantMs;
}

ZonedMoment _addUnits(
  TzZone zone,
  ZonedMoment moment, {
  int months = 0,
  int days = 0,
  int milliseconds = 0,
}) {
  if (months == 0 && days == 0 && milliseconds == 0) return moment;

  var wall = moment.wallMs;
  if (months != 0) {
    final fields = civilFromUtcMs(wall);
    final targetMonthIndex = (fields.month - 1) + months;
    // moment: `date < 29 ? date : min(date, daysInMonth(year, rawMonthIndex))`.
    final date = fields.day < 29
        ? fields.day
        : (fields.day < daysInMonth(fields.year, targetMonthIndex)
              ? fields.day
              : daysInMonth(fields.year, targetMonthIndex));
    wall = utcMsFromCivil(
      fields.year,
      targetMonthIndex + 1,
      date,
      fields.hour,
      fields.minute,
      fields.second,
      fields.millisecond,
    );
  }
  if (days != 0) {
    final fields = civilFromUtcMs(wall);
    // moment's `setUTCDate` allows overflow into neighbouring months.
    wall = utcMsFromCivil(
      fields.year,
      fields.month,
      fields.day + days,
      fields.hour,
      fields.minute,
      fields.second,
      fields.millisecond,
    );
  }
  if (milliseconds != 0) wall += milliseconds;

  return _updateOffset(
    zone,
    wall,
    moment.offsetMinutes,
    months != 0 || days != 0,
  );
}

int _floorDiv(int a, int b) => (a - _mod(a, b)) ~/ b;
