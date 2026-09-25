import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/models.dart';
import 'package:decision_compass/reading_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UI to engine mode mapping', () {
    test('every UI mode maps to its own engine mode', () {
      const expected = {
        DecisionMode.yesNo: engine.DecisionMode.yesNo,
        DecisionMode.actWait: engine.DecisionMode.actWait,
        DecisionMode.advanceRetreat: engine.DecisionMode.advanceRetreat,
        DecisionMode.stayGo: engine.DecisionMode.stayGo,
        DecisionMode.keepLetGo: engine.DecisionMode.keepLetGo,
        DecisionMode.forwardBackward: engine.DecisionMode.forwardBackward,
        DecisionMode.leftRight: engine.DecisionMode.leftRight,
      };

      expect(expected.keys.toSet(), DecisionMode.values.toSet());
      for (final entry in expected.entries) {
        expect(toEngineMode(entry.key), entry.value);
      }
    });

    test('mapping is injective — no mode collapses into another', () {
      final mapped = DecisionMode.values.map(toEngineMode).toSet();
      expect(mapped, hasLength(DecisionMode.values.length));
    });

    test('FORWARD/BACKWARD and LEFT/RIGHT never route through YES/NO', () {
      expect(
        toEngineMode(DecisionMode.forwardBackward).wireValue,
        'forward_backward',
      );
      expect(toEngineMode(DecisionMode.leftRight).wireValue, 'left_right');
      expect(
        toEngineMode(DecisionMode.forwardBackward),
        isNot(engine.DecisionMode.yesNo),
      );
      expect(
        toEngineMode(DecisionMode.leftRight),
        isNot(engine.DecisionMode.yesNo),
      );
    });

    test('round-trips through the engine enum', () {
      for (final mode in DecisionMode.values) {
        expect(fromEngineMode(toEngineMode(mode)), mode);
      }
      for (final mode in engine.DecisionMode.values) {
        expect(toEngineMode(fromEngineMode(mode)), mode);
      }
    });

    test('UI labels match the engine percentage keys for every mode', () {
      // The Result screen reads percentages by label, so the two label sets
      // must not drift apart.
      const engineLabels = {
        engine.DecisionMode.yesNo: ('YES', 'NO'),
        engine.DecisionMode.actWait: ('ACT', 'WAIT'),
        engine.DecisionMode.advanceRetreat: ('ADVANCE', 'RETREAT'),
        engine.DecisionMode.stayGo: ('STAY', 'GO'),
        engine.DecisionMode.keepLetGo: ('KEEP', 'LET GO'),
        engine.DecisionMode.forwardBackward: ('FORWARD', 'BACKWARD'),
        engine.DecisionMode.leftRight: ('LEFT', 'RIGHT'),
      };

      for (final mode in DecisionMode.values) {
        final labels = engineLabels[toEngineMode(mode)]!;
        expect(mode.first, labels.$1);
        expect(mode.second, labels.$2);
      }
    });
  });

  group('UI to engine period mapping', () {
    test('every UI period maps to its own engine period', () {
      const expected = {
        TimePeriod.now: engine.TimePeriod.now,
        TimePeriod.morning: engine.TimePeriod.morning,
        TimePeriod.midday: engine.TimePeriod.midday,
        TimePeriod.afternoon: engine.TimePeriod.afternoon,
        TimePeriod.evening: engine.TimePeriod.evening,
      };

      expect(expected.keys.toSet(), TimePeriod.values.toSet());
      for (final entry in expected.entries) {
        expect(toEnginePeriod(entry.key), entry.value);
      }
    });

    test('mapping is injective and round-trips', () {
      expect(
        TimePeriod.values.map(toEnginePeriod).toSet(),
        hasLength(TimePeriod.values.length),
      );
      for (final period in TimePeriod.values) {
        expect(fromEnginePeriod(toEnginePeriod(period)), period);
      }
      for (final period in engine.TimePeriod.values) {
        expect(toEnginePeriod(fromEnginePeriod(period)), period);
      }
    });
  });

  group('AppProfile to BirthProfile', () {
    AppProfile profileWith({String? birthTime, DateTime? birthDate}) =>
        AppProfile(
          userName: 'Alex',
          birthDate: birthDate ?? DateTime(1998, 6, 21),
          birthTime: birthTime,
          birthCountryCode: 'VN',
          zodiacSign: ZodiacSign.cancer,
          useCurrentLocation: false,
        );

    test('an unknown birth time is sent as null', () {
      expect(profileWith().toBirthProfile().birthTime, isNull);
      expect(
        profileWith().toBirthProfile().toJson().containsKey('birthTime'),
        isFalse,
      );
    });

    test('a known birth time is sent as HH:mm', () {
      final birthProfile = profileWith(birthTime: '09:05').toBirthProfile();
      expect(birthProfile.birthTime, '09:05');
      expect(birthProfile.toJson()['birthTime'], '09:05');
    });

    test('birth date is zero-padded ISO, never a locale format', () {
      expect(
        profileWith(birthDate: DateTime(1998, 6, 2)).formattedBirthDate,
        '1998-06-02',
      );
      expect(
        profileWith(birthDate: DateTime(2001, 11, 30)).formattedBirthDate,
        '2001-11-30',
      );
    });

    test(
      'birth country travels as an ISO code and birth timezone stays null',
      () {
        final birthProfile = profileWith().toBirthProfile();
        expect(birthProfile.birthCountry, 'VN');
        expect(birthProfile.birthTimezone, isNull);
      },
    );

    test('traditional profile is never inferred', () {
      expect(profileWith().traditionalProfile, isNull);
      expect(profileWith().toBirthProfile().traditionalProfile, isNull);
    });
  });
}
