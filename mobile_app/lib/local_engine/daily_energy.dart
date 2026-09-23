/// Port of `calculation-engine/src/daily-energy.js`.
///
/// A full local day's general fusion is weighted by elapsed seconds. The
/// index is an internal symbolic projection; the tone also reflects whether
/// the existing action or change axis contributes more strongly.
library;

import 'core/core.dart';
import 'core/numbers.dart';

typedef DailyEnergyValue = ({String level, int? index, double dataCoverage});

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

  final index = (50 + 40 * clampUnit(.65 * daily.a + .35 * daily.c) + .5)
      .floor();
  final level = daily.a >= .04 && daily.a - daily.c >= .06
      ? 'focused'
      : daily.c >= .04 && daily.c - daily.a >= .06
      ? 'flowing'
      : index < 49
      ? 'quiet'
      : index < 50
      ? 'soft'
      : index < 52
      ? 'steady'
      : index < 54
      ? 'lively'
      : index < 58
      ? 'bright'
      : 'radiant';
  return (level: level, index: index, dataCoverage: coverage);
}
