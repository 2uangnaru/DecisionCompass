/// Port of `calculation-engine/src/calendar.js`.
///
/// Solar terms, sexagenary pillars, the almanac (`T`) module and the natal
/// pillars the BaZi and Zi Wei modules build on.
///
/// The convention is the documented Chinese civil-date ruleset: solar month
/// boundaries at the exact 节 instant, day boundaries at civil midnight in the
/// reading's own timezone. It is not a fully localized Vietnamese or Japanese
/// calendar school.
library;

import '../core/bounded_cache.dart';
import '../core/core.dart';
import '../core/numbers.dart';
import '../time/local_time.dart';
import '../time/moment_shim.dart'
    show civilFromUtcMs, msPerDay, msPerHour, utcMsFromCivil;
import 'calendar_data.dart';
import 'chinese_calendar.dart';

const List<String> stems = <String>[
  '甲',
  '乙',
  '丙',
  '丁',
  '戊',
  '己',
  '庚',
  '辛',
  '壬',
  '癸',
];
const List<String> branches = <String>[
  '子',
  '丑',
  '寅',
  '卯',
  '辰',
  '巳',
  '午',
  '未',
  '申',
  '酉',
  '戌',
  '亥',
];

/// The twelve 节 that open a solar month, in month order from 立春.
const List<String> _jie = <String>[
  '立春',
  '惊蛰',
  '清明',
  '立夏',
  '芒种',
  '小暑',
  '立秋',
  '白露',
  '寒露',
  '立冬',
  '大雪',
  '小寒',
];

final BoundedCache<int, List<SolarTerm>> _termCache =
    BoundedCache<int, List<SolarTerm>>(210);
final BoundedCache<String, CivilCalendar> _civilCache =
    BoundedCache<String, CivilCalendar>(512);

/// One solar term: its name, its exact UTC instant, and its solar-month index
/// when it is a 节 that opens a month (-1 otherwise).
class SolarTerm {
  const SolarTerm(this.name, this.instant, this.monthIndex);

  final String name;
  final double instant;
  final int monthIndex;
}

final RegExp _sentinelKey = RegExp(r'[A-Z_]');

/// Solar terms falling inside a civil year, as exact UTC instants.
List<SolarTerm> solarTerms(int year) {
  final cached = _termCache.get(year);
  if (cached != null) return cached;

  final table = jieQiTable(year);
  // Provider tables use the fixed UTC+08 Chinese calendar reference meridian.
  // They must not be read in the device timezone or in historical Shanghai DST.
  double instantOf(SolarDateTime s) =>
      utcMsFromCivil(s.year, s.month, s.day, s.hour, s.minute, s.second) -
      8 * msPerHour;

  final result = <SolarTerm>[];
  for (final entry in table.entries) {
    if (_sentinelKey.hasMatch(entry.key)) continue;
    if (entry.value.year != year) continue;
    result.add(
      SolarTerm(entry.key, instantOf(entry.value), _jie.indexOf(entry.key)),
    );
  }
  result.sort((a, b) => a.instant.compareTo(b.instant));

  // 冬至 is exported as DONG_ZHI for the current calendar year in this provider.
  final hasSolstice = result.any(
    (t) => t.name == '冬至' && civilFromUtcMs(t.instant).year == year,
  );
  if (!hasSolstice) {
    final s = table['DONG_ZHI'];
    if (s != null && s.year == year) {
      result.add(SolarTerm('冬至', instantOf(s), -1));
    }
  }
  result.sort((a, b) => a.instant.compareTo(b.instant));
  return _termCache.set(year, result);
}

/// Solar terms of the surrounding three civil years, in instant order.
List<SolarTerm> termsAround(double ms) {
  final year = civilFromUtcMs(ms).year;
  final result = <SolarTerm>[
    ...solarTerms(year - 1),
    ...solarTerms(year),
    ...solarTerms(year + 1),
  ];
  result.sort((a, b) => a.instant.compareTo(b.instant));
  return result;
}

/// One sexagenary pillar.
class Pillar {
  const Pillar(this.stem, this.branch, this.text);

  final int stem;
  final int branch;
  final String text;
}

Pillar pillar(int stem, int branch) {
  if (stem < 0 ||
      stem > 9 ||
      branch < 0 ||
      branch > 11 ||
      stem % 2 != branch % 2) {
    throw const EngineFailure('INVALID_PILLAR');
  }
  return Pillar(stem, branch, stems[stem] + branches[branch]);
}

/// The lunar date and day pillar of a civil date.
class CivilCalendar {
  const CivilCalendar(this.lunar, this.day);

  final LunarDate lunar;
  final Pillar day;
}

CivilCalendar civilCalendar(String date) {
  final cached = _civilCache.get(date);
  if (cached != null) return cached;
  final parts = date.split('-').map(int.parse).toList();
  final lunar = lunarFromSolar(parts[0], parts[1], parts[2]);
  final ganZhi = dayGanZhi(parts[0], parts[1], parts[2]);
  return _civilCache.set(
    date,
    CivilCalendar(lunar, pillar(ganZhi.$1, ganZhi.$2)),
  );
}

/// The year and month pillars in force at an instant, from the solar terms.
class SolarPillars {
  const SolarPillars(this.year, this.month, this.latestJie, this.solarYear);

  final Pillar year;
  final Pillar month;
  final SolarTerm latestJie;
  final int solarYear;
}

SolarPillars solarPillars(double ms) {
  final terms = termsAround(ms);
  SolarTerm? spring;
  SolarTerm? jie;
  for (final term in terms) {
    if (term.name == '立春' && term.instant <= ms) spring = term;
    if (term.monthIndex >= 0 && term.instant <= ms) jie = term;
  }
  if (spring == null || jie == null)
    throw const EngineFailure('SOLAR_TERM_RANGE');

  final year = civilFromUtcMs(spring.instant).year;
  final stem = jsMod(year - 4, 10);
  final branch = jsMod(year - 4, 12);
  final n = jie.monthIndex;
  return SolarPillars(
    pillar(stem, branch),
    pillar(jsMod((stem % 5) * 2 + 2 + n, 10), jsMod(2 + n, 12)),
    jie,
    year,
  );
}

/// The full calendar view of one instant in one timezone.
class CalendarAt {
  const CalendarAt({
    required this.local,
    required this.lunar,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.solarYear,
    required this.latestJie,
  });

  final LocalTime local;
  final LunarDate lunar;
  final Pillar year;
  final Pillar month;
  final Pillar day;
  final Pillar hour;
  final int solarYear;
  final SolarTerm latestJie;
}

CalendarAt calendarAt(double ms, String zone) {
  final local = localAt(ms, zone);
  final civil = civilCalendar(local.date);
  final solar = solarPillars(ms);
  final branch = hourBranch(local.hour);
  final hour = pillar(jsMod(2 * (civil.day.stem % 5) + branch, 10), branch);
  return CalendarAt(
    local: local,
    lunar: civil.lunar,
    year: solar.year,
    month: solar.month,
    day: civil.day,
    hour: hour,
    solarYear: solar.solarYear,
    latestJie: solar.latestJie,
  );
}

/// The four natal pillars, with any pillar the birth data cannot pin down left
/// null rather than guessed.
List<Pillar?> natalPillars(BirthContext birth) {
  final day = civilCalendar(birth.date).day;
  Pillar? year;
  Pillar? month;

  if (birth.intervals.isNotEmpty) {
    final candidates = <SolarPillars>[];
    for (final interval in birth.intervals) {
      final breaks = termsAround(interval.start)
          .where(
            (t) =>
                t.monthIndex >= 0 &&
                t.instant > interval.start &&
                t.instant <= interval.end,
          )
          .map((t) => t.instant);
      for (final instant in <double>[interval.start, interval.end, ...breaks]) {
        candidates.add(solarPillars(instant));
      }
    }
    if (candidates.every((c) => c.year.text == candidates[0].year.text)) {
      year = candidates[0].year;
    }
    if (candidates.every((c) => c.month.text == candidates[0].month.text)) {
      month = candidates[0].month;
    }
  }

  Pillar? hour;
  final clock = birth.clock;
  if (clock != null && birth.status != 'birth_time_nonexistent') {
    final branch = hourBranch(int.parse(clock.substring(0, 2)));
    hour = pillar(jsMod(2 * (day.stem % 5) + branch, 10), branch);
  }
  return <Pillar?>[year, month, day, hour];
}

const List<List<double>> _officerVectors = <List<double>>[
  <double>[.3, .3],
  <double>[.1, .7],
  <double>[.1, -.3],
  <double>[0, 0],
  <double>[.2, -.7],
  <double>[.1, -.6],
  <double>[-.5, .7],
  <double>[-.5, 0],
  <double>[.5, .2],
  <double>[.3, -.3],
  <double>[.4, .6],
  <double>[-.3, -.5],
];

const List<String> _officerIds = <String>[
  'establish',
  'remove',
  'full',
  'balance',
  'stable',
  'hold',
  'break',
  'danger',
  'success',
  'receive',
  'open',
  'close',
];

/// The almanac module: day and hour gods plus the twelve day officers.
ModuleResult almanac(CalendarAt cal) {
  ({String name, bool auspicious}) god(int baseBranch, int selectedBranch) {
    final offset = zhiTianShenOffset[branches[baseBranch]]!;
    final name = tianShen[jsMod(selectedBranch + offset, 12) + 1];
    return (name: name, auspicious: tianShenType[name] == huangDao);
  }

  final dayGod = god(cal.month.branch, cal.day.branch);
  final hourGod = god(cal.day.branch, cal.hour.branch);
  final officer = jsMod(cal.day.branch - cal.month.branch, 12);
  final v = _officerVectors[officer];

  return ModuleResult(
    Evidence(
      .25 * (dayGod.auspicious ? .5 : -.5) +
          .40 * (hourGod.auspicious ? .5 : -.5) +
          .35 * v[0],
      v[1],
      1,
    ),
    <String, Object?>{
      'dayGod': <String, Object?>{
        'name': dayGod.name,
        'auspicious': dayGod.auspicious,
      },
      'hourGod': <String, Object?>{
        'name': hourGod.name,
        'auspicious': hourGod.auspicious,
      },
      'officer': _officerIds[officer],
      'rules': 'solar-month-exact/civil-day-midnight',
    },
  );
}

/// Solar-term instants within three days of [ms], used as extra segment
/// boundaries so a month change never lands inside a scored segment.
List<double> nearbyBoundaries(double ms) =>
    termsAround(ms)
        .where((t) => (t.instant - ms).abs() < 3 * msPerDay)
        .map((t) => t.instant)
        .toList();
