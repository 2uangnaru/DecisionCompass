import 'package:decision_compass/local_engine/calendar/calendar.dart';
import 'package:decision_compass/local_engine/time/local_time.dart';
import 'package:decision_compass/local_engine/ziwei/ziwei.dart';
import 'package:decision_compass/local_engine/ziwei/ziwei_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'corpus_loader.dart';

/// Differential tests for the offline Zi Wei module.
///
/// Two levels are checked. The raw chart level (palace names, star placement,
/// brightness, transformations and the five horoscope layers) makes a
/// placement bug visible directly instead of leaving it buried in a fused
/// score; the module level then checks the score the engine actually uses,
/// including the conservative cross-scenario handling of an unknown birth hour.
void main() {
  final corpus = loadCorpus('ziwei_corpus.json');
  const tolerance = 1e-12;
  const zone = 'Asia/Ho_Chi_Minh';

  test('category target palaces and weights match', () {
    final expected = corpus['targets'] as Map<String, dynamic>;
    expect(ziweiCategoryTargets.keys.toSet(), expected.keys.toSet());
    for (final entry in expected.entries) {
      final want = (entry.value as List<dynamic>).cast<Map<String, dynamic>>();
      final actual = ziweiCategoryTargets[entry.key]!;
      expect(actual.length, want.length, reason: '${entry.key} target count');
      for (var i = 0; i < want.length; i++) {
        expect(
          actual[i].palaces,
          asStrings(want[i]['palaces']),
          reason: '${entry.key} target $i palaces',
        );
        expect(
          actual[i].weight,
          closeTo(asDouble(want[i]['weight']), tolerance),
          reason: '${entry.key} target $i weight',
        );
      }
    }
    validateZiweiTargets();
  });

  test('palaces, body palace and star placement match iztro', () {
    for (final row in rows(corpus, 'charts')) {
      final chart = buildAstrolabe(
        solarDate: row['date'] as String,
        timeIndex: row['timeIndex'] as int,
        gender: row['gender'] as String,
      );
      final label = '${row['date']} h${row['timeIndex']} ${row['gender']}';

      expect(
        chart.palaces.map((p) => p.name).toList(),
        asStrings(row['palaceNames']),
        reason: '$label palace names',
      );
      expect(
        chart.palaces.indexWhere((p) => p.isBodyPalace),
        row['bodyPalace'],
        reason: '$label body palace',
      );

      final expected = (row['stars'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(chart.stars.length, expected.length, reason: '$label star count');
      for (var i = 0; i < expected.length; i++) {
        expect(
          chart.stars[i].name,
          expected[i]['name'],
          reason: '$label star $i name',
        );
        expect(
          chart.stars[i].palace,
          expected[i]['palace'],
          reason: '$label star $i palace',
        );
        expect(
          chart.stars[i].brightness,
          expected[i]['brightness'],
          reason: '$label star $i (${expected[i]['name']}) brightness',
        );
        expect(
          chart.stars[i].mutagen,
          expected[i]['mutagen'],
          reason: '$label star $i (${expected[i]['name']}) mutagen',
        );
      }
    }
  });

  test('all five horoscope layers match', () {
    for (final row in rows(corpus, 'horoscopes')) {
      final chart = buildAstrolabe(
        solarDate: row['date'] as String,
        timeIndex: row['timeIndex'] as int,
        gender: row['gender'] as String,
      );
      final horoscope = horoscopeFor(
        chart,
        row['targetDate'] as String,
        row['targetTimeIndex'] as int,
      );
      final label =
          '${row['date']} h${row['timeIndex']} ${row['gender']} '
          '-> ${row['targetDate']} h${row['targetTimeIndex']}';
      final layers = row['layers'] as Map<String, dynamic>;
      for (final entry in layers.entries) {
        final want = entry.value as Map<String, dynamic>;
        final actual = horoscope[entry.key]!;
        expect(
          actual.index,
          want['index'],
          reason: '$label ${entry.key} index',
        );
        if ((want['index'] as int) >= 0) {
          expect(
            actual.mutagen,
            asStrings(want['mutagen']),
            reason: '$label ${entry.key} mutagen',
          );
        }
      }
    }
  });

  test('module scores match, including conservative unknown-hour handling', () {
    for (final row in rows(corpus, 'modules')) {
      final profile = row['profile'] as Map<String, dynamic>;
      final built = buildZiWei(
        birthContext(
          birthDate: profile['birthDate'] as String,
          birthTime: profile['birthTime'] as String?,
          birthCountry: profile['birthCountry'] as String?,
          birthTimezone: profile['birthTimezone'] as String?,
        ),
        row['convention'] as String?,
      );
      final cal = calendarAt(parseInstant(row['iso']), zone);
      final module = scoreZiWei(built, cal, row['category'] as String);
      final label =
          '${profile['birthDate']}/${row['convention']} '
          '${row['category']} @ ${row['iso']}';

      expect(module.status, row['status'], reason: '$label status');
      expect(
        module.evidence.a,
        closeTo(asDouble(row['a']), tolerance),
        reason: '$label a',
      );
      expect(
        module.evidence.c,
        closeTo(asDouble(row['c']), tolerance),
        reason: '$label c',
      );
      expect(
        module.evidence.coverage,
        closeTo(asDouble(row['coverage']), tolerance),
        reason: '$label coverage',
      );
      expect(
        module.diagnostics['scenarioCount'],
        row['scenarioCount'],
        reason: '$label scenario count',
      );
      expect(
        module.diagnostics['unknownBirthHour'],
        row['unknownBirthHour'],
        reason: '$label unknown hour',
      );
      expect(
        module.diagnostics['unknownConvention'],
        row['unknownConvention'],
        reason: '$label unknown convention',
      );
    }
  });
}
