import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/theme.dart';
import 'package:decision_compass/widgets/celestial_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  final profile = AppProfile(
    userName: 'Minh Quang',
    birthDate: DateTime(1998, 6, 21),
    birthCountryCode: 'VN',
    zodiacSign: ZodiacSign.capricorn,
    useCurrentLocation: false,
    safetyAcknowledged: true,
  );

  group('Monetization Options Lock - HomePage', () {
    testWidgets('unlocked state when quota is available (free reading ready)', (
      tester,
    ) async {
      useScreen(tester, size: const Size(393, 900));
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        quotaManager: FakeReadingQuotaController(initialCooldown: false),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      // In available state, no AdOptionBadge is shown on Home
      expect(find.byType(AdOptionBadge), findsNothing);

      // User can freely tap love category without any Ad modal
      await tester.ensureVisible(find.byKey(const Key('category_love')));
      await tester.tap(find.byKey(const Key('category_love')));
      await tester.pump();
      expect(find.byKey(const Key('option_unlock_ad_button')), findsNothing);
    });

    testWidgets(
      'gates non-default modes & categories with Ad badge when in cooldown, unlocks via Ad',
      (tester) async {
        useScreen(tester, size: const Size(393, 900));
        final quota = FakeReadingQuotaController(initialCooldown: true);
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
          quotaManager: quota,
          locale: AppLocale.vietnamese,
        );
        await tester.pumpWidget(
          localizedApp(
            theme: buildCompassTheme(),
            locale: AppLocale.vietnamese,
            home: HomePage(profile: profile, dependencies: rig.dependencies),
          ),
        );
        await tester.pump();

        // There should be AdOptionBadges for locked modes and categories
        expect(find.byType(AdOptionBadge), findsWidgets);

        // Tapping default category (general) does not trigger ad modal
        await tester.ensureVisible(find.byKey(const Key('category_general')));
        await tester.tap(find.byKey(const Key('category_general')));
        await tester.pump();
        expect(find.byKey(const Key('option_unlock_ad_button')), findsNothing);

        // Tapping locked category (love) triggers bottom sheet
        await tester.ensureVisible(find.byKey(const Key('category_love')));
        await tester.tap(find.byKey(const Key('category_love')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byKey(const Key('option_unlock_ad_button')), findsOneWidget);
        expect(find.text('Tình cảm & Mối quan hệ'), findsWidgets);

        // Tap watch ad button
        await tester.tap(find.byKey(const Key('option_unlock_ad_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 350));

        // Option is unlocked for selection, but quota must NOT receive bonus readings
        expect(quota.bonusReadings, 0);
        expect(find.text(rig.strings.adUnlockedReward), findsNothing);

        // Individual unlock: Love is unlocked, so tapping it does not open ad modal
        await tester.ensureVisible(find.byKey(const Key('category_love')));
        await tester.tap(find.byKey(const Key('category_love')));
        await tester.pump();
        expect(find.byKey(const Key('option_unlock_ad_button')), findsNothing);

        // Other categories like Career remain locked and still require ad
        await tester.ensureVisible(find.byKey(const Key('category_career')));
        await tester.tap(find.byKey(const Key('category_career')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('option_unlock_ad_button')), findsOneWidget);
      },
    );
  });

  group('Monetization Options Lock - RitualPage', () {
    testWidgets(
      'gates non-default periods when in cooldown and unlocks via Ad',
      (tester) async {
        useScreen(tester, size: const Size(393, 873));
        final quota = FakeReadingQuotaController(initialCooldown: true);
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
          quotaManager: quota,
          locale: AppLocale.vietnamese,
        );

        await tester.pumpWidget(
          localizedApp(
            theme: buildCompassTheme(),
            locale: AppLocale.vietnamese,
            home: RitualPage(
              mode: DecisionMode.yesNo,
              period: TimePeriod.now,
              category: engine.ReadingCategory.general,
              profile: profile,
              dependencies: rig.dependencies,
              isCooldown: true,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Period NOW does not have Ad badge, but other periods have Ad badge
        expect(find.byType(AdOptionBadge), findsWidgets);

        // Check for ChoiceChips
        final periodChips = find.byType(ChoiceChip);
        expect(periodChips, findsWidgets);

        // Tap the unlock Ad button on a locked period if selectable
        for (final period in TimePeriod.values) {
          if (period == TimePeriod.now) continue;
          final chipFinder = find.byKey(Key('ritual_period_${period.name}'));
          if (chipFinder.evaluate().isNotEmpty) {
            await tester.tap(chipFinder);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));

            // If selectable, bottom sheet opens
            if (find.byKey(const Key('option_unlock_ad_button')).evaluate().isNotEmpty) {
              await tester.tap(find.byKey(const Key('option_unlock_ad_button')));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 350));
              await tester.pump(const Duration(milliseconds: 350));

              // Option is unlocked for selection, but quota must NOT receive bonus readings
              expect(quota.bonusReadings, 0);
              expect(find.text(rig.strings.adUnlockedReward), findsNothing);
              break;
            }
          }
        }
      },
    );

    testWidgets(
      'displays quota badge counter accurately inside reveal orb (0/3, 1/3, 3/3, 3/3 (+1))',
      (tester) async {
        useScreen(tester, size: const Size(393, 873));

        // 1. Fresh state: 0/3
        final freshQuota = FakeReadingQuotaController(
          initialCooldown: false,
          initialUsed: 0,
        );
        final freshRig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
          quotaManager: freshQuota,
        );
        await tester.pumpWidget(
          localizedApp(
            theme: buildCompassTheme(),
            home: RitualPage(
              mode: DecisionMode.yesNo,
              period: TimePeriod.now,
              category: engine.ReadingCategory.general,
              profile: profile,
              dependencies: freshRig.dependencies,
              isCooldown: false,
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const Key('ritual_quota_badge')), findsOneWidget);
        expect(find.text('0/3'), findsOneWidget);

        // 2. Cooldown after 1 reading: 1/3
        final coolQuota = FakeReadingQuotaController(
          initialCooldown: true,
          initialUsed: 1,
        );
        final coolRig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
          quotaManager: coolQuota,
        );
        await tester.pumpWidget(
          localizedApp(
            theme: buildCompassTheme(),
            home: RitualPage(
              mode: DecisionMode.yesNo,
              period: TimePeriod.now,
              category: engine.ReadingCategory.general,
              profile: profile,
              dependencies: coolRig.dependencies,
              isCooldown: true,
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const Key('ritual_quota_badge')), findsOneWidget);
        expect(find.text('1/3'), findsOneWidget);

        // 3. Exhausted daily quota: 3/3
        final exhaustQuota = FakeReadingQuotaController(
          initialCooldown: true,
          initialUsed: 3,
        );
        final exhaustRig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
          quotaManager: exhaustQuota,
        );
        await tester.pumpWidget(
          localizedApp(
            theme: buildCompassTheme(),
            home: RitualPage(
              mode: DecisionMode.yesNo,
              period: TimePeriod.now,
              category: engine.ReadingCategory.general,
              profile: profile,
              dependencies: exhaustRig.dependencies,
              isCooldown: true,
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const Key('ritual_quota_badge')), findsOneWidget);
        expect(find.text('3/3'), findsOneWidget);

        // 4. Exhausted but with bonus from reward: 3/3 (+1)
        await exhaustQuota.earnBonusReading();
        await tester.pump();
        expect(find.text('3/3 (+1)'), findsOneWidget);
      },
    );
  });
}
