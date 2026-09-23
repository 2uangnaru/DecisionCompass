/// Port of the `lunar-lite` helpers iztro calls.
///
/// lunar-lite is MIT licensed, © SylarLong; it is a thin wrapper over
/// lunar-typescript, whose 寿星天文历 tables are byte-identical to the
/// lunar-javascript tables the calendar module already carries. The port
/// therefore reuses [chinese_calendar.dart] rather than embedding a second
/// copy of the same series.
library;

import '../calendar/chinese_calendar.dart';

/// Stems and branches as indices, in the canonical 甲..癸 / 子..亥 order.
class GanZhi {
  const GanZhi(this.stem, this.branch);

  final int stem;
  final int branch;
}

/// The four pillars iztro reads, as index pairs.
class GanZhiSet {
  const GanZhiSet({
    required this.yearly,
    required this.monthly,
    required this.daily,
    required this.hourly,
  });

  final GanZhi yearly;
  final GanZhi monthly;
  final GanZhi daily;
  final GanZhi hourly;
}

/// 五虎遁 lookup, indexed by year stem.
const List<int> _fiveTiger = <int>[2, 4, 6, 8, 0, 2, 4, 6, 8, 0];

/// The earthly branch that opens each lunar month, from 寅.
const List<int> _monthlyBranches = <int>[2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 1];

int _fixIndex(int index, [int max = 12]) {
  var value = index % max;
  if (value < 0) value += max;
  return value;
}

/// lunar-javascript's `LunarUtil.getTimeZhiIndex`, for a `HH:mm` string.
int _timeZhiIndex(int hour, int minute) {
  final hm =
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  var x = 1;
  for (var i = 1; i < 22; i += 2) {
    final lo = '${i.toString().padLeft(2, '0')}:00';
    final hi = '${(i + 1).toString().padLeft(2, '0')}:59';
    if (hm.compareTo(lo) >= 0 && hm.compareTo(hi) <= 0) return x;
    x++;
  }
  return 0;
}

/// `getHeavenlyStemAndEarthlyBranchBySolarDate` with iztro's configured
/// `normal` year and month division — i.e. the year turns at 正月初一 and the
/// month at 初一, not at a solar term.
GanZhiSet ganZhiBySolarDate(int year, int month, int day, int timeIndex) {
  final hour = timeIndex * 2 - 1 < 0 ? 0 : timeIndex * 2 - 1;
  const minute = 30;

  final lunar = lunarFromSolar(year, month, day);
  final lunarYear = lunar.year;

  // Year pillar, `normal`: straight from the lunar year.
  final yearly = GanZhi(
    _fixIndex(lunarYear - 4, 10),
    _fixIndex(lunarYear - 4, 12),
  );

  // Month pillar, `normal`: 五虎遁 from the year stem plus the lunar month, with
  // the second half of a leap month counted as the following month.
  final fixLeap = lunar.isLeap && lunar.day > 15 ? 1 : 0;
  final lunarMonth = lunar.month.abs();
  final monthly = GanZhi(
    _fixIndex(_fiveTiger[yearly.stem] + lunarMonth - 1 + fixLeap, 10),
    _monthlyBranches[lunarMonth - 1 + fixLeap],
  );

  // Day pillar, `exact`: the pillar rolls over at 23:00, not at midnight.
  final base = dayGanZhi(year, month, day);
  var dayStem = base.$1;
  var dayBranch = base.$2;
  if (hour == 23) {
    dayStem = (dayStem + 1) % 10;
    dayBranch = (dayBranch + 1) % 12;
  }
  final daily = GanZhi(dayStem, dayBranch);

  // Hour pillar, from the exact day stem.
  final timeBranch = _timeZhiIndex(hour, minute);
  final hourly = GanZhi((dayStem % 5 * 2 + timeBranch) % 10, timeBranch);

  return GanZhiSet(
    yearly: yearly,
    monthly: monthly,
    daily: daily,
    hourly: hourly,
  );
}

/// `getTotalDaysOfLunarMonth`: the length of the lunar month a civil date falls
/// in, honouring leap months.
int totalDaysOfLunarMonth(int year, int month, int day) {
  final lunar = lunarFromSolar(year, month, day);
  final signed = lunar.isLeap ? -lunar.month.abs() : lunar.month.abs();
  for (final m in lunarYear(lunar.year).months) {
    if (m.year == lunar.year && m.month == signed) return m.dayCount;
  }
  return 0;
}
