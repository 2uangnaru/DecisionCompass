import '../app_locale.dart';
import '../local_engine/calendar/calendar.dart';
import '../local_engine/calendar/calendar_data.dart';
import '../local_engine/core/numbers.dart';

/// Today's most fitting two-hour Hoàng Đạo (黄道) window for one profile.
///
/// The almanac's own hour-god rule (`almanac` in `calendar.dart`) marks six of
/// a civil day's twelve double-hours as Hoàng Đạo. Of the waking ones
/// (05:00–21:00), an hour clashing (六冲) with the natal day branch is dropped;
/// a window still ahead today beats one already past, then 六合 beats 三合
/// beats neutral, then the earlier one. Never tomorrow's. A symbolic almanac
/// convention, not a prediction. Returns the hour's earthly branch (0 = 子).
int bestAuspiciousHourBranch({
  required DateTime nowLocal,
  required DateTime birthDate,
}) {
  final dayBranch = civilCalendar(_isoDate(nowLocal)).day.branch;
  final natal = civilCalendar(_isoDate(birthDate)).day.branch;
  final offset = zhiTianShenOffset[branches[dayBranch]]!;
  bool isHuangDao(int hour) =>
      tianShenType[tianShen[jsMod(hour + offset, 12) + 1]] == huangDao;
  int affinity(int hour) => (hour + natal) % 12 == 1
      ? 2 // 六合
      : hour % 4 == natal % 4
      ? 1 // 三合
      : 0;

  // 卯..戌: 05:00–21:00. Six of twelve are Hoàng Đạo, so at least two are
  // waking hours and at most one of those clashes: never empty.
  final candidates = [
    for (var hour = 3; hour <= 10; hour++)
      if (isHuangDao(hour) && hour != (natal + 6) % 12) hour,
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
