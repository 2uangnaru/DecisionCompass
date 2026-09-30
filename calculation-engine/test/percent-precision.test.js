import assert from 'node:assert/strict';
import test from 'node:test';
import { MODES } from '../src/core.js';
import { displayPercent, displayTenths } from '../src/scoring.js';
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
    assert.equal(Math.round(displayTenths(score) / 10), Math.round(displayPercent(score)),
      `tenths and percent disagree at ${score}`);
  }
  assert.equal(displayTenths(0), 500);
  assert.equal(displayTenths(1), 900);
  assert.equal(displayTenths(-1), 100);
  // Clamped, never beyond the 10–90 band.
  assert.equal(displayTenths(5), 900);
  assert.equal(displayTenths(-5), 100);
  // The v9.1 curve is flatter than the one it replaced, so a modest score is
  // allowed to leave the 50s instead of being crushed against the middle.
  assert.ok(displayTenths(.25) > 680, `a quarter-scale lean showed ${displayTenths(.25) / 10}%`);
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

test('consecutive days are told apart at one decimal', () => {
  const days = [22, 23, 24].map(day => readingOn(day));
  const scores = days.map(r => r.modeScore);
  assert.equal(new Set(scores).size, 3, 'the raw scores were already distinct');
  const shown = days.map(r => r.percentages.YES);
  assert.equal(new Set(shown).size, 3, 'tenths must tell them apart');
  // Deliberately not asserting particular percentages: the scoring system is
  // experimental, and pinning the numbers here would turn a calibration change
  // into a test failure instead of a reported difference.
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
  // Two scores a millionth apart legitimately share a tenth. The engine must
  // not manufacture a difference to avoid looking stale.
  assert.equal(displayTenths(.05000), displayTenths(.0500001));
  // A score of exactly zero is 50.0/50.0 and is reported as balanced, not
  // nudged off the middle.
  assert.equal(displayTenths(0), 500);
});

test('every mode keeps its own projection at one decimal', () => {
  const byMode = new Map();
  for (const mode of Object.keys(MODES)) byMode.set(mode, readingOn(20, mode).modeScore);
  // COMMIT/WITHDRAW and LEFT/RIGHT must not be aliases of YES/NO.
  assert.notEqual(byMode.get('commit_withdraw'), byMode.get('yes_no'));
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
