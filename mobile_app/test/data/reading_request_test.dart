import 'package:decision_compass/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingRequest round trip', () {
    test('full request with location, mode, period and diagnostics', () {
      const request = ReadingRequest(
        profile: BirthProfile(
          birthDate: '1998-06-21',
          birthTime: '14:30',
          birthCountry: 'VN',
          traditionalProfile: TraditionalProfile.male,
          revision: 1,
        ),
        context: CurrentContext(
          instantUtc: '2026-09-18T08:30:00.000Z',
          deviceTimezone: 'Asia/Ho_Chi_Minh',
          location: CurrentLocation(
            latitude: 10.7769,
            longitude: 106.7009,
            accuracyMeters: 100,
            capturedAtUtc: '2026-09-18T08:29:45.000Z',
          ),
        ),
        period: TimePeriod.evening,
        mode: DecisionMode.yesNo,
        diagnostics: false,
      );

      final json = request.toJson();
      final roundTripped = ReadingRequest.fromJson(json);

      expect(roundTripped.toJson(), equals(json));
      expect(json['mode'], 'yes_no');
      expect(json['period'], 'evening');
      expect((json['profile'] as JsonMap)['traditionalProfile'], 'male');
      expect(roundTripped.context.location, isNotNull);
    });

    test('minimal request with unknown birth time and no location omits those keys', () {
      const request = ReadingRequest(
        profile: BirthProfile(birthDate: '1998-06-21'),
        context: CurrentContext(
          instantUtc: '2026-09-18T08:30:00.000Z',
          deviceTimezone: 'Asia/Ho_Chi_Minh',
        ),
      );

      final json = request.toJson();
      expect(json.containsKey('birthTime'), isFalse);
      expect((json['profile'] as JsonMap).containsKey('birthTime'), isFalse);
      expect((json['context'] as JsonMap).containsKey('location'), isFalse);
      expect(json['category'], 'general');

      final roundTripped = ReadingRequest.fromJson(json);
      expect(roundTripped.profile.birthTime, isNull);
      expect(roundTripped.context.location, isNull);
      expect(roundTripped.period, isNull);
      expect(roundTripped.mode, isNull);
    });

    test(
      'traditionalProfile "unspecified" round-trips distinctly from omitted',
      () {
        const withUnspecified = BirthProfile(
          birthDate: '1998-06-21',
          traditionalProfile: TraditionalProfile.unspecified,
        );
        const withOmitted = BirthProfile(birthDate: '1998-06-21');

        expect(withUnspecified.toJson()['traditionalProfile'], 'unspecified');
        expect(withOmitted.toJson().containsKey('traditionalProfile'), isFalse);
      },
    );

    test('missing required profile.birthDate throws a typed exception', () {
      final json = {
        'profile': <String, dynamic>{},
        'context': {
          'instantUtc': '2026-09-18T08:30:00.000Z',
          'deviceTimezone': 'Asia/Ho_Chi_Minh',
        },
      };
      expect(
        () => ReadingRequest.fromJson(json),
        throwsA(isA<ReadingDtoException>()),
      );
    });

    test('category defaults to general and is always serialized', () {
      const request = ReadingRequest(
        profile: BirthProfile(birthDate: '1998-06-21'),
        context: CurrentContext(
          instantUtc: '2026-09-18T08:30:00.000Z',
          deviceTimezone: 'Asia/Ho_Chi_Minh',
        ),
      );

      expect(request.category, ReadingCategory.general);
      expect(request.toJson()['category'], 'general');
    });

    test('any category other than general throws a typed exception', () {
      for (final illegal in ['medical', 'finance', 'General', '']) {
        final json = {
          'profile': {'birthDate': '1998-06-21'},
          'context': {
            'instantUtc': '2026-09-18T08:30:00.000Z',
            'deviceTimezone': 'Asia/Ho_Chi_Minh',
          },
          'category': illegal,
        };
        expect(
          () => ReadingRequest.fromJson(json),
          throwsA(isA<ReadingDtoException>()),
          reason: 'category "$illegal" must be rejected',
        );
      }
    });

    test('an invalid traditionalProfile value throws a typed exception', () {
      final json = {
        'profile': {
          'birthDate': '1998-06-21',
          'traditionalProfile': 'not_a_real_value',
        },
        'context': {
          'instantUtc': '2026-09-18T08:30:00.000Z',
          'deviceTimezone': 'Asia/Ho_Chi_Minh',
        },
      };
      expect(
        () => ReadingRequest.fromJson(json),
        throwsA(isA<ReadingDtoException>()),
      );
    });
  });

  group('enum wire values match the engine contract exactly', () {
    test('DecisionMode', () {
      expect(DecisionMode.values.map((m) => m.wireValue), [
        'yes_no',
        'act_wait',
        'advance_retreat',
        'stay_go',
        'keep_let_go',
        'forward_backward',
        'left_right',
      ]);
    });

    test('TimePeriod', () {
      expect(TimePeriod.values.map((p) => p.wireValue), [
        'now',
        'morning',
        'midday',
        'afternoon',
        'evening',
      ]);
    });

    test('ReadingStatus', () {
      expect(ReadingStatus.values.map((s) => s.wireValue), [
        'ready',
        'balanced',
        'insufficient_data',
        'period_elapsed',
      ]);
    });

    test('WindowStatus', () {
      expect(WindowStatus.values.map((s) => s.wireValue), [
        'not_applicable',
        'two_available',
        'one_remaining',
        'no_15_minute_window',
      ]);
    });

    test('ZoneSource', () {
      expect(ZoneSource.values.map((s) => s.wireValue), ['device', 'location']);
    });

    test('ReadingCategory has exactly one legal value', () {
      expect(ReadingCategory.values.map((c) => c.wireValue), ['general']);
    });

    test('TraditionalProfile', () {
      expect(TraditionalProfile.values.map((s) => s.wireValue), [
        'male',
        'female',
        'male_convention',
        'female_convention',
        'unspecified',
      ]);
    });
  });
}
