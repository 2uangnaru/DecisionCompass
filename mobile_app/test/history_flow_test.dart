import 'package:decision_compass/data/history_entry.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/pages/history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// The ritual floor is 4.2–5.2s, so this clears any draw of the jitter.
Future<void> pumpPastRitual(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'revealing readings for different categories and periods each saves its '
    'own history entry, not a shared/overwritten one',
    (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      // General / YES-NO / NOW.
      await revealReading(tester);
      await pumpPastRitual(tester);
      expect(find.byKey(const Key('result_ready')), findsOneWidget);

      // "Try Another Direction" pops back to Home without a fresh onboarding.
      await tester.ensureVisible(find.text('Try Another Direction'));
      await tester.tap(find.text('Try Another Direction'));
      await tester.pumpAndSettle();

      // Love / STAY-GO / EVENING — a different category *and* period.
      rig.repository.respondWith(fixtureResponse('ready_love_evening.json'));
      await revealReading(
        tester,
        category: engine.ReadingCategory.love,
        periodName: 'evening',
      );
      await pumpPastRitual(tester);
      expect(find.byKey(const Key('result_ready')), findsOneWidget);

      await tester.ensureVisible(find.text('Try Another Direction'));
      await tester.tap(find.text('Try Another Direction'));
      await tester.pumpAndSettle();

      // Career / ACT-WAIT / NOW — a third distinct combination.
      rig.repository.respondWith(fixtureResponse('ready_career_now.json'));
      await revealReading(tester, category: engine.ReadingCategory.career);
      await pumpPastRitual(tester);
      expect(find.byKey(const Key('result_ready')), findsOneWidget);

      final saved = rig.historyRepository.saved;
      expect(saved, hasLength(3));
      expect(saved[0].reading.category, engine.ReadingCategory.general);
      expect(saved[0].reading.period, engine.TimePeriod.now);
      expect(saved[1].reading.category, engine.ReadingCategory.love);
      expect(saved[1].reading.period, engine.TimePeriod.evening);
      expect(saved[2].reading.category, engine.ReadingCategory.career);
      expect(saved[2].reading.period, engine.TimePeriod.now);

      // Distinct readings must not collapse onto the same history key.
      final ids = saved.map((entry) => entry.id).toSet();
      expect(ids, hasLength(3));
    },
  );

  testWidgets(
    'the History page lists every saved category and period distinctly',
    (tester) async {
      final rig = ReadingTestRig();
      await rig.historyRepository.save(
        HistoryEntry(
          id: 'love-evening',
          reading: fixtureResponse('ready_love_evening.json'),
          savedAtUtc: DateTime.utc(2026, 9, 18, 8),
        ),
      );
      await rig.historyRepository.save(
        HistoryEntry(
          id: 'career-now',
          reading: fixtureResponse('ready_career_now.json'),
          savedAtUtc: DateTime.utc(2026, 9, 18, 9),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: HistoryPage(dependencies: rig.dependencies)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('history_empty')), findsNothing);
      expect(find.textContaining('Love'), findsOneWidget);
      expect(find.textContaining('Career'), findsOneWidget);
      expect(find.textContaining('EVENING'), findsOneWidget);
      expect(find.textContaining('NOW'), findsOneWidget);
    },
  );

  testWidgets('an empty history shows an explicit empty state, not mock rows', (
    tester,
  ) async {
    final rig = ReadingTestRig();

    await tester.pumpWidget(
      MaterialApp(home: HistoryPage(dependencies: rig.dependencies)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history_empty')), findsOneWidget);
    expect(find.text('YES / NO'), findsNothing);
    expect(find.text('STAY / GO'), findsNothing);
  });
}
