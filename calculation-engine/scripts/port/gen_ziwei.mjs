// Emits the iztro tables the calculation engine needs, as Dart.
//
// iztro is MIT licensed, © SylarLong. Its own tables are keyed by i18n
// identifiers; this generator resolves them through iztro's `zh-CN` locale so
// the Dart port can work directly with the Chinese star and palace names the
// engine's own catalogs use.
//
// Only the 14 major stars and the 12 auxiliary stars `src/ziwei.js` scores are
// exported. iztro's decorative, 12-stage and yearly star systems are left out:
// the engine never reads them, and an APK should not carry tables it cannot
// use.

import { createRequire } from 'node:module';
import { emit, header, dartString, ENGINE_ROOT } from './lib.mjs';

const require = createRequire(`${ENGINE_ROOT}/`);
const data = require('iztro/lib/data');
const i18n = require('iztro/lib/i18n');
const iztro = require('iztro');

iztro.astro.config({
  yearDivide: 'normal',
  horoscopeDivide: 'normal',
  ageDivide: 'normal',
  dayDivide: 'current',
  algorithm: 'default',
});
i18n.setLanguage('zh-CN');

const t = (key) => i18n.t(key);

const MAJOR = ['ziweiMaj', 'tianjiMaj', 'taiyangMaj', 'wuquMaj', 'tiantongMaj', 'lianzhenMaj',
  'tianfuMaj', 'taiyinMaj', 'tanlangMaj', 'jumenMaj', 'tianxiangMaj', 'tianliangMaj',
  'qishaMaj', 'pojunMaj'];
const AUX = ['zuofuMin', 'youbiMin', 'wenchangMin', 'wenquMin', 'tiankuiMin', 'tianyueMin',
  'qingyangMin', 'tuoluoMin', 'huoxingMin', 'lingxingMin', 'dikongMin', 'dijieMin'];

const stems = data.HEAVENLY_STEMS.map(t);
const branches = data.EARTHLY_BRANCHES.map(t);
const palaces = data.PALACES.map(t);

// Brightness arrays are twelve entries long, indexed by palace.
const brightness = {};
for (const key of [...MAJOR, ...AUX]) {
  const info = data.STARS_INFO[key];
  const table = info?.brightness;
  if (!table) continue; // several auxiliary stars carry no brightness at all
  if (table.length !== 12) throw new Error(`BRIGHTNESS_SHAPE:${key}`);
  brightness[t(key)] = table.map(t);
}

// Every major star must have a brightness table, because `src/ziwei.js`
// refuses to score a chart where one is missing.
for (const key of MAJOR) {
  if (!brightness[t(key)]) throw new Error(`MAJOR_BRIGHTNESS_MISSING:${key}`);
}

const mutagens = data.HEAVENLY_STEMS.map((stem) => {
  const list = data.heavenlyStems[stem].mutagen ?? [];
  if (list.length !== 4) throw new Error(`MUTAGEN_SHAPE:${stem}`);
  return list.map(t);
});

const stemYang = data.HEAVENLY_STEMS.map((stem) => data.heavenlyStems[stem].yinYang === '阳');
const branchYang = data.EARTHLY_BRANCHES.map(
  (branch) => data.earthlyBranches[branch].yinYang === '阳',
);

const tigerRule = data.HEAVENLY_STEMS.map(
  (stem) => data.HEAVENLY_STEMS.indexOf(data.TIGER_RULE[stem]),
);

const fiveElements = ['wood3rd', 'metal4th', 'water2nd', 'fire6th', 'earth5th']
  .map((name) => data.FiveElementsClass[name]);

const stringList = (name, values) =>
  `const List<String> ${name} = <String>[\n${values.map((v) => `  ${dartString(v)},`).join('\n')}\n];\n`;

const intList = (name, values) =>
  `const List<int> ${name} = <int>[${values.join(', ')}];\n`;

const boolList = (name, values) =>
  `const List<bool> ${name} = <bool>[${values.join(', ')}];\n`;

const brightnessEntries = Object.entries(brightness)
  .map(([star, table]) =>
    `  ${dartString(star)}: <String>[${table.map(dartString).join(', ')}],`)
  .join('\n');

const mutagenEntries = mutagens
  .map((list) => `  <String>[${list.map(dartString).join(', ')}],`)
  .join('\n');

const body = `${header('gen_ziwei.mjs')}
/// Heavenly stems and earthly branches, in iztro's index order.
${stringList('ziweiStems', stems)}${stringList('ziweiBranches', branches)}
/// Palace names starting from 命宫, in iztro's own order.
${stringList('ziweiPalaceNames', palaces)}
/// The fourteen major stars and the twelve auxiliary stars the engine scores.
${stringList('majorStarNames', MAJOR.map(t))}${stringList('auxiliaryStarNames', AUX.map(t))}
/// Star brightness by palace index. Stars with no brightness table are absent.
const Map<String, List<String>> starBrightness = <String, List<String>>{
${brightnessEntries}
};

/// The four transformed stars for each heavenly stem, in 禄权科忌 order.
const List<List<String>> stemMutagens = <List<String>>[
${mutagenEntries}
];

/// The four transformation kinds, aligned with [stemMutagens].
${stringList('mutagenKinds', data.MUTAGEN.map(t))}
/// 五虎遁: the stem that opens the 寅 palace, per year stem.
${intList('tigerRule', tigerRule)}
/// Whether each stem / branch is yang.
${boolList('stemIsYang', stemYang)}${boolList('branchIsYang', branchYang)}
/// 五行局 values, indexed as \`[wood, metal, water, fire, earth]\`.
${intList('fiveElementsValues', fiveElements)}`;

const target = emit('ziwei/ziwei_data.dart', body);
process.stdout.write(
  `ziwei: ${MAJOR.length} major, ${AUX.length} auxiliary, ` +
    `${Object.keys(brightness).length} brightness tables -> ${target}\n`,
);
