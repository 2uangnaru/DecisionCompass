import test from 'node:test';
import assert from 'node:assert/strict';
import { dailyEnergy } from '../src/daily-energy.js';
import { calculate } from '../src/index.js';

test('daily energy averages actual segment durations and has honest cutoffs', () => {
  const segment = (hours, a, c, coverage = 1) => ({
    start: 0, end: hours * 3600000, evidence: { a, c, coverage },
  });
  assert.deepEqual(dailyEnergy([segment(12, 0, 0), segment(12, 0, 0)]),
    { level: 'steady', index: 50, dataCoverage: 1 });
  assert.equal(dailyEnergy([segment(24, -.05, 0)]).level, 'soft');
  assert.equal(dailyEnergy([segment(24, .08, 0)]).level, 'steady');
  assert.equal(dailyEnergy([segment(24, .115, 0)]).level, 'bright');
  assert.equal(dailyEnergy([segment(3, 1, 0), segment(21, -1, 0)]).level, 'soft');
  assert.equal(dailyEnergy([segment(21, 1, 0), segment(3, -1, 0)]).level, 'bright');
  assert.deepEqual(dailyEnergy([segment(23, 1, 0, 0)]),
    { level: 'unavailable', index: null, dataCoverage: 0 });
});

test('daily energy is fixed for one local day across moment, mode, category and period', () => {
  const profile = { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male' };
  const context = instantUtc => ({ instantUtc, deviceTimezone: 'Asia/Ho_Chi_Minh' });
  const morning = calculate({ profile, context: context('2026-09-18T02:00:00Z'), mode: 'yes_no', period: 'now', category: 'general' });
  const evening = calculate({ profile, context: context('2026-09-18T13:00:00Z'), mode: 'left_right', period: 'evening', category: 'love' });
  assert.deepEqual(morning.dailyBrief.energy, evening.dailyBrief.energy);
  assert.ok(['soft', 'steady', 'bright'].includes(morning.dailyBrief.energy.level));
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
