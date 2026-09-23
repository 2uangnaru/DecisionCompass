import 'package:decision_compass/local_engine/calendar/calendar.dart';
import 'package:decision_compass/local_engine/calendar/chinese_calendar.dart';
import 'package:decision_compass/local_engine/time/local_time.dart';
import 'package:flutter_test/flutter_test.dart';

import 'corpus_loader.dart';

/// Differential tests for the offline Chinese calendar.
///
/// Solar-term instants are asserted to the millisecond: the engine uses them
/// both as segment boundaries and as the 节 that selects a month pillar, so a
/// one-second drift can move a whole pillar.
void main() {
  final corpus = loadCorpus('calendar_corpus.json');

  BirthContext birthFrom(Map<String, dynamic> profile) => birthContext(
    birthDate: profile['birthDate'] as String,
    birthTime: profile['birthTime'] as String?,
    birthCountry: profile['birthCountry'] as String?,
    birthTimezone: profile['birthTimezone'] as String?,
  );

  void expectPillar(Pillar? actual, Object? expected, String reason) {
    if (expected == null) {
      expect(actual, isNull, reason: reason);
      return;
    }
    final want = expected as Map<String, dynamic>;
    expect(actual, isNotNull, reason: reason);
    expect(actual!.stem, want['stem'], reason: '$reason stem');
    expect(actual.branch, want['branch'], reason: '$reason branch');
    expect(actual.text, want['text'], reason: '$reason text');
  }

  test('stem and branch glyph tables match', () {
    expect(stems, asStrings(corpus['stems']));
    expect(branches, asStrings(corpus['branches']));
  });

  test('solar terms match to the millisecond across 1899–2100', () {
    for (final row in rows(corpus, 'solarTerms')) {
      final year = row['year'] as int;
      final actual = solarTerms(year);
      final expected = (row['terms'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(actual.length, expected.length, reason: '$year term count');
      for (var i = 0; i < expected.length; i++) {
        expect(
          actual[i].name,
          expected[i]['name'],
          reason: '$year term $i name',
        );
        expect(
          actual[i].instant,
          asDouble(expected[i]['instant']),
          reason: '$year term $i (${expected[i]['name']}) instant',
        );
        expect(
          actual[i].monthIndex,
          expected[i]['monthIndex'],
          reason: '$year term $i month index',
        );
      }
    }
  });

  test('lunar date and day pillar match, including leap months', () {
    for (final row in rows(corpus, 'civilCalendar')) {
      final date = row['date'] as String;
      final actual = civilCalendar(date);
      final lunar = row['lunar'] as Map<String, dynamic>;
      expect(actual.lunar.year, lunar['year'], reason: '$date lunar year');
      expect(
        actual.lunar.month.abs(),
        lunar['month'],
        reason: '$date lunar month',
      );
      expect(actual.lunar.day, lunar['day'], reason: '$date lunar day');
      expect(actual.lunar.isLeap, lunar['leap'], reason: '$date leap');
      expectPillar(actual.day, row['day'], '$date day pillar');
    }
  });

  test('year and month pillars follow the exact 节 instants', () {
    for (final row in rows(corpus, 'solarPillars')) {
      final actual = solarPillars(asDouble(row['ms']));
      expectPillar(actual.year, row['year'], '${row['iso']} year');
      expectPillar(actual.month, row['month'], '${row['iso']} month');
      expect(
        actual.solarYear,
        row['solarYear'],
        reason: '${row['iso']} solar year',
      );
      final jie = row['latestJie'] as Map<String, dynamic>;
      expect(
        actual.latestJie.name,
        jie['name'],
        reason: '${row['iso']} latest jie',
      );
      expect(
        actual.latestJie.instant,
        asDouble(jie['instant']),
        reason: '${row['iso']} latest jie instant',
      );
    }
  });

  test('calendarAt and the almanac module match in every timezone', () {
    for (final row in rows(corpus, 'calendarAt')) {
      final cal = calendarAt(asDouble(row['ms']), row['zone'] as String);
      final label = '${row['zone']} @ ${row['iso']}';
      expect(cal.local.date, row['localDate'], reason: '$label local date');
      final lunar = row['lunar'] as Map<String, dynamic>;
      expect(cal.lunar.year, lunar['year'], reason: '$label lunar year');
      expect(
        cal.lunar.month.abs(),
        lunar['month'],
        reason: '$label lunar month',
      );
      expect(cal.lunar.day, lunar['day'], reason: '$label lunar day');
      expect(cal.lunar.isLeap, lunar['leap'], reason: '$label leap');
      expectPillar(cal.year, row['year'], '$label year');
      expectPillar(cal.month, row['month'], '$label month');
      expectPillar(cal.day, row['day'], '$label day');
      expectPillar(cal.hour, row['hour'], '$label hour');
      expect(cal.solarYear, row['solarYear'], reason: '$label solar year');
      expect(cal.latestJie.name, row['latestJie'], reason: '$label latest jie');

      final expected = row['almanac'] as Map<String, dynamic>;
      final actual = almanac(cal);
      expect(
        actual.status,
        expected['status'],
        reason: '$label almanac status',
      );
      expect(
        actual.evidence.a,
        closeTo(asDouble(expected['a']), 1e-12),
        reason: '$label almanac a',
      );
      expect(
        actual.evidence.c,
        closeTo(asDouble(expected['c']), 1e-12),
        reason: '$label almanac c',
      );
      expect(
        actual.evidence.coverage,
        asDouble(expected['coverage']),
        reason: '$label almanac coverage',
      );
      expect(
        actual.diagnostics['officer'],
        expected['officer'],
        reason: '$label officer',
      );
      final dayGod = actual.diagnostics['dayGod']! as Map<String, Object?>;
      final wantDayGod = expected['dayGod'] as Map<String, dynamic>;
      expect(dayGod['name'], wantDayGod['name'], reason: '$label day god');
      expect(
        dayGod['auspicious'],
        wantDayGod['auspicious'],
        reason: '$label day god type',
      );
      final hourGod = actual.diagnostics['hourGod']! as Map<String, Object?>;
      final wantHourGod = expected['hourGod'] as Map<String, dynamic>;
      expect(hourGod['name'], wantHourGod['name'], reason: '$label hour god');
      expect(
        hourGod['auspicious'],
        wantHourGod['auspicious'],
        reason: '$label hour god type',
      );
    }
  });

  test('natal pillars leave unknowns null instead of guessing', () {
    for (final row in rows(corpus, 'natalPillars')) {
      final profile = row['profile'] as Map<String, dynamic>;
      final actual = natalPillars(birthFrom(profile));
      final expected = row['pillars'] as List<dynamic>;
      expect(actual.length, expected.length, reason: '$profile pillar count');
      for (var i = 0; i < expected.length; i++) {
        expectPillar(actual[i], expected[i], '$profile pillar $i');
      }
    }
  });

  test('solar-term boundaries near an instant match', () {
    for (final row in rows(corpus, 'nearbyBoundaries')) {
      expect(
        nearbyBoundaries(parseInstant(row['iso'])),
        asDoubles(row['boundaries']),
        reason: '${row['iso']}',
      );
    }
    for (final row in rows(corpus, 'termsAroundCount')) {
      expect(
        termsAround(parseInstant(row['iso'])).length,
        row['count'],
        reason: '${row['iso']} terms around',
      );
    }
  });

  test('lunar year tables expose 31 terms and 15 candidate months', () {
    for (final year in <int>[1900, 1984, 2026, 2033, 2099]) {
      final data = lunarYear(year);
      expect(data.jieQiJulianDays.length, 31, reason: '$year term count');
      expect(data.months.length, 15, reason: '$year month count');
    }
  });
}
