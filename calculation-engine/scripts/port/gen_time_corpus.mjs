// Dumps a time-layer parity corpus straight out of the Node engine.
//
// The Dart port under `mobile_app/lib/local_engine/time/` must reproduce these
// values exactly. The corpus deliberately leans on the hard cases: DST gaps and
// folds, quarter-hour offsets, the date line, LMT-era offsets in the earliest
// supported birth years, 23/25-hour local days and skipped local dates.

import { emitFixture } from './lib.mjs';
import moment from 'moment-timezone';
import {
  localAt, localCandidates, birthContext, civilBoundaries, segmentsForDay,
  periodSegments, addCivil, parseInstant, hourBranch, PERIODS, TZDB_VERSION,
} from '../../src/time.js';

const ZONES = [
  'Asia/Ho_Chi_Minh', 'UTC', 'Europe/London', 'America/New_York', 'Australia/Lord_Howe',
  'Asia/Kathmandu', 'Pacific/Chatham', 'Pacific/Kiritimati', 'Pacific/Apia',
  'America/Sao_Paulo', 'Africa/Cairo', 'Asia/Tehran', 'Europe/Berlin', 'Asia/Shanghai',
  'America/Santiago', 'Antarctica/Troll', 'Asia/Tokyo', 'Europe/Lisbon', 'Asia/Kolkata',
];

const LOCAL_PROBES = [
  // Spring-forward gaps.
  ['2026-03-08', '02:30', 'America/New_York'],
  ['2026-03-29', '01:30', 'Europe/London'],
  ['2026-10-04', '02:15', 'Australia/Lord_Howe'],
  ['2026-09-06', '00:30', 'America/Santiago'],
  // Autumn folds.
  ['2026-11-01', '01:30', 'America/New_York'],
  ['2026-10-25', '01:30', 'Europe/London'],
  ['2026-04-05', '01:30', 'Australia/Lord_Howe'],
  // Quarter-hour and unusual offsets.
  ['1998-06-21', '14:30', 'Asia/Kathmandu'],
  ['1998-06-21', '14:30', 'Pacific/Chatham'],
  ['2026-06-21', '12:00', 'Antarctica/Troll'],
  // Date-line and skipped-date behaviour.
  ['2011-12-30', '12:00', 'Pacific/Apia'],
  ['1994-12-31', '12:00', 'Pacific/Kiritimati'],
  // LMT era inside the supported range.
  ['1900-01-02', '00:30', 'Asia/Ho_Chi_Minh'],
  ['1906-07-01', '06:00', 'Asia/Ho_Chi_Minh'],
  ['1901-05-05', '11:11', 'Europe/Lisbon'],
  ['1900-03-03', '23:59', 'Asia/Kolkata'],
];

const BIRTH_PROFILES = [
  { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN' },
  { birthDate: '1998-06-21', birthTime: null, birthCountry: 'VN' },
  { birthDate: '1998-06-21', birthTime: '14:30', birthTimezone: 'Asia/Ho_Chi_Minh' },
  { birthDate: '1985-03-31', birthTime: '01:30', birthCountry: 'GB' },
  { birthDate: '2011-12-30', birthTime: '12:00', birthCountry: 'WS' },
  { birthDate: '2011-12-30', birthTime: null, birthCountry: 'WS' },
  { birthDate: '1974-11-03', birthTime: '01:30', birthCountry: 'US' },
  { birthDate: '1974-11-03', birthTime: null, birthCountry: 'US' },
  { birthDate: '1900-01-01', birthTime: null, birthCountry: 'VN' },
  { birthDate: '1900-01-01', birthTime: '00:30', birthCountry: 'PT' },
  { birthDate: '2026-10-04', birthTime: '02:15', birthCountry: 'AU' },
  { birthDate: '2001-09-11', birthTime: '08:46', birthCountry: 'RU' },
  { birthDate: '1960-02-29', birthTime: '23:59', birthCountry: 'NP' },
  { birthDate: '2024-04-07', birthTime: '00:30', birthCountry: 'CL' },
  { birthDate: '1999-12-31', birthTime: null, birthCountry: 'KI' },
];

const SEGMENT_PROBES = [
  ['2026-09-18T08:30:00.000Z', 'Asia/Ho_Chi_Minh'],
  ['2026-03-08T12:00:00.000Z', 'America/New_York'],
  ['2026-11-01T12:00:00.000Z', 'America/New_York'],
  ['2026-10-04T02:00:00.000Z', 'Australia/Lord_Howe'],
  ['2026-04-05T02:00:00.000Z', 'Australia/Lord_Howe'],
  ['2026-03-29T05:00:00.000Z', 'Europe/London'],
  ['2026-10-25T05:00:00.000Z', 'Europe/London'],
  ['2026-06-21T00:00:00.000Z', 'Pacific/Chatham'],
  ['2026-06-21T00:00:00.000Z', 'Asia/Kathmandu'],
  ['2026-01-15T23:30:00.000Z', 'Pacific/Kiritimati'],
  ['1900-06-15T03:00:00.000Z', 'Asia/Ho_Chi_Minh'],
];

const corpus = {
  tzdbVersion: TZDB_VERSION,
  countries: moment.tz.countries(),
  zonesForCountry: Object.fromEntries(
    ['VN', 'US', 'GB', 'AU', 'RU', 'WS', 'KI', 'NP', 'CL', 'PT', 'CN', 'DE', 'FR', 'AQ']
      .map((code) => [code, moment.tz.zonesForCountry(code)]),
  ),
  zoneTables: Object.fromEntries(ZONES.map((zone) => {
    const z = moment.tz.zone(zone);
    // JSON cannot carry Infinity, so the open-ended final until is dropped and
    // asserted separately on the Dart side.
    const finite = (value) => (Number.isFinite(value) ? value : null);
    return [zone, { offsets: z.offsets, untilCount: z.untils.length,
      firstUntils: z.untils.slice(0, 6).map(finite),
      lastFiniteUntil: finite(z.untils[z.untils.length - 2]) }];
  })),
  localAt: [],
  localCandidates: LOCAL_PROBES.map(([date, clock, zone]) => ({
    date, clock, zone, instants: localCandidates(date, clock, zone),
  })),
  hourBranch: Array.from({ length: 24 }, (_, hour) => hourBranch(hour)),
  periods: PERIODS,
  birthContexts: BIRTH_PROFILES.map((profile) => {
    const birth = birthContext(profile);
    return {
      profile,
      date: birth.date, clock: birth.clock, zones: birth.zones, zoneSource: birth.zoneSource,
      exact: birth.exact, status: birth.status, nonexistentZones: birth.nonexistentZones,
      intervals: birth.intervals.map((i) => ({ start: i.start, end: i.end, zone: i.zone })),
    };
  }),
  civilBoundaries: SEGMENT_PROBES.map(([iso, zone]) => ({
    date: localAt(parseInstant(iso), zone).date, zone,
    boundaries: civilBoundaries(localAt(parseInstant(iso), zone).date, zone),
  })),
  segments: SEGMENT_PROBES.map(([iso, zone]) => {
    const ms = parseInstant(iso);
    const segments = segmentsForDay(ms, zone);
    return {
      iso, zone, instantMs: ms,
      segments: segments.map((s) => ({ start: s.start, end: s.end, hourBranch: s.hourBranch,
        localDate: s.local.date, localClock: s.local.clock, localHour: s.local.hour,
        offsetSeconds: s.local.offsetSeconds, iso: s.local.iso })),
      periods: Object.fromEntries(['now', ...Object.keys(PERIODS)].map((period) => [period,
        periodSegments(segments, ms, period).map((s) => ({ start: s.start, end: s.end,
          candidateStart: s.candidateStart ?? null }))])),
    };
  }),
  addCivil: [],
  parseInstant: [
    '2026-09-18T08:30:00.000Z', '2026-09-18T08:30:00Z', '2026-09-18T15:30:00+07:00',
    '1900-01-01T00:00:00.000Z', '2099-12-31T23:59:59.999Z', '2026-09-18T08:30:00.000+00:00',
    '2026-02-28T23:00:00-05:00',
  ].map((value) => ({ value, ms: parseInstant(value) })),
  parseInstantRejected: [
    '2026-09-18T08:30:00.000', '2023-02-29T00:00:00Z', '1899-12-31T23:00:00Z',
    '2100-01-01T00:00:00Z', 'not-a-date', '2026-13-01T00:00:00Z', '2026-09-18T25:00:00Z',
  ].map((value) => {
    try { parseInstant(value); return { value, error: null }; }
    catch (error) { return { value, error: error.message }; }
  }),
};

for (const zone of ZONES) {
  for (const iso of ['2026-09-18T08:30:00.000Z', '2026-03-08T07:30:00.000Z',
    '2026-11-01T05:30:00.000Z', '1900-02-01T00:00:00.000Z', '1998-06-21T07:30:00.000Z',
    '2099-12-31T12:00:00.000Z']) {
    const ms = parseInstant(iso);
    const local = localAt(ms, zone);
    corpus.localAt.push({ zone, iso, ms, year: local.year, month: local.month, day: local.day,
      hour: local.hour, minute: local.minute, second: local.second, date: local.date,
      clock: local.clock, offsetSeconds: local.offsetSeconds, isoLocal: local.iso });
  }
}

for (const [iso, zone] of SEGMENT_PROBES) {
  const ms = parseInstant(iso);
  for (const [years, months, days, hours] of [
    [0, 0, 0, 0], [10, 0, 0, 0], [1, 0, 0, 0], [0, 7, 0, 0], [0, 0, 45, 0], [0, 0, 0, 13],
    [3, 4, 20, 9], [20, 0, 0, 0], [0, 0, 1, 0], [0, 1, 0, 0],
  ]) {
    corpus.addCivil.push({ iso, zone, years, months, days, hours,
      result: addCivil(ms, zone, years, months, days, hours) });
  }
}

const target = emitFixture('time_corpus.json', JSON.stringify(corpus, null, 2));
process.stdout.write(`time corpus -> ${target}\n`);
