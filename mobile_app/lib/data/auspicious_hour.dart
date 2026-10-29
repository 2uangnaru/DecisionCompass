import '../app_locale.dart';
import '../local_engine/calendar/calendar.dart';
import '../local_engine/calendar/calendar_data.dart';
import '../local_engine/core/numbers.dart';

/// Today's most fitting two-hour Hoàng Đạo (黄道) window for one profile.
///
/// The almanac's own hour-god rule (`almanac` in `calendar.dart`) marks six of
/// a civil day's twelve double-hours as Hoàng Đạo. Of the waking ones
/// (05:00–21:00), an hour clashing (六冲) with the natal day branch is dropped;
/// a window still ahead today beats one already past. The rest rank by the
/// sum of two affinities with the natal day pillar, then the earlier hour:
/// - branch: 六合 2, 三合 1, otherwise 0;
/// - the hour stem's element against the day master (natal day stem):
///   generating it (印) 2, the same element (比) 1, controlling it (官杀) -1,
///   otherwise 0. The hour stem follows the day stem, so a reader's window
///   repeats on a 30-day cycle rather than every 6 days.
///
/// Never tomorrow's. A symbolic almanac convention, not a prediction.
/// Returns the hour's earthly branch (0 = 子).
int bestAuspiciousHourBranch({
  required DateTime nowLocal,
  required DateTime birthDate,
}) {
  final day = civilCalendar(_isoDate(nowLocal)).day;
  final natal = civilCalendar(_isoDate(birthDate)).day;
  final offset = zhiTianShenOffset[branches[day.branch]]!;
  bool isHuangDao(int hour) =>
      tianShenType[tianShen[jsMod(hour + offset, 12) + 1]] == huangDao;
  // Elements 0..4: wood, fire, earth, metal, water (generating order).
  final dayMaster = natal.stem ~/ 2;
  int affinity(int hour) {
    final branch = (hour + natal.branch) % 12 == 1
        ? 2 // 六合
        : hour % 4 == natal.branch % 4
        ? 1 // 三合
        : 0;
    // The same hour-stem rule as `calendarAt`.
    final element = (2 * (day.stem % 5) + hour) % 10 ~/ 2;
    final stem = (element + 1) % 5 == dayMaster
        ? 2 // 印: generates the day master
        : element == dayMaster
        ? 1 // 比: same element
        : (element + 2) % 5 == dayMaster
        ? -1 // 官杀: controls the day master
        : 0;
    return branch + stem;
  }

  // 卯..戌: 05:00–21:00. Six of twelve are Hoàng Đạo, so at least two are
  // waking hours and at most one of those clashes: never empty.
  final candidates = [
    for (var hour = 3; hour <= 10; hour++)
      if (isHuangDao(hour) && hour != (natal.branch + 6) % 12) hour,
  ];
  bool ahead(int hour) => nowLocal.hour < 2 * hour + 1;
  candidates.sort((a, b) {
    if (ahead(a) != ahead(b)) return ahead(a) ? -1 : 1;
    final byAffinity = affinity(b).compareTo(affinity(a));
    return byAffinity != 0 ? byAffinity : a.compareTo(b);
  });
  return candidates.first;
}

/// `13:00 — 15:00`, with the hour's traditional name where the locale has
/// one: `(Mùi)`, `(未时)`, `(未の刻)`, `(미시)`.
String formatAuspiciousHour(int branch, AppLocale locale) {
  String two(int h) => '${h.toString().padLeft(2, '0')}:00';
  final window = '${two(2 * branch - 1)} — ${two(2 * branch + 1)}';
  final name = switch (locale) {
    AppLocale.vietnamese => _vietnameseBranches[branch],
    AppLocale.simplifiedChinese => '${branches[branch]}时',
    AppLocale.japanese => '${branches[branch]}の刻',
    AppLocale.korean => '${_koreanBranches[branch]}시',
    _ => null,
  };
  return name == null ? window : '$window ($name)';
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

const _vietnameseBranches = [
  'Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', //
  'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi',
];
const _koreanBranches = [
  '자', '축', '인', '묘', '진', '사', //
  '오', '미', '신', '유', '술', '해',
];
