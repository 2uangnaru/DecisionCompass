import { clamp, round, weightedTimeAverage } from './core.js';

/**
 * A symbolic tone for the entire local civil day. Each segment is weighted by
 * its actual elapsed seconds, so 23/25-hour DST days are handled naturally.
 * It uses the general six-module fusion and is independent of a reading's
 * decision mode, category, chosen period, or moment within that day.
 *
 * The 65/35 projection and the label cutoffs are editorial product rules, not
 * measurements of physical energy or validated predictions. A day's label also
 * distinguishes whether the existing action or change axis contributes more
 * strongly, so days with the same projection need not have the same tone.
 */
export function dailyEnergy(segments) {
  if (!segments.length) return { level: 'unavailable', index: null, dataCoverage: 0 };
  const daily = weightedTimeAverage(segments.map(({ start, end, evidence }) => ({
    duration: (end - start) / 1000, evidence,
  })));
  const dataCoverage = round(daily.coverage);
  if (daily.coverage < .2) return { level: 'unavailable', index: null, dataCoverage };
  const index = Math.floor(50 + 40 * clamp(.65 * daily.a + .35 * daily.c) + .5);
  let level;
  if (daily.a >= .04 && daily.a - daily.c >= .06) level = 'focused';
  else if (daily.c >= .04 && daily.c - daily.a >= .06) level = 'flowing';
  else if (index < 49) level = 'quiet';
  else if (index < 50) level = 'soft';
  else if (index < 52) level = 'steady';
  else if (index < 54) level = 'lively';
  else if (index < 58) level = 'bright';
  else level = 'radiant';
  return { level, index, dataCoverage };
}
