import { clamp, round, weightedTimeAverage } from './core.js';

/**
 * A symbolic tone for the entire local civil day. Each segment is weighted by
 * its actual elapsed seconds, so 23/25-hour DST days are handled naturally.
 * It uses the general six-module fusion and is independent of a reading's
 * decision mode, category, chosen period, or moment within that day.
 *
 * The 65/35 projection and the label cutoffs are editorial product rules, not
 * measurements of physical energy or validated predictions.
 */
export function dailyEnergy(segments) {
  if (!segments.length) return { level: 'unavailable', index: null, dataCoverage: 0 };
  const daily = weightedTimeAverage(segments.map(({ start, end, evidence }) => ({
    duration: (end - start) / 1000, evidence,
  })));
  const dataCoverage = round(daily.coverage);
  if (daily.coverage < .2) return { level: 'unavailable', index: null, dataCoverage };
  const index = Math.floor(50 + 40 * clamp(.65 * daily.a + .35 * daily.c) + .5);
  return { level: index < 50 ? 'soft' : index >= 53 ? 'bright' : 'steady', index, dataCoverage };
}
