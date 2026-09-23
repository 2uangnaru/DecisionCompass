// Emits the lunar-javascript tables the calculation engine needs, as Dart.
//
// `ShouXingUtil` holds the 寿星天文历 series that produce solar-term and new-moon
// instants, plus the historical correction strings that keep the modern
// Chinese civil calendar aligned with the published almanacs. They are read
// straight off the pinned package (MIT, © 6tail) and re-emitted, so the Dart
// calendar and the Node calendar are computing from identical numbers.
//
// The `LunarYear` leap-month lists and the `LunarUtil` day-officer / 天神
// tables come along for the ride, because they are small and the engine's
// almanac module reads them.

import { createRequire } from 'node:module';
import { emit, header, dartDouble, dartString, wrapList, ENGINE_ROOT } from './lib.mjs';

const require = createRequire(`${ENGINE_ROOT}/`);
const lunar = require('lunar-javascript');
const { ShouXingUtil, LunarUtil, Solar } = lunar;

const readSource = () =>
  require('node:fs').readFileSync(
    require.resolve('lunar-javascript/lunar.js'),
    'utf8',
  );
const source = readSource();

/** Pulls a `_LEAP_11` / `_LEAP_12` literal out of the LunarYear closure. */
function leapList(name) {
  const marker = `var ${name} = [`;
  const start = source.indexOf(marker);
  if (start < 0) throw new Error(`LEAP_LIST_NOT_FOUND:${name}`);
  const end = source.indexOf('];', start);
  const literal = source.slice(start + marker.length - 1, end + 1);
  // eslint-disable-next-line no-eval
  const values = (0, eval)(literal);
  if (!Array.isArray(values) || values.some((v) => !Number.isSafeInteger(v))) {
    throw new Error(`LEAP_LIST_SHAPE:${name}`);
  }
  return values;
}

const leap11 = leapList('_LEAP_11');
const leap12 = leapList('_LEAP_12');

function doubleList(name, values) {
  return `const List<double> ${name} = <double>[\n${wrapList(values.map(dartDouble), 6)}\n];\n`;
}

function intList(name, values) {
  return `const List<int> ${name} = <int>[\n${wrapList(values.map(String), 12)}\n];\n`;
}

/** Splits a very long string constant so the analyzer stays responsive. */
function chunkedString(name, value, size = 900) {
  const parts = [];
  for (let i = 0; i < value.length; i += size) {
    parts.push(`    ${dartString(value.slice(i, i + size))}`);
  }
  // Adjacent Dart string literals concatenate at compile time.
  return `const String ${name} =\n${parts.join('\n')};\n`;
}

// `ZHI_TIAN_SHEN_OFFSET` and `TIAN_SHEN_TYPE` carry both i18n placeholder keys
// and resolved Chinese names. Only the resolved entries are emitted; the engine
// looks them up by the resolved name.
const isResolved = (key) => !key.startsWith('{');
const tianShenOffset = Object.fromEntries(
  Object.entries(LunarUtil.ZHI_TIAN_SHEN_OFFSET).filter(([key]) => isResolved(key)),
);
const tianShenType = Object.fromEntries(
  Object.entries(LunarUtil.TIAN_SHEN_TYPE).filter(([key]) => isResolved(key)),
);
if (Object.keys(tianShenOffset).length !== 12) throw new Error('TIAN_SHEN_OFFSET_SHAPE');
if (Object.keys(tianShenType).length !== 12) throw new Error('TIAN_SHEN_TYPE_SHAPE');
if (LunarUtil.TIAN_SHEN.some((name) => name.startsWith('{'))) throw new Error('TIAN_SHEN_UNRESOLVED');

const mapEntries = (map, indent = '  ') =>
  Object.entries(map)
    .map(([key, value]) =>
      `${indent}${dartString(key)}: ${typeof value === 'number' ? value : dartString(value)},`)
    .join('\n');

const body = `${header('gen_calendar.mjs')}
/// Julian day number of the J2000 epoch, as lunar-javascript defines it.
const int solarJ2000 = ${Solar.J2000};

/// Nutation-in-longitude series (寿星天文历).
${doubleList('nutB', ShouXingUtil.NUT_B)}
/// ΔT piecewise fit, five values per row.
${doubleList('dtAt', ShouXingUtil.DT_AT)}
/// Truncated solar longitude series, with its own index header.
${doubleList('xl0', ShouXingUtil.XL0)}
/// Truncated lunar longitude series, four blocks of six-element terms.
${ShouXingUtil.XL1.map((block, index) => doubleList(`xl1_$${''}${index}`.replace('$', ''), block)).join('\n')}
const List<List<double>> xl1 = <List<double>>[
${ShouXingUtil.XL1.map((_, index) => `  xl1_${index},`).join('\n')}
];

/// Solar-term keyframe table: pairs of (Julian day, mean term length).
${doubleList('qiKb', ShouXingUtil.QI_KB)}
/// New-moon keyframe table: pairs of (Julian day, mean synodic month).
${doubleList('shuoKb', ShouXingUtil.SHUO_KB)}
/// Decoded historical corrections for solar terms and new moons: one character
/// per event, \`1\` adds a day and \`2\` subtracts one.
${chunkedString('qiCorrections', ShouXingUtil.QB)}
${chunkedString('shuoCorrections', ShouXingUtil.SB)}
/// Years whose leap month falls on the eleventh / twelfth month.
${intList('leapEleven', leap11)}
${intList('leapTwelve', leap12)}
/// Month numbering cycle used when naming lunar months.
const List<int> lunarMonthCycle = <int>[11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

/// The twelve day gods, indexed from 1 (index 0 is a spacer upstream).
const List<String> tianShen = <String>[
${LunarUtil.TIAN_SHEN.map((name) => `  ${dartString(name)},`).join('\n')}
];

/// Offset from a base earthly branch to the first day god.
const Map<String, int> zhiTianShenOffset = <String, int>{
${mapEntries(tianShenOffset)}
};

/// Whether each day god belongs to the yellow (auspicious) or black path.
const Map<String, String> tianShenType = <String, String>{
${mapEntries(tianShenType)}
};

/// The auspicious classification the almanac module tests for.
const String huangDao = ${dartString(LunarUtil.TIAN_SHEN_TYPE['青龙'])};

/// Solar-term keys in the order lunar-javascript computes them.
const List<String> jieQiInUse = <String>[
${LunarUtil.JIE_QI_IN_USE.map((key) => `  ${dartString(key)},`).join('\n')}
];
`;

const target = emit('calendar/calendar_data.dart', body);
process.stdout.write(
  `calendar: XL0 ${ShouXingUtil.XL0.length}, XL1 ${ShouXingUtil.XL1.map((b) => b.length).join('/')}, ` +
    `QB ${ShouXingUtil.QB.length}, SB ${ShouXingUtil.SB.length} -> ${target}\n`,
);
