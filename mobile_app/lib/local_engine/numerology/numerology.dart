/// Port of `calculation-engine/src/numerology.js`.
///
/// Life path plus personal year/month/day, reduced to 1–9 and mapped onto the
/// two axes. Master numbers are deliberately not treated specially, which the
/// diagnostics state explicitly.
library;

import '../core/core.dart';

int _digitSum(int n) =>
    n.abs().toString().split('').fold<int>(0, (s, c) => s + int.parse(c));

int _reduce(int n) => 1 + ((n - 1) % 9);

const Map<int, List<double>> _vectors = <int, List<double>>{
  1: <double>[.6, .6],
  2: <double>[-.2, -.3],
  3: <double>[.4, .2],
  4: <double>[.1, -.6],
  5: <double>[.3, .7],
  6: <double>[.1, -.5],
  7: <double>[-.6, -.2],
  8: <double>[.5, .1],
  9: <double>[-.2, .6],
};

ModuleResult numerology(String birthDate, String currentDate) {
  final birth = birthDate.split('-').map(int.parse).toList();
  final current = currentDate.split('-').map(int.parse).toList();
  // String comparison is what the Node engine uses, and it is correct for
  // zero-padded ISO dates.
  if (birthDate.compareTo(currentDate) > 0) {
    throw const EngineFailure('BIRTH_DATE_IN_FUTURE');
  }

  final lifePath = _reduce(
    _digitSum(birth[0]) + _digitSum(birth[1]) + _digitSum(birth[2]),
  );
  final personalYear = _reduce(birth[1] + birth[2] + _digitSum(current[0]));
  final personalMonth = _reduce(personalYear + current[1]);
  final personalDay = _reduce(personalMonth + current[2]);

  const weights = <double>[.1, .15, .25, .5];
  final numbers = <int>[lifePath, personalYear, personalMonth, personalDay];
  final axes = <double>[
    for (var axis = 0; axis < 2; axis++)
      () {
        var sum = 0.0;
        for (var i = 0; i < numbers.length; i++) {
          sum += weights[i] * _vectors[numbers[i]]![axis];
        }
        return sum;
      }(),
  ];

  return ModuleResult(Evidence(axes[0], axes[1], 1), <String, Object?>{
    'lifePath': lifePath,
    'personalYear': personalYear,
    'personalMonth': personalMonth,
    'personalDay': personalDay,
    'masterNumbers': false,
  });
}
