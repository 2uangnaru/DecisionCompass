/// Port of the iztro astrolabe the calculation engine reads.
///
/// iztro is MIT licensed, © SylarLong. Only the parts `src/ziwei.js` actually
/// scores are implemented: the twelve palaces, the fourteen major stars, the
/// twelve auxiliary stars, their brightness and transformations, and the five
/// horoscope layers. iztro's decorative, twelve-stage and yearly star systems
/// are deliberately absent — the engine never reads them.
///
/// The engine pins iztro's configuration to
/// `yearDivide: normal, horoscopeDivide: normal, ageDivide: normal,
/// dayDivide: current, algorithm: default`, and this port hard-codes the same
/// choices rather than re-exposing them.
library;

import '../calendar/chinese_calendar.dart';
import 'lunar_lite.dart';
import 'ziwei_data.dart';

int fixIndex(int index, [int max = 12]) {
  var value = index % max;
  if (value < 0) value += max;
  return value;
}

/// Palaces run from 寅, whose branch index is 2.
const int _yinBranchIndex = 2;

int fixEarthlyBranchIndex(int branchIndex) =>
    fixIndex(branchIndex - _yinBranchIndex);

/// One star on the chart.
class ZiweiStar {
  const ZiweiStar({
    required this.name,
    required this.brightness,
    required this.mutagen,
    required this.palace,
    required this.isMajor,
  });

  final String name;
  final String brightness;

  /// One of 禄/权/科/忌, or the empty string.
  final String mutagen;

  final int palace;
  final bool isMajor;
}

/// One palace on the chart.
class ZiweiPalace {
  ZiweiPalace({
    required this.index,
    required this.name,
    required this.isBodyPalace,
    required this.heavenlyStem,
    required this.earthlyBranch,
    required this.decadalRange,
    required this.ages,
  });

  final int index;
  final String name;
  final bool isBodyPalace;
  final int heavenlyStem;
  final int earthlyBranch;
  final List<int> decadalRange;
  final List<int> ages;
}

/// A built natal astrolabe.
class ZiweiAstrolabe {
  ZiweiAstrolabe({
    required this.palaces,
    required this.stars,
    required this.soulIndex,
    required this.bodyIndex,
    required this.birthLunar,
    required this.birthHourBranch,
    required this.gender,
  });

  final List<ZiweiPalace> palaces;

  /// Every scored star, in placement order.
  final List<ZiweiStar> stars;

  final int soulIndex;
  final int bodyIndex;
  final LunarDate birthLunar;

  /// The earthly-branch index of the birth hour pillar.
  final int birthHourBranch;

  /// `male` or `female`.
  final String gender;
}

String _brightnessOf(String star, int index) {
  final table = starBrightness[star];
  if (table == null) return '';
  return table[fixIndex(index)];
}

String _mutagenOf(String star, int yearStem) {
  final index = stemMutagens[yearStem].indexOf(star);
  return index < 0 ? '' : mutagenKinds[index];
}

/// `fixLunarMonthIndex`: the lunar month as a palace offset from 寅, with the
/// second half of a leap month counted as the next month.
int _fixLunarMonthIndex(LunarDate lunar, int timeIndex, bool fixLeap) {
  final needToAdd =
      lunar.isLeap && fixLeap && lunar.day > 15 && timeIndex != 12;
  return fixIndex(
    lunar.month.abs() + 1 - _yinBranchIndex + (needToAdd ? 1 : 0),
  );
}

class _SoulAndBody {
  const _SoulAndBody(
    this.soulIndex,
    this.bodyIndex,
    this.soulStem,
    this.soulBranch,
  );

  final int soulIndex;
  final int bodyIndex;
  final int soulStem;
  final int soulBranch;
}

_SoulAndBody _soulAndBody(
  int year,
  int month,
  int day,
  int timeIndex,
  bool fixLeap,
) {
  final ganZhi = ganZhiBySolarDate(year, month, day, timeIndex);
  final lunar = lunarFromSolar(year, month, day);
  final monthIndex = _fixLunarMonthIndex(lunar, timeIndex, fixLeap);
  final soulIndex = fixIndex(monthIndex - ganZhi.hourly.branch);
  final bodyIndex = fixIndex(monthIndex + ganZhi.hourly.branch);
  final soulStem = fixIndex(tigerRule[ganZhi.yearly.stem] + soulIndex, 10);
  final soulBranch = fixIndex(soulIndex + _yinBranchIndex);
  return _SoulAndBody(soulIndex, bodyIndex, soulStem, soulBranch);
}

/// 五行局 value (2–6) from the soul palace's stem and branch.
int _fiveElementsValue(int stem, int branch) {
  final stemNumber = (stem ~/ 2) + 1;
  final branchNumber = (fixIndex(branch, 6) ~/ 2) + 1;
  var index = stemNumber + branchNumber;
  while (index > 5) {
    index -= 5;
  }
  return fiveElementsValues[index - 1];
}

List<String> _palaceNames(int fromIndex) => <String>[
  for (var i = 0; i < 12; i++) ziweiPalaceNames[fixIndex(i - fromIndex)],
];

class _StartIndex {
  const _StartIndex(this.ziwei, this.tianfu);

  final int ziwei;
  final int tianfu;
}

_StartIndex _startIndex(
  int year,
  int month,
  int day,
  int timeIndex,
  bool fixLeap,
) {
  final soul = _soulAndBody(year, month, day, timeIndex, fixLeap);
  final lunarDay = lunarFromSolar(year, month, day).day;
  final value = _fiveElementsValue(soul.soulStem, soul.soulBranch);
  final maxDays = totalDaysOfLunarMonth(year, month, day);

  // `dayDivide: current` means a late 子 hour stays on the same day, so the
  // upstream's +1 branch is never taken here.
  var day0 = lunarDay;
  if (day0 > maxDays) day0 -= maxDays;

  var offset = -1;
  var quotient = 0;
  var remainder = -1;
  do {
    offset++;
    final divisor = day0 + offset;
    quotient = divisor ~/ value;
    remainder = divisor % value;
  } while (remainder != 0);

  quotient %= 12;
  var ziwei = quotient - 1;
  if (offset % 2 == 0) {
    ziwei += offset;
  } else {
    ziwei -= offset;
  }
  ziwei = fixIndex(ziwei);
  return _StartIndex(ziwei, fixIndex(12 - ziwei));
}

/// 紫微 series, counted anticlockwise; empty strings are gaps.
const List<String> _ziweiGroup = <String>[
  '紫微',
  '天机',
  '',
  '太阳',
  '武曲',
  '天同',
  '',
  '',
  '廉贞',
];

/// 天府 series, counted clockwise.
const List<String> _tianfuGroup = <String>[
  '天府',
  '太阴',
  '贪狼',
  '巨门',
  '天相',
  '天梁',
  '七杀',
  '',
  '',
  '',
  '破军',
];

/// 左辅/右弼, by lunar month.
(int, int) _zuoYouIndex(int lunarMonth) => (
  fixIndex(fixEarthlyBranchIndex(4) + (lunarMonth - 1)),
  fixIndex(fixEarthlyBranchIndex(10) - (lunarMonth - 1)),
);

/// 文昌/文曲, by hour branch.
(int, int) _changQuIndex(int timeIndex) => (
  fixIndex(fixEarthlyBranchIndex(10) - fixIndex(timeIndex)),
  fixIndex(fixEarthlyBranchIndex(4) + fixIndex(timeIndex)),
);

/// 天魁/天钺, by year stem.
(int, int) _kuiYueIndex(int yearStem) {
  switch (yearStem) {
    case 0: // 甲
    case 4: // 戊
    case 6: // 庚
      return (fixEarthlyBranchIndex(1), fixEarthlyBranchIndex(7));
    case 1: // 乙
    case 5: // 己
      return (fixEarthlyBranchIndex(0), fixEarthlyBranchIndex(8));
    case 7: // 辛
      return (fixEarthlyBranchIndex(6), fixEarthlyBranchIndex(2));
    case 2: // 丙
    case 3: // 丁
      return (fixEarthlyBranchIndex(11), fixEarthlyBranchIndex(9));
    default: // 壬 癸
      return (fixEarthlyBranchIndex(3), fixEarthlyBranchIndex(5));
  }
}

/// 禄存/擎羊/陀罗, by year stem.
(int, int, int) _luYangTuoIndex(int yearStem) {
  const luByStem = <int>[2, 3, 5, 6, 5, 6, 8, 9, 11, 0];
  final lu = fixEarthlyBranchIndex(luByStem[yearStem]);
  return (lu, fixIndex(lu + 1), fixIndex(lu - 1));
}

/// 火星/铃星, by year branch and hour branch.
(int, int) _huoLingIndex(int yearBranch, int timeIndex) {
  final fixed = fixIndex(timeIndex);
  int huo;
  int ling;
  switch (yearBranch) {
    case 2: // 寅
    case 6: // 午
    case 10: // 戌
      huo = fixEarthlyBranchIndex(1) + fixed;
      ling = fixEarthlyBranchIndex(3) + fixed;
    case 8: // 申
    case 0: // 子
    case 4: // 辰
      huo = fixEarthlyBranchIndex(2) + fixed;
      ling = fixEarthlyBranchIndex(10) + fixed;
    case 5: // 巳
    case 9: // 酉
    case 1: // 丑
      huo = fixEarthlyBranchIndex(3) + fixed;
      ling = fixEarthlyBranchIndex(10) + fixed;
    default: // 亥 卯 未
      huo = fixEarthlyBranchIndex(9) + fixed;
      ling = fixEarthlyBranchIndex(10) + fixed;
  }
  return (fixIndex(huo), fixIndex(ling));
}

/// 地空/地劫, by hour branch.
(int, int) _kongJieIndex(int timeIndex) {
  final fixed = fixIndex(timeIndex);
  final hai = fixEarthlyBranchIndex(11);
  return (fixIndex(hai - fixed), fixIndex(hai + fixed));
}

/// 小限 start palace, by year branch.
int _ageIndex(int yearBranch) {
  if (const <int>[2, 6, 10].contains(yearBranch))
    return fixEarthlyBranchIndex(4);
  if (const <int>[8, 0, 4].contains(yearBranch))
    return fixEarthlyBranchIndex(10);
  if (const <int>[5, 9, 1].contains(yearBranch))
    return fixEarthlyBranchIndex(7);
  return fixIndex(fixEarthlyBranchIndex(1));
}

/// Builds the natal astrolabe for a civil birth date, hour index and
/// traditional convention.
ZiweiAstrolabe buildAstrolabe({
  required String solarDate,
  required int timeIndex,
  required String gender,
  bool fixLeap = true,
}) {
  final parts = solarDate.split('-').map(int.parse).toList();
  final year = parts[0];
  final month = parts[1];
  final day = parts[2];

  // `dayDivide: current` folds a late 子 hour back onto the same day.
  final tIndex = timeIndex >= 12 ? 0 : timeIndex;

  final ganZhi = ganZhiBySolarDate(year, month, day, tIndex);
  final soul = _soulAndBody(year, month, day, tIndex, fixLeap);
  final names = _palaceNames(soul.soulIndex);
  final lunar = lunarFromSolar(year, month, day);
  final monthIndex = _fixLunarMonthIndex(lunar, tIndex, fixLeap);

  // iztro groups stars per palace, majors before minors, and the engine sums
  // them in that order — which is observable in the last bits of a score, so
  // the grouping is reproduced rather than flattened into placement order.
  final majorByPalace = List<List<ZiweiStar>>.generate(
    12,
    (_) => <ZiweiStar>[],
  );
  final minorByPalace = List<List<ZiweiStar>>.generate(
    12,
    (_) => <ZiweiStar>[],
  );

  void addStar(
    String name,
    int palace, {
    required bool isMajor,
    bool mutable = true,
  }) {
    final star = ZiweiStar(
      name: name,
      brightness: _brightnessOf(name, palace),
      mutagen: mutable ? _mutagenOf(name, ganZhi.yearly.stem) : '',
      palace: palace,
      isMajor: isMajor,
    );
    (isMajor ? majorByPalace : minorByPalace)[palace].add(star);
  }

  final start = _startIndex(year, month, day, tIndex, fixLeap);
  for (var i = 0; i < _ziweiGroup.length; i++) {
    if (_ziweiGroup[i].isEmpty) continue;
    addStar(_ziweiGroup[i], fixIndex(start.ziwei - i), isMajor: true);
  }
  for (var i = 0; i < _tianfuGroup.length; i++) {
    if (_tianfuGroup[i].isEmpty) continue;
    addStar(_tianfuGroup[i], fixIndex(start.tianfu + i), isMajor: true);
  }

  final zuoYou = _zuoYouIndex(monthIndex + 1);
  final changQu = _changQuIndex(tIndex);
  final kuiYue = _kuiYueIndex(ganZhi.yearly.stem);
  final huoLing = _huoLingIndex(ganZhi.yearly.branch, tIndex);
  final kongJie = _kongJieIndex(tIndex);
  final luYangTuo = _luYangTuoIndex(ganZhi.yearly.stem);

  // 左辅/右弼/文昌/文曲 can carry a transformation; the rest never do.
  addStar('左辅', zuoYou.$1, isMajor: false);
  addStar('右弼', zuoYou.$2, isMajor: false);
  addStar('文昌', changQu.$1, isMajor: false);
  addStar('文曲', changQu.$2, isMajor: false);
  addStar('天魁', kuiYue.$1, isMajor: false, mutable: false);
  addStar('天钺', kuiYue.$2, isMajor: false, mutable: false);
  addStar('地空', kongJie.$1, isMajor: false, mutable: false);
  addStar('地劫', kongJie.$2, isMajor: false, mutable: false);
  addStar('火星', huoLing.$1, isMajor: false, mutable: false);
  addStar('铃星', huoLing.$2, isMajor: false, mutable: false);
  addStar('擎羊', luYangTuo.$2, isMajor: false, mutable: false);
  addStar('陀罗', luYangTuo.$3, isMajor: false, mutable: false);

  // 大限 ranges and 小限 age lists.
  final decadalRanges = List<List<int>>.filled(12, const <int>[]);
  final fiveElements = _fiveElementsValue(soul.soulStem, soul.soulBranch);
  final forward = (gender == 'male') == branchIsYang[ganZhi.yearly.branch];
  for (var i = 0; i < 12; i++) {
    final idx = forward
        ? fixIndex(soul.soulIndex + i)
        : fixIndex(soul.soulIndex - i);
    final startAge = fiveElements + 10 * i;
    decadalRanges[idx] = <int>[startAge, startAge + 9];
  }

  final ageLists = List<List<int>>.filled(12, const <int>[]);
  final ageStart = _ageIndex(ganZhi.yearly.branch);
  for (var i = 0; i < 12; i++) {
    final idx = gender == 'male'
        ? fixIndex(ageStart + i)
        : fixIndex(ageStart - i);
    ageLists[idx] = <int>[for (var j = 0; j < 10; j++) 12 * j + i + 1];
  }

  final palaces = <ZiweiPalace>[
    for (var i = 0; i < 12; i++)
      ZiweiPalace(
        index: i,
        name: names[i],
        isBodyPalace: soul.bodyIndex == i,
        heavenlyStem: fixIndex(soul.soulStem - soul.soulIndex + i, 10),
        earthlyBranch: fixIndex(_yinBranchIndex + i),
        decadalRange: decadalRanges[i],
        ages: ageLists[i],
      ),
  ];

  final stars = <ZiweiStar>[
    for (var i = 0; i < 12; i++) ...<ZiweiStar>[
      ...majorByPalace[i],
      ...minorByPalace[i],
    ],
  ];

  return ZiweiAstrolabe(
    palaces: palaces,
    stars: stars,
    soulIndex: soul.soulIndex,
    bodyIndex: soul.bodyIndex,
    birthLunar: lunar,
    birthHourBranch: ganZhi.hourly.branch,
    gender: gender,
  );
}

/// One horoscope layer: which palace it lands on and which stars it transforms.
class HoroscopeLayer {
  const HoroscopeLayer(this.index, this.mutagen);

  final int index;
  final List<String> mutagen;
}

/// The five time layers the engine scores, for a target civil date and hour.
class Horoscope {
  const Horoscope({
    required this.decadal,
    required this.yearly,
    required this.monthly,
    required this.daily,
    required this.hourly,
  });

  final HoroscopeLayer decadal;
  final HoroscopeLayer yearly;
  final HoroscopeLayer monthly;
  final HoroscopeLayer daily;
  final HoroscopeLayer hourly;

  HoroscopeLayer? operator [](String name) => switch (name) {
    'decadal' => decadal,
    'yearly' => yearly,
    'monthly' => monthly,
    'daily' => daily,
    'hourly' => hourly,
    _ => null,
  };
}

/// Palaces consulted before the decade cycle starts (童限).
const List<String> _childhoodPalaces = <String>[
  '命宫',
  '财帛',
  '疾厄',
  '夫妻',
  '福德',
  '官禄',
];

Horoscope horoscopeFor(ZiweiAstrolabe chart, String targetDate, int timeIndex) {
  final parts = targetDate.split('-').map(int.parse).toList();
  final target = lunarFromSolar(parts[0], parts[1], parts[2]);
  final adjusted = timeIndex >= 12 ? 0 : timeIndex;
  final ganZhi = ganZhiBySolarDate(parts[0], parts[1], parts[2], adjusted);

  // `ageDivide: normal` counts a whole nominal year regardless of birthday.
  final nominalAge = target.year - chart.birthLunar.year + 1;

  var decadalIndex = -1;
  var decadalStem = 0;
  for (final palace in chart.palaces) {
    if (palace.decadalRange.length == 2 &&
        nominalAge >= palace.decadalRange[0] &&
        nominalAge <= palace.decadalRange[1]) {
      decadalIndex = palace.index;
      decadalStem = palace.heavenlyStem;
      break;
    }
  }
  if (decadalIndex < 0) {
    // Before the decade cycle opens, the reading falls back to 童限.
    final name = nominalAge >= 1 && nominalAge <= _childhoodPalaces.length
        ? _childhoodPalaces[nominalAge - 1]
        : null;
    if (name != null) {
      for (final palace in chart.palaces) {
        if (palace.name == name) {
          decadalIndex = palace.index;
          decadalStem = palace.heavenlyStem;
          break;
        }
      }
    }
  }

  final yearlyIndex = fixEarthlyBranchIndex(ganZhi.yearly.branch);

  final birthLeapAddition = chart.birthLunar.isLeap && chart.birthLunar.day > 15
      ? 1
      : 0;
  final targetLeapAddition = target.isLeap && target.day > 15 ? 1 : 0;
  final monthlyIndex = fixIndex(
    yearlyIndex -
        (chart.birthLunar.month.abs() + birthLeapAddition) +
        chart.birthHourBranch +
        (target.month.abs() + targetLeapAddition),
  );
  final dailyIndex = fixIndex(monthlyIndex + target.day - 1);
  final hourlyIndex = fixIndex(dailyIndex + ganZhi.hourly.branch);

  return Horoscope(
    decadal: HoroscopeLayer(
      decadalIndex,
      decadalIndex < 0 ? const <String>[] : stemMutagens[decadalStem],
    ),
    yearly: HoroscopeLayer(yearlyIndex, stemMutagens[ganZhi.yearly.stem]),
    monthly: HoroscopeLayer(monthlyIndex, stemMutagens[ganZhi.monthly.stem]),
    daily: HoroscopeLayer(dailyIndex, stemMutagens[ganZhi.daily.stem]),
    hourly: HoroscopeLayer(hourlyIndex, stemMutagens[ganZhi.hourly.stem]),
  );
}
