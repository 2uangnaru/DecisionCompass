// Offline calibration of the daily energy cutoffs (ruleset v9.7).
//
//   node scripts/calibrate-energy.mjs [--profiles 160] [--dates 12] [--seed 20261105]
//   node scripts/calibrate-energy.mjs --only calibration --shard 0 --shards 6
//       fills one shard of one cohort's cache, so several can run at once
//
// Each cutoff is a quantile of a synthetic calibration cohort's own days, set
// so that each tone takes the share the owner chose on 2026-11-05 (`SHARES`):
//
// 1. FOCUSED and FLOWING are the days one axis leads the other. Each lead
//    threshold gives that tone its share of all days, among days whose
//    leading axis is itself positive.
// 2. The remaining days are cut by the 65/35 projection into six bands, QUIET
//    to RADIANT, each taking its share.
//
// The output is a constant block for `src/daily-energy.js` and its Dart port.
// Paste it, do not import it: nothing at runtime may recompute these, or two
// readers would stop being comparable and a saved reading would stop
// reproducing.
//
// A second, disjoint held-out cohort, read over thirty consecutive days per
// profile in a different year, is measured against the cutoffs pasted into
// `src/`. Its numbers are evidence about the cutoffs, not a target; nothing is
// tuned to hit them.
//
// Each cohort's day axes are cached on disk (they do not depend on the
// cutoffs), so changing `SHARES` or the pasted cutoffs reruns in seconds.

import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createCalculator } from '../src/index.js';
import { dailyEnergy } from '../src/daily-energy.js';
import { rng, makeProfile, ZONES, percentile } from './cohort.mjs';

const arg = (name, fallback) => {
  const at = process.argv.indexOf(`--${name}`);
  return at > -1 ? process.argv[at + 1] : fallback;
};
const PROFILES = Number(arg('profiles', 160));
const DATES = Number(arg('dates', 12));
const SEED = Number(arg('seed', 20261105));
const HELD_OUT_SEED = SEED + 7919;
const HELD_OUT_PROFILES = Number(arg('heldout-profiles', 64));
const HELD_OUT_DAYS = Number(arg('heldout-days', 30));
const ONLY = arg('only', null);
const CACHE = arg('cache', join(tmpdir(), 'astracue-energy-calibration'));
const DAY = 86400000;

/** Owner decision, 2026-11-05: both extremes rare, mid-to-bright most common. */
const SHARES = Object.freeze({
  quiet: .07, soft: .10, steady: .15, lively: .17, bright: .15, radiant: .08,
  focused: .14, flowing: .14,
});
const BANDED = ['quiet', 'soft', 'steady', 'lively', 'bright', 'radiant'];
const LEVELS = [...BANDED, 'focused', 'flowing'];

/** Day axes for one profile on the given UTC noons in one device zone. */
function days(profile, zone, instants) {
  const calculator = createCalculator(profile);
  return instants.map(ms => calculator.calculate({
    context: { instantUtc: new Date(ms).toISOString(), deviceTimezone: zone },
    mode: 'yes_no', period: 'now', category: 'general', probeEnergyAxes: true,
  }).scoring.energyAxes);
}

// `--shard k --shards n` computes every n-th profile from k, so one cohort can
// be filled by n processes at once; a later run merges the shard files.
const SHARDS = Number(arg('shards', 1)), SHARD = Number(arg('shard', 0));

/** Each cohort is a list of {profile, zone, instants} specs, then their days. */
function cohortDays(name, specs) {
  const file = n => join(CACHE, `${name}${n}.json`);
  if (existsSync(file(''))) return JSON.parse(readFileSync(file(''), 'utf8'));
  const shardFile = k => file(`-s${k}of${SHARDS}`);
  const compute = k => {
    const started = Date.now();
    const value = specs.filter((_, i) => i % SHARDS === k)
      .map(({ profile, zone, instants }) => days(profile, zone, instants));
    mkdirSync(CACHE, { recursive: true });
    writeFileSync(shardFile(k), JSON.stringify(value));
    console.log(`${name} shard ${k}/${SHARDS}: ${((Date.now() - started) / 1000).toFixed(0)}s`);
    return value;
  };
  if (ONLY) return compute(SHARD);
  // Merge a complete set of shard files, whatever `--shards` filled it.
  const sets = existsSync(CACHE) ? readdirSync(CACHE)
    .map(f => f.match(new RegExp(`^${name}-s(\\d+)of(\\d+)\\.json$`))).filter(Boolean) : [];
  const total = [...new Set(sets.map(m => Number(m[2])))]
    .find(n => sets.filter(m => Number(m[2]) === n).length === n);
  const parts = total
    ? Array.from({ length: total }, (_, k) => JSON.parse(readFileSync(file(`-s${k}of${total}`), 'utf8')))
    : Array.from({ length: SHARDS }, (_, k) => compute(k));
  const merged = parts.flat();
  writeFileSync(file(''), JSON.stringify(merged));
  return merged;
}

const calibrationCohort = () => {
  const next = rng(SEED);
  const start = Date.UTC(2025, 0, 1), span = 3 * 365;
  const specs = Array.from({ length: PROFILES }, () => ({
    profile: makeProfile(next),
    zone: ZONES[Math.floor(next() * ZONES.length)],
    instants: Array.from({ length: DATES }, () => start + Math.floor(next() * span) * DAY + 12 * 3600000),
  }));
  return cohortDays(`calibration-${SEED}-${PROFILES}x${DATES}`, specs).flat();
};

const heldOutCohort = () => {
  const next = rng(HELD_OUT_SEED);
  const specs = Array.from({ length: HELD_OUT_PROFILES }, () => {
    const profile = makeProfile(next);
    const zone = ZONES[Math.floor(next() * ZONES.length)];
    const first = Date.UTC(2028, 0, 1) + Math.floor(next() * 330) * DAY + 12 * 3600000;
    return { profile, zone, instants: Array.from({ length: HELD_OUT_DAYS }, (_, k) => first + k * DAY) };
  });
  return cohortDays(`heldout-${HELD_OUT_SEED}-${HELD_OUT_PROFILES}x${HELD_OUT_DAYS}`, specs);
};

if (ONLY === 'calibration') { calibrationCohort(); process.exit(0); }
if (ONLY === 'heldout') { heldOutCohort(); process.exit(0); }

// Days below the coverage gate are `unavailable` whatever the cutoffs.
const sample = calibrationCohort().filter(d => d.coverage >= .2);
const leadThreshold = (leads, share) => percentile(leads, 1 - share * sample.length / leads.length);
const focusedLead = leadThreshold(sample.filter(d => d.a > 0).map(d => d.a - d.c), SHARES.focused);
const flowingLead = leadThreshold(sample.filter(d => d.c > 0).map(d => d.c - d.a), SHARES.flowing);
const rest = sample.filter(d =>
  !(d.a > 0 && d.a - d.c >= focusedLead) && !(d.c > 0 && d.c - d.a >= flowingLead));
const projections = rest.map(d => .65 * d.a + .35 * d.c);
const restShare = BANDED.reduce((s, l) => s + SHARES[l], 0);
let cumulative = 0;
const bands = BANDED.slice(0, -1).map(level => {
  cumulative += SHARES[level];
  return percentile(projections, cumulative / restShare);
});
const r = x => Number(x.toFixed(4));
console.log(`calibration cohort: ${sample.length} days, ${PROFILES} profiles, 2025-2027`);
console.log('\n// Paste into src/daily-energy.js and lib/local_engine/daily_energy.dart:');
console.log(`FOCUSED_LEAD = ${r(focusedLead)}, FLOWING_LEAD = ${r(flowingLead)}`);
console.log(`BANDS (soft|steady|lively|bright|radiant start at) = [${bands.map(r).join(', ')}]`);

const levelOf = d => dailyEnergy([{ start: 0, end: DAY, evidence: d }]).level;

/** Shares, per-reader runs and the spread of tones a single reader sees. */
function report(label, perProfile) {
  const rows = perProfile.flat().filter(d => d.coverage >= .2);
  const counts = Object.fromEntries(LEVELS.map(l => [l, 0]));
  for (const row of rows) counts[levelOf(row)]++;
  console.log(`\n${label}: ${rows.length} days (target in brackets)`);
  console.log(LEVELS.map(l => `${l} ${(100 * counts[l] / rows.length).toFixed(1)}% [${Math.round(100 * SHARES[l])}]`).join('  '));
  if (perProfile.length < 2) return;
  const weak = l => l === 'quiet' || l === 'soft';
  const stats = perProfile.map(list => {
    let run = 0, weakRun = 0, best = 0, bestWeak = 0, prev = null;
    const tally = {};
    for (const level of list.map(levelOf)) {
      run = level === prev ? run + 1 : 1; prev = level; best = Math.max(best, run);
      weakRun = weak(level) ? weakRun + 1 : 0; bestWeak = Math.max(bestWeak, weakRun);
      tally[level] = (tally[level] ?? 0) + 1;
    }
    return {
      distinct: Object.keys(tally).length, sameRun: best, weakRun: bestWeak,
      top: Math.max(...Object.values(tally)) / list.length,
      weakShare: list.filter(d => weak(levelOf(d))).length / list.length,
    };
  });
  const q = (key, p) => percentile(stats.map(s => s[key]), p);
  console.log(`per reader over ${perProfile[0].length} consecutive days (median / p90 / max):`);
  const names = {
    distinct: 'distinct tones', sameRun: 'longest same-tone run', weakRun: 'longest quiet/soft run',
    top: 'most frequent tone share', weakShare: 'quiet/soft share',
  };
  for (const key of Object.keys(names)) {
    const f = v => key === 'top' || key === 'weakShare' ? `${(100 * v).toFixed(0)}%` : v.toFixed(0);
    console.log(`  ${names[key].padEnd(26)} ${f(q(key, .5))} / ${f(q(key, .9))} / ${f(q(key, 1))}`);
  }
}

report('calibration cohort, cutoffs now in src/', [sample]);
report(`held-out cohort, ${HELD_OUT_PROFILES} profiles x ${HELD_OUT_DAYS} consecutive days in 2028, cutoffs now in src/`, heldOutCohort());
