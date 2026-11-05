import test from 'node:test';
import assert from 'node:assert/strict';
import { dailyEnergy, ENERGY_CUTOFFS } from '../src/daily-energy.js';
import { calculate } from '../src/index.js';

test('daily energy averages actual segment durations and keeps low-coverage days unavailable', () => {
  const segment = (hours, a, c, coverage = 1) => ({
    start: 0, end: hours * 3600000, evidence: { a, c, coverage },
  });
  assert.deepEqual(dailyEnergy([segment(12, .02, .02), segment(12, .02, .02)]),
    { level: 'steady', index: 51, dataCoverage: 1 });
  assert.equal(dailyEnergy([segment(3, 1, 1), segment(21, -1, -1)]).level, 'quiet');
  assert.equal(dailyEnergy([segment(21, 1, 1), segment(3, -1, -1)]).level, 'radiant');
  assert.deepEqual(dailyEnergy([segment(23, 1, 0, 0)]),
    { level: 'unavailable', index: null, dataCoverage: 0 });
});

test('six intensity tones and two axis-led tones distinguish days without changing the index', () => {
  const tone = (a, c) => dailyEnergy([{
    start: 0, end: 86400000, evidence: { a, c, coverage: 1 },
  }]);
  assert.equal(tone(-.03, -.03).level, 'quiet');
  assert.equal(tone(0, 0).level, 'soft');
  assert.equal(tone(.02, .02).level, 'steady');
  assert.equal(tone(.05, .05).level, 'lively');
  assert.equal(tone(.08, .08).level, 'bright');
  assert.equal(tone(.12, .12).level, 'radiant');

  // Same 0.05 projection, so the same index; only the lead differs.
  const lively = tone(.05, .05);
  const focused = tone(.05 + .35 * .1, .05 - .65 * .1);
  const flowing = tone(.05 - .35 * .08, .05 + .65 * .08);
  assert.deepEqual([lively.index, focused.index, flowing.index], [52, 52, 52]);
  assert.equal(focused.level, 'focused');
  assert.equal(flowing.level, 'flowing');
  // A lead below the cutoff is not axis-led.
  assert.equal(tone(.05 + .35 * .08, .05 - .65 * .08).level, 'lively');
  // An axis that leads only because the other is lower is not leading.
  assert.equal(tone(-.2, -.35).level, 'quiet');
  assert.equal(tone(-.2, 0).level, 'quiet');
});

test('band starts are ordered and every band is reachable at its own start', () => {
  const { bands } = ENERGY_CUTOFFS;
  assert.deepEqual([...bands].sort((x, y) => x - y), [...bands]);
  const tone = p => dailyEnergy([{ start: 0, end: 86400000, evidence: { a: p, c: p, coverage: 1 } }]).level;
  assert.deepEqual([bands[0] - .001, ...bands].map(tone), ['quiet', 'soft', 'steady', 'lively', 'bright', 'radiant']);
});

test('daily energy is fixed for one local day across moment, mode, category and period', () => {
  const profile = { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male' };
  const context = instantUtc => ({ instantUtc, deviceTimezone: 'Asia/Ho_Chi_Minh' });
  const morning = calculate({ profile, context: context('2026-09-18T02:00:00Z'), mode: 'yes_no', period: 'now', category: 'general' });
  const evening = calculate({ profile, context: context('2026-09-18T13:00:00Z'), mode: 'left_right', period: 'evening', category: 'love' });
  assert.deepEqual(morning.dailyBrief.energy, evening.dailyBrief.energy);
  assert.ok(['quiet', 'soft', 'steady', 'lively', 'bright', 'radiant', 'focused', 'flowing'].includes(morning.dailyBrief.energy.level));
  assert.ok(morning.dailyBrief.energy.index >= 10 && morning.dailyBrief.energy.index <= 90);
  assert.ok(morning.dailyBrief.energy.dataCoverage > 0);
});

test('elapsed period does not fabricate a daily brief', () => {
  const result = calculate({
    profile: { birthDate: '1998-06-21', birthCountry: 'VN' },
    context: { instantUtc: '2026-09-18T16:00:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' },
    period: 'morning',
  });
  assert.equal(result.status, 'period_elapsed');
  assert.equal(Object.hasOwn(result, 'dailyBrief'), false);
});
