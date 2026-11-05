/// Port of `calculation-engine/src/daily-energy.js`.
///
/// A full local day's general fusion, before the luck baseline, is weighted by
/// elapsed seconds. The index is an internal symbolic projection. FOCUSED and
/// FLOWING are the days one axis clearly leads the other; the rest are cut by
/// the projection into six bands.
///
/// Ruleset v9.7: the cutoffs are quantiles of a synthetic calibration cohort
/// (`calculation-engine/scripts/calibrate-energy.mjs`), set so that each tone
/// takes the share the owner chose on 2026-11-05 — QUIET 7%, SOFT 10%, STEADY
/// 15%, LIVELY 17%, BRIGHT 15%, RADIANT 8%, FOCUSED 14%, FLOWING 14%.
library;

import 'core/core.dart';
import 'core/numbers.dart';

typedef DailyEnergyValue = ({String level, int? index, double dataCoverage});

const double energyFocusedLead = 0.0893;
const double energyFlowingLead = 0.0687;

/// The projection at which SOFT, STEADY, LIVELY, BRIGHT and RADIANT begin.
const List<double> energyBands = [-0.0155, 0.0099, 0.0376, 0.0635, 0.0969];
const List<String> _banded = [
  'quiet',
  'soft',
  'steady',
  'lively',
  'bright',
  'radiant',
];

DailyEnergyValue dailyEnergy(
  List<({double duration, Evidence evidence})> segments,
) {
  if (segments.isEmpty) {
    return (level: 'unavailable', index: null, dataCoverage: 0);
  }
  final daily = weightedTimeAverage(segments);
  final coverage = roundTen(daily.coverage);
  if (daily.coverage < .2) {
    return (level: 'unavailable', index: null, dataCoverage: coverage);
  }

  final projection = .65 * daily.a + .35 * daily.c;
  final index = (50 + 40 * clampUnit(projection) + .5).floor();
  // The leading axis must itself be positive: an axis is not "leading" merely
  // because the other one is even lower.
  final level = daily.a > 0 && daily.a - daily.c >= energyFocusedLead
      ? 'focused'
      : daily.c > 0 && daily.c - daily.a >= energyFlowingLead
      ? 'flowing'
      : _banded[energyBands.where((start) => projection >= start).length];
  return (level: level, index: index, dataCoverage: coverage);
}
