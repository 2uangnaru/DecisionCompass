/**
 * Every mode's numbers, pinned against a committed baseline.
 *
 * The point of this file is to make "I changed one mode" a checkable claim.
 * A mixture change is allowed — it is how the system is tuned deliberately —
 * but it must not reach a mode it was not aimed at, and a diff of whole
 * readings cannot show that, because a ruleset bump rewrites every
 * `readingKey` in every mode at once.
 *
 * So the baseline deliberately excludes `readingKey`, the ruleset, the
 * scoring version and the engine version, and records only what a reader
 * would see: the winner, both percentages, the mode score and basis, the data
 * coverage, the window status, and each lucky window's own identity and score.
 *
 * Regenerate with `node scripts/mode-baseline.mjs --write`, and say in
 * VERIFICATION.md which modes moved and why.
 */
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { createCalculator } from '../src/index.js';
import { MODES } from '../src/core.js';

const baseline = JSON.parse(readFileSync(
  fileURLToPath(new URL('./fixtures/mode-baseline.json', import.meta.url)),
  'utf8',
));

const ZONE = 'Asia/Ho_Chi_Minh';

const PROFILES = {
  known_hour: {
    birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male',
  },
  unknown_hour: {
    birthDate: '1998-06-21', birthCountry: 'VN', traditionalProfile: 'male',
  },
};

const CONTEXTS = {
  now: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: ZONE },
  future: { instantUtc: '2026-09-18T02:00:00Z', deviceTimezone: ZONE },
};

const PERIODS = { now: 'now', future: 'evening' };

const CATEGORIES = ['general', 'love', 'career', 'money', 'study', 'friends', 'other'];

/** Mirrors `scripts/mode-baseline.mjs`; keep the two in step. */
function numericOnly(result) {
  return {
    status: result.status,
    winner: result.winner ?? null,
    percentages: result.percentages ?? null,
    modeScore: result.modeScore ?? null,
    modeBasis: result.modeBasis ?? null,
    dataCoverage: result.dataCoverage ?? null,
    windowStatus: result.windowStatus ?? null,
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

const calculators = Object.fromEntries(
  Object.entries(PROFILES).map(([name, profile]) => [name, createCalculator(profile)]),
);

test('every mode still produces exactly its committed numbers', () => {
  // 2 birth-hour states x 2 contexts x 7 categories x 7 modes.
  assert.equal(Object.keys(baseline).length, 196, 'the baseline lost coverage');

  const moved = [];
  for (const [profileName, calculator] of Object.entries(calculators)) {
    for (const [contextName, context] of Object.entries(CONTEXTS)) {
      for (const category of CATEGORIES) {
        for (const mode of Object.keys(MODES)) {
          const key = [profileName, contextName, category, mode].join('|');
          assert.ok(baseline[key], `${key} is missing from the baseline`);
          const actual = numericOnly(calculator.calculate({
            context, mode, period: PERIODS[contextName], category,
          }));
          if (JSON.stringify(actual) !== JSON.stringify(baseline[key])) moved.push(key);
        }
      }
    }
  }
  assert.deepEqual(moved, [], `${moved.length} mode results no longer match the baseline`);
});

test('the baseline covers what a mode change could plausibly break', () => {
  const seen = { profiles: new Set(), contexts: new Set(), categories: new Set(), modes: new Set() };
  for (const key of Object.keys(baseline)) {
    const [profile, context, category, mode] = key.split('|');
    seen.profiles.add(profile);
    seen.contexts.add(context);
    seen.categories.add(category);
    seen.modes.add(mode);
  }
  assert.deepEqual([...seen.profiles].sort(), ['known_hour', 'unknown_hour']);
  assert.deepEqual([...seen.contexts].sort(), ['future', 'now']);
  assert.deepEqual([...seen.categories].sort(), [...CATEGORIES].sort());
  assert.deepEqual([...seen.modes].sort(), Object.keys(MODES).sort());

  // A future period has to actually carry windows, or the ordering half of
  // this baseline would be checking nothing.
  const future = Object.entries(baseline).filter(([key]) => key.split('|')[1] === 'future');
  assert.ok(future.length > 0);
  assert.ok(
    future.every(([, value]) => value.luckyWindows.length > 0),
    'a future-period reading came back with no windows to rank',
  );
  // NOW never has windows; that is the contract, not an accident of this data.
  const now = Object.entries(baseline).filter(([key]) => key.split('|')[1] === 'now');
  assert.ok(now.every(([, value]) => value.luckyWindows.length === 0));
});

test('nothing a version bump owns leaked into the baseline', () => {
  // If any of these ever appear here, the file stops being able to answer the
  // question it exists for: a ruleset bump would make every mode look changed.
  const serialized = JSON.stringify(baseline);
  for (const field of ['readingKey', 'ruleset', 'rulesetVersion', 'engineVersion', 'scoringVersion', 'scaleVersion']) {
    assert.ok(!serialized.includes(field), `${field} must not be pinned here`);
  }
});
