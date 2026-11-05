import 'package:decision_compass/local_engine/core/core.dart';
import 'package:decision_compass/local_engine/daily_energy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DailyEnergyValue tone(double a, double c, [double coverage = 1]) =>
      dailyEnergy([(duration: 86400.0, evidence: Evidence(a, c, coverage))]);

  test('labels use both full-day axes while preserving the same index', () {
    expect(tone(-.03, -.03).level, 'quiet');
    expect(tone(0, 0).level, 'soft');
    expect(tone(.02, .02).level, 'steady');
    expect(tone(.05, .05).level, 'lively');
    expect(tone(.08, .08).level, 'bright');
    expect(tone(.12, .12).level, 'radiant');

    // Same 0.05 projection, so the same index; only the lead differs.
    final lively = tone(.05, .05);
    final focused = tone(.05 + .35 * .1, .05 - .65 * .1);
    final flowing = tone(.05 - .35 * .08, .05 + .65 * .08);
    expect([lively.index, focused.index, flowing.index], [52, 52, 52]);
    expect(focused.level, 'focused');
    expect(flowing.level, 'flowing');
    expect(tone(.05 + .35 * .08, .05 - .65 * .08).level, 'lively');
    expect(tone(-.2, -.35).level, 'quiet');
    expect(tone(-.2, 0).level, 'quiet');
  });

  test('band starts are ordered and every band is reachable at its start', () {
    expect([...energyBands]..sort(), energyBands);
    expect(
      [energyBands.first - .001, ...energyBands].map((p) => tone(p, p).level),
      ['quiet', 'soft', 'steady', 'lively', 'bright', 'radiant'],
    );
  });

  test('elapsed seconds and insufficient coverage are handled explicitly', () {
    expect(
      dailyEnergy([
        (duration: 10800.0, evidence: Evidence(1, 1, 1)),
        (duration: 75600.0, evidence: Evidence(-1, -1, 1)),
      ]).level,
      'quiet',
    );
    expect(tone(1, 0, 0), (level: 'unavailable', index: null, dataCoverage: 0));
  });
}
