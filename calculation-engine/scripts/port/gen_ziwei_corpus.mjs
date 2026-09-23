// Dumps a Zi Wei parity corpus straight out of the Node engine.
//
// Two levels are captured: the raw iztro chart (palace names, star placement,
// brightness and transformations, plus the five horoscope layers) and the
// engine's scored module. The raw level makes a placement bug obvious instead
// of leaving it hidden inside a fused score.

import { emitFixture } from './lib.mjs';
import iztro from 'iztro';
import { buildZiWei, scoreZiWei, ZIWEI_CATEGORY_TARGETS } from '../../src/ziwei.js';
import { birthContext, parseInstant } from '../../src/time.js';
import { calendarAt } from '../../src/calendar.js';
import { CATEGORIES } from '../../src/core.js';

const CONFIG = { yearDivide: 'normal', horoscopeDivide: 'normal', ageDivide: 'normal',
  dayDivide: 'current', algorithm: 'default' };
iztro.astro.config(CONFIG);
iztro.i18n?.setLanguage?.('zh-CN');

const CATALOG = new Set([
  '紫微', '天机', '太阳', '武曲', '天同', '廉贞', '天府', '太阴', '贪狼', '巨门',
  '天相', '天梁', '七杀', '破军',
  '左辅', '右弼', '文昌', '文曲', '天魁', '天钺', '擎羊', '陀罗', '火星', '铃星',
  '地空', '地劫',
]);

// Birth dates chosen to exercise leap months, both conventions, every hour
// index and the very edges of the supported range.
const BIRTH_DATES = ['1900-01-01', '1923-07-04', '1950-12-25', '1969-07-20',
  '1984-02-04', '1998-06-21', '2001-05-15', '2004-03-07', '2020-05-10', '2023-03-22',
  '2026-02-17', '2033-12-22', '2050-06-15', '2099-12-31'];

const TARGET_DATES = ['1998-06-21', '2026-09-18', '2026-02-03', '2050-06-15', '2099-12-31'];

const corpus = { charts: [], horoscopes: [], modules: [], targets: {} };

for (const [category, spec] of Object.entries(ZIWEI_CATEGORY_TARGETS)) {
  corpus.targets[category] = spec.map((t) => ({ palaces: [...t.palaces], weight: t.weight }));
}

for (const date of BIRTH_DATES) {
  for (const timeIndex of [0, 3, 7, 11]) {
    for (const gender of ['男', '女']) {
      const chart = iztro.astro.bySolar(date, timeIndex, gender, true, 'zh-CN');
      const stars = chart.palaces.flatMap((p, index) =>
        [...p.majorStars, ...p.minorStars, ...p.adjectiveStars]
          .filter((s) => CATALOG.has(s.name))
          // Stars iztro builds without a transformation carry `undefined`,
          // which JSON drops; the engine treats that exactly like "no
          // transformation", so it is normalized here.
          .map((s) => ({ name: s.name, brightness: s.brightness ?? '',
            mutagen: s.mutagen ?? '', palace: index })));
      corpus.charts.push({
        date, timeIndex, gender: gender === '男' ? 'male' : 'female',
        palaceNames: chart.palaces.map((p) => p.name),
        bodyPalace: chart.palaces.findIndex((p) => p.isBodyPalace),
        stars,
      });

      for (const targetDate of TARGET_DATES) {
        for (const targetTimeIndex of [0, 5, 9]) {
          const h = chart.horoscope(targetDate, targetTimeIndex);
          corpus.horoscopes.push({
            date, timeIndex, gender: gender === '男' ? 'male' : 'female',
            targetDate, targetTimeIndex,
            layers: Object.fromEntries(['decadal', 'yearly', 'monthly', 'daily', 'hourly']
              .map((k) => [k, { index: h[k].index, mutagen: h[k].mutagen }])),
          });
        }
      }
    }
  }
}

const PROFILES = [
  { profile: { birthDate: '1998-06-21', birthTime: '14:30', birthTimezone: 'Asia/Ho_Chi_Minh' }, convention: 'male' },
  { profile: { birthDate: '1998-06-21', birthTime: '14:30', birthTimezone: 'Asia/Ho_Chi_Minh' }, convention: 'female' },
  { profile: { birthDate: '1998-06-21', birthTime: '14:30', birthTimezone: 'Asia/Ho_Chi_Minh' }, convention: null },
  { profile: { birthDate: '1998-06-21', birthTime: null, birthCountry: 'VN' }, convention: 'male' },
  { profile: { birthDate: '1998-06-21', birthTime: null, birthCountry: 'VN' }, convention: null },
  { profile: { birthDate: '1984-02-04', birthTime: '04:00', birthTimezone: 'Asia/Shanghai' }, convention: 'female' },
  { profile: { birthDate: '2023-03-22', birthTime: '23:30', birthTimezone: 'Asia/Ho_Chi_Minh' }, convention: 'male' },
  { profile: { birthDate: '1900-01-01', birthTime: null, birthCountry: 'VN' }, convention: null },
];

const INSTANTS = ['1998-06-21T07:30:00.000Z', '2026-09-18T08:00:00.000Z',
  '2026-02-03T21:00:00.000Z', '2099-12-31T12:00:00.000Z'];

for (const { profile, convention } of PROFILES) {
  const built = buildZiWei(birthContext(profile), convention);
  for (const iso of INSTANTS) {
    const cal = calendarAt(parseInstant(iso), 'Asia/Ho_Chi_Minh');
    for (const category of CATEGORIES) {
      const module = scoreZiWei(built, cal, category);
      corpus.modules.push({
        profile, convention, iso, category,
        status: module.status, a: module.evidence.a, c: module.evidence.c,
        coverage: module.evidence.coverage,
        scenarioCount: module.diagnostics.scenarioCount ?? null,
        unknownBirthHour: module.diagnostics.unknownBirthHour ?? null,
        unknownConvention: module.diagnostics.unknownConvention ?? null,
        reason: module.diagnostics.reason ?? null,
      });
    }
  }
}

const target = emitFixture('ziwei_corpus.json', JSON.stringify(corpus));
process.stdout.write(
  `ziwei corpus: ${corpus.charts.length} charts, ${corpus.horoscopes.length} horoscopes, ` +
    `${corpus.modules.length} module scores -> ${target}\n`,
);
