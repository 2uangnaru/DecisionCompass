// A reproducible synthetic cohort, shared by the v9.1 calibration script and
// the held-out simulation.
//
// The randomness here is offline and seeded. It never touches a reading: it
// only decides which imaginary profiles and which dates get measured, and the
// same seed always produces the same cohort on any machine. Nothing in
// `src/` imports this file.

/** Mulberry32 — small, fast, and identical everywhere. */
export function rng(seed) {
  let a = seed >>> 0;
  return function next() {
    a = (a + 0x6D2B79F5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const pick = (next, list) => list[Math.floor(next() * list.length)];

/**
 * Birth countries spanning single-zone and multi-zone territories, the
 * northern and southern DST hemispheres, half-hour and three-quarter-hour
 * offsets, and countries that observe no DST at all.
 */
export const COUNTRIES = Object.freeze([
  'VN', 'JP', 'CN', 'IN', 'TH', 'ES', 'US', 'AU', 'BR', 'NP', 'IR', 'NZ',
  'GB', 'DE', 'MX', 'ZA', 'EG', 'RU', 'KR', 'ID', 'PH', 'CA', 'AR', 'NG',
]);

/** Device timezones used for the reading context, deliberately not derived from birth country. */
export const ZONES = Object.freeze([
  'Asia/Ho_Chi_Minh', 'Asia/Tokyo', 'Asia/Shanghai', 'Asia/Kolkata', 'Asia/Bangkok',
  'Europe/Madrid', 'America/New_York', 'America/Los_Angeles', 'Australia/Sydney',
  'Australia/Lord_Howe', 'America/Sao_Paulo', 'Asia/Kathmandu', 'Asia/Tehran',
  'Pacific/Auckland', 'Europe/London', 'Africa/Cairo', 'America/Mexico_City',
  'Asia/Seoul', 'Europe/Berlin', 'Pacific/Chatham',
]);

export const CATEGORIES = Object.freeze(['general', 'love', 'career', 'money', 'study', 'friends', 'other']);
export const MODES = Object.freeze(['yes_no', 'act_wait', 'advance_retreat', 'stay_go', 'keep_let_go', 'commit_withdraw', 'left_right']);
export const PERIODS = Object.freeze(['now', 'morning', 'midday', 'afternoon', 'evening']);

const TRADITIONAL = Object.freeze(['male', 'female', 'unspecified']);

const pad = n => String(n).padStart(2, '0');

/**
 * One synthetic profile.
 *
 * Roughly a third have no birth time, which is what keeps unknown-hour
 * coverage inside the calibration rather than beside it.
 */
export function makeProfile(next) {
  const year = 1940 + Math.floor(next() * 71);
  const month = 1 + Math.floor(next() * 12);
  const day = 1 + Math.floor(next() * 28);
  const knowsTime = next() > 0.32;
  return {
    birthDate: `${year}-${pad(month)}-${pad(day)}`,
    birthTime: knowsTime ? `${pad(Math.floor(next() * 24))}:${pad(Math.floor(next() * 60))}` : null,
    birthCountry: pick(next, COUNTRIES),
    traditionalProfile: pick(next, TRADITIONAL),
    revision: 1,
  };
}

/**
 * A reading context somewhere in the sampling year.
 *
 * Dates are spread across all twelve months so that both DST transitions, and
 * the solar terms that move the almanac, are represented.
 */
export function makeContext(next, { year = 2026 } = {}) {
  const dayOfYear = Math.floor(next() * 365);
  const base = Date.UTC(year, 0, 1) + dayOfYear * 86400000 + Math.floor(next() * 24) * 3600000;
  return { instantUtc: new Date(base).toISOString(), deviceTimezone: pick(next, ZONES) };
}

/** A deterministic cohort of `size` profiles plus one context each. */
export function cohort(seed, size, options = {}) {
  const next = rng(seed);
  return Array.from({ length: size }, () => ({
    profile: makeProfile(next),
    context: makeContext(next, options),
    category: pick(next, CATEGORIES),
    period: pick(next, PERIODS),
  }));
}

/** The p-th percentile of `values` by linear interpolation, p in 0..1. */
export function percentile(values, p) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  if (sorted.length === 1) return sorted[0];
  const index = p * (sorted.length - 1);
  const low = Math.floor(index), high = Math.ceil(index);
  return low === high ? sorted[low] : sorted[low] + (sorted[high] - sorted[low]) * (index - low);
}
