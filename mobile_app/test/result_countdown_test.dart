import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/widgets/astracue_plus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

void main() {
  setUpAll(loadBundledFonts);
  late DateTime local;
  late SharedPreferencesReadingQuotaController quota;
  late ReadingTestRig rig;
  void resultTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      useScreen(tester, size: const Size(390, 844));
      SharedPreferences.setMockInitialValues({});
      local = DateTime(2026, 10, 29, 9);
      quota = SharedPreferencesReadingQuotaController();
      await quota.ensureLoaded();
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });
  }

  Future<void> mount(
    WidgetTester tester, [
    AppLocale locale = AppLocale.english,
  ]) async {
    rig = ReadingTestRig(
      quotaManager: quota,
      localNow: local,
      liveLocalClock: () => local,
      locale: locale,
    );
    await tester.pumpWidget(
      localizedApp(
        locale: locale,
        home: ResultPage(
          reading: fixtureResponse('ready_yes_no_now.json'),
          dependencies: rig.dependencies,
          autoSave: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  final card = find.byKey(const Key('result_energy_plus_card'));
  AnalysisEnergyPlusCard energyCard(WidgetTester tester) =>
      tester.widget<AnalysisEnergyPlusCard>(card);
  Iterable<String> cardText(WidgetTester tester) => tester
      .widgetList<Text>(find.descendant(of: card, matching: find.byType(Text)))
      .map((text) => text.data ?? '');

  Future<void> tick(WidgetTester tester, Duration duration) async {
    local = local.add(duration);
    await tester.pump(duration);
  }

  for (final locale in AppLocale.values) {
    resultTest(
      'last countdown tick changes to ready without tapping (${locale.tag})',
      (tester) async {
        await quota.consumeReading(local);
        local = local.add(
          const Duration(hours: 3) - const Duration(seconds: 2),
        );
        await mount(tester, locale);
        final reading = tester
            .widget<ResultPage>(find.byType(ResultPage))
            .reading;
        expect(
          energyCard(tester).snapshot.cooldownRemaining,
          const Duration(seconds: 2),
        );
        expect(cardText(tester).any((text) => text.contains('⏱')), isTrue);

        await tick(tester, const Duration(seconds: 1));
        expect(
          energyCard(tester).snapshot.cooldownRemaining,
          const Duration(seconds: 1),
        );
        await tick(tester, const Duration(seconds: 1));

        expect(quota.isFreeEnergyReady(local), isTrue);
        expect(energyCard(tester).snapshot.cooldownRemaining, Duration.zero);
        expect(energyCard(tester).snapshot.isCoolingDown, isFalse);
        expect(energyCard(tester).snapshot.remainingFreeTurns, 2);
        expect(cardText(tester).any((text) => text.contains('⏱')), isFalse);
        // Repainting the countdown must not calculate, consume or alter a reading.
        expect(quota.dailyFreeReadingsUsed(local), 1);
        expect(quota.bonusReadings, 0);
        expect(rig.repository.requests, isEmpty);
        expect(rig.historyRepository.saved, isEmpty);
        expect(
          tester.widget<ResultPage>(find.byType(ResultPage)).reading,
          same(reading),
        );
      },
    );
  }

  resultTest('a clock jump past expiry clears the last displayed countdown', (
    tester,
  ) async {
    await quota.consumeReading(local);
    await mount(tester);
    local = local.add(const Duration(hours: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(energyCard(tester).snapshot.isCoolingDown, isFalse);
    expect(cardText(tester).any((text) => text.contains('⏱')), isFalse);
  });

  resultTest(
    'quota changed on open Result still refreshes if expiry precedes next tick',
    (tester) async {
      quota = SharedPreferencesReadingQuotaController(
        cooldownDuration: const Duration(seconds: 3),
      );
      await quota.ensureLoaded();
      await mount(tester);
      expect(energyCard(tester).snapshot.remainingFreeTurns, 3);
      await quota.consumeReading(local);
      await tester.pump();
      expect(energyCard(tester).snapshot.isCoolingDown, isTrue);
      // No intermediate timer callback sees the active countdown.
      local = local.add(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
      expect(energyCard(tester).snapshot.isCoolingDown, isFalse);
      expect(energyCard(tester).snapshot.remainingFreeTurns, 2);
    },
  );

  resultTest(
    'midnight still resets exhausted daily turns without spending anything',
    (tester) async {
      for (final hour in [9, 12, 15]) {
        await quota.consumeReading(DateTime(2026, 10, 29, hour));
      }
      local = DateTime(2026, 10, 29, 23, 59, 58);
      await mount(tester);
      expect(energyCard(tester).snapshot.isDailyFreeExhausted, isTrue);
      await tick(tester, const Duration(seconds: 1));
      expect(energyCard(tester).snapshot.isDailyFreeExhausted, isTrue);
      await tick(tester, const Duration(seconds: 1));
      expect(energyCard(tester).snapshot.remainingFreeTurns, 3);
      expect(energyCard(tester).snapshot.isDailyFreeExhausted, isFalse);
      expect(cardText(tester).any((text) => text.contains('⏱')), isFalse);
      expect(quota.dailyFreeReadingsUsed(local), 0);
    },
  );

  resultTest('ready Result is not rebuilt by idle countdown ticks', (
    tester,
  ) async {
    await mount(tester);
    final before = energyCard(tester);
    await tick(tester, const Duration(seconds: 5));
    expect(energyCard(tester), same(before));
  });

  resultTest('ticks stop rebuilding once expiry transition was rendered', (
    tester,
  ) async {
    await quota.consumeReading(local);
    local = local.add(const Duration(hours: 3) - const Duration(seconds: 1));
    await mount(tester);
    await tick(tester, const Duration(seconds: 1));
    expect(energyCard(tester).snapshot.isCoolingDown, isFalse);
    final readyCard = energyCard(tester);
    await tick(tester, const Duration(seconds: 5));
    expect(energyCard(tester), same(readyCard));
  });

  resultTest(
    'bonus notifications stay intact and timer cannot consume bonus credits',
    (tester) async {
      await quota.consumeReading(local);
      await mount(tester);
      await quota.earnBonusReading();
      await tester.pump();
      expect(energyCard(tester).snapshot.bonusTurns, 1);
      await tick(tester, const Duration(seconds: 2));
      expect(quota.bonusReadings, 1);
      expect(quota.dailyFreeReadingsUsed(local), 1);
      expect(rig.repository.requests, isEmpty);
    },
  );
}
