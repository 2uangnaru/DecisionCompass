import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/compass_awakening_page.dart';
import 'package:decision_compass/pages/history_page.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:decision_compass/pages/loading_page.dart';
import 'package:decision_compass/pages/onboarding_page.dart';
import 'package:decision_compass/pages/profile_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:decision_compass/widgets/astracue_plus_ui.dart';
import 'package:decision_compass/widgets/celestial_network_dialog.dart';
import 'package:decision_compass/widgets/celestial_ui.dart';
import 'package:decision_compass/widgets/responsible_use_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

void main() {
  setUpAll(loadBundledFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final profile = AppProfile(
    userName: 'Alexandro Nguyễn',
    birthDate: DateTime(1998, 6, 21),
    birthTime: '14:30',
    birthCountryCode: 'VN',
    zodiacSign: ZodiacSign.cancer,
    useCurrentLocation: false,
    safetyAcknowledged: true,
  );

  const viewports = <({String label, Size size})>[
    (label: 'xs-phone 320x568', size: Size(320, 568)),
    (label: 'compact-phone 360x640', size: Size(360, 640)),
    (label: 'std-phone 393x852', size: Size(393, 852)),
    (label: 'landscape-phone 640x360', size: Size(640, 360)),
    (label: 'tablet-portrait 768x1024', size: Size(768, 1024)),
    (label: 'tablet-landscape 1024x768', size: Size(1024, 768)),
  ];

  void expectNoLayoutTrouble(WidgetTester tester, String where) {
    final thrown = tester.takeException();
    if (thrown == null) return;
    if ('$thrown'.contains('is not supported by all of its localization')) {
      return;
    }
    fail('$where: $thrown');
  }

  void expectWithinViewport(WidgetTester tester, Finder finder, Size viewport, String where) {
    final rect = tester.getRect(finder);
    expect(rect.width, greaterThan(0), reason: '$where: zero width');
    expect(rect.height, greaterThan(0), reason: '$where: zero height');
    expect(
      rect.left,
      greaterThanOrEqualTo(-0.5),
      reason: '$where: clipped off left (${rect.left})',
    );
    expect(
      rect.right,
      lessThanOrEqualTo(viewport.width + 0.5),
      reason: '$where: clipped off right (${rect.right} > ${viewport.width})',
    );
    if (viewport.width > 640) {
      // CelestialScaffold centers content at maxWidth 640 on tablet/landscape.
      expect(
        rect.width,
        lessThanOrEqualTo(640.5),
        reason: '$where: exceeded 640dp max content width (${rect.width})',
      );
    }
  }

  ReadingTestRig makeRig({
    required AppLocale locale,
    ReadingQuotaController? quota,
    Object? error,
  }) {
    final rig = ReadingTestRig(
      locale: locale,
      quotaManager: quota ?? FakeReadingQuotaController(),
      adService: const NoOpAdService(),
      adsEnabled: false,
      plusEnabled: false,
      privacyPolicyUrl: 'https://astracue.example.com/privacy',
      response: fixtureResponse('ready_commit_withdraw_two_windows.json'),
      error: error,
    );
    rig.dailyBriefProvider.response = engine.DailyBrief(
      luckyNumber: 7,
      colors: testDailyColors(),
      energy: const engine.DailyEnergy(
        level: 'radiant',
        index: 71,
        dataCoverage: 1,
      ),
    );
    return rig;
  }

  group('Multi-screen responsive layout across viewports with Ads=OFF & VIP=OFF', () {
    for (final vp in viewports) {
      for (final scale in const [1.0, 1.5]) {
        // Check all 8 locales on tight phones, landscape, and tablet portrait,
        // and representative scripts on the larger viewports.
        final localesToCheck =
            (vp.label.startsWith('xs-phone') ||
                vp.label.startsWith('compact-phone') ||
                vp.label.startsWith('landscape-phone') ||
                vp.label.startsWith('tablet-portrait'))
            ? AppLocale.values
            : const [
                AppLocale.vietnamese,
                AppLocale.english,
                AppLocale.spanish,
                AppLocale.hindi,
                AppLocale.thai,
                AppLocale.japanese,
              ];

        for (final locale in localesToCheck) {
          final tag = '${vp.label} | ${locale.tag} | scale=$scale';

          testWidgets('Onboarding (welcome + profile) [$tag]', (tester) async {
            useScreen(tester, size: vp.size, textScale: scale);
            final rig = makeRig(locale: locale);
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: OnboardingPage(dependencies: rig.dependencies),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expectNoLayoutTrouble(tester, 'Onboarding welcome $tag');
            expectWithinViewport(
              tester,
              find.byKey(const Key('welcome_language_card')),
              vp.size,
              'welcome_language_card $tag',
            );

            await tester.ensureVisible(find.byKey(const Key('continue_to_profile')));
            await tester.tap(find.byKey(const Key('continue_to_profile')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            expectNoLayoutTrouble(tester, 'Onboarding profile $tag');
          });

          testWidgets('CompassAwakeningPage [$tag]', (tester) async {
            useScreen(tester, size: vp.size, textScale: scale);
            final rig = makeRig(locale: locale);
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: CompassAwakeningPage(
                  profile: profile,
                  dependencies: rig.dependencies,
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 3100));
            expectNoLayoutTrouble(tester, 'CompassAwakeningPage $tag');

            final astrolabe = tester.getRect(
              find.byKey(const Key('compass_awakening_astrolabe')),
            );
            final status = tester.getRect(
              find.byKey(const Key('compass_awakening_status')),
            );
            expect(
              astrolabe.top,
              greaterThanOrEqualTo(-0.5),
              reason: 'CompassAwakeningPage astrolabe clipped top $tag',
            );
            expect(
              astrolabe.bottom,
              lessThanOrEqualTo(status.top + 0.5),
              reason: 'CompassAwakeningPage astrolabe overlaps status $tag',
            );
            expect(
              status.bottom,
              lessThanOrEqualTo(vp.size.height + 0.5),
              reason: 'CompassAwakeningPage status clipped bottom $tag',
            );
          });

          testWidgets('HomePage ready + cooldown settings open + exhausted [$tag]', (
            tester,
          ) async {
            useScreen(tester, size: vp.size, textScale: scale);
            final quota = FakeReadingQuotaController(
              initialCooldown: true,
              initialUsed: 1,
            );
            final rig = makeRig(locale: locale, quota: quota);
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: HomePage(profile: profile, dependencies: rig.dependencies),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
            expectNoLayoutTrouble(tester, 'HomePage cooldown $tag');

            expect(find.byType(AstraCuePlusHeaderBadge), findsNothing);
            expect(find.byType(AdOptionBadge), findsNothing);
            expect(find.byKey(const Key('banner_layout_slot')), findsNothing);
            expect(find.textContaining('✦ PLUS'), findsNothing);

            final tray = find.byKey(const Key('home_daily_energy_tray'));
            expect(tray, findsOneWidget);
            expectWithinViewport(tester, tray, vp.size, 'Home energy tray $tag');

            // Expand header settings capsule to verify it never overflows on small screens
            await tester.ensureVisible(find.byKey(const Key('home_settings_button')));
            await tester.tap(find.byKey(const Key('home_settings_button')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 350));
            expectNoLayoutTrouble(tester, 'HomePage settings open $tag');

            // Switch to exhausted state (0/3 remaining)
            quota.setUsedToday(3);
            await tester.pump();
            expectNoLayoutTrouble(tester, 'HomePage exhausted $tag');
          });

          testWidgets('RitualPage ready, cooldown+notice, exhausted [$tag]', (
            tester,
          ) async {
            useScreen(tester, size: vp.size, textScale: scale);
            final quota = FakeReadingQuotaController(
              initialCooldown: false,
              initialUsed: 0,
            );
            final rig = makeRig(locale: locale, quota: quota);
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: RitualPage(
                  mode: DecisionMode.commitWithdraw,
                  period: TimePeriod.now,
                  category: engine.ReadingCategory.career,
                  profile: profile,
                  dependencies: rig.dependencies,
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expectNoLayoutTrouble(tester, 'RitualPage ready $tag');

            expect(find.byType(AdOptionBadge), findsNothing);
            expect(find.byKey(const Key('ritual_watch_ad_button')), findsNothing);
            expect(find.byKey(const Key('ritual_energy_plus_card')), findsNothing);
            expect(find.byKey(const Key('banner_layout_slot')), findsNothing);

            // Switch to cooldown & tap reveal to trigger locked notice overlay
            quota.setCooldown(true);
            quota.setUsedToday(1);
            await tester.pump();
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: RitualPage(
                  mode: DecisionMode.commitWithdraw,
                  period: TimePeriod.now,
                  category: engine.ReadingCategory.career,
                  profile: profile,
                  dependencies: rig.dependencies,
                  isCooldown: true,
                ),
              ),
            );
            await tester.pump();
            await tester.ensureVisible(find.byKey(const Key('reveal_button')));
            await tester.tap(find.byKey(const Key('reveal_button')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expectNoLayoutTrouble(tester, 'RitualPage cooldown+notice $tag');
            expect(find.byKey(const Key('ritual_locked_notice')), findsOneWidget);

            // Switch to exhausted state
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: RitualPage(
                  mode: DecisionMode.commitWithdraw,
                  period: TimePeriod.now,
                  category: engine.ReadingCategory.career,
                  profile: profile,
                  dependencies: rig.dependencies,
                  isCooldown: true,
                  isQuotaExhausted: true,
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expectNoLayoutTrouble(tester, 'RitualPage exhausted $tag');
          });

          testWidgets('LoadingPage & Error view [$tag]', (tester) async {
            useScreen(tester, size: vp.size, textScale: scale);
            final rig = makeRig(
              locale: locale,
              quota: FakeReadingQuotaController(initialCooldown: true),
            );
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: LoadingPage(
                  mode: DecisionMode.advanceRetreat,
                  period: TimePeriod.now,
                  category: engine.ReadingCategory.money,
                  profile: profile,
                  instantUtc: DateTime.utc(2026, 9, 18, 1, 30),
                  dependencies: rig.dependencies,
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));
            expectNoLayoutTrouble(tester, 'LoadingPage spinner $tag');

            // Fast-forward past _minimumRitual (5300ms) to trigger _ReadingErrorView for cooldown
            await tester.pump(const Duration(milliseconds: 5400));
            await tester.pump();
            expectNoLayoutTrouble(tester, 'LoadingPage quota error $tag');
            expect(find.text(lookupAppLocalizations(locale.locale).watchAdPrompt), findsNothing);
          });

          testWidgets('ResultPage [$tag]', (tester) async {
            useScreen(tester, size: vp.size, textScale: scale);
            final quota = FakeReadingQuotaController(
              initialCooldown: true,
              initialUsed: 2,
            );
            final rig = makeRig(locale: locale, quota: quota);
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: ResultPage(
                  reading: fixtureResponse('ready_commit_withdraw_two_windows.json'),
                  dependencies: rig.dependencies,
                  autoSave: false,
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));
            expectNoLayoutTrouble(tester, 'ResultPage $tag');

            expect(find.byKey(const Key('result_guidance_watch_ad_button')), findsNothing);
            expect(find.textContaining('✦ PLUS'), findsNothing);
            expectWithinViewport(
              tester,
              find.byKey(const Key('result_energy_plus_card')),
              vp.size,
              'result_energy_plus_card $tag',
            );
            expectWithinViewport(
              tester,
              find.byKey(const Key('result_cosmic_context')),
              vp.size,
              'result_cosmic_context $tag',
            );
            expectWithinViewport(
              tester,
              find.byKey(const Key('result_action_guidance')),
              vp.size,
              'result_action_guidance $tag',
            );
          });

          testWidgets('ProfilePage, HistoryPage, ResponsibleUseSheet & NetworkDialog [$tag]', (
            tester,
          ) async {
            useScreen(tester, size: vp.size, textScale: scale);
            final rig = makeRig(locale: locale);
            final now = rig.dependencies.nowUtc();

            // 1. ProfilePage with all 3 locks active
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: ProfilePage(
                  profile: profile.copyWith(
                    birthTimeChangedAtUtc: now.subtract(const Duration(minutes: 5)),
                    birthCountryChangedAtUtc: now.subtract(const Duration(minutes: 5)),
                    birthDateChangedAtUtc: now.subtract(const Duration(minutes: 5)),
                  ),
                  dependencies: rig.dependencies,
                ),
              ),
            );
            await tester.pump();
            expectNoLayoutTrouble(tester, 'ProfilePage $tag');

            // 2. HistoryPage with entry
            await rig.historyRepository.save(
              historyEntryFor(fixtureResponse('ready_commit_withdraw_two_windows.json')),
            );
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: HistoryPage(dependencies: rig.dependencies),
              ),
            );
            await tester.pumpAndSettle();
            expectNoLayoutTrouble(tester, 'HistoryPage $tag');

            // 3. ResponsibleUseSheet (with Privacy Policy URL)
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: const Scaffold(
                  body: ResponsibleUseSheet(
                    privacyPolicyUrl: 'https://astracue.example.com/privacy',
                  ),
                ),
              ),
            );
            await tester.pump();
            expectNoLayoutTrouble(tester, 'ResponsibleUseSheet $tag');

            // 4. CelestialNetworkDialog + Still Offline state
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        key: const Key('open_net'),
                        onPressed: () {
                          showCelestialNetworkDialog(
                            context,
                            isOnline: () async => false,
                            manualDelay: Duration.zero,
                          );
                        },
                        child: const Text('open'),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(find.byKey(const Key('open_net')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));
            expectNoLayoutTrouble(tester, 'CelestialNetworkDialog $tag');
            final retryBtn = find.byKey(const Key('network_retry'));
            await tester.ensureVisible(retryBtn);
            await tester.tap(retryBtn);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));
            expectNoLayoutTrouble(tester, 'CelestialNetworkDialog stillOffline $tag');
          });
        }
      }
    }
  });
}
