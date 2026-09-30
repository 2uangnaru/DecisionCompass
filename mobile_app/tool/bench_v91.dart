// ignore_for_file: avoid_print
// Throwaway probe: how long a v9.1 reading takes in Dart, by mode and by how
// much birth data the profile carries.
import '../lib/local_engine/local_reading_engine.dart';

void main() {
  const context = <String, Object?>{
    'instantUtc': '2026-09-30T03:00:00.000Z',
    'deviceTimezone': 'Asia/Ho_Chi_Minh',
  };
  const modes = [
    'yes_no',
    'act_wait',
    'advance_retreat',
    'stay_go',
    'keep_let_go',
    'commit_withdraw',
    'left_right',
  ];
  final cases = <String, Map<String, Object?>>{
    'known hour + convention': {
      'birthTime': '08:25',
      'traditionalProfile': 'female',
    },
    'known hour, unspecified': {
      'birthTime': '08:25',
      'traditionalProfile': 'unspecified',
    },
    'unknown hour + convention': {
      'birthTime': null,
      'traditionalProfile': 'female',
    },
    'unknown hour, unspecified': {
      'birthTime': null,
      'traditionalProfile': 'unspecified',
    },
  };
  var n = 0;
  Map<String, Object?> fresh(Map<String, Object?> base) => {
    'birthDate':
        '19${60 + n ~/ 12}-${(1 + n++ % 12).toString().padLeft(2, '0')}-14',
    'birthCountry': 'VN',
    'revision': 1,
    ...base,
  };
  ReadingCalculator(fresh(cases.values.first))
      .calculate(context: context, mode: 'yes_no', period: 'now');
  print('profile                    mode                 ms');
  final worst = <String, int>{};
  for (final entry in cases.entries) {
    for (final mode in modes) {
      final calc = ReadingCalculator(fresh(entry.value));
      final sw = Stopwatch()..start();
      calc.calculate(
        context: context,
        mode: mode,
        period: 'now',
        category: 'general',
      );
      final ms = sw.elapsedMilliseconds;
      worst[entry.key] = ms > (worst[entry.key] ?? 0) ? ms : worst[entry.key]!;
      print(
        '${entry.key.padRight(26)} ${mode.padRight(17)} ${ms.toString().padLeft(5)}',
      );
    }
  }
  print('\nWorst mode per profile class:');
  worst.forEach((k, v) => print('  ${k.padRight(26)} $v ms'));
}
