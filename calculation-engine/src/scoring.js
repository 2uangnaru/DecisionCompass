// The v9.1 experimental symbolic scoring system.
//
// The engine's older scoring projected one fused pair of axes onto seven fixed
// lines, so every mode read the same instant from a slightly different angle
// and the results clustered near the middle. v9.1 instead extracts nine named
// signals, several of which look at other days, and gives each mode its own
// mixture of them. A mode that is about durability now actually reads a
// seven-day horizon; a mode that is about momentum actually compares today
// with the last three days.
//
// Everything here is deterministic: no random value, no daily alternation, no
// minimum percentage and no per-user learning. The normalization scales are
// fixed constants produced once, offline, by `scripts/calibrate-v91.mjs`.
//
// A percentage produced here is symbolic alignment. It is not the probability
// that a real-world decision will succeed, and nothing in this file should be
// read as a claim that it is.

import { clamp } from './core.js';

/** Identifies the scoring system itself, independently of the engine build. */
export const SCORING_VERSION = 'v9.2-experimental';

/**
 * The nine signals, in a fixed order so that diagnostics, tests and the Dart
 * port all agree on it.
 *
 * - `P` prospect: how supportive the personal chart modules read right now.
 * - `C` change pressure: how much the same modules push toward change.
 * - `L` luck: the moment's own auspiciousness, almanac-led.
 * - `T` timing: this moment measured against the rest of today.
 * - `M` momentum: today's change pressure against the last three days.
 * - `R` release: support minus pressure, with Zi Wei given the casting vote.
 * - `G` grounding: staying power, penalised when the week ahead improves.
 * - `H` horizon: the durable middle of the coming week.
 * - `Y` polarity: an explicitly symbolic yin/yang convention.
 */
export const SIGNALS = Object.freeze(['P', 'C', 'L', 'T', 'M', 'R', 'G', 'H', 'Y']);

/** `P` reads only the three personal-chart modules. */
const PROSPECT_MODULES = Object.freeze(['B', 'Z', 'W']);

/** `L` reads the almanac, the Vedic transit and numerology, in that order. */
const LUCK_PARTS = Object.freeze([['T', 0.50], ['V', 0.30], ['N', 0.20]]);

/**
 * Subtracted from `L` in proportion to the coverage behind it.
 *
 * An average day should not read as lucky merely because the sources exist,
 * so the baseline is removed once, here. It is deliberately the only place a
 * luck baseline is applied: the old post-fusion subtraction would have counted
 * the same sources twice.
 */
export const LUCK_BASELINE = 0.05;

/** The spread, in raw `Q` units, that saturates the timing signal. */
const TIMING_SPREAD = 0.40;

/** How far the fourteen-day median pushes today away from itself. */
export const MEDIAN_PUSH = 0.5;

/** The display curve's exponent: flatter than the old 0.65, so a real lean shows. */
export const DISPLAY_EXPONENT = 0.55;

/**
 * Normalization scales, one per signal, each fixed at four times the 75th
 * percentile of that signal's absolute raw value across the calibration
 * cohort. See `scripts/calibrate-v91.mjs` and `CALIBRATION.md`.
 *
 * These are constants on purpose. Nothing at runtime may learn, tune or
 * per-user adjust them, or two readers would stop being comparable and a
 * reading would stop being reproducible from its saved snapshot.
 */
export const SCALE_VERSION = 'v9.2-cohort-2026-09-30';

// Measured by `node scripts/calibrate-v91.mjs --profiles 120 --seed 20260930`:
// 374 readings from 120 synthetic profiles across seven categories, four
// periods and twenty timezones, with roughly a third of the profiles having no
// birth hour. Reproduce with that exact command.
//
// Only `T` moved between v9.1 and v9.2, because only `T` changed definition:
// it now compares against the rest of the selected period as well as the
// periods still ahead, so its median absolute value rose from 0.011 to 0.089.
// Under v9.1 an evening reading had nothing later to compare against at all
// and the signal was simply zero.

export const SCALES = Object.freeze({
  P: 0.1650744988,
  C: 0.3025025936,
  L: 0.7610000000,
  T: 0.5170646117,
  M: 0.3683472651,
  R: 0.1269505512,
  G: 0.1432921879,
  H: 0.1769609522,
  Y: 0.8748830544,
});

/**
 * Which signals each mode mixes, and in what proportion.
 *
 * The weights of each mode sum to one, and every mode names at least one
 * signal no other mode leans on as heavily — that separation is the point of
 * the system, and `test/scoring.test.js` asserts it.
 *
 * LEFT / RIGHT gained a personal share in v9.2. Under v9.1 it was `Y` alone,
 * which made it the only mode that read nothing about the person: two readers
 * on the same date with the same hour branch got the same polarity. It also
 * made it by far the most extreme mode, because `Y` carries half its weight on
 * three terms that are each exactly +1 or -1. It keeps the largest share, so
 * the polarity convention still decides it.
 */
export const MODE_SIGNALS = Object.freeze({
  yes_no: Object.freeze({ P: 0.45, C: 0.20, L: 0.35 }),
  act_wait: Object.freeze({ P: 0.30, C: 0.10, T: 0.30, L: 0.30 }),
  advance_retreat: Object.freeze({ P: 0.25, M: 0.60, L: 0.15 }),
  stay_go: Object.freeze({ G: 0.70, P: 0.20, L: 0.10 }),
  keep_let_go: Object.freeze({ R: 0.70, P: 0.20, L: 0.10 }),
  commit_withdraw: Object.freeze({ H: 0.80, P: 0.15, L: 0.05 }),
  left_right: Object.freeze({ Y: 0.70, P: 0.20, L: 0.10 }),
});

/**
 * What each mixture is divided by, so that the seven modes read on one scale.
 *
 * A weighted average of several roughly independent signals is narrower than
 * any one of them: with weights summing to one, the spread shrinks by
 * `sqrt(sum of w squared)`. Under v9.1 that made a four-signal mode
 * structurally milder than a one-signal mode, and the held-out simulation
 * showed it plainly — LEFT / RIGHT reached 80%+ on 24.6% of readings while
 * YES / NO never reached it at all. The percentage therefore meant something
 * different depending on which question had been asked.
 *
 * Dividing by that same `sqrt(sum of w squared)` restores a common footing. It
 * is derived from the weights alone — no cohort, no per-user value, nothing
 * fitted — and it is strictly positive, so it can never change which side a
 * mode names, only how far from the middle it reads.
 *
 * The cost is real and is recorded in `VERIFICATION.md`: a mixture that
 * averages away more of its evidence is no longer shown as correspondingly
 * less certain.
 */
export const MODE_GAIN = Object.freeze(Object.fromEntries(
  Object.entries(MODE_SIGNALS).map(([mode, mixture]) => {
    // Written as an explicit sum rather than `Math.hypot`, which the Dart port
    // has no equivalent of and which rounds differently.
    const squares = Object.values(mixture).reduce((sum, w) => sum + w * w, 0);
    return [mode, 1 / Math.sqrt(squares)];
  }),
));

// Validated once at load, exactly as the category profiles are: a mixture that
// does not sum to one would quietly rescale a whole mode.
for (const [mode, mixture] of Object.entries(MODE_SIGNALS)) {
  const names = Object.keys(mixture);
  if (names.some(name => !SIGNALS.includes(name))) throw new Error(`MODE_SIGNAL_UNKNOWN:${mode}`);
  if (!Object.values(mixture).every(w => Number.isFinite(w) && w > 0)) throw new Error(`MODE_SIGNAL_VALUE:${mode}`);
  if (Math.abs(Object.values(mixture).reduce((s, w) => s + w, 0) - 1) > 1e-9) {
    throw new Error(`MODE_SIGNAL_NOT_NORMALIZED:${mode}`);
  }
}
for (const signal of SIGNALS) {
  if (!Number.isFinite(SCALES[signal]) || SCALES[signal] <= 0) throw new Error(`SCALE_INVALID:${signal}`);
}

/** Which signals a mode needs, so a reading only pays for the days it reads. */
export function signalsNeededBy(mode) {
  const mixture = MODE_SIGNALS[mode];
  if (!mixture) throw new Error('INVALID_DECISION_MODE');
  return Object.keys(mixture);
}

/** True when scoring this mode has to look at dates other than the anchor's. */
export function readsOtherDates(mode) {
  return signalsNeededBy(mode).some(signal => signal === 'T' || signal === 'M' || signal === 'G' || signal === 'H');
}

// ---------------------------------------------------------------------------
// Signals that need only the anchor instant
// ---------------------------------------------------------------------------

const cov = (modules, id) => modules[id].evidence.coverage;
const axisA = (modules, id) => modules[id].evidence.a;
const axisC = (modules, id) => modules[id].evidence.c;

/**
 * `P` — prospect.
 *
 * The denominator is the sum of the three modules' *weights*, never the sum of
 * the weights that happened to have coverage. A missing chart therefore pulls
 * `P` toward zero instead of handing its share to the survivors, which is what
 * keeps thin evidence from reading as strong evidence.
 */
export function prospect(modules, weights) {
  let numerator = 0, denominator = 0;
  for (const id of PROSPECT_MODULES) {
    denominator += weights[id];
    numerator += weights[id] * cov(modules, id) * axisA(modules, id);
  }
  return denominator > 0 ? numerator / denominator : 0;
}

/** `C` — change pressure, across every module, coverage applied once. */
export function changePressure(modules, weights) {
  let sum = 0;
  for (const id of Object.keys(weights)) sum += weights[id] * cov(modules, id) * axisC(modules, id);
  return sum;
}

/** `L` — the moment's own auspiciousness, less the coverage-scaled baseline. */
export function luck(modules) {
  let sum = 0, base = 0;
  for (const [id, weight] of LUCK_PARTS) {
    sum += weight * cov(modules, id) * axisA(modules, id);
    base += weight * cov(modules, id);
  }
  return sum - LUCK_BASELINE * base;
}

/** `Q` — the blended alignment of one moment, used by `T` and by windows. */
export const alignment = (p, l) => 0.70 * p + 0.30 * l;

/** `R` — release: support, minus pressure, with Zi Wei casting the last vote. */
export const release = (p, c, ziWeiSupport) => 0.50 * p - 0.35 * c + 0.15 * ziWeiSupport;

/**
 * Even is yang (+1), odd is yin (−1), on the engine's own zero-based stem and
 * branch indices and on the one-based personal day.
 *
 * This is a stated symbolic convention, not a discovered fact, and positive
 * `Y` selects LEFT. It is never advice about traffic, driving, route-finding
 * or any physical direction.
 */
export const parity = n => (n % 2 === 0 ? 1 : -1);

/** `Y` — symbolic polarity. */
export function polarity({ dayStem, hourBranch, personalDay, ziWeiChange, westernChange, baZiChange }) {
  return 0.20 * parity(dayStem)
    + 0.15 * parity(hourBranch)
    + 0.15 * parity(personalDay)
    + 0.25 * ziWeiChange
    - 0.15 * westernChange
    + 0.10 * baZiChange;
}

/**
 * Every quantity one evaluated instant contributes, derived once and cached.
 *
 * `zSupport` and friends are the coverage-scaled module axes the cross-day
 * signals reuse, kept here so `H` never has to re-open a module result.
 */
export function momentSignals(modules, weights, calendar) {
  const p = prospect(modules, weights);
  const c = changePressure(modules, weights);
  const l = luck(modules);
  const zSupport = cov(modules, 'Z') * axisA(modules, 'Z');
  const bSupport = cov(modules, 'B') * axisA(modules, 'B');
  return {
    p, c, l,
    q: alignment(p, l),
    zSupport, bSupport,
    r: release(p, c, zSupport),
    y: polarity({
      dayStem: calendar.day.stem,
      hourBranch: calendar.hour.branch,
      personalDay: modules.N.diagnostics.personalDay,
      ziWeiChange: cov(modules, 'Z') * axisC(modules, 'Z'),
      westernChange: cov(modules, 'W') * axisC(modules, 'W'),
      baZiChange: cov(modules, 'B') * axisC(modules, 'B'),
    }),
  };
}

// ---------------------------------------------------------------------------
// Signals that read other moments
// ---------------------------------------------------------------------------

/**
 * `T` — where this moment sits against the rest of today.
 *
 * Positive means the chosen moment reads better than what is still to come,
 * which is what ACT is about. With nothing left in the day the signal is zero
 * rather than an invented advantage.
 */
export function timing(selectedQ, laterQs) {
  if (!laterQs.length) return 0;
  const mean = laterQs.reduce((s, x) => s + x, 0) / laterQs.length;
  return clamp((selectedQ - mean) / TIMING_SPREAD);
}

/**
 * `M` — today's change pressure against the previous three local dates.
 *
 * Dates whose equivalent local time does not exist — the hour a spring-forward
 * transition skips — are left out rather than approximated. With none of the
 * three available the signal is zero.
 */
export function momentum(todayC, priorCs) {
  if (!priorCs.length) return 0;
  return todayC - priorCs.reduce((s, x) => s + x, 0) / priorCs.length;
}

/**
 * `G` — grounding.
 *
 * Support minus pressure, then penalised by however much better the far end of
 * the week looks: if next week reads stronger than today, staying put is worth
 * less. An unavailable horizon date makes the third term zero, not negative.
 */
export function grounding(p, c, horizonEndP) {
  return 0.35 * p - 0.45 * c - 0.20 * ((horizonEndP ?? p) - p);
}

/** The middle value; the mean of the two middles for an even count. */
export function median(values) {
  if (!values.length) return 0;
  const sorted = [...values].sort((x, y) => x - y);
  const mid = sorted.length >> 1;
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

/**
 * `H` — the durable middle of today plus the seven days after it.
 *
 * Medians rather than means on purpose: one extraordinary day should not carry
 * a week, which is also why COMMIT/WITHDRAW does not flip direction daily.
 */
export function horizon(series) {
  return 0.50 * median(series.map(x => x.p))
    + 0.30 * median(series.map(x => x.zSupport))
    + 0.20 * median(series.map(x => x.bSupport));
}

// ---------------------------------------------------------------------------
// Normalization, mode score and display
// ---------------------------------------------------------------------------

/** `tanh(raw / scale)` against the fixed, versioned scale for that signal. */
export function normalizeSignal(name, raw) {
  const scale = SCALES[name];
  if (scale === undefined) throw new Error(`UNKNOWN_SIGNAL:${name}`);
  if (!Number.isFinite(raw)) throw new Error(`SIGNAL_NOT_FINITE:${name}`);
  return Math.tanh(raw / scale);
}

/** Every named raw signal, normalized. */
export function normalizeAll(raw) {
  const out = {};
  for (const [name, value] of Object.entries(raw)) out[name] = normalizeSignal(name, value);
  return out;
}

/**
 * The first option's raw score for one mode, from normalized signals.
 *
 * Raw here means "before the fourteen-day median adjustment"; it is the value
 * the prior dates contribute to that median.
 */
export function modeScore(mode, normalized) {
  const mixture = MODE_SIGNALS[mode];
  if (!mixture) throw new Error('INVALID_DECISION_MODE');
  let score = 0;
  for (const [name, weight] of Object.entries(mixture)) {
    const value = normalized[name];
    if (value === undefined) throw new Error(`MISSING_SIGNAL:${mode}:${name}`);
    score += weight * value;
  }
  return clamp(score * MODE_GAIN[mode]);
}

/**
 * Push today away from its own fortnight.
 *
 * A day that reads like every other day of the last two weeks stays where it
 * is; a day that genuinely departs from them is allowed to say so. This is a
 * contrast term, not a guaranteed flip and not a minimum.
 */
export function adjustAgainstHistory(todayScore, prior14) {
  if (!prior14.length) return clamp(todayScore);
  return clamp(todayScore + MEDIAN_PUSH * (todayScore - median(prior14)));
}

/**
 * The display band, in tenths of a percent so the pair sums to exactly 100.0.
 *
 * `50 + 40 · sign(s) · |s|^0.55`, so a full-scale score shows 90.0 / 10.0 and
 * a genuinely neutral one shows 50.0 / 50.0.
 */
export function displayTenths(score) {
  const s = clamp(score);
  const sign = s < 0 ? -1 : s > 0 ? 1 : 0;
  return Math.floor(500 + 400 * clamp(sign * Math.pow(Math.abs(s), DISPLAY_EXPONENT)) + 0.5);
}

/** The same band as a whole percent, used where a window shows one number. */
export function displayPercent(score) {
  return Math.round(displayTenths(score) / 10);
}
