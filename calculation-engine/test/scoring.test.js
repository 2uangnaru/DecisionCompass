import assert from 'node:assert/strict';
import test from 'node:test';
import {
  SIGNALS, SCALES, SCALE_VERSION, SCORING_VERSION, MODE_SIGNALS,
  LUCK_BASELINE, MEDIAN_PUSH, DISPLAY_EXPONENT,
  prospect, changePressure, luck, alignment, release, polarity, parity,
  timing, momentum, grounding, horizon, median,
  normalizeSignal, normalizeAll, modeScore, adjustAgainstHistory,
  displayTenths, displayPercent, signalsNeededBy, readsOtherDates,
} from '../src/scoring.js';
import { evidence, moduleResult, WEIGHTS, weightsFor } from '../src/core.js';
import { createCalculator } from '../src/index.js';

/** A module map with every id present, so a test can vary one thing at a time. */
function modules(overrides = {}) {
  const base = {};
  for (const id of Object.keys(WEIGHTS)) base[id] = moduleResult(evidence(0, 0, 1));
  for (const [id, [a, c, coverage]] of Object.entries(overrides)) {
    base[id] = moduleResult(evidence(a, c, coverage));
  }
  // Numerology always reports the personal day; `Y` reads it.
  base.N = moduleResult(base.N.evidence, { personalDay: 4 });
  return base;
}

const GENERAL = weightsFor('general');

// ---------------------------------------------------------------------------

test('a missing chart pulls prospect toward zero instead of promoting the rest', () => {
  const all = prospect(modules({ B: [1, 0, 1], Z: [1, 0, 1], W: [1, 0, 1] }), GENERAL);
  assert.ok(Math.abs(all - 1) < 1e-12, 'full agreement at full coverage reads as 1');

  // Zi Wei absent. The denominator is still B + Z + W, so the answer drops.
  const partial = prospect(modules({ B: [1, 0, 1], Z: [0, 0, 0], W: [1, 0, 1] }), GENERAL);
  const share = (GENERAL.B + GENERAL.W) / (GENERAL.B + GENERAL.Z + GENERAL.W);
  assert.ok(Math.abs(partial - share) < 1e-12, `missing evidence was redistributed: ${partial}`);
  assert.ok(partial < all);

  // Half coverage on every module is half the evidence, not the same evidence.
  const thin = prospect(modules({ B: [1, 0, .5], Z: [1, 0, .5], W: [1, 0, .5] }), GENERAL);
  assert.ok(Math.abs(thin - .5) < 1e-12);
});

test('change pressure reads every module, weighted, with coverage applied once', () => {
  const only = changePressure(modules({ N: [0, 1, 1] }), GENERAL);
  assert.ok(Math.abs(only - GENERAL.N) < 1e-12);
  const half = changePressure(modules({ N: [0, 1, .5] }), GENERAL);
  assert.ok(Math.abs(half - GENERAL.N * .5) < 1e-12);
});

test('luck subtracts its baseline in proportion to the coverage behind it', () => {
  // An ordinary day — every luck source present and neutral — is slightly
  // negative, not zero, so "lucky" has to be earned.
  const ordinary = luck(modules({ T: [0, 0, 1], V: [0, 0, 1], N: [0, 0, 1] }));
  assert.ok(Math.abs(ordinary + LUCK_BASELINE) < 1e-12, `neutral day read ${ordinary}`);

  // With no luck sources at all the baseline is not charged either.
  const blank = luck(modules({ T: [0, 0, 0], V: [0, 0, 0], N: [0, 0, 0] }));
  assert.equal(blank, 0);
});

test('polarity is an explicit yin/yang convention on the engine indices', () => {
  assert.equal(parity(0), 1, 'stem index 0 is Jia, which is yang');
  assert.equal(parity(1), -1);
  assert.equal(parity(4), 1);

  const yang = polarity({ dayStem: 0, hourBranch: 0, personalDay: 2, ziWeiChange: 0, westernChange: 0, baZiChange: 0 });
  const yin = polarity({ dayStem: 1, hourBranch: 1, personalDay: 3, ziWeiChange: 0, westernChange: 0, baZiChange: 0 });
  assert.ok(Math.abs(yang - .5) < 1e-12);
  assert.ok(Math.abs(yin + .5) < 1e-12);
  assert.ok(yang > 0, 'positive Y selects LEFT, by stated convention');
});

test('release and alignment are the documented combinations', () => {
  assert.ok(Math.abs(alignment(1, 0) - .70) < 1e-12);
  assert.ok(Math.abs(alignment(0, 1) - .30) < 1e-12);
  assert.ok(Math.abs(release(1, 1, 1) - (.50 - .35 + .15)) < 1e-12);
});

// ---------------------------------------------------------------------------

test('the cross-day signals are zero rather than invented when a day is missing', () => {
  assert.equal(timing(.5, []), 0, 'nothing later left is no advantage, not a big one');
  assert.equal(momentum(.5, []), 0);
  assert.equal(grounding(.2, .1, null), grounding(.2, .1, .2), 'an unreachable horizon leaves the term at zero');
  assert.equal(median([]), 0);
});

test('timing saturates at the documented spread and keeps its sign', () => {
  assert.equal(timing(.4, [0]), 1, 'a 0.40 lead is the top of the scale');
  assert.equal(timing(-.4, [0]), -1);
  assert.equal(timing(.8, [0]), 1, 'clamped, never beyond');
  assert.ok(Math.abs(timing(.2, [0]) - .5) < 1e-12);
  // The mean, not the best, of what is left.
  assert.ok(Math.abs(timing(.2, [0, .2]) - .25) < 1e-12);
});

test('horizon uses medians, so one extraordinary day cannot carry a week', () => {
  const flat = Array.from({ length: 8 }, () => ({ p: .1, zSupport: .1, bSupport: .1 }));
  const spike = [...flat.slice(0, 7), { p: 1, zSupport: 1, bSupport: 1 }];
  assert.ok(Math.abs(horizon(flat) - horizon(spike)) < 1e-12, 'a single outlier moved the horizon');
  assert.ok(Math.abs(median([1, 2, 3, 4]) - 2.5) < 1e-12);
  assert.ok(Math.abs(median([3, 1, 2]) - 2) < 1e-12);
});

// ---------------------------------------------------------------------------

test('the scales are fixed constants, not something a reading can move', () => {
  assert.equal(typeof SCALE_VERSION, 'string');
  assert.ok(SCALE_VERSION.length > 0);
  assert.ok(Object.isFrozen(SCALES));
  for (const name of SIGNALS) {
    assert.ok(Number.isFinite(SCALES[name]) && SCALES[name] > 0, name);
  }
  // Normalization is a pure function of the raw value and that constant.
  const before = normalizeSignal('P', .2);
  for (let i = 0; i < 50; i++) normalizeSignal('P', Math.random());
  assert.equal(normalizeSignal('P', .2), before, 'normalization drifted with use');
  assert.throws(() => normalizeSignal('Q', 0), /UNKNOWN_SIGNAL/);
  assert.throws(() => normalizeSignal('P', NaN), /SIGNAL_NOT_FINITE/);
});

test('normalization never turns thin evidence into strong evidence', () => {
  // tanh is strictly increasing and odd, so a smaller raw signal is always a
  // smaller normalized one and coverage effects survive.
  let previous = -Infinity;
  for (const raw of [-1, -.5, -.1, -.01, 0, .01, .1, .5, 1]) {
    const value = normalizeSignal('P', raw);
    assert.ok(value > previous, `not increasing at ${raw}`);
    assert.ok(Math.abs(value) < 1, 'tanh never reaches its asymptote');
    previous = value;
  }
  assert.equal(normalizeSignal('P', 0), 0, 'no evidence is no lean');
  assert.ok(Math.abs(normalizeSignal('P', .05)) < Math.abs(normalizeSignal('P', .5)));
});

test('every mode mixes a normalized set that sums to one, and no two agree', () => {
  for (const [mode, mixture] of Object.entries(MODE_SIGNALS)) {
    const total = Object.values(mixture).reduce((s, w) => s + w, 0);
    assert.ok(Math.abs(total - 1) < 1e-9, `${mode} sums to ${total}`);
    assert.deepEqual(signalsNeededBy(mode), Object.keys(mixture));
  }
  const normalized = normalizeAll({ P: .18, C: -.22, L: .09, T: .31, M: -.14, R: .07, G: -.05, H: .12, Y: .44 });
  const scores = Object.keys(MODE_SIGNALS).map(mode => modeScore(mode, normalized));
  assert.equal(new Set(scores).size, scores.length, 'two modes collapsed onto the same score');
  assert.throws(() => modeScore('yes_no', { P: 0, C: 0 }), /MISSING_SIGNAL/);
  assert.throws(() => modeScore('forward_backward', normalized), /INVALID_DECISION_MODE/);
});

test('only the modes that read other days pay for them', () => {
  assert.equal(readsOtherDates('yes_no'), false);
  assert.equal(readsOtherDates('keep_let_go'), false);
  assert.equal(readsOtherDates('left_right'), false);
  assert.equal(readsOtherDates('act_wait'), true);
  assert.equal(readsOtherDates('advance_retreat'), true);
  assert.equal(readsOtherDates('stay_go'), true);
  assert.equal(readsOtherDates('commit_withdraw'), true);
});

// ---------------------------------------------------------------------------

test('the fortnight push is a contrast, not a flip and not a floor', () => {
  // A day identical to its own fortnight is left exactly where it is.
  assert.equal(adjustAgainstHistory(.2, [.2, .2, .2]), .2);
  // With no history at all the adjustment is the identity.
  assert.equal(adjustAgainstHistory(.2, []), .2);
  // A day above its fortnight is pushed further from it, by half the gap.
  assert.ok(Math.abs(adjustAgainstHistory(.3, [.1]) - (.3 + MEDIAN_PUSH * .2)) < 1e-12);
  // A day below it is pushed the other way — the sign follows the day, never
  // an alternation rule.
  assert.ok(adjustAgainstHistory(-.3, [-.1]) < -.3);
  // It never leaves the band.
  assert.equal(adjustAgainstHistory(1, [-1]), 1);
  assert.equal(adjustAgainstHistory(-1, [1]), -1);
  // A quiet day against a loud fortnight still cannot be dragged past the
  // middle into the opposite verdict by the push alone.
  assert.ok(adjustAgainstHistory(.01, [0]) > 0, 'a positive day turned negative');
});

test('the display band is 10 to 90, one decimal, exact halves', () => {
  assert.equal(displayTenths(0), 500);
  assert.equal(displayTenths(1), 900);
  assert.equal(displayTenths(-1), 100);
  assert.equal(DISPLAY_EXPONENT, 0.55);
  for (const score of [-1, -.73, -.2, -.004, 0, .004, .2, .73, 1]) {
    const tenths = displayTenths(score);
    assert.ok(Number.isInteger(tenths), `not an integer number of tenths at ${score}`);
    assert.ok(tenths >= 100 && tenths <= 900);
    assert.equal(tenths + (1000 - tenths), 1000);
    assert.equal(displayTenths(-score), 1000 - tenths, `asymmetric at ${score}`);
  }
  assert.equal(displayPercent(0), 50);
  assert.equal(displayPercent(1), 90);
});

test('the display curve moves a modest score out of the fifties', () => {
  // The whole point of the flatter exponent: a real but small lean should be
  // legible. These are the curve's own values, not a target distribution.
  assert.ok(displayTenths(.05) >= 570, `0.05 showed ${displayTenths(.05) / 10}%`);
  assert.ok(displayTenths(.15) >= 630, `0.15 showed ${displayTenths(.15) / 10}%`);
  assert.ok(displayTenths(.40) >= 710, `0.40 showed ${displayTenths(.40) / 10}%`);
  // And an 80%+ result is reachable without being a target.
  assert.ok(displayTenths(.70) >= 800, `0.70 showed ${displayTenths(.70) / 10}%`);
});

// ---------------------------------------------------------------------------

test('the reading reports signals that reproduce its own score', () => {
  const engine = createCalculator({
    birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male',
  });
  const context = { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' };

  for (const mode of Object.keys(MODE_SIGNALS)) {
    const reading = engine.calculate({ context, mode, period: 'now', category: 'general' });
    const scoring = reading.scoring;
    assert.equal(scoring.system, SCORING_VERSION);
    assert.equal(scoring.scaleVersion, SCALE_VERSION);
    assert.deepEqual(Object.keys(scoring.signals).sort(), signalsNeededBy(mode).sort(),
      `${mode} reported signals it does not mix, or hid ones it does`);

    const remixed = modeScore(mode, scoring.normalized);
    assert.ok(Math.abs(remixed - scoring.rawModeScore) < 1e-9,
      `${mode}: rawModeScore is not the mixture of its own signals`);
    const pushed = adjustAgainstHistory(scoring.rawModeScore, [scoring.priorMedian]);
    assert.ok(Math.abs(pushed - scoring.adjustedModeScore) < 1e-9,
      `${mode}: adjustedModeScore is not the push from the reported median`);
    assert.ok(Math.abs(reading.modeScore - scoring.adjustedModeScore) < 1e-9);
    assert.equal(Math.round(reading.percentages[Object.keys(reading.percentages)[0]] * 10),
      displayTenths(reading.modeScore));
    assert.ok(scoring.priorDatesUsed >= 13, `only ${scoring.priorDatesUsed} of the previous fourteen dates were readable`);
  }
});

test('COMMIT/WITHDRAW does not reverse direction every day', () => {
  const engine = createCalculator({
    birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male',
  });
  const winners = [];
  for (let day = 14; day <= 27; day++) {
    winners.push(engine.calculate({
      context: { instantUtc: new Date(Date.UTC(2026, 8, day, 3, 0, 0)).toISOString(), deviceTimezone: 'Asia/Ho_Chi_Minh' },
      mode: 'commit_withdraw', period: 'now', category: 'general',
    }).winner);
  }
  let alternations = 0;
  for (let i = 1; i < winners.length; i++) if (winners[i] !== winners[i - 1]) alternations++;
  assert.ok(alternations < winners.length - 1,
    `the horizon mode flipped on every one of ${winners.length} consecutive days`);
});

test('a reading is reproducible from its inputs alone, with no hidden state', () => {
  const profile = { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male' };
  const context = { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' };
  const first = createCalculator(profile).calculate({ context, mode: 'act_wait', period: 'now' });

  // A different calculator, after a different history of calls, must agree.
  const other = createCalculator(profile);
  other.calculate({ context, mode: 'left_right', period: 'evening', category: 'love' });
  other.calculate({ context: { ...context, instantUtc: '2026-09-11T08:30:00Z' }, mode: 'stay_go' });
  const again = other.calculate({ context, mode: 'act_wait', period: 'now' });
  assert.deepEqual(again, first);
});

test('a local date whose anchor hour does not exist is dropped, not approximated', () => {
  // Pacific/Chatham springs forward 02:45 -> 03:45 on 2026-09-27, so 03:00
  // never happens there that day. A reading anchored at 03:00 a week later
  // reaches that date in its fortnight and must leave it out rather than
  // sliding to a neighbouring hour and calling it the same time of day.
  const engine = createCalculator({
    birthDate: '1990-03-14', birthTime: '08:25', birthCountry: 'NZ', traditionalProfile: 'female',
  });
  const reading = engine.calculate({
    context: { instantUtc: '2026-10-04T14:00:00Z', deviceTimezone: 'Pacific/Chatham' },
    mode: 'yes_no', period: 'now', category: 'general',
  });
  assert.equal(reading.scoring.anchorLocal, '2026-10-05T03:00');
  assert.equal(reading.scoring.priorDatesUsed, 13, 'the skipped date was not dropped');
  assert.equal(reading.status, 'ready', 'a missing comparison date must not break the reading');
  assert.ok(reading.scoring.priorMedian !== null);

  // And it is deterministic: the same inputs give the same answer.
  const again = createCalculator({
    birthDate: '1990-03-14', birthTime: '08:25', birthCountry: 'NZ', traditionalProfile: 'female',
  }).calculate({
    context: { instantUtc: '2026-10-04T14:00:00Z', deviceTimezone: 'Pacific/Chatham' },
    mode: 'yes_no', period: 'now', category: 'general',
  });
  assert.deepEqual(again, reading);
});

test('an elapsed period still refuses to score, and says so', () => {
  const engine = createCalculator({
    birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male',
  });
  const reading = engine.calculate({
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' },
    mode: 'act_wait', period: 'morning', category: 'general',
  });
  assert.equal(reading.status, 'period_elapsed');
  assert.equal(reading.percentages, null);
  assert.equal(reading.winner, null);
  assert.equal(reading.scoring, undefined, 'an elapsed period must not report a score it did not compute');
  assert.deepEqual(reading.luckyWindows, []);
});

// ---------------------------------------------------------------------------
// Lucky windows
// ---------------------------------------------------------------------------

const WINDOW_PROFILE = {
  birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male',
};
const WINDOW_CONTEXT = { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' };
const windowsFor = mode => createCalculator(WINDOW_PROFILE).calculate({
  context: WINDOW_CONTEXT, mode, period: 'evening', category: 'general',
});

test('a window is scored at its own moment, timing included', () => {
  const reading = windowsFor('act_wait');
  assert.ok(reading.luckyWindows.length >= 2, 'need two windows to compare');

  // Under the scoring this replaced, every window of a reading reused the
  // headline's timing signal, so the one thing ACT / WAIT is about could not
  // separate them. An evening reading is the sharpest case: no period starts
  // after 18:00, so the headline timing was exactly zero and stayed zero.
  assert.notEqual(reading.scoring.signals.T, 0,
    'an evening ACT/WAIT reading still has no timing signal');

  const scores = reading.luckyWindows.map(w => w.score);
  assert.equal(new Set(scores).size, scores.length,
    'the windows all scored the same, so timing is not reaching them');
});

test('a window ranking follows the mode, and timing is what moves it', () => {
  // YES / NO does not read timing at all; ACT / WAIT is mostly timing. Same
  // profile, same instant, same period, same candidate windows — so any
  // difference in the order is the timing signal doing it.
  const timed = windowsFor('act_wait');
  const untimed = windowsFor('yes_no');
  const order = reading => reading.luckyWindows.map(w => w.startLocal);
  assert.deepEqual(
    [...order(timed)].sort(), [...order(untimed)].sort(),
    'the two modes did not consider the same candidate slots',
  );
  assert.notDeepEqual(order(timed), order(untimed),
    'the timing signal did not change the ranking of the same slots');
});

test('a window score is the mode score for that slot, on the display curve', () => {
  for (const mode of ['act_wait', 'yes_no', 'commit_withdraw']) {
    const reading = windowsFor(mode);
    for (const window of reading.luckyWindows) {
      assert.ok(Number.isInteger(window.score), `${mode}: a window score gained a decimal`);
      assert.ok(window.score >= 10 && window.score <= 90, `${mode}: ${window.score} is outside the band`);
      assert.equal(window.meaning, 'symbolic_timing_score_not_probability');
    }
    // Ranked by score, ties broken by the earlier slot.
    const scores = reading.luckyWindows.map(w => w.score);
    assert.deepEqual(scores, [...scores].sort((a, b) => b - a), `${mode}: windows are not ranked`);
  }
});

// ---------------------------------------------------------------------------
// Cache identity
// ---------------------------------------------------------------------------

test('the requested signal set is part of the score cache identity', () => {
  const normalThenProbe = createCalculator(WINDOW_PROFILE);
  const normalFirst = normalThenProbe.calculate({ context: WINDOW_CONTEXT, mode: 'yes_no', period: 'now' });
  const probeSecond = normalThenProbe.calculate({ context: WINDOW_CONTEXT, mode: 'yes_no', period: 'now', probeAllSignals: true });

  const probeThenNormal = createCalculator(WINDOW_PROFILE);
  const probeFirst = probeThenNormal.calculate({ context: WINDOW_CONTEXT, mode: 'yes_no', period: 'now', probeAllSignals: true });
  const normalSecond = probeThenNormal.calculate({ context: WINDOW_CONTEXT, mode: 'yes_no', period: 'now' });

  // A probe asks for all nine whichever call came first.
  assert.deepEqual(Object.keys(probeSecond.scoring.signals).sort(), [...SIGNALS].sort());
  assert.deepEqual(Object.keys(probeFirst.scoring.signals).sort(), [...SIGNALS].sort());
  // And a normal reading reports only the three YES / NO mixes, either way.
  assert.deepEqual(Object.keys(normalFirst.scoring.signals).sort(), ['C', 'L', 'P']);
  assert.deepEqual(Object.keys(normalSecond.scoring.signals).sort(), ['C', 'L', 'P']);

  // The call order must not touch the reading itself.
  assert.deepEqual(normalSecond, normalFirst);
  assert.equal(probeSecond.modeScore, normalFirst.modeScore);
});
