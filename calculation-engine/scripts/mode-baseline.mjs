/**
 * Captures the numeric result of every decision mode, with nothing that a
 * version bump is allowed to change.
 *
 *   node scripts/mode-baseline.mjs --write   overwrite the committed baseline
 *   node scripts/mode-baseline.mjs --check   fail when a mode's numbers moved
 *   node scripts/mode-baseline.mjs           same as --check
 *
 * This exists so that a change to one mode's mixture can be shown not to have
 * touched the others. `readingKey`, `ruleset`, `scoringVersion` and the engine
 * version are deliberately excluded: a ruleset bump changes every reading key
 * in every mode by design, and a diff dominated by that tells you nothing
 * about whether a number moved.
 *
 * What is recorded is what a reader would actually see — the winner, both
 * percentages, the mode score and basis, the data coverage, and every lucky
 * window — across seven categories, both birth-hour states, and NOW plus a
 * future period.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { createCalculator } from '../src/index.js';
import { MODES } from '../src/core.js';

const BASELINE = fileURLToPath(new URL('../test/fixtures/mode-baseline.json', import.meta.url));

const ZONE = 'Asia/Ho_Chi_Minh';

const PROFILES = Object.freeze({
  known_hour: {
    birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male',
  },
  unknown_hour: {
    birthDate: '1998-06-21', birthCountry: 'VN', traditionalProfile: 'male',
  },
});

/** 08:30 Z is 15:30 in Ho Chi Minh City, which is inside the afternoon. */
const CONTEXTS = Object.freeze({
  now: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: ZONE },
  future: { instantUtc: '2026-09-18T02:00:00Z', deviceTimezone: ZONE },
});

const PERIODS = Object.freeze({ now: 'now', future: 'evening' });

const CATEGORIES = Object.freeze([
  'general', 'love', 'career', 'money', 'study', 'friends', 'other',
]);

/** Everything a version bump may legitimately change is dropped here. */
function numericOnly(result) {
  return {
    status: result.status,
    winner: result.winner ?? null,
    percentages: result.percentages ?? null,
    modeScore: result.modeScore ?? null,
    modeBasis: result.modeBasis ?? null,
    dataCoverage: result.dataCoverage ?? null,
    windowStatus: result.windowStatus ?? null,
    // Ordering matters: the top two are ranked, so the window's own identity
    // is recorded and not just its score — a reorder with equal scores would
    // otherwise be invisible, and a reorder is exactly what a mixture change
    // is allowed to do to the mode it touched.
    luckyWindows: (result.luckyWindows ?? []).map(w => ({
      startUtc: w.startUtc ?? null,
      endUtc: w.endUtc ?? null,
      startLocal: w.startLocal ?? null,
      endLocal: w.endLocal ?? null,
      hourBranch: w.hourBranch ?? null,
      score: w.score ?? null,
      dataCoverage: w.dataCoverage ?? null,
    })),
  };
}

function capture() {
  const out = {};
  for (const [profileName, profile] of Object.entries(PROFILES)) {
    const calculator = createCalculator(profile);
    for (const [contextName, context] of Object.entries(CONTEXTS)) {
      for (const category of CATEGORIES) {
        for (const mode of Object.keys(MODES)) {
          const key = [profileName, contextName, category, mode].join('|');
          out[key] = numericOnly(calculator.calculate({
            context, mode, period: PERIODS[contextName], category,
          }));
        }
      }
    }
  }
  return out;
}

const mode = process.argv.includes('--write') ? 'write' : 'check';
const captured = capture();
const serialized = `${JSON.stringify(captured, null, 2)}\n`;

if (mode === 'write') {
  writeFileSync(BASELINE, serialized);
  console.log(`Wrote ${Object.keys(captured).length} mode results to ${BASELINE}.`);
  process.exit(0);
}

let committed;
try {
  committed = JSON.parse(readFileSync(BASELINE, 'utf8'));
} catch {
  console.error('No committed baseline. Run with --write first.');
  process.exit(1);
}

const moved = [];
for (const key of new Set([...Object.keys(committed), ...Object.keys(captured)])) {
  const before = JSON.stringify(committed[key] ?? null);
  const after = JSON.stringify(captured[key] ?? null);
  if (before !== after) moved.push(key);
}

if (moved.length === 0) {
  console.log(`All ${Object.keys(captured).length} mode results match the committed baseline.`);
  process.exit(0);
}

const byMode = new Map();
for (const key of moved) {
  const name = key.split('|')[3];
  byMode.set(name, (byMode.get(name) ?? 0) + 1);
}
console.error(`${moved.length} mode results differ from the committed baseline:`);
for (const [name, count] of [...byMode].sort()) console.error(`  ${name}: ${count}`);
console.error('\nIf this is an intended mixture change, rerun with --write and say so in VERIFICATION.md.');
process.exit(1);
