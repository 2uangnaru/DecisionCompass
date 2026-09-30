// Captures the outputs v9.1 promised not to touch.
//
//   node scripts/capture-foundations.mjs [--engine ../.baseline-src/index.js] [--out test/foundations.json]
//
// The birth charts and the daily brief are not part of the decision score and
// must read exactly the same after the scoring change. This dumps both for a
// spread of profiles so `test/foundations.test.js` can compare the current
// engine against a capture taken from the engine before v9.1.
//
// `--engine` exists so the same script can be pointed at an older copy of
// `src/`, which is how the committed baseline was produced.

import { writeFileSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const arg = (name, fallback) => {
  const at = process.argv.indexOf(`--${name}`);
  return at > -1 ? process.argv[at + 1] : fallback;
};

const enginePath = resolve(here, arg('engine', '../src/index.js'));
const { createCalculator } = await import(pathToFileURL(enginePath).href);

/**
 * Profiles chosen to exercise the paths that feed the charts and the brief:
 * a known hour and an unknown one, both traditional conventions and none,
 * several hemispheres, a half-hour and a quarter-hour offset, and a country
 * with more than one candidate timezone.
 */
const PROFILES = [
  { key: 'vn_known_female', birthDate: '1990-03-14', birthTime: '08:25', birthCountry: 'VN', traditionalProfile: 'female' },
  { key: 'vn_unknown_unspecified', birthDate: '1990-03-14', birthTime: null, birthCountry: 'VN', traditionalProfile: 'unspecified' },
  { key: 'us_known_male', birthDate: '1975-11-02', birthTime: '23:10', birthCountry: 'US', traditionalProfile: 'male' },
  { key: 'in_known_female', birthDate: '2001-07-19', birthTime: '05:45', birthCountry: 'IN', traditionalProfile: 'female' },
  { key: 'np_known_male', birthDate: '1988-01-31', birthTime: '12:00', birthCountry: 'NP', traditionalProfile: 'male' },
  { key: 'au_unknown_female', birthDate: '1964-09-30', birthTime: null, birthCountry: 'AU', traditionalProfile: 'female' },
  { key: 'jp_known_unspecified', birthDate: '1999-02-28', birthTime: '18:33', birthCountry: 'JP', traditionalProfile: 'unspecified' },
  { key: 'br_known_male', birthDate: '1982-06-05', birthTime: '03:05', birthCountry: 'BR', traditionalProfile: 'male' },
];

/** Instants spanning both DST transitions and a solar-term boundary. */
const CONTEXTS = [
  { key: 'vn_autumn', instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' },
  { key: 'ny_dst_end', instantUtc: '2026-11-01T05:30:00Z', deviceTimezone: 'America/New_York' },
  { key: 'syd_dst_start', instantUtc: '2026-10-03T16:30:00Z', deviceTimezone: 'Australia/Sydney' },
  { key: 'kathmandu_quarter', instantUtc: '2026-02-04T02:15:00Z', deviceTimezone: 'Asia/Kathmandu' },
];

const captured = { profiles: {}, brief: {} };

for (const { key, ...profile } of PROFILES) {
  const calculator = createCalculator(profile);
  captured.profiles[key] = calculator.inspectBirthCharts();
  for (const { key: contextKey, ...context } of CONTEXTS) {
    // The brief is read once for the whole local day with the general profile,
    // so mode, period and category must not reach it. Asking with an unusual
    // combination is the point: the answer has to be the same anyway.
    const reading = calculator.calculate({
      context, mode: 'left_right', period: 'now', category: 'money',
    });
    if (reading.status === 'period_elapsed') continue;
    captured.brief[`${key}|${contextKey}`] = {
      dailyBrief: reading.dailyBrief,
      birthData: reading.birthData,
      warnings: reading.warnings,
      context: reading.context,
    };
  }
}

const out = resolve(here, arg('out', '../test/foundations.json'));
writeFileSync(out, JSON.stringify(captured, null, 2) + '\n');
console.log(`captured ${Object.keys(captured.profiles).length} charts and ${Object.keys(captured.brief).length} briefs from ${enginePath}`);
console.log(`-> ${out}`);
