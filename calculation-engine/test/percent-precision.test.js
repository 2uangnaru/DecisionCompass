import assert from 'node:assert/strict';
import test from 'node:test';
import { MODES, percent, percentTenths, scoreForMode } from '../src/core.js';
import { createCalculator } from '../src/index.js';

const PROFILE = { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'US', traditionalProfile: 'unspecified' };
const ZONE = 'Asia/Ho_Chi_Minh';
const engine = createCalculator(PROFILE);

const readingOn = (day, mode = 'yes_no') => engine.calculate({
  context: { instantUtc: new Date(Date.UTC(2026, 8, day, 3, 0, 0)).toISOString(), deviceTimezone: ZONE },
  mode, period: 'now', category: 'general',
});

test('tenths follow the same projection as whole percent', () => {
  for (const score of [-1, -.5, -.0125, 0, .0125, .25, .5, 1]) {
    assert.equal(Math.round(percentTenths(score) / 10), Math.round(percent(score)),
      `tenths and percent disagree at ${score}`);
  }
  assert.equal(percentTenths(0), 500);
  assert.equal(percentTenths(1), 900);
  assert.equal(percentTenths(-1), 100);
  // Clamped, never beyond the 10–90 band.
  assert.equal(percentTenths(5), 900);
  assert.equal(percentTenths(-5), 100);
});

test('the two sides always add to exactly 100.0', () => {
  for (let day = 18; day <= 30; day++) {
    for (const mode of Object.keys(MODES)) {
      const reading = readingOn(day, mode);
      if (!reading.percentages) continue;
      const values = Object.values(reading.percentages);
      assert.equal(values.length, 2);
      // Built from one integer of tenths, so the pair is exact.
      const tenths = values.map(v => Math.round(v * 10));
      assert.equal(tenths[0] + tenths[1], 1000, `${day} ${mode}`);
      for (const value of values) {
        assert.equal(Math.round(value * 10) / 10, value, 'more than one decimal');
        assert.ok(value >= 10 && value <= 90);
      }
    }
  }
});

test('tenths separate consecutive days that whole percent collapsed', () => {
  // 22–24 September 2026 scored .0565, .0599 and .0548 for this profile:
  // three different readings that all floored to 52.
  const days = [22, 23, 24].map(day => readingOn(day));
  const scores = days.map(r => r.modeScore);
  assert.equal(new Set(scores).size, 3, 'the raw scores were already distinct');
  assert.deepEqual(days.map(r => percent(r.modeScore)), [52, 52, 52],
    'whole percent is why they looked stale');
  const shown = days.map(r => r.percentages.YES);
  assert.equal(new Set(shown).size, 3, 'tenths must tell them apart');
});

test('raw evidence genuinely moves from day to day', () => {
  const rows = [];
  for (let day = 18; day <= 30; day++) rows.push(readingOn(day));
  for (let i = 1; i < rows.length; i++) {
    assert.notEqual(rows[i].modeScore, rows[i - 1].modeScore, `day ${17 + i} repeated a score`);
    assert.notEqual(rows[i].readingKey, rows[i - 1].readingKey);
  }
});

test('a genuine tie is still reported honestly', () => {
  // Two scores a ten-thousandth apart legitimately share a tenth. The engine
  // must not manufacture a difference to avoid looking stale.
  assert.equal(percentTenths(.05000), percentTenths(.050001));
  const balanced = { a: 0, c: 0, coverage: 1 };
  assert.equal(percentTenths(scoreForMode(balanced, 'yes_no')), 500);
});

test('every mode keeps its own projection at one decimal', () => {
  const byMode = new Map();
  for (const mode of Object.keys(MODES)) byMode.set(mode, readingOn(20, mode).modeScore);
  // FORWARD/BACKWARD and LEFT/RIGHT must not be aliases of YES/NO.
  assert.notEqual(byMode.get('forward_backward'), byMode.get('yes_no'));
  assert.notEqual(byMode.get('left_right'), byMode.get('yes_no'));
  assert.notEqual(byMode.get('stay_go'), byMode.get('yes_no'));
});

test('lucky windows deliberately stay at whole percent', () => {
  const reading = engine.calculate({
    context: { instantUtc: '2026-09-18T03:00:00.000Z', deviceTimezone: ZONE },
    mode: 'yes_no', period: 'evening', category: 'general',
  });
  for (const window of reading.luckyWindows) {
    assert.ok(Number.isInteger(window.score), 'a window score gained a decimal');
  }
});
