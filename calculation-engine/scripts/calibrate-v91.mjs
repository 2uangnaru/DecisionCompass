// Offline calibration of the v9.1 normalization scales.
//
//   node scripts/calibrate-v91.mjs [--profiles 160] [--seed 20260930]
//
// Each signal gets one scale, fixed at four times the 75th percentile of its
// absolute raw value across a synthetic calibration cohort. Four times the
// upper quartile puts an ordinary day well inside tanh's straight section and
// still leaves an unusual day somewhere to go, without any signal saturating
// so early that every reader looks extreme.
//
// The output is a constant block for `src/scoring.js`. Paste it, do not import
// it: nothing at runtime may recompute or adjust these, or two readers would
// stop being comparable and a saved reading would stop reproducing.
//
// A second, disjoint held-out cohort is then measured against the chosen
// scales and reported. The held-out numbers are evidence about the scales;
// they are not a target, and this script never tunes anything to hit them.

import { createCalculator } from '../src/index.js';
import { SIGNALS, SCALES } from '../src/scoring.js';
import { cohort, percentile } from './cohort.mjs';

const arg = (name, fallback) => {
  const at = process.argv.indexOf(`--${name}`);
  return at > -1 ? Number(process.argv[at + 1]) : fallback;
};

const PROFILES = arg('profiles', 160);
const SEED = arg('seed', 20260930);
const HELD_OUT_SEED = SEED + 7919;

/** Collects every raw signal value the cohort produces, per signal name. */
function sample(seed, size, label) {
  const samples = Object.fromEntries(SIGNALS.map(name => [name, []]));
  let readings = 0, elapsed = 0, failures = 0;
  const started = Date.now();
  for (const entry of cohort(seed, size)) {
    let calculator;
    try {
      calculator = createCalculator(entry.profile);
    } catch {
      failures++;
      continue;
    }
    // One mode is enough for the raw signals — `probeAllSignals` computes all
    // nine regardless of which mode asked — but every category and period is
    // walked, because both change the weights and the anchor.
    for (const period of ['now', 'morning', 'afternoon', 'evening']) {
      try {
        const reading = calculator.calculate({
          context: entry.context, mode: 'yes_no', period,
          category: entry.category, probeAllSignals: true,
        });
        if (reading.status === 'period_elapsed') { elapsed++; continue; }
        readings++;
        for (const name of SIGNALS) samples[name].push(reading.scoring.signals[name]);
      } catch {
        failures++;
      }
    }
  }
  console.log(`${label}: ${readings} readings from ${size} profiles (${elapsed} elapsed periods, ${failures} rejected) in ${((Date.now() - started) / 1000).toFixed(1)}s`);
  return samples;
}

const calibration = sample(SEED, PROFILES, 'calibration cohort');

const scales = {};
console.log('\nsignal      n      p50|raw|    p75|raw|    p95|raw|    max|raw|    scale = 4 x p75');
for (const name of SIGNALS) {
  const absolute = calibration[name].map(Math.abs);
  const p75 = percentile(absolute, 0.75);
  // A signal that is flat across the whole cohort would divide by zero; a
  // floor keeps the scale finite and the normalization honest about it.
  scales[name] = Math.max(4 * p75, 1e-6);
  console.log(
    `${name.padEnd(6)} ${String(absolute.length).padEnd(7)}`
    + `${percentile(absolute, 0.50).toFixed(6).padStart(10)}  `
    + `${p75.toFixed(6).padStart(10)}  `
    + `${percentile(absolute, 0.95).toFixed(6).padStart(10)}  `
    + `${Math.max(...absolute).toFixed(6).padStart(10)}  `
    + `${scales[name].toFixed(10).padStart(14)}`
  );
}

console.log('\n--- paste into src/scoring.js ---');
console.log('export const SCALES = Object.freeze({');
for (const name of SIGNALS) console.log(`  ${name}: ${scales[name].toFixed(10)},`);
console.log('});');

// --- held-out assessment ---------------------------------------------------
const heldOut = sample(HELD_OUT_SEED, Math.max(24, Math.round(PROFILES / 2)), '\nheld-out cohort');

console.log('\nHeld-out assessment against the scales above.');
console.log('"saturated" is |tanh(raw/scale)| > 0.95 — a signal that can no longer tell two days apart.');
console.log('\nsignal   p75|raw|   |tanh| p50   |tanh| p95   saturated   in +/-0.25');
for (const name of SIGNALS) {
  const scale = scales[name];
  const absolute = heldOut[name].map(Math.abs);
  const normalized = absolute.map(x => Math.abs(Math.tanh(x / scale)));
  const saturated = normalized.filter(x => x > 0.95).length;
  const flat = normalized.filter(x => x < 0.25).length;
  console.log(
    `${name.padEnd(8)} ${percentile(absolute, 0.75).toFixed(6).padStart(9)}`
    + `${percentile(normalized, 0.50).toFixed(4).padStart(13)}`
    + `${percentile(normalized, 0.95).toFixed(4).padStart(13)}`
    + `${(saturated / normalized.length * 100).toFixed(1).padStart(10)}%`
    + `${(flat / normalized.length * 100).toFixed(1).padStart(11)}%`
  );
}

// --- drift against whatever is currently committed -------------------------
console.log('\nDrift from the scales currently in src/scoring.js:');
let drifted = false;
for (const name of SIGNALS) {
  const ratio = scales[name] / SCALES[name];
  if (Math.abs(ratio - 1) > 0.02) {
    drifted = true;
    console.log(`  ${name}: committed ${SCALES[name].toFixed(10)} -> cohort ${scales[name].toFixed(10)} (x${ratio.toFixed(3)})`);
  }
}
if (!drifted) console.log('  none beyond 2% — the committed scales still describe this cohort.');
