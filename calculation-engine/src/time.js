import moment from 'moment-timezone';
import { mod, boundedCache } from './core.js';

export const TZDB_VERSION = moment.tz.dataVersion;
export const HOUR = 3600000;
export const DAY = 24 * HOUR;
export const PERIODS = Object.freeze({ morning: [6, 12], midday: [12, 14], afternoon: [14, 18], evening: [18, 24] });
export function validZone(zone) { return typeof zone === 'string' && !!moment.tz.zone(zone); }
export function requireZone(zone) { if (!validZone(zone)) throw new Error('INVALID_IANA_TIMEZONE'); return zone; }
export function parseInstant(value) {
  if (value instanceof Date) value = value.toISOString();
  if (typeof value !== 'string' || !/(Z|[+-]\d{2}:\d{2})$/.test(value)) throw new Error('UTC_OR_OFFSET_REQUIRED');
  const p = moment.parseZone(value, moment.ISO_8601, true);
  if (!p.isValid()) throw new Error('INVALID_INSTANT');
  if (p.year() < 1900 || p.year() > 2099) throw new Error('SUPPORTED_READING_YEARS_1900_2099');
  return p.valueOf();
}
export function parseBirthDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) throw new Error('INVALID_BIRTH_DATE');
  const p = moment.utc(value, 'YYYY-MM-DD', true);
  if (!p.isValid() || p.year() < 1900 || p.year() > 2099) throw new Error('SUPPORTED_BIRTH_YEARS_1900_2099');
  return value;
}
export function parseBirthTime(value) {
  if (value == null || value === 'unknown') return null;
  if (typeof value !== 'string' || !/^([01]\d|2[0-3]):[0-5]\d$/.test(value)) throw new Error('INVALID_BIRTH_TIME');
  return value;
}
export function localAt(ms, zone) {
  const m = moment.tz(ms, requireZone(zone));
  return { year: m.year(), month: m.month() + 1, day: m.date(), hour: m.hour(), minute: m.minute(), second: m.second(),
    date: m.format('YYYY-MM-DD'), clock: m.format('HH:mm:ss'), offsetSeconds: m.utcOffset() * 60,
    iso: m.format('YYYY-MM-DDTHH:mm:ssZ'), zone };
}
export function hourBranch(hour) { return Math.floor((hour + 1) / 2) % 12; }

// Enumerating candidate offsets explicitly preserves DST folds and rejects gaps.
export function localCandidates(date, clock, zone) {
  requireZone(zone);
  const label = `${date}T${clock.length === 5 ? clock + ':00' : clock}`;
  const civil = moment.utc(label, 'YYYY-MM-DDTHH:mm:ss', true);
  if (!civil.isValid()) throw new Error('INVALID_LOCAL_DATETIME');
  const wanted = civil.format('YYYY-MM-DDTHH:mm:ss');
  const offsets = new Set(moment.tz.zone(zone).offsets);
  return [...new Set([...offsets].map(offset => civil.valueOf() + offset * 60000)
    .filter(ms => moment.tz(ms, zone).format('YYYY-MM-DDTHH:mm:ss') === wanted))].sort((a, b) => a - b);
}

export function birthContext(profile) {
  const date = parseBirthDate(profile.birthDate), clock = parseBirthTime(profile.birthTime);
  let zones = [], source = 'unresolved';
  if (profile.birthTimezone != null) {
    zones = [requireZone(profile.birthTimezone)]; source = 'explicit_birth_timezone';
  } else if (profile.birthCountry != null) {
    if (typeof profile.birthCountry !== 'string' || !moment.tz.countries().includes(profile.birthCountry.toUpperCase())) throw new Error('INVALID_BIRTH_COUNTRY');
    zones = moment.tz.zonesForCountry(profile.birthCountry.toUpperCase()) ?? [];
    source = zones.length === 1 ? 'single_zone_birth_country' : 'birth_country_zone_candidates';
  }
  const intervals = [], nonexistentZones = [];
  for (const zone of zones) {
    if (clock) {
      const instants = localCandidates(date, clock, zone);
      if (!instants.length) nonexistentZones.push(zone);
      for (const instant of instants) intervals.push({ start: instant, end: instant, zone });
    } else {
      const d = moment.utc(date), wallStart = d.valueOf(), wallEnd = wallStart + DAY;
      // Intersect every UTC offset era with the desired civil date. Handles 23/25h
      // dates and completely skipped dates without pretending noon was observed.
      const z = moment.tz.zone(zone);
      for (let i = 0; i < z.untils.length; i++) {
        const start = Math.max(i ? z.untils[i - 1] : -Infinity, wallStart + z.offsets[i] * 60000);
        const end = Math.min(z.untils[i], wallEnd + z.offsets[i] * 60000);
        if (end > start) intervals.push({ start, end: end - 1, zone });
      }
      if (!intervals.some(x => x.zone === zone)) nonexistentZones.push(zone);
    }
  }
  // Distinct timezone IDs can represent the same birth instant (e.g. a country
  // whose regions only differed before the entered birth year).
  const exact = clock != null && intervals.length > 0 && new Set(intervals.map(x => x.start)).size === 1
    && intervals.every(x => x.start === x.end) && nonexistentZones.length === 0;
  return { date, clock, zones, zoneSource: source, intervals, exact,
    status: !zones.length ? 'birth_timezone_unresolved' : !intervals.length ? 'birth_time_nonexistent' : exact ? 'exact' : 'uncertain',
    nonexistentZones };
}

const boundaryCache = boundedCache(64);
export function civilBoundaries(date, zone) {
  const key = `${date}|${zone}`;
  if (boundaryCache.get(key)) return boundaryCache.get(key);
  const boundaries = new Set();
  const day = moment.utc(date);
  for (let delta = -1; delta <= 2; delta++) {
    const d = day.clone().add(delta, 'days').format('YYYY-MM-DD');
    for (const h of [0, 1, 3, 5, 6, 7, 9, 11, 12, 13, 14, 15, 17, 18, 19, 21, 23]) {
      for (const ms of localCandidates(d, `${String(h).padStart(2, '0')}:00`, zone)) boundaries.add(ms);
    }
  }
  for (const ms of moment.tz.zone(zone).untils) if (ms >= day.valueOf() - 2 * DAY && ms <= day.valueOf() + 4 * DAY) boundaries.add(ms);
  return boundaryCache.set(key, [...boundaries].sort((a, b) => a - b));
}
export function segmentsForDay(ms, zone, extraBoundaries = []) {
  const date = localAt(ms, zone).date;
  const points = [...new Set([...civilBoundaries(date, zone), ...extraBoundaries])].sort((a, b) => a - b);
  const result = [];
  for (let i = 0; i < points.length - 1; i++) {
    const start = points[i], end = points[i + 1];
    if (localAt(start, zone).date !== date) continue;
    result.push({ start, end, local: localAt(start, zone), hourBranch: hourBranch(localAt(start, zone).hour) });
  }
  return result;
}
export function periodSegments(segments, now, period) {
  if (period === 'now') return segments.filter(s => s.start <= now && now < s.end);
  if (!Object.hasOwn(PERIODS, period)) throw new Error('INVALID_PERIOD');
  const [lo, hi] = PERIODS[period];
  return segments.filter(s => s.local.hour >= lo && s.local.hour < hi && s.end > now)
    .map(s => ({ ...s, candidateStart: Math.max(now, s.start) }));
}
export function addCivil(ms, zone, years, months = 0, days = 0, hours = 0) {
  return moment.tz(ms, zone).add(years, 'years').add(months, 'months').add(days, 'days').add(hours, 'hours').valueOf();
}
export const cyclical = (stem, branch) => { for (let i = 0; i < 60; i++) if (mod(i, 10) === stem && mod(i, 12) === branch) return i; throw new Error('INVALID_PILLAR'); };
