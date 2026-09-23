import 'dart:convert';

import 'package:decision_compass/local_engine/local_reading_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'corpus_loader.dart';

/// Whole-reading parity for the cases an engine is easiest to get quietly
/// wrong: DST folds and gaps, a date-line timezone, a quarter-hour offset, an
/// unknown birth hour, a birth country with several candidate zones, an
/// elapsed period, and periods leaving two, one or zero lucky windows.
///
/// Every expectation is Node engine output from `edge_readings.json`.
void main() {
  final corpus = loadCorpus('edge_readings.json');

  /// Deep comparison that names the first differing JSON path.
  void expectDeepEqual(Object? actual, Object? expected, String path) {
    if (expected is Map) {
      expect(actual, isA<Map<dynamic, dynamic>>(), reason: 'at $path');
      final actualMap = actual! as Map<dynamic, dynamic>;
      expect(
        actualMap.keys.map((k) => k.toString()).toSet(),
        expected.keys.map((k) => k.toString()).toSet(),
        reason: 'keys at $path',
      );
      for (final key in expected.keys) {
        expectDeepEqual(actualMap[key], expected[key], '$path.$key');
      }
      return;
    }
    if (expected is List) {
      expect(actual, isA<List<dynamic>>(), reason: 'at $path');
      final actualList = actual! as List<dynamic>;
      expect(actualList.length, expected.length, reason: 'length at $path');
      for (var i = 0; i < expected.length; i++) {
        expectDeepEqual(actualList[i], expected[i], '$path[$i]');
      }
      return;
    }
    if (expected is num && actual is num) {
      if (expected is int) {
        expect(actual, expected, reason: 'at $path');
      } else {
        expect(
          actual.toDouble(),
          closeTo(expected.toDouble(), 1e-12),
          reason: 'at $path',
        );
      }
      return;
    }
    expect(actual, expected, reason: 'at $path');
  }

  Map<String, Object?> run(Map<String, dynamic> scenario) => calculateReading(
    profile: Map<String, Object?>.from(
      scenario['profile'] as Map<String, dynamic>,
    ),
    context: Map<String, Object?>.from(
      scenario['context'] as Map<String, dynamic>,
    ),
    period: scenario['period'] as String,
    mode: scenario['mode'] as String,
    category: scenario['category'] as String,
  );

  for (final scenario in rows(corpus, 'readings')) {
    final name = scenario['name'] as String;
    test('local engine reproduces the $name reading exactly', () {
      final actual =
          jsonDecode(jsonEncode(run(scenario))) as Map<String, dynamic>;
      expectDeepEqual(actual, scenario['result'], name);
    });
  }

  test('the awkward cases land on the statuses they are meant to', () {
    final byName = <String, Map<String, dynamic>>{
      for (final scenario in rows(corpus, 'readings'))
        scenario['name'] as String: scenario,
    };

    Map<String, Object?> resultFor(String name) => run(byName[name]!);

    // A birth time inside a DST gap never happened: the engine says so rather
    // than moving the birth an hour to make it exist.
    final gap = resultFor('dst_gap_birth_nonexistent');
    expect((gap['birthData']! as Map)['status'], 'birth_time_nonexistent');
    expect(gap['warnings'], contains('birth_time_nonexistent'));

    // A birth country with several zones stays a candidate set; no majority
    // vote and no substitution of the current zone.
    final fold = resultFor('dst_fold_birth');
    final birthData = fold['birthData']! as Map;
    expect(birthData['timezoneSource'], 'birth_country_zone_candidates');
    expect((birthData['timezoneCandidates']! as List).length, greaterThan(1));

    // An unknown birth hour lowers coverage and says which inputs are missing.
    final unknown = resultFor('unknown_birth_hour');
    expect(unknown['warnings'], contains('unknown_birth_time'));
    expect(unknown['warnings'], contains('unspecified_traditional_convention'));
    expect((unknown['dataCoverage']! as num).toDouble(), lessThan(1));

    // An elapsed period returns no score and no window at all, and never rolls
    // into tomorrow.
    final elapsed = resultFor('period_elapsed_morning');
    expect(elapsed['status'], 'period_elapsed');
    expect(elapsed['winner'], isNull);
    expect(elapsed['percentages'], isNull);
    expect(elapsed['luckyWindows'], isEmpty);
    expect(elapsed['consumeUnlock'], false);
    expect(elapsed.containsKey('windowStatus'), isFalse);
    expect(elapsed.containsKey('dailyBrief'), isFalse);

    // NOW never offers a window; future periods offer two, one or none.
    expect(resultFor('dst_fold_birth')['windowStatus'], 'not_applicable');
    expect(resultFor('dst_fold_birth')['luckyWindows'], isEmpty);
    expect(resultFor('two_windows_evening')['windowStatus'], 'two_available');
    expect(
      (resultFor('two_windows_evening')['luckyWindows']! as List).length,
      2,
    );
    expect(
      resultFor('one_window_evening_late')['windowStatus'],
      'one_remaining',
    );
    expect(
      (resultFor('one_window_evening_late')['luckyWindows']! as List).length,
      1,
    );
    expect(
      resultFor('no_window_evening_latest')['windowStatus'],
      'no_15_minute_window',
    );
    expect(resultFor('no_window_evening_latest')['luckyWindows'], isEmpty);
    // Still a real reading, even with no window to offer.
    expect(resultFor('no_window_evening_latest')['status'], 'ready');

    // A position fix never becomes the birth location, and a rejected fix
    // falls back to the device timezone without failing the reading.
    for (final name in <String>['invalid_location_fix', 'stale_location_fix']) {
      final result = resultFor(name);
      final context = result['context']! as Map;
      expect(context['zoneSource'], 'device');
      expect(context['timezone'], 'Asia/Ho_Chi_Minh');
      expect(context['locationZoneCandidates'], isEmpty);
      expect(result['status'], 'ready');
    }
    expect(
      (resultFor('invalid_location_fix')['context']! as Map)['locationStatus'],
      'invalid_fix',
    );
    expect(
      (resultFor('stale_location_fix')['context']! as Map)['locationStatus'],
      'stale_fix',
    );

    // A date-line zone is segmented in its own local day at its own offset:
    // Kiritimati is fourteen hours ahead, so 08:30 UTC is late evening there.
    final dateLine = resultFor('date_line_reading');
    final dateLineContext = dateLine['context']! as Map;
    expect(dateLineContext['timezone'], 'Pacific/Kiritimati');
    expect(dateLineContext['offsetSeconds'], 14 * 3600);
    expect(dateLine['evaluatedAtUtc'], isNotNull);
    expect(
      (dateLine['luckyWindows']! as List)
          .map((w) => (w as Map)['startLocal'] as String)
          .every((iso) => iso.endsWith('+14:00')),
      isTrue,
    );
  });

  test('a valid fresh fix reports the geometry gap instead of guessing a zone', () {
    // The coordinate-to-zone dataset is not bundled (see
    // `lib/local_engine/location/location.dart`). A usable fix must therefore
    // say the lookup was unavailable and keep the device timezone, rather than
    // pretending the position was ambiguous or inventing a zone.
    final result = calculateReading(
      profile: const <String, Object?>{
        'birthDate': '1998-06-21',
        'birthTime': '14:30',
        'birthCountry': 'VN',
        'traditionalProfile': 'male',
      },
      context: const <String, Object?>{
        'instantUtc': '2026-09-18T08:30:00Z',
        'deviceTimezone': 'Asia/Ho_Chi_Minh',
        'location': <String, Object?>{
          'latitude': 10.77,
          'longitude': 106.7,
          'accuracyMeters': 40,
          'capturedAtUtc': '2026-09-18T08:29:00Z',
        },
      },
    );

    final context = result['context']! as Map<String, Object?>;
    expect(context['locationStatus'], 'zone_lookup_unavailable');
    expect(context['zoneSource'], 'device');
    expect(context['timezone'], 'Asia/Ho_Chi_Minh');
    expect(context['locationZoneCandidates'], isEmpty);
    expect(
      result['warnings'],
      contains('location_zone_lookup_unavailable_using_device'),
    );
    // Reduced certainty, not a failed reading.
    expect(result['status'], 'ready');
  });
}
