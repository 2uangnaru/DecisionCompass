import assert from 'node:assert/strict';
import test from 'node:test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { createCalculator } from '../src/index.js';

/**
 * v9.1 changed how a decision is scored and nothing else.
 *
 * `test/foundations.json` was captured from the engine as it stood *before*
 * the change (`node scripts/capture-foundations.mjs --engine ../.baseline-src/index.js`,
 * run against a checkout of the previous `src/`). Every value in it — the natal
 * BaZi, the Zi Wei scenario set, the Western natal sky, the lucky number, both
 * daily colours, the energy level and the birth-data status — must still come
 * out identical.
 *
 * If one of these ever has to change, it is a separate decision with its own
 * reasoning, not a side effect of a scoring release.
 */
const BASELINE = JSON.parse(readFileSync(fileURLToPath(new URL('./foundations.json', import.meta.url)), 'utf8'));

const PROFILES = {
  vn_known_female: { birthDate: '1990-03-14', birthTime: '08:25', birthCountry: 'VN', traditionalProfile: 'female' },
  vn_unknown_unspecified: { birthDate: '1990-03-14', birthTime: null, birthCountry: 'VN', traditionalProfile: 'unspecified' },
  us_known_male: { birthDate: '1975-11-02', birthTime: '23:10', birthCountry: 'US', traditionalProfile: 'male' },
  in_known_female: { birthDate: '2001-07-19', birthTime: '05:45', birthCountry: 'IN', traditionalProfile: 'female' },
  np_known_male: { birthDate: '1988-01-31', birthTime: '12:00', birthCountry: 'NP', traditionalProfile: 'male' },
  au_unknown_female: { birthDate: '1964-09-30', birthTime: null, birthCountry: 'AU', traditionalProfile: 'female' },
  jp_known_unspecified: { birthDate: '1999-02-28', birthTime: '18:33', birthCountry: 'JP', traditionalProfile: 'unspecified' },
  br_known_male: { birthDate: '1982-06-05', birthTime: '03:05', birthCountry: 'BR', traditionalProfile: 'male' },
};

const CONTEXTS = {
  vn_autumn: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' },
  ny_dst_end: { instantUtc: '2026-11-01T05:30:00Z', deviceTimezone: 'America/New_York' },
  syd_dst_start: { instantUtc: '2026-10-03T16:30:00Z', deviceTimezone: 'Australia/Sydney' },
  kathmandu_quarter: { instantUtc: '2026-02-04T02:15:00Z', deviceTimezone: 'Asia/Kathmandu' },
};

const calculators = new Map();
const calculatorFor = key => {
  if (!calculators.has(key)) calculators.set(key, createCalculator(PROFILES[key]));
  return calculators.get(key);
};

test('the baseline covers every profile and context this test claims to check', () => {
  assert.deepEqual(Object.keys(BASELINE.profiles).sort(), Object.keys(PROFILES).sort());
  assert.ok(Object.keys(BASELINE.brief).length >= 24, 'the captured brief set looks truncated');
});

for (const key of Object.keys(PROFILES)) {
  test(`birth charts for ${key} are untouched by v9.1`, () => {
    assert.deepEqual(calculatorFor(key).inspectBirthCharts(), BASELINE.profiles[key]);
  });
}

for (const [key, expected] of Object.entries(BASELINE.brief)) {
  test(`the daily brief for ${key} is untouched by v9.1`, () => {
    const [profileKey, contextKey] = key.split('|');
    const reading = calculatorFor(profileKey).calculate({
      context: CONTEXTS[contextKey], mode: 'left_right', period: 'now', category: 'money',
    });
    assert.deepEqual(reading.dailyBrief, expected.dailyBrief);
    assert.deepEqual(reading.birthData, expected.birthData);
    assert.deepEqual(reading.warnings, expected.warnings);
    assert.deepEqual(reading.context, expected.context);
  });
}

test('the brief still ignores the mode, the period and the category', () => {
  const calculator = calculatorFor('vn_known_female');
  const context = CONTEXTS.vn_autumn;
  const reference = calculator.calculate({ context, mode: 'yes_no', period: 'now', category: 'general' }).dailyBrief;
  for (const mode of ['act_wait', 'commit_withdraw', 'left_right']) {
    for (const category of ['love', 'money', 'other']) {
      const reading = calculator.calculate({ context, mode, period: 'now', category });
      assert.deepEqual(reading.dailyBrief, reference, `${mode}/${category} moved the brief`);
    }
  }
});

test('daily energy is not reused as a bonus on top of the decision score', () => {
  // The energy index describes the whole local day and does not move with the
  // mode; a score that leaned on it would have to move with it. Two modes on
  // the same instant share the energy and must still differ, and the scoring
  // block must not name an energy term at all.
  const calculator = calculatorFor('vn_known_female');
  const context = CONTEXTS.vn_autumn;
  const first = calculator.calculate({ context, mode: 'yes_no', period: 'now', category: 'general' });
  const second = calculator.calculate({ context, mode: 'keep_let_go', period: 'now', category: 'general' });
  assert.deepEqual(first.dailyBrief.energy, second.dailyBrief.energy);
  assert.notEqual(first.modeScore, second.modeScore);
  for (const reading of [first, second]) {
    const names = Object.keys(reading.scoring.signals);
    assert.ok(!names.includes('E'), 'an energy signal appeared in the mixture');
    assert.ok(names.every(name => 'PCLTMRGHY'.includes(name)), `unexpected signal in ${names}`);
  }
});
