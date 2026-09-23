import 'package:decision_compass/local_engine/core/core.dart';
import 'package:decision_compass/local_engine/daily_energy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DailyEnergyValue tone(double a, double c, [double coverage = 1]) =>
      dailyEnergy([(duration: 86400.0, evidence: Evidence(a, c, coverage))]);

  test('labels use both full-day axes while preserving the same index', () {
    expect(tone(-.05, -.05).level, 'quiet');
    expect(tone(-.02, -.02).level, 'soft');
    expect(tone(0, 0).level, 'steady');
    expect(tone(.06, .06).level, 'lively');
    expect(tone(.11, .11).level, 'bright');
    expect(tone(.2, .2).level, 'radiant');

    final lively = tone(.075, .075);
    final focused = tone(.12, 0);
    final flowing = tone(0, .223);
    expect([lively.index, focused.index, flowing.index], [53, 53, 53]);
    expect(focused.level, 'focused');
    expect(flowing.level, 'flowing');
    expect(tone(-.2, 0).level, 'quiet');
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
