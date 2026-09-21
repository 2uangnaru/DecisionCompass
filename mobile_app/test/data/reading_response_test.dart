import 'package:decision_compass/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_loader.dart';

void main() {
  final fixtures = readAllFixtures();

  group('ReadingResponse.fromJson / toJson round trip', () {
    for (final entry in fixtures.entries) {
      test('parses and round-trips ${entry.key}', () {
        final response = ReadingResponse.fromJson(entry.value);
        final json = response.toJson();

        // Every field the DTO emits must match the payload exactly. The payload
        // may carry extra engine fields the DTO deliberately drops (`segments`
        // diagnostics, and the top-level `meaning` that index.d.ts omits), so
        // this is a subset check rather than whole-map equality.
        for (final field in json.entries) {
          expect(
            field.value,
            equals(entry.value[field.key]),
            reason:
                '${entry.key}: "${field.key}" did not survive the round trip',
          );
        }

        // Re-parsing our own output is stable.
        expect(ReadingResponse.fromJson(json).toJson(), equals(json));
      });
    }
  });

  group('contract coverage across fixtures', () {
    test('every DecisionMode appears in at least one fixture', () {
      final modes = fixtures.values.map(
        (json) => DecisionMode.fromWire(json['mode'] as String),
      );
      expect(modes.toSet(), equals(DecisionMode.values.toSet()));
    });

    test('every TimePeriod appears in at least one fixture', () {
      final periods = fixtures.values.map(
        (json) => TimePeriod.fromWire(json['period'] as String),
      );
      expect(periods.toSet(), equals(TimePeriod.values.toSet()));
    });

    test('every ReadingStatus appears in at least one fixture', () {
      final statuses = fixtures.values.map(
        (json) => ReadingStatus.fromWire(json['status'] as String),
      );
      expect(statuses.toSet(), equals(ReadingStatus.values.toSet()));
    });

    test('every WindowStatus appears in at least one fixture', () {
      final statuses = fixtures.values
          .map((json) => json['windowStatus'])
          .whereType<String>()
          .map((value) => WindowStatus.fromWire(value));
      expect(statuses.toSet(), equals(WindowStatus.values.toSet()));
    });
  });

  group('business invariants', () {
    test('ready/balanced percentages sum to 100', () {
      for (final entry in fixtures.entries) {
        final response = ReadingResponse.fromJson(entry.value);
        if (response.status == ReadingStatus.ready ||
            response.status == ReadingStatus.balanced) {
          final sum = response.percentages!.values.values.fold<int>(
            0,
            (a, b) => a + b,
          );
          expect(
            sum,
            100,
            reason: '${entry.key} percentages should sum to 100',
          );
        }
      }
    });

    test('NOW never has lucky windows', () {
      for (final entry in fixtures.entries) {
        final response = ReadingResponse.fromJson(entry.value);
        if (response.period != TimePeriod.now) continue;
        expect(
          response.luckyWindows,
          isEmpty,
          reason: '${entry.key} is a NOW reading',
        );
        expect(response.windowStatus, WindowStatus.notApplicable);
      }
    });

    test('two_available never exceeds two windows', () {
      for (final entry in fixtures.entries) {
        final response = ReadingResponse.fromJson(entry.value);
        if (response.windowStatus == WindowStatus.twoAvailable) {
          expect(
            response.luckyWindows.length,
            lessThanOrEqualTo(2),
            reason: '${entry.key} should not fabricate more than two windows',
          );
        }
      }
    });

    test(
      'every window is at least 15 minutes, in the future, ranked by score',
      () {
        for (final entry in fixtures.entries) {
          final response = ReadingResponse.fromJson(entry.value);
          final instant = DateTime.parse(response.context.instantUtc);
          double? previousScore;
          for (final window in response.luckyWindows) {
            final start = DateTime.parse(window.startUtc);
            final end = DateTime.parse(window.endUtc);
            expect(
              end.difference(start).inMinutes,
              greaterThanOrEqualTo(15),
              reason: '${entry.key} window shorter than the 15-minute minimum',
            );
            expect(
              start.isBefore(instant),
              isFalse,
              reason: '${entry.key} window starts before the reading instant',
            );
            if (previousScore != null) {
              expect(
                window.score,
                lessThanOrEqualTo(previousScore),
                reason: '${entry.key} windows are not ranked by score',
              );
            }
            previousScore = window.score;
          }
        }
      },
    );

    test('context.instantMs matches context.instantUtc', () {
      for (final entry in fixtures.entries) {
        final response = ReadingResponse.fromJson(entry.value);
        expect(
          response.context.instantMs,
          DateTime.parse(response.context.instantUtc).millisecondsSinceEpoch,
          reason: '${entry.key} has an inconsistent instant',
        );
      }
    });

    test('insufficient_data has null winner and percentages', () {
      final response = ReadingResponse.fromJson(
        fixtures['synthetic_insufficient_data.json']!,
      );
      expect(response.status, ReadingStatus.insufficientData);
      expect(response.winner, isNull);
      expect(response.percentages, isNull);
      expect(response.dataCoverage, isNull);
    });

    test(
      'period_elapsed carries consumeUnlock:false and no window/day fields',
      () {
        final response = ReadingResponse.fromJson(
          fixtures['period_elapsed.json']!,
        );
        expect(response.status, ReadingStatus.periodElapsed);
        expect(response.consumeUnlock, isFalse);
        expect(response.luckyWindows, isEmpty);
        expect(response.windowStatus, isNull);
        expect(response.dailyBrief, isNull);
        expect(response.dataCoverage, isNull);
        expect(response.readingKey, isNull);
      },
    );

    test(
      'unknown birth time surfaces matching warnings and reduced coverage',
      () {
        final response = ReadingResponse.fromJson(
          fixtures['unknown_birth_time_warnings.json']!,
        );
        expect(
          response.warnings.map((w) => w.code),
          contains('unknown_birth_time'),
        );
        expect(response.birthData.timeKnown, isFalse);
        expect(response.dataCoverage, lessThan(1));
      },
    );

    test('a stale location fix falls back to the device timezone', () {
      final response = ReadingResponse.fromJson(
        fixtures['location_fallback_device_timezone.json']!,
      );
      expect(response.context.zoneSource, ZoneSource.device);
      expect(response.context.locationStatus, 'stale_fix');
      expect(response.context.locationZoneCandidates, isEmpty);
      expect(response.status, ReadingStatus.ready);
    });
  });

  group('category is restricted to the single legal MVP value', () {
    test('every fixture parses to ReadingCategory.general', () {
      for (final entry in fixtures.entries) {
        final response = ReadingResponse.fromJson(entry.value);
        expect(response.category, ReadingCategory.general, reason: entry.key);
        expect(response.toJson()['category'], 'general');
      }
    });

    test('any other category throws a typed exception', () {
      for (final illegal in ['medical', 'finance', 'General', '']) {
        final broken = JsonMap.from(fixtures['ready_yes_no_now.json']!)
          ..['category'] = illegal;
        expect(
          () => ReadingResponse.fromJson(broken),
          throwsA(isA<ReadingDtoException>()),
          reason: 'category "$illegal" must be rejected',
        );
      }
    });
  });

  group('parsed readings are immutable', () {
    test('collections on the response reject mutation', () {
      final response = ReadingResponse.fromJson(
        fixtures['ready_forward_backward_two_windows.json']!,
      );

      expect(
        () => response.providers['tzdb'] = 'tampered',
        throwsUnsupportedError,
      );
      expect(
        () => response.warnings.add(const EngineWarning(code: 'fake')),
        throwsUnsupportedError,
      );
      expect(() => response.luckyWindows.removeAt(0), throwsUnsupportedError);
      expect(
        () => response.percentages!.values['FORWARD'] = 99,
        throwsUnsupportedError,
      );
      expect(
        () => response.context.countryCandidates.add('XX'),
        throwsUnsupportedError,
      );
      expect(
        () => response.context.locationZoneCandidates.add('XX'),
        throwsUnsupportedError,
      );
      expect(
        () => response.birthData.timezoneCandidates.clear(),
        throwsUnsupportedError,
      );
    });

    test('nested inputSnapshot data is deeply unmodifiable', () {
      final response = ReadingResponse.fromJson(
        fixtures['ready_yes_no_now.json']!,
      );

      expect(
        () => response.inputSnapshot.raw['profile'] = <String, dynamic>{},
        throwsUnsupportedError,
      );
      final profile =
          response.inputSnapshot.raw['profile'] as Map<String, dynamic>;
      expect(() => profile['birthDate'] = '1900-01-01', throwsUnsupportedError);
    });

    test(
      'mutating the source JSON after parsing cannot poison the reading',
      () {
        final json = readFixture('ready_yes_no_now.json');
        final response = ReadingResponse.fromJson(json);

        (json['providers'] as Map<String, dynamic>)['tzdb'] = 'tampered';
        ((json['inputSnapshot'] as Map<String, dynamic>)['profile']
                as Map<String, dynamic>)['birthDate'] =
            '1900-01-01';

        expect(response.providers['tzdb'], isNot('tampered'));
        expect(
          (response.inputSnapshot.raw['profile']
              as Map<String, dynamic>)['birthDate'],
          isNot('1900-01-01'),
        );
      },
    );
  });

  group('malformed / evolving payloads', () {
    test('a missing required field throws a typed ReadingDtoException', () {
      final broken = JsonMap.from(fixtures['ready_yes_no_now.json']!)
        ..remove('status');
      expect(
        () => ReadingResponse.fromJson(broken),
        throwsA(isA<ReadingDtoException>()),
      );
    });

    test('a required-but-present-with-wrong-type field throws', () {
      final broken = JsonMap.from(fixtures['ready_yes_no_now.json']!)
        ..['engineVersion'] = 42;
      expect(
        () => ReadingResponse.fromJson(broken),
        throwsA(isA<ReadingDtoException>()),
      );
    });

    test('winner missing entirely (not just null) throws', () {
      final broken = JsonMap.from(fixtures['ready_yes_no_now.json']!)
        ..remove('winner');
      expect(
        () => ReadingResponse.fromJson(broken),
        throwsA(isA<ReadingDtoException>()),
      );
    });

    test('an unrecognized enum value throws with a clear message', () {
      final broken = JsonMap.from(fixtures['ready_yes_no_now.json']!)
        ..['status'] = 'future_server_status';
      expect(
        () => ReadingResponse.fromJson(broken),
        throwsA(
          isA<ReadingDtoException>().having(
            (e) => e.message,
            'message',
            contains('future_server_status'),
          ),
        ),
      );
    });

    test('unknown top-level and nested fields from a newer server do not crash parsing', () {
      final future = JsonMap.from(
        fixtures['ready_forward_backward_two_windows.json']!,
      );
      future['futureTopLevelField'] = {'anything': 'goes'};
      future['meaning'] = 'symbolic_alignment_not_success_probability';
      future['segments'] = [
        {
          'startUtc': '2026-09-18T12:00:00.000Z',
          'modules': <String, dynamic>{},
        },
      ];
      final context = JsonMap.from(future['context'] as JsonMap)
        ..['futureNestedField'] = 'ignored-for-now';
      future['context'] = context;

      final response = ReadingResponse.fromJson(future);
      expect(response.status, ReadingStatus.ready);
      expect(response.mode, DecisionMode.forwardBackward);
      expect(response.luckyWindows, hasLength(2));
    });
  });
}
