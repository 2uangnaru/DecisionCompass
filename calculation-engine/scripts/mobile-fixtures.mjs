/**
 * Generates and validates the Flutter DTO fixtures in mobile_app/test/fixtures/
 * from the real engine, so those fixtures are engine output rather than
 * hand-written numbers.
 *
 *   node scripts/mobile-fixtures.mjs --write   overwrite fixtures with engine output
 *   node scripts/mobile-fixtures.mjs --check   fail when a committed fixture differs
 *   node scripts/mobile-fixtures.mjs           same as --check
 *
 * Projection checks call the engine's own MODES / percent / scoreForMode, so no
 * formula is re-implemented here. This script never writes the synthetic_*
 * fixtures: those cover states the engine cannot be asked to emit on demand and
 * are maintained by hand (see mobile_app/test/fixtures/README.md).
 */
import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { createCalculator } from '../src/index.js';
import { MODES, percent, scoreForMode } from '../src/core.js';

const FIXTURE_DIR = fileURLToPath(new URL('../../mobile_app/test/fixtures/', import.meta.url));
const ZONE_VN = 'Asia/Ho_Chi_Minh';

const PROFILE_KNOWN_HOUR = {
  birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male',
};
const PROFILE_UNKNOWN_HOUR = {
  birthDate: '1998-06-21', birthCountry: 'VN', traditionalProfile: 'male',
};

/**
 * Every instant below is chosen so the local clock actually sits inside (or
 * after) the requested period; `expect` records why the scenario exists, and a
 * mismatch fails loudly instead of silently writing a fixture that no longer
 * covers its case.
 */
const SCENARIOS = [
  {
    file: 'ready_yes_no_now.json', profile: PROFILE_KNOWN_HOUR,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: ZONE_VN },
    mode: 'yes_no', period: 'now',
    expect: { status: 'ready', windowStatus: 'not_applicable', luckyWindows: 0 },
  },
  {
    file: 'ready_forward_backward_two_windows.json', profile: PROFILE_KNOWN_HOUR,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: ZONE_VN },
    mode: 'forward_backward', period: 'evening',
    expect: { status: 'ready', windowStatus: 'two_available', luckyWindows: 2 },
  },
  {
    file: 'ready_left_right.json', profile: PROFILE_KNOWN_HOUR,
    context: { instantUtc: '2026-09-18T07:30:00Z', deviceTimezone: ZONE_VN },
    mode: 'left_right', period: 'afternoon',
    expect: { status: 'ready', windowStatus: 'two_available', luckyWindows: 2 },
  },
  {
    file: 'ready_advance_retreat.json', profile: PROFILE_KNOWN_HOUR,
    context: { instantUtc: '2026-09-17T23:30:00Z', deviceTimezone: ZONE_VN },
    mode: 'advance_retreat', period: 'morning',
    expect: { status: 'ready', windowStatus: 'two_available', luckyWindows: 2 },
  },
  {
    file: 'ready_act_wait_midday.json', profile: PROFILE_KNOWN_HOUR,
    context: { instantUtc: '2026-09-18T05:30:00Z', deviceTimezone: ZONE_VN },
    mode: 'act_wait', period: 'midday',
    expect: { status: 'ready', windowStatus: 'two_available', luckyWindows: 2 },
  },
  {
    file: 'one_remaining.json', profile: PROFILE_KNOWN_HOUR,
    context: { instantUtc: '2026-09-18T16:30:00Z', deviceTimezone: ZONE_VN },
    mode: 'keep_let_go', period: 'evening',
    expect: { status: 'ready', windowStatus: 'one_remaining', luckyWindows: 1 },
  },
  {
    file: 'no_15_minute_window.json', profile: PROFILE_KNOWN_HOUR,
    context: { instantUtc: '2026-09-18T16:50:00Z', deviceTimezone: ZONE_VN },
    mode: 'yes_no', period: 'evening',
    expect: { status: 'ready', windowStatus: 'no_15_minute_window', luckyWindows: 0 },
  },
  {
    file: 'period_elapsed.json', profile: PROFILE_KNOWN_HOUR,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: ZONE_VN },
    mode: 'stay_go', period: 'morning',
    expect: { status: 'period_elapsed', luckyWindows: 0 },
  },
  {
    file: 'unknown_birth_time_warnings.json', profile: PROFILE_UNKNOWN_HOUR,
    context: { instantUtc: '2026-09-18T07:30:00Z', deviceTimezone: ZONE_VN },
    mode: 'forward_backward', period: 'afternoon',
    expect: { status: 'ready', warnings: ['unknown_birth_time'] },
  },
  {
    // A fix older than 15 minutes is rejected as stale, so the reading falls
    // back to the device timezone. Deterministic, unlike a border-straddling fix.
    file: 'location_fallback_device_timezone.json', profile: PROFILE_KNOWN_HOUR,
    context: {
      instantUtc: '2026-09-17T10:30:00Z', deviceTimezone: 'Europe/Paris',
      location: {
        latitude: 48.8566, longitude: 2.3522, accuracyMeters: 120,
        capturedAtUtc: '2026-09-17T10:00:00Z',
      },
    },
    mode: 'stay_go', period: 'midday',
    expect: { status: 'ready', zoneSource: 'device', locationStatus: 'stale_fix' },
  },
];

function projectionProblems(result, label) {
  const problems = [];
  const axes = result.axisScores;
  if (axes) {
    const recomputed = scoreForMode({ a: axes.action, c: axes.change }, result.mode);
    if (Math.abs(recomputed - axes.selected) > 1e-9) {
      problems.push(`${label}: axisScores.selected ${axes.selected} != projection ${recomputed}`);
    }
    if (result.modeScore != null && Math.abs(result.modeScore - axes.selected) > 1e-9) {
      problems.push(`${label}: modeScore ${result.modeScore} != axisScores.selected ${axes.selected}`);
    }
  }
  if (result.percentages) {
    const [first, second] = MODES[result.mode].labels;
    const expected = percent(result.modeScore);
    if (result.percentages[first] !== expected) {
      problems.push(`${label}: percentages.${first} ${result.percentages[first]} != percent(modeScore) ${expected}`);
    }
    if (result.percentages[first] + result.percentages[second] !== 100) {
      problems.push(`${label}: percentages do not sum to 100`);
    }
    const winner = expected === 50 ? null : expected > 50 ? first : second;
    if (result.winner !== winner) {
      problems.push(`${label}: winner ${result.winner} != ${winner}`);
    }
  }
  return problems;
}

function expectationProblems(result, scenario) {
  const problems = [], want = scenario.expect ?? {};
  const check = (name, actual, wanted) => {
    if (wanted !== undefined && actual !== wanted) {
      problems.push(`${scenario.file}: ${name} is ${actual}, scenario expects ${wanted}`);
    }
  };
  check('status', result.status, want.status);
  check('windowStatus', result.windowStatus, want.windowStatus);
  check('luckyWindows.length', result.luckyWindows.length, want.luckyWindows);
  check('context.zoneSource', result.context.zoneSource, want.zoneSource);
  check('context.locationStatus', result.context.locationStatus, want.locationStatus);
  for (const warning of want.warnings ?? []) {
    if (!result.warnings.includes(warning)) {
      problems.push(`${scenario.file}: expected warning "${warning}", got ${JSON.stringify(result.warnings)}`);
    }
  }
  return problems;
}

function generate(scenario) {
  const { profile, context, mode, period } = scenario;
  return createCalculator(profile).calculate({ context, mode, period });
}

function main() {
  const write = process.argv.includes('--write');
  const problems = [], changed = [];

  for (const scenario of SCENARIOS) {
    const result = generate(scenario);
    problems.push(...expectationProblems(result, scenario));
    problems.push(...projectionProblems(result, scenario.file));

    const path = FIXTURE_DIR + scenario.file;
    const serialized = JSON.stringify(result, null, 2) + '\n';
    if (write) {
      writeFileSync(path, serialized);
      continue;
    }
    let committed = null;
    try { committed = readFileSync(path, 'utf8'); } catch { /* missing file reported below */ }
    if (committed === null) changed.push(`${scenario.file}: missing, run with --write`);
    else if (JSON.stringify(JSON.parse(committed)) !== JSON.stringify(result)) {
      changed.push(`${scenario.file}: committed fixture differs from engine output`);
    }
  }

  // Synthetic fixtures are hand-maintained but must still be self-consistent.
  for (const file of readdirSync(FIXTURE_DIR).filter(f => f.endsWith('.json'))) {
    const fixture = JSON.parse(readFileSync(FIXTURE_DIR + file, 'utf8'));
    if (fixture.mode) problems.push(...projectionProblems(fixture, `${file} (as committed)`));
  }

  for (const line of [...problems, ...changed]) console.error(line);
  if (write) {
    console.log(`Wrote ${SCENARIOS.length} fixtures to ${FIXTURE_DIR}`);
  } else if (!problems.length && !changed.length) {
    console.log(`All ${SCENARIOS.length} engine fixtures match current engine output.`);
  }
  process.exit(problems.length || changed.length ? 1 : 0);
}

main();
