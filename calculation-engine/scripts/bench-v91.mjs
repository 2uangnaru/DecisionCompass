// What a v9.1 reading costs, by mode and by how much birth data the reader
// gave.
//
//   node scripts/bench-v91.mjs
//
// A fresh calculator per measurement, so nothing is reading a cache another
// measurement filled. The numbers are desktop Node; a phone is slower, and the
// point of the run is the shape — which modes and which profiles are
// expensive, and how much of that is the Zi Wei provider.

import { createCalculator } from '../src/index.js';
import { ziweiCounters, resetZiweiCounters } from '../src/ziwei.js';

const CONTEXT = { instantUtc: '2026-09-30T03:00:00.000Z', deviceTimezone: 'Asia/Ho_Chi_Minh' };

const PROFILES = {
  'known hour + convention': { birthDate: '1990-03-14', birthTime: '08:25', birthCountry: 'VN', traditionalProfile: 'female', revision: 1 },
  'known hour, unspecified': { birthDate: '1990-03-14', birthTime: '08:25', birthCountry: 'VN', traditionalProfile: 'unspecified', revision: 1 },
  'unknown hour + convention': { birthDate: '1990-03-14', birthTime: null, birthCountry: 'VN', traditionalProfile: 'female', revision: 1 },
  'unknown hour, unspecified': { birthDate: '1990-03-14', birthTime: null, birthCountry: 'VN', traditionalProfile: 'unspecified', revision: 1 },
};

const MODES = ['yes_no', 'act_wait', 'advance_retreat', 'stay_go', 'keep_let_go', 'commit_withdraw', 'left_right'];

// One throwaway reading so the profile-independent caches — solar terms, civil
// boundaries, the tz database — are warm, as they are in a running app.
createCalculator(PROFILES['known hour + convention']).calculate({ context: CONTEXT, mode: 'yes_no', period: 'now' });

// Each measurement needs a birth date no earlier run has scored, because the
// Zi Wei chart and score caches are keyed by it and live for the process.
let distinct = 0;
const freshProfile = base => ({ ...base, birthDate: `19${60 + Math.floor(distinct / 12)}-${String(1 + (distinct++ % 12)).padStart(2, '0')}-14` });

console.log('profile                    mode              ms   horoscopes  scoreChart hit%   heap MB');
const worst = {};
for (const [label, base] of Object.entries(PROFILES)) {
  for (const mode of MODES) {
    const profile = freshProfile(base);
    resetZiweiCounters();
    global.gc?.();
    const heapBefore = process.memoryUsage().heapUsed;
    const calculator = createCalculator(profile);
    const started = process.hrtime.bigint();
    calculator.calculate({ context: CONTEXT, mode, period: 'now', category: 'general' });
    const ms = Number(process.hrtime.bigint() - started) / 1e6;
    const counts = ziweiCounters();
    const heapMb = (process.memoryUsage().heapUsed - heapBefore) / 1048576;
    worst[label] = Math.max(worst[label] ?? 0, ms);
    console.log(
      `${label.padEnd(26)} ${mode.padEnd(16)}${ms.toFixed(0).padStart(5)}`
      + `${String(counts.horoscopes).padStart(13)}`
      + `${(counts.scoreChartHits / Math.max(1, counts.scoreChartCalls) * 100).toFixed(0).padStart(14)}%`
      + `${heapMb.toFixed(1).padStart(10)}`
    );
  }
}

console.log('\nWorst mode per profile class:');
for (const [label, ms] of Object.entries(worst)) console.log(`  ${label.padEnd(26)} ${ms.toFixed(0)} ms`);

// A second reading for the same profile is what a reader actually does next.
console.log('\nSecond reading on the same calculator (a reader changing mode or period):');
const calculator = createCalculator(freshProfile(PROFILES['unknown hour, unspecified']));
calculator.calculate({ context: CONTEXT, mode: 'act_wait', period: 'now', category: 'general' });
for (const [mode, period, category] of [['yes_no', 'now', 'general'], ['act_wait', 'evening', 'love'], ['commit_withdraw', 'now', 'career']]) {
  const started = process.hrtime.bigint();
  calculator.calculate({ context: CONTEXT, mode, period, category });
  console.log(`  ${mode}/${period}/${category}`.padEnd(40) + `${(Number(process.hrtime.bigint() - started) / 1e6).toFixed(0).padStart(5)} ms`);
}
