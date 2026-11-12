import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/billing/plus_billing.dart';
import 'package:decision_compass/billing/plus_demo.dart';
import 'package:decision_compass/data/guidance_lock_store.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:decision_compass/theme.dart';
import 'package:decision_compass/widgets/astracue_plus_ui.dart';
import 'package:decision_compass/widgets/celestial_ui.dart';
import 'package:decision_compass/widgets/responsible_use_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

void main() {
  setUpAll(loadBundledFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final profile = AppProfile(
    userName: 'Minh Quang',
    birthDate: DateTime(1998, 6, 21),
    birthCountryCode: 'VN',
    zodiacSign: ZodiacSign.capricorn,
    useCurrentLocation: false,
    safetyAcknowledged: true,
  );

  test('AdConstants disables ads by default when ADS_ENABLED is omitted', () {
    expect(AdConstants.adsEnabled, isFalse);
    expect(AdConstants.realAndroidInterstitialUnitId, isEmpty);
    expect(AdConstants.realAndroidRewardedUnitId, isEmpty);
  });

  testWidgets(
    'HomePage hides AD badges and allows selection during cooldown when adsEnabled is false',
    (tester) async {
      useScreen(tester, size: const Size(393, 900));
      final quota = FakeReadingQuotaController(initialCooldown: true);
      final rig = ReadingTestRig(
        quotaManager: quota,
        locale: AppLocale.vietnamese,
        adService: const NoOpAdService(),
        adsEnabled: false,
      );
      await tester.pumpWidget(
        localizedApp(
          theme: buildCompassTheme(),
          locale: AppLocale.vietnamese,
          home: HomePage(profile: profile, dependencies: rig.dependencies),
        ),
      );
      await tester.pump();

      expect(find.byType(AdOptionBadge), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('category_love')));
      await tester.tap(find.byKey(const Key('category_love')));
      await tester.pump();

      expect(
        tester.widget<GlassCard>(find.byKey(const Key('category_love'))).selected,
        isTrue,
      );
      expect(find.text(rig.strings.adNotReady), findsNothing);
    },
  );

  testWidgets(
    'RitualPage hides Watch Ad button and period AD badges when adsEnabled is false',
    (tester) async {
      useScreen(tester, size: const Size(393, 873));
      final quota = FakeReadingQuotaController(initialCooldown: true);
      final rig = ReadingTestRig(
        quotaManager: quota,
        locale: AppLocale.vietnamese,
        adService: const NoOpAdService(),
        adsEnabled: false,
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

      expect(find.byType(AdOptionBadge), findsNothing);
      expect(find.byKey(const Key('ritual_watch_ad_button')), findsNothing);
      expect(find.byKey(const Key('banner_layout_slot')), findsNothing);
    },
  );

  testWidgets(
    'ResultPage leaves Action Guidance unlocked when adsEnabled is false',
    (tester) async {
      useScreen(tester, size: const Size(412, 2400));
      final store = GuidanceLockStore();
      await tester.runAsync(() async {
        await store.admit('earlier_0');
        await store.admit('earlier_1');
        await store.admit('earlier_2');
      });
      final reading = fixtureResponse('ready_yes_no_now.json');
      final rig = ReadingTestRig(
        guidanceLocks: store,
        adService: const NoOpAdService(),
        adsEnabled: false,
      );
      await tester.pumpWidget(
        localizedApp(
          home: ResultPage(
            reading: reading,
            dependencies: rig.dependencies,
            autoSave: true,
            billableResult: true,
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('result_guidance_watch_ad_button')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'ResponsibleUseSheet renders Privacy Policy only for HTTPS URL and invokes channel',
    (tester) async {
      useScreen(tester, size: const Size(393, 900));
      const channel = MethodChannel('astracue/external_links');
      final openedUrls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'openHttpsUrl' && call.arguments is String) {
          openedUrls.add(call.arguments as String);
          return true;
        }
        return false;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );

      await tester.pumpWidget(
        localizedApp(
          home: const Scaffold(
            body: ResponsibleUseSheet(
              privacyPolicyUrl: 'http://insecure.example.com/privacy',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('privacy_policy_link')), findsNothing);

      await tester.pumpWidget(
        localizedApp(
          home: const Scaffold(
            body: ResponsibleUseSheet(
              privacyPolicyUrl: 'https://astracue.example.com/privacy',
            ),
          ),
        ),
      );
      await tester.pump();

      final link = find.byKey(const Key('privacy_policy_link'));
      expect(link, findsOneWidget);
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pump();

      expect(openedUrls, ['https://astracue.example.com/privacy']);
    },
  );

  test(
    'PlusBillingConfig disables VIP by default even if PLUS_DEMO_BILLING=true',
    () {
      expect(PlusBillingConfig.plusEnabled, isFalse);
      expect(effectiveDemoPlusBilling(demoBilling: true), isFalse);
      expect(
        effectiveDemoPlusBilling(plusEnabled: true, demoBilling: true),
        isTrue,
      );
    },
  );

  testWidgets(
    'HomePage hides header Plus badge and Plus tray upsell when plusEnabled is false',
    (tester) async {
      useScreen(tester, size: const Size(393, 900));
      final rig = ReadingTestRig(
        locale: AppLocale.vietnamese,
        adService: const NoOpAdService(),
        adsEnabled: false,
        plusEnabled: false,
      );
      await tester.pumpWidget(
        localizedApp(
          theme: buildCompassTheme(),
          locale: AppLocale.vietnamese,
          home: HomePage(profile: profile, dependencies: rig.dependencies),
        ),
      );
      await tester.pump();

      expect(find.byType(AstraCuePlusHeaderBadge), findsNothing);
      final tray = find.byKey(const Key('home_daily_energy_tray'));
      expect(tray, findsOneWidget);
      expect(find.textContaining('✦ PLUS'), findsNothing);

      await tester.ensureVisible(tray);
      await tester.tap(tray);
      await tester.pump();
      expect(find.byKey(const Key('astracue_plus_sheet')), findsNothing);
    },
  );

  testWidgets(
    'RitualPage hides AnalysisEnergyPlusCard when plusEnabled is false',
    (tester) async {
      useScreen(tester, size: const Size(393, 873));
      final rig = ReadingTestRig(
        locale: AppLocale.vietnamese,
        adService: const NoOpAdService(),
        adsEnabled: false,
        plusEnabled: false,
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
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const Key('ritual_energy_plus_card')), findsNothing);
    },
  );

  testWidgets(
    'ResultPage keeps free energy status non-tappable and hides Plus gem when plusEnabled is false',
    (tester) async {
      useScreen(tester, size: const Size(412, 2400));
      final reading = fixtureResponse('ready_yes_no_now.json');
      final rig = ReadingTestRig(
        locale: AppLocale.vietnamese,
        adService: const NoOpAdService(),
        adsEnabled: false,
        plusEnabled: false,
      );
      await tester.pumpWidget(
        localizedApp(
          home: ResultPage(
            reading: reading,
            dependencies: rig.dependencies,
            autoSave: false,
            billableResult: false,
          ),
        ),
      );
      await tester.pump();

      final card = find.byKey(const Key('result_energy_plus_card'));
      expect(card, findsOneWidget);
      expect(find.textContaining('✦ PLUS'), findsNothing);

      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pump();
      expect(find.byKey(const Key('astracue_plus_sheet')), findsNothing);
    },
  );
}
