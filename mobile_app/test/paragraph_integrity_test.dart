import 'package:flutter_test/flutter_test.dart';
import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/action_guidance.dart';
import 'package:decision_compass/data/models/models.dart';

import 'data/fixture_loader.dart';

void main() {
  group('Paragraph Integrity and Clean Formatting Audit', () {
    test('all locales, modes, categories, and periods format clean 2-paragraph headlines without artifacts', () {
      final sampleDates = [
        '1995-05-15T00:00:00.000Z',
        '2000-11-20T00:00:00.000Z',
        '1988-02-04T00:00:00.000Z',
        null,
      ];
      final sampleCountries = ['VN', 'US', 'IN', 'JP', null];

      int totalChecked = 0;
      final errors = <String>[];

      for (final locale in AppLocale.values) {
        for (final category in ReadingCategory.values) {
          for (final period in TimePeriod.values) {
            for (final mode in DecisionMode.values) {
              for (final date in sampleDates) {
                final country = sampleCountries[totalChecked % sampleCountries.length];

                final json = readFixture('ready_yes_no_now.json');
                json['mode'] = mode.wireValue;
                json['category'] = category.wireValue;
                json['period'] = period.wireValue;
                json['winner'] = 'YES';
                json['readingKey'] = 'audit_$totalChecked';
                final snapshot = Map<String, Object?>.from(json['inputSnapshot']! as JsonMap);
                snapshot['mode'] = mode.wireValue;
                final profile = <String, Object?>{};
                if (date != null) profile['birthDate'] = date;
                if (country != null) profile['birthCountry'] = country;
                snapshot['profile'] = profile;
                json['inputSnapshot'] = snapshot;

                final reading = ReadingResponse.fromJson(json);

                final guidance = resolveActionGuidance(locale: locale, reading: reading);
                final headline = guidance.headline;

                // 1. Must split into exactly 2 paragraphs
                final paragraphs = headline.split('\n\n');
                if (paragraphs.length != 2) {
                  errors.add('${locale.tag} $category $period $mode: expected 2 paragraphs but got ${paragraphs.length}\nText: $headline');
                  continue;
                }

                final p1 = paragraphs[0].trim();
                final p2 = paragraphs[1].trim();

                // 2. Neither paragraph should be empty
                if (p1.isEmpty || p2.isEmpty) {
                  errors.add('${locale.tag} $category $period $mode: empty paragraph\nP1: "$p1"\nP2: "$p2"');
                }

                // 3. Check for awkward punctuation artifacts: ,, or .. or ,. or dangling comma at end
                if (p1.contains(',,') || p1.contains('..') || p1.contains(',.') || p1.endsWith(',')) {
                  errors.add('${locale.tag} $category $period $mode: awkward punctuation in P1: "$p1"');
                }
                if (p2.contains(',,') || p2.contains('..') || p2.contains(',.') || p2.endsWith(',')) {
                  errors.add('${locale.tag} $category $period $mode: awkward punctuation in P2: "$p2"');
                }

                // 4. In Latin languages (vi, en, es), verify capitalization and terminal period
                if (locale == AppLocale.vietnamese || locale == AppLocale.english || locale == AppLocale.spanish) {
                  if (!p1.endsWith('.')) {
                    errors.add('${locale.tag} P1 does not end with period: "$p1"');
                  }
                  if (!p2.endsWith('.')) {
                    errors.add('${locale.tag} P2 does not end with period: "$p2"');
                  }
                  if (p2[0] != p2[0].toUpperCase()) {
                    errors.add('${locale.tag} P2 does not start with capital letter: "$p2"');
                  }
                }

                // 5. In Chinese & Japanese, verify full-width terminal period
                if (locale == AppLocale.simplifiedChinese || locale == AppLocale.japanese) {
                  if (!p1.endsWith('。')) {
                    errors.add('${locale.tag} P1 does not end with 。: "$p1"');
                  }
                  if (!p2.endsWith('。')) {
                    errors.add('${locale.tag} P2 does not end with 。: "$p2"');
                  }
                }

                totalChecked++;
              }
            }
          }
        }
      }

      expect(errors, isEmpty, reason: errors.take(10).join('\n'));
    });

    test('balanced readings also produce clean, non-empty 2-paragraph headlines', () {
      final errors = <String>[];
      for (final locale in AppLocale.values) {
        for (final category in ReadingCategory.values) {
          final json = readFixture('ready_yes_no_now.json');
          json['status'] = 'balanced';
          json['winner'] = null;
          json['category'] = category.wireValue;
          final reading = ReadingResponse.fromJson(json);

          final guidance = resolveActionGuidance(locale: locale, reading: reading);
          final headline = guidance.headline;

          final paragraphs = headline.split('\n\n');
          if (paragraphs.length != 2) {
            errors.add('${locale.tag} balanced $category: expected 2 paragraphs, got ${paragraphs.length}\n$headline');
            continue;
          }

          final p1 = paragraphs[0].trim();
          final p2 = paragraphs[1].trim();
          if (p1.isEmpty || p2.isEmpty) {
            errors.add('${locale.tag} balanced $category has empty paragraph');
          }
        }
      }
      expect(errors, isEmpty, reason: errors.join('\n'));
    });
  });
}
