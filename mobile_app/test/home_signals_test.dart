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
    );

    await tester.pumpWidget(rig.app);
    await completeOnboarding(tester);
    await tester.pump(); // let the daily-brief future settle

    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Ocean Blue'), findsOneWidget);
    // The old static card is gone entirely, not just its values.
    expect(find.text('Daily energy'), findsNothing);
    expect(find.text('STEADY'), findsNothing);
    expect(find.text('7'), findsNothing);
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
    'falls back to placeholders, never stale mock values, when no brief is '
    'available yet',
    (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await tester.pump();

      expect(find.text('—'), findsNWidgets(2));
      expect(find.text('Ocean Blue'), findsNothing);
      expect(find.text('7'), findsNothing);
    },
  );
}
