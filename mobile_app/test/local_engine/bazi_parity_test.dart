import 'package:decision_compass/local_engine/bazi/bazi.dart';
import 'package:decision_compass/local_engine/calendar/calendar.dart';
import 'package:decision_compass/local_engine/time/local_time.dart';
import 'package:flutter_test/flutter_test.dart';

import 'corpus_loader.dart';

/// Differential tests for the offline BaZi module.
///
/// The corpus deliberately includes charts the engine cannot complete — an
/// unknown birth hour, an unspecified traditional convention — so the test
/// proves the port reduces coverage and leaves the decade cycle null in the
/// same places, rather than inventing a pillar.
void main() {
  final corpus = loadCorpus('bazi_corpus.json');
  const tolerance = 1e-12;
  const zone = 'Asia/Ho_Chi_Minh';

  BaZiChart chartFrom(Map<String, dynamic> profile, String? convention) =>
      buildBaZi(
        birthContext(
          birthDate: profile['birthDate'] as String,
          birthTime: profile['birthTime'] as String?,
          birthCountry: profile['birthCountry'] as String?,
          birthTimezone: profile['birthTimezone'] as String?,
        ),
        convention,
      );

  test('hidden stems table matches', () {
    final expected = (corpus['hidden'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).cast<int>())
        .toList();
    expect(hiddenStems, expected);
  });

  test('Ten Gods and branch relations match for every pair', () {
    for (final row in rows(corpus, 'tenGods')) {
      expect(
        tenGod(row['day'] as int, row['other'] as int),
        row['god'],
        reason: '${row['day']}/${row['other']}',
      );
    }
    for (final row in rows(corpus, 'relations')) {
      expect(
        relations(row['a'] as int, row['b'] as int),
        asStrings(row['relations']),
        reason: '${row['a']}/${row['b']}',
      );
    }
  });

  test('charts match, with missing pillars and null Yong Shen preserved', () {
    for (final row in rows(corpus, 'charts')) {
      final profile = row['profile'] as Map<String, dynamic>;
      final chart = chartFrom(profile, row['convention'] as String?);
      final label = '$profile/${row['convention']}';

      final expectedPillars = row['pillars'] as List<dynamic>;
      for (var i = 0; i < expectedPillars.length; i++) {
        expect(
          chart.pillars[i]?.text,
          expectedPillars[i],
          reason: '$label pillar $i',
        );
      }
      expect(
        chart.missing,
        asStrings(row['missing']),
        reason: '$label missing',
      );
      expect(
        chart.coverage,
        closeTo(asDouble(row['coverage']), tolerance),
        reason: '$label coverage',
      );
      expect(
        chart.supportIndex,
        closeTo(asDouble(row['supportIndex']), tolerance),
        reason: '$label support index',
      );
      expect(
        chart.rootPositions,
        (row['rootPositions'] as List<dynamic>).cast<int>(),
        reason: '$label roots',
      );
      expect(
        chart.traditionalYongShen,
        isNull,
        reason: '$label yong shen stays unavailable',
      );
      expect(
        chart.traditionalXiShen,
        isNull,
        reason: '$label xi shen stays unavailable',
      );

      final distribution = asDoubles(row['elementDistribution']);
      for (var i = 0; i < distribution.length; i++) {
        expect(
          chart.elementDistribution[i],
          closeTo(distribution[i], tolerance),
          reason: '$label element $i',
        );
      }
      final seasonal = asDoubles(row['seasonalDistribution']);
      for (var i = 0; i < seasonal.length; i++) {
        expect(
          chart.seasonalDistribution[i],
          closeTo(seasonal[i], tolerance),
          reason: '$label seasonal $i',
        );
      }

      expect(
        chart.structures.length,
        (row['structures'] as List<dynamic>).length,
        reason: '$label structure count',
      );
      expect(
        chart.pairs.length,
        (row['pairs'] as List<dynamic>).length,
        reason: '$label pair count',
      );

      final expectedDecade = row['decade'];
      if (expectedDecade == null) {
        expect(chart.decade, isNull, reason: '$label decade stays unavailable');
      } else {
        final want = expectedDecade as Map<String, dynamic>;
        expect(chart.decade, isNotNull, reason: '$label decade');
        expect(
          chart.decade!.forward,
          want['forward'],
          reason: '$label decade direction',
        );
        expect(
          chart.decade!.startUtc,
          asDouble(want['startUtc']),
          reason: '$label decade start',
        );
        expect(
          chart.decade!.birthZone,
          want['birthZone'],
          reason: '$label decade zone',
        );
        final age = want['startAge'] as Map<String, dynamic>;
        expect(chart.decade!.startAge, <String, int>{
          'years': age['years'] as int,
          'months': age['months'] as int,
          'days': age['days'] as int,
          'hours': age['hours'] as int,
        }, reason: '$label decade start age');
        final term = want['referenceTerm'] as Map<String, dynamic>;
        expect(
          chart.decade!.referenceTerm.name,
          term['name'],
          reason: '$label decade term',
        );
        expect(
          chart.decade!.referenceTerm.instant,
          asDouble(term['instant']),
          reason: '$label decade term instant',
        );
      }
    }
  });

  test('module scores and active decade match at every instant', () {
    for (final row in rows(corpus, 'scores')) {
      final profile = row['profile'] as Map<String, dynamic>;
      final chart = chartFrom(profile, row['convention'] as String?);
      final ms = parseInstant(row['iso']);
      final module = scoreBaZi(chart, calendarAt(ms, zone), ms);
      final label =
          '${profile['birthDate']}/${row['convention']} @ ${row['iso']}';

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

      final decade = decadeAt(chart, ms);
      final expected = row['activeDecade'];
      if (expected == null) {
        expect(decade, isNull, reason: '$label active decade');
      } else {
        final want = expected as Map<String, dynamic>;
        expect(decade, isNotNull, reason: '$label active decade');
        expect(
          decade!.pillar.text,
          want['pillar'],
          reason: '$label decade pillar',
        );
        expect(decade.index, want['index'], reason: '$label decade index');
        expect(
          decade.startUtc,
          asDouble(want['startUtc']),
          reason: '$label decade start',
        );
        expect(
          decade.endUtc,
          asDouble(want['endUtc']),
          reason: '$label decade end',
        );
      }
    }
  });
}
