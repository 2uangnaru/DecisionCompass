import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  testWidgets('greets by local time of day and shows the real daily brief', (
    tester,
  ) async {
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
      localNow: DateTime(2026, 9, 18, 7),
    );
    rig.dailyBriefProvider.response = const engine.DailyBrief(
      luckyNumber: 4,
      colorInspiration: 'ocean_blue',
      energy: engine.DailyEnergy(level: 'steady', index: 51, dataCoverage: 1),
    );

    await tester.pumpWidget(rig.app);
    await completeOnboarding(tester);
    await tester.pump(); // let the daily-brief future settle

    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Ocean Blue'), findsOneWidget);
    expect(find.text('Daily energy'), findsOneWidget);
    expect(find.text('STEADY'), findsOneWidget);
    expect(find.text('7'), findsNothing);
  });

  testWidgets('explains only the current energy label, in place', (
    tester,
  ) async {
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
      localNow: DateTime(2026, 9, 18, 7),
    );
    rig.dailyBriefProvider.response = const engine.DailyBrief(
      luckyNumber: 4,
      colorInspiration: 'ocean_blue',
      energy: engine.DailyEnergy(level: 'focused', index: 52, dataCoverage: 1),
    );

    await tester.pumpWidget(rig.app);
    await completeOnboarding(tester);
    await tester.pump();
    await tester.tap(find.byKey(const Key('daily_energy_info_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily_energy_note')), findsOneWidget);
    expect(
      find.text(
        'Today’s symbolic energy gathers around a clear direction; '
        'the action signal takes the lead.',
      ),
      findsOneWidget,
    );
    expect(find.text('QUIET'), findsNothing);
    expect(find.text('FLOWING'), findsNothing);
    // One sentence only: no title, no disclaimer, nothing layered over it.
    expect(find.textContaining('A symbolic reflection'), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.tap(find.byKey(const Key('daily_energy_info_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('daily_energy_note')), findsNothing);
  });

  testWidgets('greets for afternoon and evening too', (tester) async {
    final afternoon = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
      localNow: DateTime(2026, 9, 18, 14),
    );
    await tester.pumpWidget(afternoon.app);
    await completeOnboarding(tester);
    expect(find.text('Good afternoon,'), findsOneWidget);

    final evening = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
      localNow: DateTime(2026, 9, 18, 20),
    );
    // Forces a clean remount instead of updating the afternoon app's element
    // tree (which would keep the Navigator already on Home) in place.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(evening.app);
    await completeOnboarding(tester);
    expect(find.text('Good evening,'), findsOneWidget);
  });

  testWidgets(
    'refreshes daily energy when the app resumes on a new local day',
    (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 20),
      );
      rig.dailyBriefProvider.response = const engine.DailyBrief(
        luckyNumber: 4,
        colorInspiration: 'ocean_blue',
        energy: engine.DailyEnergy(level: 'steady', index: 50, dataCoverage: 1),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await tester.pump();
      expect(find.text('STEADY'), findsOneWidget);
      expect(rig.dailyBriefProvider.previewCalls, 1);

      rig.localClock = DateTime(2026, 9, 19, 7);
      rig.dailyBriefProvider.response = const engine.DailyBrief(
        luckyNumber: 5,
        colorInspiration: 'sage',
        energy: engine.DailyEnergy(level: 'bright', index: 58, dataCoverage: 1),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(); // resolve the replacement FutureBuilder snapshot
      expect(find.text('BRIGHT'), findsOneWidget);
      expect(find.text('STEADY'), findsNothing);
      expect(rig.dailyBriefProvider.previewCalls, 2);
      await tester.tap(find.byKey(const Key('daily_energy_info_button')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Today’s symbolic energy shines with momentum and room for '
          'expression.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'falls back to placeholders, never stale mock values, when no brief is '
    'available yet',
    (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await tester.pump();

      expect(find.text('—'), findsNWidgets(3));
      expect(find.text('Ocean Blue'), findsNothing);
      expect(find.text('7'), findsNothing);
      expect(find.text('STEADY'), findsNothing);
      expect(find.byKey(const Key('daily_energy_info_button')), findsNothing);
    },
  );
}
