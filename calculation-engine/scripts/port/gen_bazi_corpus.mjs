// Dumps a BaZi parity corpus straight out of the Node engine.
//
// Covers the cases where the chart is deliberately incomplete: an unknown birth
// hour drops the hour pillar and lowers coverage, and an unspecified
// traditional convention suppresses the decade cycle entirely rather than
// picking a direction.

import { emitFixture } from './lib.mjs';
import { buildBaZi, scoreBaZi, decadeAt, tenGod, relations, HIDDEN } from '../../src/bazi.js';
import { birthContext, parseInstant } from '../../src/time.js';
import { calendarAt } from '../../src/calendar.js';

const BIRTHS = [
  { profile: { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN' }, convention: 'male' },
  { profile: { birthDate: '1998-06-21', birthTime: '14:30', birthTimezone: 'Asia/Ho_Chi_Minh' }, convention: 'male' },
  { profile: { birthDate: '1998-06-21', birthTime: '14:30', birthTimezone: 'Asia/Ho_Chi_Minh' }, convention: 'female' },
  { profile: { birthDate: '1998-06-21', birthTime: '14:30', birthTimezone: 'Asia/Ho_Chi_Minh' }, convention: null },
  { profile: { birthDate: '1998-06-21', birthTime: null, birthCountry: 'VN' }, convention: 'male' },
  { profile: { birthDate: '1974-11-03', birthTime: '01:30', birthCountry: 'US' }, convention: 'female' },
  { profile: { birthDate: '2026-02-03', birthTime: '22:00', birthTimezone: 'Asia/Ho_Chi_Minh' }, convention: 'male' },
  { profile: { birthDate: '1900-01-01', birthTime: null, birthCountry: 'VN' }, convention: null },
  { profile: { birthDate: '1984-02-04', birthTime: '04:00', birthTimezone: 'Asia/Shanghai' }, convention: 'female' },
];

const INSTANTS = ['1998-06-21T07:30:00.000Z', '2026-09-18T08:00:00.000Z',
  '2026-02-03T21:00:00.000Z', '2050-06-15T03:21:09.000Z', '2099-12-31T23:00:00.000Z'];

const ZONE = 'Asia/Ho_Chi_Minh';

const corpus = {
  hidden: HIDDEN,
  tenGods: [],
  relations: [],
  charts: BIRTHS.map(({ profile, convention }) => {
    const chart = buildBaZi(birthContext(profile), convention);
    return {
      profile, convention,
      pillars: chart.pillars.map((p) => (p == null ? null : p.text)),
      elementDistribution: chart.elementDistribution,
      seasonalDistribution: chart.seasonalDistribution,
      supportIndex: chart.supportIndex,
      rootPositions: chart.rootPositions,
      structures: chart.structures,
      pairs: chart.pairs,
      coverage: chart.coverage,
      missing: chart.missing,
      traditionalYongShen: chart.traditionalYongShen,
      traditionalXiShen: chart.traditionalXiShen,
      decade: chart.decade == null ? null : {
        forward: chart.decade.forward, startUtc: chart.decade.startUtc,
        birthZone: chart.decade.birthZone, startAge: chart.decade.startAge,
        referenceTerm: { name: chart.decade.referenceTerm.name, instant: chart.decade.referenceTerm.instant },
      },
      tenGods: chart.tenGods,
    };
  }),
  scores: [],
};

for (let day = 0; day < 10; day++) {
  for (let other = 0; other < 10; other++) corpus.tenGods.push({ day, other, god: tenGod(day, other) });
}
for (let a = 0; a < 12; a++) {
  for (let b = 0; b < 12; b++) corpus.relations.push({ a, b, relations: relations(a, b) });
}

for (const { profile, convention } of BIRTHS) {
  const chart = buildBaZi(birthContext(profile), convention);
  for (const iso of INSTANTS) {
    const ms = parseInstant(iso);
    const module = scoreBaZi(chart, calendarAt(ms, ZONE), ms);
    const decade = decadeAt(chart, ms);
    corpus.scores.push({
      profile, convention, iso,
      status: module.status, a: module.evidence.a, c: module.evidence.c,
      coverage: module.evidence.coverage,
      activeDecade: decade == null ? null : { pillar: decade.pillar.text, index: decade.index,
        startUtc: decade.startUtc, endUtc: decade.endUtc },
    });
  }
}

const target = emitFixture('bazi_corpus.json', JSON.stringify(corpus, null, 2));
process.stdout.write(`bazi corpus -> ${target}\n`);
