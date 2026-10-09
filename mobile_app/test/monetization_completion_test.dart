import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_api_exception.dart';
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/loading_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/reading_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

final _profile = AppProfile(
  userName: 'Alex',
  birthDate: DateTime(2001, 2, 12),
  birthCountryCode: 'VN',
  zodiacSign: ZodiacSign.aquarius,
  useCurrentLocation: false,
  safetyAcknowledged: true,
);

ReadingDependencies _deps(ReadingTestRig rig, ReadingQuotaController quota) {
  final d = rig.dependencies;
  return ReadingDependencies(
    repository: d.repository,
    contextProvider: d.contextProvider,
    historyRepository: d.historyRepository,
    profileRepository: d.profileRepository,
    dailyBriefProvider: d.dailyBriefProvider,
    homeDescriptionDeck: d.homeDescriptionDeck,
    dailyEnergyInsights: d.dailyEnergyInsights,
    localeController: d.localeController,
    quotaManager: quota,
    nowUtc: d.nowUtc,
    nowLocal: d.nowLocal,
  );
}

Widget _loading(ReadingTestRig rig, ReadingQuotaController quota) =>
    localizedApp(
      home: LoadingPage(
        mode: DecisionMode.yesNo,
        period: TimePeriod.now,
        category: engine.ReadingCategory.general,
        profile: _profile,
        instantUtc: rig.revealInstant,
        dependencies: _deps(rig, quota),
      ),
    );

Future<void> _finish(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final fixture in ['ready_yes_no_now.json', 'synthetic_balanced.json']) {
    testWidgets(
      'successful $fixture commits once, only after the result exists',
      (tester) async {
        final q = SharedPreferencesReadingQuotaController();
        final rig = ReadingTestRig(response: fixtureResponse(fixture));
        await tester.pumpWidget(_loading(rig, q));
        await tester.pump();
        expect(q.dailyFreeReadingsUsed(rig.localClock), 0);
        await _finish(tester);
        expect(find.byType(ResultPage), findsOneWidget);
        expect(q.dailyFreeReadingsUsed(rig.localClock), 1);
        await tester.pump();
        expect(q.dailyFreeReadingsUsed(rig.localClock), 1);
      },
    );
  }
  for (final fixture in [
    'synthetic_insufficient_data.json',
    'period_elapsed.json',
  ]) {
    testWidgets('$fixture preserves the bonus credit', (tester) async {
      final q = SharedPreferencesReadingQuotaController();
      await q.earnBonusReading();
      final rig = ReadingTestRig(response: fixtureResponse(fixture));
      await tester.pumpWidget(_loading(rig, q));
      await _finish(tester);
      expect(find.byType(ResultPage), findsOneWidget);
      expect(q.bonusReadings, 1);
      expect(q.dailyFreeReadingsUsed(rig.localClock), 0);
    });
  }
  testWidgets('failure and repeated retry preserve credit until one success', (
    tester,
  ) async {
    final q = SharedPreferencesReadingQuotaController();
    await q.earnBonusReading();
    final rig = ReadingTestRig(
      error: const ReadingApiException(
        kind: ReadingApiFailureKind.network,
        safeCode: 'network_unavailable',
        safeMessage: 'Unable to connect.',
      ),
    );
    await tester.pumpWidget(_loading(rig, q));
    await _finish(tester);
    expect(q.bonusReadings, 1);
    expect(q.dailyFreeReadingsUsed(rig.localClock), 0);
    await tester.tap(find.byKey(const Key('retry_reading')));
    await _finish(tester);
    expect(q.bonusReadings, 1);
    rig.repository.error = null;
    rig.repository.respondWith(fixtureResponse('ready_yes_no_now.json'));
    await tester.tap(find.byKey(const Key('retry_reading')));
    await _finish(tester);
    expect(find.byType(ResultPage), findsOneWidget);
    expect(q.bonusReadings, 0);
    expect(q.dailyFreeReadingsUsed(rig.localClock), 0);
  });
  testWidgets('failed free reading does not start cooldown or spend quota', (
    tester,
  ) async {
    final q = SharedPreferencesReadingQuotaController();
    final rig = ReadingTestRig(error: StateError('test failure'));
    await tester.pumpWidget(_loading(rig, q));
    await _finish(tester);
    expect(q.dailyFreeReadingsUsed(rig.localClock), 0);
    expect(q.isAvailable(rig.localClock), isTrue);
    expect(q.remainingCooldown(rig.localClock), Duration.zero);
  });

  testWidgets('a malformed ready split cannot spend a reading', (tester) async {
    final json = fixtureResponse('ready_yes_no_now.json').toJson();
    json['percentages'] = null;
    final q = SharedPreferencesReadingQuotaController();
    final rig = ReadingTestRig(response: engine.ReadingResponse.fromJson(json));
    await tester.pumpWidget(_loading(rig, q));
    await _finish(tester);
    expect(find.byKey(const Key('reading_error')), findsOneWidget);
    expect(q.dailyFreeReadingsUsed(rig.localClock), 0);
    expect(q.isAvailable(rig.localClock), isTrue);
  });
  testWidgets('local completion day wins over the UTC snapshot date', (
    tester,
  ) async {
    final local = DateTime(2026, 10, 10, 1);
    final q = SharedPreferencesReadingQuotaController();
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
      localNow: local,
      now: DateTime.utc(2026, 10, 9, 18),
    );
    await tester.pumpWidget(_loading(rig, q));
    await _finish(tester);
    expect(q.dailyFreeReadingsUsed(local), 1);
    expect(rig.sentRequest!.context.instantUtc, '2026-10-09T18:00:00.000Z');
  });
  testWidgets('attempt straddling midnight spends the new day only', (
    tester,
  ) async {
    var local = DateTime(2026, 10, 9, 23, 59, 59);
    final q = SharedPreferencesReadingQuotaController();
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
      liveLocalClock: () => local,
    );
    await tester.pumpWidget(_loading(rig, q));
    await tester.pump();
    local = DateTime(2026, 10, 10, 0, 0, 5);
    await _finish(tester);
    expect(q.dailyFreeReadingsUsed(local), 1);
    expect(q.remainingCooldown(local), const Duration(hours: 3));
  });
  testWidgets('direct Loading entry cannot bypass an exhausted real quota', (
    tester,
  ) async {
    final q = SharedPreferencesReadingQuotaController();
    for (final hour in [0, 3, 6]) {
      await q.consumeReading(DateTime(2026, 9, 18, hour));
    }
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(_loading(rig, q));
    await _finish(tester);
    expect(rig.repository.requests, isEmpty);
    expect(find.byKey(const Key('reading_error')), findsOneWidget);
    expect(q.dailyFreeReadingsUsed(rig.localClock), 3);
  });
  testWidgets(
    'badge, long press and false preview override cannot grant a fourth reading',
    (tester) async {
      useScreen(tester, size: const Size(393, 852));
      final q = SharedPreferencesReadingQuotaController();
      for (final hour in [0, 3, 6]) {
        await q.consumeReading(DateTime(2026, 9, 18, hour));
      }
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(
        localizedApp(
          home: RitualPage(
            mode: DecisionMode.yesNo,
            period: TimePeriod.now,
            category: engine.ReadingCategory.general,
            profile: _profile,
            dependencies: _deps(rig, q),
            isCooldown: false,
            isQuotaExhausted: false,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('ritual_category_badge')));
      await tester.longPress(find.byKey(const Key('reveal_button')));
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump();
      expect(rig.repository.requests, isEmpty);
      expect(q.dailyFreeReadingsUsed(rig.localClock), 3);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets('leaving an unfinished analysis does not spend a free reading', (
    tester,
  ) async {
    final q = SharedPreferencesReadingQuotaController();
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
      apiDelay: const Duration(seconds: 10),
    );
    await tester.pumpWidget(_loading(rig, q));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 11));
    expect(q.dailyFreeReadingsUsed(rig.localClock), 0);
  });
}
