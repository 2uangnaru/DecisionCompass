// Dumps a Chinese-calendar parity corpus straight out of the Node engine.
//
// Solar-term instants are compared to the millisecond, because the engine uses
// them as segment boundaries and as the 节 that decides a month pillar: being
// a second out can move a whole pillar.

import { emitFixture } from './lib.mjs';
import {
  solarTerms, termsAround, civilCalendar, solarPillars, calendarAt, natalPillars,
  almanac, nearbyBoundaries, STEMS, BRANCHES,
} from '../../src/calendar.js';
import { birthContext, parseInstant } from '../../src/time.js';

const YEARS = [1899, 1900, 1901, 1923, 1950, 1969, 1984, 1998, 1999, 2000, 2020, 2024,
  2025, 2026, 2027, 2033, 2050, 2098, 2099, 2100];

const DATES = ['1900-01-01', '1900-06-15', '1923-07-04', '1950-12-25', '1969-07-20',
  '1984-02-02', '1998-06-21', '2000-02-29', '2020-01-25', '2023-02-20', '2025-01-29',
  '2026-02-17', '2026-09-18', '2033-12-22', '2050-06-15', '2099-12-31'];

const INSTANTS = ['1900-01-01T00:00:00.000Z', '1923-07-04T11:11:11.000Z',
  '1969-07-20T20:17:40.000Z', '1998-06-21T07:30:00.000Z', '2026-02-03T21:00:00.000Z',
  '2026-09-18T08:00:00.000Z', '2026-09-18T08:30:00.000Z', '2026-12-21T15:00:00.000Z',
  '2050-06-15T03:21:09.000Z', '2099-12-31T23:00:00.000Z'];

const ZONES = ['Asia/Ho_Chi_Minh', 'UTC', 'America/New_York', 'Pacific/Kiritimati',
  'Asia/Kathmandu'];

const BIRTHS = [
  { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN' },
  { birthDate: '1998-06-21', birthTime: null, birthCountry: 'VN' },
  { birthDate: '1974-11-03', birthTime: '01:30', birthCountry: 'US' },
  { birthDate: '2026-02-03', birthTime: '22:00', birthCountry: 'VN' },
  { birthDate: '1900-01-01', birthTime: null, birthCountry: 'VN' },
  { birthDate: '1984-02-04', birthTime: null, birthCountry: 'CN' },
];

const serializePillar = (p) => (p == null ? null : { stem: p.stem, branch: p.branch, text: p.text });

const corpus = {
  stems: STEMS, branches: BRANCHES,
  solarTerms: YEARS.map((year) => ({
    year,
    terms: solarTerms(year).map((t) => ({ name: t.name, instant: t.instant, monthIndex: t.monthIndex })),
  })),
  civilCalendar: DATES.map((date) => {
    const c = civilCalendar(date);
    return { date, lunar: c.lunar, day: serializePillar(c.day) };
  }),
  solarPillars: INSTANTS.map((iso) => {
    const ms = parseInstant(iso);
    const p = solarPillars(ms);
    return { iso, ms, year: serializePillar(p.year), month: serializePillar(p.month),
      solarYear: p.solarYear, latestJie: { name: p.latestJie.name, instant: p.latestJie.instant } };
  }),
  calendarAt: [],
  natalPillars: BIRTHS.map((profile) => ({
    profile, pillars: natalPillars(birthContext(profile)).map(serializePillar),
  })),
  nearbyBoundaries: INSTANTS.map((iso) => ({ iso, boundaries: nearbyBoundaries(parseInstant(iso)) })),
  termsAroundCount: INSTANTS.map((iso) => ({ iso, count: termsAround(parseInstant(iso)).length })),
};

for (const iso of INSTANTS) {
  for (const zone of ZONES) {
    const ms = parseInstant(iso);
    const cal = calendarAt(ms, zone);
    const t = almanac(cal);
    corpus.calendarAt.push({
      iso, zone, ms,
      localDate: cal.local.date, lunar: cal.lunar,
      year: serializePillar(cal.year), month: serializePillar(cal.month),
      day: serializePillar(cal.day), hour: serializePillar(cal.hour),
      solarYear: cal.solarYear, latestJie: cal.latestJie.name,
      almanac: { status: t.status, a: t.evidence.a, c: t.evidence.c, coverage: t.evidence.coverage,
        dayGod: t.diagnostics.dayGod, hourGod: t.diagnostics.hourGod, officer: t.diagnostics.officer },
    });
  }
}

const target = emitFixture('calendar_corpus.json', JSON.stringify(corpus, null, 2));
process.stdout.write(`calendar corpus -> ${target}\n`);
