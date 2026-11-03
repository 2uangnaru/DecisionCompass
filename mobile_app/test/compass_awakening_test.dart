import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/compass_awakening_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  testWidgets('CompassMetaphysicalPillars evaluates all 6 sacred pillars', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(),
      ),
    );
    await tester.pump();

    final BuildContext context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    final profile1 = AppProfile(
      birthDate: DateTime(1990, 5, 15),
      birthCountryCode: 'VN',
      zodiacSign: ZodiacSign.taurus,
      useCurrentLocation: false,
    );

    final pillars1 = CompassMetaphysicalPillars.fromProfile(
      profile1,
      l10n,
      'vi',
    );

    expect(pillars1.zodiacSign, ZodiacSign.taurus);
    expect(pillars1.lifePathNumber, 3); // 1+9+9+0 + 5 + 1+5 = 30 -> 3
    expect(pillars1.planetName, contains('Sao Kim'));
    expect(pillars1.planetGlyph, '♀️');
    expect(pillars1.animalName, contains('Ngọ'));
    expect(pillars1.elementName, contains('Thổ'));
    expect(pillars1.vedicNakshatra.isNotEmpty, isTrue);

    // Profile 2: Scorpio / 1997 / Life Path 6
    final profile2 = AppProfile(
      birthDate: DateTime(1997, 10, 24),
      birthCountryCode: 'VN',
      zodiacSign: ZodiacSign.scorpio,
      useCurrentLocation: false,
    );
    final pillars2 = CompassMetaphysicalPillars.fromProfile(
      profile2,
      l10n,
      'vi',
    );
    expect(pillars2.zodiacSign, ZodiacSign.scorpio);
    expect(pillars2.lifePathNumber, 6);
    expect(pillars2.animalName, contains('Sửu'));
    expect(pillars2.elementName, contains('Thủy'));
  });

  testWidgets(
    'CompassAwakeningPage renders astrolabe and completes animation',
    (tester) async {
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      final rig = ReadingTestRig();
      var completed = false;

      final profile = AppProfile(
        birthDate: DateTime(1990, 5, 15),
        birthCountryCode: 'VN',
        zodiacSign: ZodiacSign.taurus,
        useCurrentLocation: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: CompassAwakeningPage(
            profile: profile,
            dependencies: rig.dependencies,
            animationDuration: const Duration(milliseconds: 1200),
            onCompleted: () => completed = true,
          ),
        ),
      );

      expect(find.byType(CompassAwakeningPage), findsOneWidget);
      expect(completed, isFalse);

      // Advance by 100ms
      await tester.pump(const Duration(milliseconds: 100));
      expect(completed, isFalse);

      // Advance past 300ms
      await tester.pump(const Duration(milliseconds: 1200));
      expect(completed, isTrue);
    },
  );

  testWidgets('CompassAwakeningPage completes immediately on user tap', (
    tester,
  ) async {
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    final rig = ReadingTestRig();
    var completed = false;

    final profile = AppProfile(
      birthDate: DateTime(1990, 5, 15),
      birthCountryCode: 'VN',
      zodiacSign: ZodiacSign.taurus,
      useCurrentLocation: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: CompassAwakeningPage(
          profile: profile,
          dependencies: rig.dependencies,
          animationDuration: const Duration(milliseconds: 3600),
          onCompleted: () => completed = true,
        ),
      ),
    );

    expect(completed, isFalse);

    // Tap anywhere to skip
    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(completed, isTrue);
  });
}
