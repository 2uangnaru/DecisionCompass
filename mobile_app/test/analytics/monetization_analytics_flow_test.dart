import 'package:decision_compass/analytics/analytics_event.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_api_exception.dart';
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:decision_compass/pages/loading_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../reading_test_rig.dart';
import 'analytics_flow_test.dart' show RecordingAnalytics;

final _profile = AppProfile(
  userName: 'Private Name',
  birthDate: DateTime(2001, 2, 12),
  birthCountryCode: 'VN',
  zodiacSign: ZodiacSign.aquarius,
  useCurrentLocation: false,
  safetyAcknowledged: true,
);

Widget _ritual(ReadingTestRig rig) => localizedApp(
  home: RitualPage(
    mode: DecisionMode.yesNo,
    period: TimePeriod.now,
    category: engine.ReadingCategory.general,
    profile: _profile,
    dependencies: rig.dependencies,
  ),
);
Widget _loading(ReadingTestRig rig) => localizedApp(
  home: LoadingPage(
    mode: DecisionMode.yesNo,
    period: TimePeriod.now,
    category: engine.ReadingCategory.general,
    profile: _profile,
    instantUtc: rig.revealInstant,
    dependencies: rig.dependencies,
  ),
);
Future<void> _finish(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

class _RejectCommit extends FakeReadingQuotaController {
  @override
  Future<ReadingEntitlementSource?> consumeReading(DateTime now) async =>
      throw const ReadingQuotaUnavailableException(exhausted: true);
}

void main() {
  setUpAll(loadBundledFonts);
  late RecordingAnalytics analytics;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    analytics = RecordingAnalytics();
  });
  tearDown(() => analytics.dispose());
  List<AnalyticsEvent> events(String name) =>
      analytics.events.where((e) => e.name == name).toList();

  testWidgets(
    'only deliberate locked taps count; timer/rebuilds emit nothing',
    (tester) async {
      useScreen(tester, size: const Size(393, 900));
      final rig = ReadingTestRig(
        analytics: analytics,
        quotaManager: FakeReadingQuotaController(initialCooldown: true),
      );
      await tester.pumpWidget(_ritual(rig));
      await tester.pump(const Duration(seconds: 2));
      expect(events('reading_locked'), isEmpty);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('reveal_button')));
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(events('reading_locked'), hasLength(3));
      for (final event in events('reading_locked')) {
        expect(event.parameters['lock_reason'], 'cooldown');
        expect(event.parameters['lock_stage'], 'ritual');
      }
      await tester.pump(const Duration(seconds: 2));
      expect(events('reading_locked'), hasLength(3));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('primary reward grants a bonus, never an option reward', (
    tester,
  ) async {
    useScreen(tester, size: const Size(393, 900));
    final quota = FakeReadingQuotaController(initialCooldown: true);
    final rig = ReadingTestRig(analytics: analytics, quotaManager: quota);
    await tester.pumpWidget(_ritual(rig));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('ritual_watch_ad_button')));
    await tester.tap(find.byKey(const Key('ritual_watch_ad_button')));
    await tester.pump();
    expect(quota.bonusReadings, 1);
    expect(events('reward_cta_tapped'), hasLength(1));
    expect(events('reward_granted'), hasLength(1));
    expect(events('reward_granted').single.parameters['placement'], 'reading');
    expect(
      events('reward_granted').single.parameters['grant_source'],
      'prototype',
    );
    await tester.pump(const Duration(seconds: 1));
    expect(events('reward_granted'), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final option in ['mode', 'category']) {
    testWidgets(
      '$option unlock does not give a reading credit; cancel emits no reward',
      (tester) async {
        useScreen(tester, size: const Size(393, 900));
        final quota = FakeReadingQuotaController(initialCooldown: true);
        final rig = ReadingTestRig(analytics: analytics, quotaManager: quota);
        await tester.pumpWidget(
          localizedApp(
            home: HomePage(profile: _profile, dependencies: rig.dependencies),
          ),
        );
        await tester.pump();
        final target = option == 'category'
            ? find.byKey(const Key('category_love'))
            : find.text('STAY');
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(events('option_locked'), hasLength(1));
        expect(events('reward_cta_tapped'), isEmpty);
        final sheetContext = tester.element(
          find.byKey(const Key('option_unlock_ad_button')),
        );
        Navigator.of(sheetContext).pop(false);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(events('reward_granted'), isEmpty);
        await tester.tap(target);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.byKey(const Key('option_unlock_ad_button')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(events('reward_granted'), hasLength(1));
        expect(events('reward_granted').single.parameters['placement'], option);
        expect(quota.bonusReadings, 0);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('period unlock is distinct from a reading reward', (
    tester,
  ) async {
    useScreen(tester, size: const Size(393, 900));
    final quota = FakeReadingQuotaController(initialCooldown: true);
    final rig = ReadingTestRig(analytics: analytics, quotaManager: quota);
    await tester.pumpWidget(_ritual(rig));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ritual_period_evening')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(events('option_locked'), hasLength(1));
    await tester.tap(find.byKey(const Key('option_unlock_ad_button')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(events('reward_granted').single.parameters['placement'], 'period');
    expect(
      events('reward_granted').single.parameters['time_period'],
      'evening',
    );
    expect(quota.bonusReadings, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final bonus in [false, true]) {
    testWidgets(
      'successful ${bonus ? 'bonus' : 'free'} commit counted once; no History charge',
      (tester) async {
        useScreen(tester, size: const Size(393, 900));
        final quota = SharedPreferencesReadingQuotaController();
        if (bonus) await quota.earnBonusReading();
        final rig = ReadingTestRig(
          analytics: analytics,
          quotaManager: quota,
          response: fixtureResponse('ready_yes_no_now.json'),
        );
        await tester.pumpWidget(_loading(rig));
        await tester.pump();
        expect(events('reading_entitlement_used'), isEmpty);
        await _finish(tester);
        expect(find.byType(ResultPage), findsOneWidget);
        expect(events('reading_entitlement_used'), hasLength(1));
        expect(
          events('reading_entitlement_used')
              .single
              .parameters['entitlement_source'],
          bonus ? 'bonus' : 'free',
        );
        expect(quota.dailyFreeReadingsUsed(rig.localClock), bonus ? 0 : 1);
        await tester.pumpWidget(
          localizedApp(
            home: ResultPage(
              reading: fixtureResponse('ready_yes_no_now.json'),
              dependencies: rig.dependencies,
              autoSave: false,
            ),
          ),
        );
        await tester.pump();
        expect(events('reading_entitlement_used'), hasLength(1));
        expect(events('reading_completed'), hasLength(1));
        final payload = analytics.events
            .map((e) => e.parameters.toString())
            .join();
        for (final secret in [
          'Private Name',
          'birthDate',
          'birthCountry',
          'readingKey',
          'inputSnapshot',
          'percentages',
        ]) {
          expect(payload, isNot(contains(secret)));
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('failure and retry have no consumption until successful commit', (
    tester,
  ) async {
    useScreen(tester, size: const Size(393, 900));
    final quota = SharedPreferencesReadingQuotaController();
    final rig = ReadingTestRig(
      analytics: analytics,
      quotaManager: quota,
      error: const ReadingApiException(
        kind: ReadingApiFailureKind.network,
        safeCode: 'network_unavailable',
        safeMessage: 'Private error',
      ),
    );
    await tester.pumpWidget(_loading(rig));
    await _finish(tester);
    expect(events('reading_entitlement_used'), isEmpty);
    rig.repository.error = null;
    rig.repository.respondWith(fixtureResponse('ready_yes_no_now.json'));
    await tester.tap(find.byKey(const Key('retry_reading')));
    await _finish(tester);
    expect(events('reading_entitlement_used'), hasLength(1));
    expect(events('reading_failed'), hasLength(1));
    expect(quota.dailyFreeReadingsUsed(rig.localClock), 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final fixture in [
    'synthetic_insufficient_data.json',
    'period_elapsed.json',
  ]) {
    testWidgets('$fixture emits no entitlement use', (tester) async {
      useScreen(tester, size: const Size(393, 900));
      final rig = ReadingTestRig(
        analytics: analytics,
        quotaManager: SharedPreferencesReadingQuotaController(),
        response: fixtureResponse(fixture),
      );
      await tester.pumpWidget(_loading(rig));
      await _finish(tester);
      expect(events('reading_entitlement_used'), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  for (final atCommit in [false, true]) {
    testWidgets(
      '${atCommit ? 'commit' : 'entry'} rejection recorded once, never consumed',
      (tester) async {
        useScreen(tester, size: const Size(393, 900));
        final quota = atCommit
            ? _RejectCommit()
            : FakeReadingQuotaController(initialCooldown: true, initialUsed: 3);
        final rig = ReadingTestRig(
          analytics: analytics,
          quotaManager: quota,
          response: fixtureResponse('ready_yes_no_now.json'),
        );
        await tester.pumpWidget(_loading(rig));
        await _finish(tester);
        expect(events('reading_locked'), hasLength(1));
        expect(
          events('reading_locked').single.parameters['lock_stage'],
          atCommit ? 'commit' : 'loading',
        );
        expect(
          events('reading_locked').single.parameters['lock_reason'],
          'exhausted',
        );
        expect(events('reading_entitlement_used'), isEmpty);
        if (!atCommit) expect(rig.repository.requests, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
