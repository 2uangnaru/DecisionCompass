import 'package:decision_compass/app.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  test('AppProfile round-trips through JSON, re-deriving the zodiac sign', () {
    final profile = AppProfile(
      userName: 'Alex',
      birthDate: DateTime(1998, 6, 21),
      birthTime: '14:30',
      birthCountryCode: 'VN',
      traditionalProfile: engine.TraditionalProfile.femaleConvention,
      // Deliberately wrong, to prove it is re-derived rather than trusted.
      zodiacSign: ZodiacSign.aries,
      useCurrentLocation: true,
    );

    final restored = AppProfile.fromJson(profile.toJson());

    expect(restored.userName, 'Alex');
    expect(restored.birthDate, DateTime(1998, 6, 21));
    expect(restored.birthTime, '14:30');
    expect(restored.birthCountryCode, 'VN');
    expect(
      restored.traditionalProfile,
      engine.TraditionalProfile.femaleConvention,
    );
    expect(restored.useCurrentLocation, isTrue);
    expect(restored.zodiacSign, zodiacForDate(DateTime(1998, 6, 21)));
  });

  test('an unknown birth time and unset traditional profile round-trip as '
      'null, never a placeholder', () {
    final profile = AppProfile(
      userName: 'Alex',
      birthDate: DateTime(1998, 6, 21),
      birthCountryCode: 'US',
      zodiacSign: ZodiacSign.gemini,
      useCurrentLocation: false,
    );

    final restored = AppProfile.fromJson(profile.toJson());
    expect(restored.birthTime, isNull);
    expect(restored.traditionalProfile, isNull);
    expect(restored.useCurrentLocation, isFalse);
  });

  testWidgets(
    'completing onboarding persists the profile, so a fresh app instance '
    'reading the same storage opens straight to Home',
    (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      expect(find.text('Caught between choices?'), findsOneWidget);

      // Simulate a cold relaunch: a brand new `DecisionCompassApp` instance
      // reading from the same (in this test, in-memory) profile storage.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        DecisionCompassApp(dependencies: rig.dependencies),
      );
      await tester.pump();

      expect(find.text('Caught between choices?'), findsOneWidget);
      expect(find.text('Read the moment\nwhere you are.'), findsNothing);
    },
  );

  testWidgets('with no saved profile, the app still starts at onboarding', (
    tester,
  ) async {
    final rig = ReadingTestRig();
    await tester.pumpWidget(rig.app);
    await tester.pump();

    expect(find.text('Read the moment\nwhere you are.'), findsOneWidget);
  });
}
