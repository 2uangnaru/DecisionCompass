/// Port of the lunar-javascript classes the calculation engine reaches:
/// `Solar`, `LunarYear`, `LunarMonth` and the parts of `Lunar` that produce a
/// lunar date, a day pillar and a solar-term table.
///
/// Upstream is MIT licensed, © 6tail. Instants are Julian days in the UTC+08
/// reference meridian the Chinese civil calendar uses; the engine converts
/// them to UTC itself and never reads them in the device's timezone.
///
/// Day-count arithmetic uses the proleptic Gregorian calendar. Upstream keeps a
/// Julian-calendar branch for dates before October 1582, which the engine can
/// never reach: it rejects birth and reading years outside 1900–2099.
library;

import '../core/bounded_cache.dart';
import 'calendar_data.dart';
import 'shou_xing.dart';

/// A civil date and time, as lunar-javascript's `Solar` models it.
class SolarDateTime {
  const SolarDateTime(
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.second,
  );

  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;

  /// `Solar.fromJulianDay`.
  factory SolarDateTime.fromJulianDay(double julianDay) {
    var d = (julianDay + 0.5).floor();
    var f = julianDay + 0.5 - d;

    if (d >= 2299161) {
      final c = ((d - 1867216.25) / 36524.25).floor();
      d += 1 + c - (c / 4).floor();
    }
    d += 1524;
    var year = ((d - 122.1) / 365.25).floor();
    d -= (365.25 * year).floor();
    var month = (d / 30.601).floor();
    d -= (30.601 * month).floor();
    var day = d;
    if (month > 13) {
      month -= 13;
      year -= 4715;
    } else {
      month -= 1;
      year -= 4716;
    }
    f *= 24;
    var hour = f.floor();
    f -= hour;
    f *= 60;
    var minute = f.floor();
    f -= minute;
    f *= 60;
    var second = (f + 0.5).floor(); // Math.round
    if (second > 59) {
      second -= 60;
      minute++;
    }
    if (minute > 59) {
      minute -= 60;
      hour++;
    }
    if (hour > 23) {
      hour -= 24;
      day += 1;
    }
    return SolarDateTime(year, month, day, hour, minute, second);
  }

  /// `Solar.getJulianDay`.
  double get julianDay {
    var y = year;
    var m = month;
    final d = day + ((second / 60 + minute) / 60 + hour) / 24;
    var n = 0;
    var g = false;
    if (y * 372 + m * 31 + d.floor() >= 588829) g = true;
    if (m <= 2) {
      m += 12;
      y--;
    }
    if (g) {
      n = (y / 100).floor();
      n = 2 - n + (n / 4).floor();
    }
    return (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() +
        d +
        n -
        1524.5;
  }

  String get ymd => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)}';

  String get ymdHms =>
      '$ymd ${_pad(hour, 2)}:${_pad(minute, 2)}:${_pad(second, 2)}';

  static String _pad(int value, int width) =>
      value.abs().toString().padLeft(width, '0');
}

/// Proleptic-Gregorian day number, used for `Solar.subtract`.
int _daysFromCivil(int year, int month, int day) {
  final y = month <= 2 ? year - 1 : year;
  final era = (y >= 0 ? y : y - 399) ~/ 400;
  final yoe = y - era * 400;
  final mp = (month + 9) % 12;
  final doy = (153 * mp + 2) ~/ 5 + day - 1;
  final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
  return era * 146097 + doe - 719468;
}

/// One lunar month: a signed month number (negative when it is the leap month)
/// and the Julian day of its first day.
class LunarMonthData {
  const LunarMonthData(
    this.year,
    this.month,
    this.dayCount,
    this.firstJulianDay,
  );

  final int year;

  /// Negative for a leap month, matching lunar-javascript.
  final int month;
  final int dayCount;
  final double firstJulianDay;

  bool get isLeap => month < 0;
}

/// A computed lunar year: its 31 solar-term instants and its 15 candidate
/// months.
class LunarYearData {
  const LunarYearData(this.year, this.jieQiJulianDays, this.months);

  final int year;

  /// Julian days of the terms named by [jieQiInUse], in that order.
  final List<double> jieQiJulianDays;

  final List<LunarMonthData> months;
}

final BoundedCache<int, LunarYearData> _yearCache =
    BoundedCache<int, LunarYearData>(64);

bool _inLeapList(List<int> list, int year) => list.contains(year);

/// `LunarYear.fromYear`.
LunarYearData lunarYear(int year) {
  final cached = _yearCache.get(year);
  if (cached != null) return cached;

  final jieQiJulianDays = <double>[];
  final months = <LunarMonthData>[];

  final jq = <double>[];
  final hs = <double>[];
  final dayCounts = <int>[];
  final monthNumbers = <int>[];

  var jd = ((year - 2000) * 365.2422 + 180).floorToDouble();
  // 355 is the 2000-12 winter solstice, giving a nearby estimate.
  var w = ((jd - 355 + 183) / 365.2422).floorToDouble() * 365.2422 + 355;
  if (calcQi(w) > jd) w -= 365.2422;

  // 26 term instants from one winter solstice past the next.
  for (var i = 0; i < 26; i++) {
    jq.add(calcQi(w + 15.2184 * i));
  }
  for (var i = 0; i < jieQiInUse.length; i++) {
    if (i == 0) {
      jd = qiAccurate2(jq[0] - 15.2184);
    } else if (i <= 26) {
      jd = qiAccurate2(jq[i - 1]);
    } else {
      jd = qiAccurate2(jq[25] + 15.2184 * (i - 26));
    }
    jieQiJulianDays.add(jd + solarJ2000);
  }

  // The new moon before the winter solstice starts the recursion.
  w = calcShuo(jq[0]);
  if (w > jq[0]) w -= 29.53;
  for (var i = 0; i < 16; i++) {
    hs.add(calcShuo(w + 29.5306 * i));
  }
  for (var i = 0; i < 15; i++) {
    dayCounts.add((hs[i + 1] - hs[i]).floor());
    monthNumbers.add(i);
  }

  final prevYear = year - 1;
  var leapIndex = 16;
  if (_inLeapList(leapEleven, year)) {
    leapIndex = 13;
  } else if (_inLeapList(leapTwelve, year)) {
    leapIndex = 14;
  } else if (hs[13] <= jq[24]) {
    var i = 1;
    while (hs[i + 1] > jq[2 * i] && i < 13) {
      i++;
    }
    leapIndex = i;
  }
  for (var j = leapIndex; j < 15; j++) {
    monthNumbers[j] -= 1;
  }

  // Upstream also tracks a within-year month index here; the engine never
  // reads it, so it is not carried.
  var fm = -1;
  var y = prevYear;
  for (var i = 0; i < 15; i++) {
    final dm = hs[i] + solarJ2000;
    final v2 = monthNumbers[i];
    var mc = lunarMonthCycle[v2 % 12];
    if (1724360 <= dm && dm < 1729794) {
      mc = lunarMonthCycle[(v2 + 1) % 12];
    } else if (1807724 <= dm && dm < 1808699) {
      mc = lunarMonthCycle[(v2 + 1) % 12];
    } else if (dm == 1729794 || dm == 1808699) {
      mc = 12;
    }
    if (fm == -1) fm = mc;
    if (mc < fm) y += 1;
    fm = mc;
    if (i == leapIndex) {
      mc = -mc;
    } else if (dm == 1729794 || dm == 1808699) {
      mc = -11;
    }
    months.add(LunarMonthData(y, mc, dayCounts[i], hs[i] + solarJ2000));
  }

  return _yearCache.set(year, LunarYearData(year, jieQiJulianDays, months));
}

/// The lunar date for a civil date: `Solar.fromYmd(y, m, d).getLunar()`.
class LunarDate {
  const LunarDate(this.year, this.month, this.day);

  final int year;

  /// Signed: negative when the month is the intercalary one.
  final int month;
  final int day;

  bool get isLeap => month < 0;
}

LunarDate lunarFromSolar(int year, int month, int day) {
  final ly = lunarYear(year);
  final target = _daysFromCivil(year, month, day);
  for (final m in ly.months) {
    final first = SolarDateTime.fromJulianDay(m.firstJulianDay);
    final days = target - _daysFromCivil(first.year, first.month, first.day);
    if (days < m.dayCount) {
      return LunarDate(m.year, m.month, days + 1);
    }
  }
  // Upstream leaves the fields at zero when nothing matches, which cannot
  // happen for the years this engine supports.
  return const LunarDate(0, 0, 0);
}

/// The solar-term table for a civil year, keyed exactly as
/// `Lunar.getJieQiTable()` keys it (resolved Chinese names, plus the
/// upstream's uppercase sentinels for terms that belong to a neighbouring
/// year).
Map<String, SolarDateTime> jieQiTable(int year) {
  final ly = lunarYear(year);
  final table = <String, SolarDateTime>{};
  for (var i = 0; i < jieQiInUse.length; i++) {
    table[jieQiInUse[i]] = SolarDateTime.fromJulianDay(ly.jieQiJulianDays[i]);
  }
  return table;
}

/// `getDayGanIndexExact2` / `getDayZhiIndexExact2`: the day pillar of a civil
/// date, taken at local noon and with no hour adjustment.
(int, int) dayGanZhi(int year, int month, int day) {
  final noon = SolarDateTime(year, month, day, 12, 0, 0);
  final offset = noon.julianDay.floor() - 11;
  return (offset % 10, offset % 12);
}
