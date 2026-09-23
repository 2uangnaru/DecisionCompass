import test from 'node:test';
import assert from 'node:assert/strict';
import { dailyEnergy } from '../src/daily-energy.js';
import { calculate } from '../src/index.js';

test('daily energy averages actual segment durations and keeps low-coverage days unavailable', () => {
  const segment = (hours, a, c, coverage = 1) => ({
    start: 0, end: hours * 3600000, evidence: { a, c, coverage },
  });
  assert.deepEqual(dailyEnergy([segment(12, 0, 0), segment(12, 0, 0)]),
    { level: 'steady', index: 50, dataCoverage: 1 });
  assert.equal(dailyEnergy([segment(3, 1, 1), segment(21, -1, -1)]).level, 'quiet');
  assert.equal(dailyEnergy([segment(21, 1, 1), segment(3, -1, -1)]).level, 'radiant');
  assert.deepEqual(dailyEnergy([segment(23, 1, 0, 0)]),
    { level: 'unavailable', index: null, dataCoverage: 0 });
});

test('six intensity tones and two axis-led tones distinguish days without changing the index', () => {
  const tone = (a, c) => dailyEnergy([{
    start: 0, end: 86400000, evidence: { a, c, coverage: 1 },
  }]);
  assert.equal(tone(-.05, -.05).level, 'quiet');
  assert.equal(tone(-.02, -.02).level, 'soft');
  assert.equal(tone(0, 0).level, 'steady');
  assert.equal(tone(.06, .06).level, 'lively');
  assert.equal(tone(.11, .11).level, 'bright');
  assert.equal(tone(.2, .2).level, 'radiant');

  const lively = tone(.075, .075);
  const focused = tone(.12, 0);
  const flowing = tone(0, .223);
  assert.equal(lively.index, 53);
  assert.equal(focused.index, 53);
  assert.equal(flowing.index, 53);
  assert.equal(focused.level, 'focused');
  assert.equal(flowing.level, 'flowing');
  assert.equal(tone(-.2, 0).level, 'quiet');
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
