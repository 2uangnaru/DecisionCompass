// GENERATED FILE — DO NOT EDIT BY HAND.
//
// Produced by `calculation-engine/scripts/port/gen_ziwei.mjs` from the pinned
// upstream provider package. See `calculation-engine/THIRD_PARTY.md` and
// `mobile_app/lib/local_engine/LICENSES.md` for attribution and licensing.

/// Heavenly stems and earthly branches, in iztro's index order.
const List<String> ziweiStems = <String>[
  "甲",
  "乙",
  "丙",
  "丁",
  "戊",
  "己",
  "庚",
  "辛",
  "壬",
  "癸",
];
const List<String> ziweiBranches = <String>[
  "子",
  "丑",
  "寅",
  "卯",
  "辰",
  "巳",
  "午",
  "未",
  "申",
  "酉",
  "戌",
  "亥",
];

/// Palace names starting from 命宫, in iztro's own order.
const List<String> ziweiPalaceNames = <String>[
  "命宫",
  "父母",
  "福德",
  "田宅",
  "官禄",
  "仆役",
  "迁移",
  "疾厄",
  "财帛",
  "子女",
  "夫妻",
  "兄弟",
];

/// The fourteen major stars and the twelve auxiliary stars the engine scores.
const List<String> majorStarNames = <String>[
  "紫微",
  "天机",
  "太阳",
  "武曲",
  "天同",
  "廉贞",
  "天府",
  "太阴",
  "贪狼",
  "巨门",
  "天相",
  "天梁",
  "七杀",
  "破军",
];
const List<String> auxiliaryStarNames = <String>[
  "左辅",
  "右弼",
  "文昌",
  "文曲",
  "天魁",
  "天钺",
  "擎羊",
  "陀罗",
  "火星",
  "铃星",
  "地空",
  "地劫",
];

/// Star brightness by palace index. Stars with no brightness table are absent.
const Map<String, List<String>> starBrightness = <String, List<String>>{
  "紫微": <String>["旺", "旺", "得", "旺", "庙", "庙", "旺", "旺", "得", "旺", "平", "庙"],
  "天机": <String>["得", "旺", "利", "平", "庙", "陷", "得", "旺", "利", "平", "庙", "陷"],
  "太阳": <String>["旺", "庙", "旺", "旺", "旺", "得", "得", "平", "不", "陷", "陷", "不"],
  "武曲": <String>["得", "利", "庙", "平", "旺", "庙", "得", "利", "庙", "平", "旺", "庙"],
  "天同": <String>["利", "平", "平", "庙", "陷", "不", "旺", "平", "平", "庙", "旺", "不"],
  "廉贞": <String>["庙", "平", "利", "陷", "平", "利", "庙", "平", "利", "陷", "平", "利"],
  "天府": <String>["庙", "得", "庙", "得", "旺", "庙", "得", "旺", "庙", "得", "庙", "庙"],
  "太阴": <String>["旺", "陷", "陷", "陷", "不", "不", "利", "旺", "旺", "庙", "庙", "庙"],
  "贪狼": <String>["平", "利", "庙", "陷", "旺", "庙", "平", "利", "庙", "陷", "旺", "庙"],
  "巨门": <String>["庙", "庙", "陷", "旺", "旺", "不", "庙", "庙", "陷", "旺", "旺", "不"],
  "天相": <String>["庙", "陷", "得", "得", "庙", "得", "庙", "陷", "得", "得", "庙", "庙"],
  "天梁": <String>["庙", "庙", "庙", "陷", "庙", "旺", "陷", "得", "庙", "陷", "庙", "旺"],
  "七杀": <String>["庙", "旺", "庙", "平", "旺", "庙", "庙", "旺", "庙", "平", "旺", "庙"],
  "破军": <String>["得", "陷", "旺", "平", "庙", "旺", "得", "陷", "旺", "平", "庙", "旺"],
  "文昌": <String>["陷", "利", "得", "庙", "陷", "利", "得", "庙", "陷", "利", "得", "庙"],
  "文曲": <String>["平", "旺", "得", "庙", "陷", "旺", "得", "庙", "陷", "旺", "得", "庙"],
  "擎羊": <String>["", "陷", "庙", "", "陷", "庙", "", "陷", "庙", "", "陷", "庙"],
  "陀罗": <String>["陷", "", "庙", "陷", "", "庙", "陷", "", "庙", "陷", "", "庙"],
  "火星": <String>["庙", "利", "陷", "得", "庙", "利", "陷", "得", "庙", "利", "陷", "得"],
  "铃星": <String>["庙", "利", "陷", "得", "庙", "利", "陷", "得", "庙", "利", "陷", "得"],
};

/// The four transformed stars for each heavenly stem, in 禄权科忌 order.
const List<List<String>> stemMutagens = <List<String>>[
  <String>["廉贞", "破军", "武曲", "太阳"],
  <String>["天机", "天梁", "紫微", "太阴"],
  <String>["天同", "天机", "文昌", "廉贞"],
  <String>["太阴", "天同", "天机", "巨门"],
  <String>["贪狼", "太阴", "右弼", "天机"],
  <String>["武曲", "贪狼", "天梁", "文曲"],
  <String>["太阳", "武曲", "太阴", "天同"],
  <String>["巨门", "太阳", "文曲", "文昌"],
  <String>["天梁", "紫微", "左辅", "武曲"],
  <String>["破军", "巨门", "太阴", "贪狼"],
];

/// The four transformation kinds, aligned with [stemMutagens].
const List<String> mutagenKinds = <String>["禄", "权", "科", "忌"];

/// 五虎遁: the stem that opens the 寅 palace, per year stem.
const List<int> tigerRule = <int>[2, 4, 6, 8, 0, 2, 4, 6, 8, 0];

/// Whether each stem / branch is yang.
const List<bool> stemIsYang = <bool>[
  true,
  false,
  true,
  false,
  true,
  false,
  true,
  false,
  true,
  false,
];
const List<bool> branchIsYang = <bool>[
  true,
  false,
  true,
  false,
  true,
  false,
  true,
  false,
  true,
  false,
  true,
  false,
];

/// 五行局 values, indexed as `[wood, metal, water, fire, earth]`.
const List<int> fiveElementsValues = <int>[3, 4, 2, 6, 5];
