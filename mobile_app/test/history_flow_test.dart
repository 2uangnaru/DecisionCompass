import 'dart:convert';

import 'package:decision_compass/data/history_entry.dart';
import 'package:decision_compass/data/history_repository.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/shared_preferences_history_repository.dart';
import 'package:decision_compass/pages/history_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/reading_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

/// The ritual floor is 4.2–5.2s, so this clears any draw of the jitter.
Future<void> pumpPastRitual(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pumpAndSettle();
}

void main() {
  test('shared text includes only the chosen symbolic result', () {
    final text = shareTextForReading(fixtureResponse('ready_yes_no_now.json'));
    expect(text, contains('YES'));
    expect(text, contains('symbolic'));
    expect(text, isNot(contains('1998-06-21')));
    expect(text, isNot(contains('birthDate')));
    expect(text, isNot(contains('latitude')));
    expect(text, isNot(contains('inputSnapshot')));
  });

  testWidgets('a failed save is not labelled saved, and retry opens History', (
    tester,
  ) async {
    final rig = ReadingTestRig();
    final history = _UnreliableHistoryRepository()..failSave = true;
    final dependencies = _withHistory(rig, history);
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          reading: fixtureResponse('ready_yes_no_now.json'),
          dependencies: dependencies,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Couldn’t save · Retry'), findsOneWidget);
    expect(history.entries, isEmpty);

    history.failSave = false;
    await tester.ensureVisible(find.byKey(const Key('result_history_action')));
    await tester.tap(find.byKey(const Key('result_history_action')));
    await tester.pump();
    expect(find.text('View in History'), findsOneWidget);
    expect(history.entries, hasLength(1));

    await tester.tap(find.byKey(const Key('result_history_action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_list')), findsOneWidget);
  });

  testWidgets('History shows storage errors, not a false empty state', (
    tester,
  ) async {
    final rig = ReadingTestRig();
    final history = _UnreliableHistoryRepository()..failList = true;
    final dependencies = _withHistory(rig, history);
    await tester.pumpWidget(
      MaterialApp(home: HistoryPage(dependencies: dependencies)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_error')), findsOneWidget);
    expect(find.byKey(const Key('history_empty')), findsNothing);

    history.failList = false;
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_empty')), findsOneWidget);
  });

  testWidgets('opening a saved snapshot never saves it again', (tester) async {
    final rig = ReadingTestRig();
    await rig.historyRepository.save(
      HistoryEntry(
        id: 'already-saved',
        reading: fixtureResponse('ready_yes_no_now.json'),
        savedAtUtc: DateTime.utc(2026, 9, 18),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: HistoryPage(dependencies: rig.dependencies)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('YES / NO'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result_ready')), findsOneWidget);
    expect(find.text('Back to History'), findsOneWidget);
    expect(rig.historyRepository.saved, hasLength(1));
  });

  test(
    'legacy single-colour history survives an upgrade and a new save',
    () async {
      final oldReading = fixtureResponse('ready_yes_no_now.json').toJson();
      oldReading['engineVersion'] = '3.4.0-mvp';
      oldReading['rulesetVersion'] =
          'civil-midnight-chinese-calendar-symbolic-v7';
      final oldBrief = Map<String, dynamic>.from(
        oldReading['dailyBrief'] as Map,
      );
      oldBrief.remove('colors');
      oldBrief['colorInspiration'] = 'pearl';
      oldReading['dailyBrief'] = oldBrief;
      oldReading['percentages'] = {'YES': 56, 'NO': 44};
      SharedPreferences.setMockInitialValues({
        'history_entries_v1': jsonEncode([
          {
            'id': 'old-reading',
            'reading': oldReading,
            'savedAtUtc': '2026-09-22T10:00:00.000Z',
          },
        ]),
      });

      const repository = SharedPreferencesHistoryRepository();
      final before = await repository.list();
      expect(before, hasLength(1));
      expect(before.single.reading.dailyBrief!.colors, isNull);
      expect(before.single.reading.dailyBrief!.legacyColorInspiration, 'pearl');
      expect(before.single.reading.percentages!.display('YES'), '56.0');

      await repository.save(
        HistoryEntry(
          id: 'new-reading',
          reading: fixtureResponse('ready_yes_no_now.json'),
          savedAtUtc: DateTime.utc(2026, 9, 24, 10),
        ),
      );
      final after = await repository.list();
      expect(after, hasLength(2));
      expect(
        after.map((entry) => entry.id),
        containsAll(['old-reading', 'new-reading']),
      );
      final storedOld = after.singleWhere((entry) => entry.id == 'old-reading');
      final storedBrief = storedOld.reading.toJson()['dailyBrief'] as Map;
      expect(storedBrief['colorInspiration'], 'pearl');
      expect(storedBrief.containsKey('colors'), isFalse);
    },
  );

  testWidgets('a saved legacy result shows its original single colour', (
    tester,
  ) async {
    final json = fixtureResponse('ready_yes_no_now.json').toJson();
    final brief = Map<String, dynamic>.from(json['dailyBrief'] as Map);
    brief.remove('colors');
    brief['colorInspiration'] = 'ocean_blue';
    json['dailyBrief'] = brief;
    final rig = ReadingTestRig();

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          reading: engine.ReadingResponse.fromJson(json),
          dependencies: rig.dependencies,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Colour to keep near you: Ocean Blue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

ReadingDependencies _withHistory(
  ReadingTestRig rig,
  HistoryRepository history,
) => ReadingDependencies(
  repository: rig.repository,
  contextProvider: rig.contextProvider,
  historyRepository: history,
  profileRepository: rig.profileRepository,
  dailyBriefProvider: rig.dailyBriefProvider,
  homeDescriptionDeck: rig.dependencies.homeDescriptionDeck,
  dailyEnergyInsights: rig.dailyEnergyInsights,
  nowUtc: rig.dependencies.nowUtc,
  nowLocal: rig.dependencies.nowLocal,
);

class _UnreliableHistoryRepository implements HistoryRepository {
  final entries = <HistoryEntry>[];
  bool failSave = false;
  bool failList = false;

  @override
  Future<void> save(HistoryEntry entry) async {
    if (failSave) throw StateError('test storage failure');
    entries.add(entry);
  }

  @override
  Future<List<HistoryEntry>> list() async {
    if (failList) throw StateError('test storage failure');
    return List.unmodifiable(entries);
  }
}
