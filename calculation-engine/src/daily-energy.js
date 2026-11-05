import { clamp, round, weightedTimeAverage } from './core.js';

/**
 * A symbolic tone for the entire local civil day. Each segment is weighted by
 * its actual elapsed seconds, so 23/25-hour DST days are handled naturally.
 * It uses the general fusion before the luck baseline and is independent of a
 * reading's decision mode, category, chosen period, or moment within that day.
 *
 * The 65/35 projection and the cutoffs are editorial product rules, not
 * measurements of physical energy or validated predictions. FOCUSED and
 * FLOWING are the days one axis clearly leads the other; the rest are cut by
 * the projection into six bands.
 *
 * Ruleset v9.7: the cutoffs are quantiles of a synthetic calibration cohort
 * (`scripts/calibrate-energy.mjs`), set so that each tone takes the share the
 * owner chose on 2026-11-05 — QUIET 7%, SOFT 10%, STEADY 15%, LIVELY 17%,
 * BRIGHT 15%, RADIANT 8%, FOCUSED 14%, FLOWING 14%. Measured on a held-out
 * cohort, not guaranteed for any one reader; see VERIFICATION.md.
 */
export const ENERGY_CUTOFFS = Object.freeze({
  focusedLead: 0.0893,
  flowingLead: 0.0687,
  // The projection at which SOFT, STEADY, LIVELY, BRIGHT and RADIANT begin.
  bands: Object.freeze([-0.0155, 0.0099, 0.0376, 0.0635, 0.0969]),
});
const BANDED = Object.freeze(['quiet', 'soft', 'steady', 'lively', 'bright', 'radiant']);

/** The day's duration-weighted axes. Exported for the calibration probe. */
export function dailyEnergyAxes(segments) {
  return weightedTimeAverage(segments.map(({ start, end, evidence }) => ({
    duration: (end - start) / 1000, evidence,
  })));
}

export function dailyEnergy(segments) {
  if (!segments.length) return { level: 'unavailable', index: null, dataCoverage: 0 };
  const daily = dailyEnergyAxes(segments);
  const dataCoverage = round(daily.coverage);
  if (daily.coverage < .2) return { level: 'unavailable', index: null, dataCoverage };
  const projection = .65 * daily.a + .35 * daily.c;
  const index = Math.floor(50 + 40 * clamp(projection) + .5);
  const { focusedLead, flowingLead, bands } = ENERGY_CUTOFFS;
  // The leading axis must itself be positive: an axis is not "leading" merely
  // because the other one is even lower.
  let level;
  if (daily.a > 0 && daily.a - daily.c >= focusedLead) level = 'focused';
  else if (daily.c > 0 && daily.c - daily.a >= flowingLead) level = 'flowing';
  else level = BANDED[bands.filter(start => projection >= start).length];
  return { level, index, dataCoverage };
}
