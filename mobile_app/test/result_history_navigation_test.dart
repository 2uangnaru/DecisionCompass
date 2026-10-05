import 'package:decision_compass/data/history_entry.dart';
import 'package:decision_compass/pages/history_page.dart';
import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/localized_presentation.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// Getting out of a saved reading.
///
/// The route stack after looking back through History is
/// `Home → current result → History → saved result`, and leaving the saved
/// one used to pop a single route — which revealed History again and needed a
/// second Back to get where the reader was actually going. The close control
/// and the system Back gesture now both skip the page in between.
///
/// "Back to History" is the one control that is *meant* to reveal it, so it
/// still pops once. "Try another direction" goes to Home, because that is what
/// its label says.
void main() {
  /// "Back to History" only exists on a reopened snapshot, so its label is
  /// how these tests tell the two Result pages apart without a second key.
  final onSavedReading = find.text(stringsFor(AppLocale.english).backToHistory);

  /// The one saved row in History. It carries the mode's first label, which
  /// for the seeded LEFT / RIGHT reading is unique on that screen.
  final savedRow = find.descendant(
    of: find.byType(HistoryPage),
    matching: find.text(
      modeLabel(stringsFor(AppLocale.english), DecisionMode.leftRight),
    ),
  );

  /// How many stored entries are the seeded reading. Reopening it must never
  /// make this more than one.
  int savedCopiesOfOlder(ReadingTestRig rig) => rig.historyRepository.saved
      .where((entry) => entry.id == 'older-reading')
      .length;

  Future<void> pumpPastRitual(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 5400));
    await tester.pumpAndSettle();
  }

  /// Presses the hardware Back button the way Android delivers it.
  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  /// Walks Home → reading → Result, then into History and onto the saved row.
  Future<ReadingTestRig> openSavedFromCurrent(WidgetTester tester) async {
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    // One saved reading already in storage, so History has a row that is not
    // the reading about to be taken.
    await rig.historyRepository.save(
      HistoryEntry(
        id: 'older-reading',
        reading: fixtureResponse('ready_left_right.json'),
        savedAtUtc: DateTime.utc(2026, 9, 20, 10),
      ),
    );
    await tester.pumpWidget(rig.app);
    await completeOnboarding(tester);
    await revealReading(tester);
    await pumpPastRitual(tester);
    expect(find.byKey(const Key('result_ready')), findsOneWidget);

    // Into History from the current result.
    await tester.ensureVisible(find.byKey(const Key('result_history_action')));
    await tester.tap(find.byKey(const Key('result_history_action')));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryPage), findsOneWidget);

    // Onto the older saved reading.
    await tester.tap(savedRow);
    await tester.pumpAndSettle();
    expect(onSavedReading, findsOneWidget);
    return rig;
  }

  group('leaving a saved reading opened from the current one', () {
    testWidgets('the close control lands on the current result in one action', (
      tester,
    ) async {
      final rig = await openSavedFromCurrent(tester);

      await tester.tap(find.byKey(const Key('result_close')));
      await tester.pumpAndSettle();

      // One action, and it is the current reading — not History.
      expect(find.byType(HistoryPage), findsNothing);
      expect(find.byKey(const Key('result_ready')), findsOneWidget);
      expect(
        find.byKey(const Key('result_history_action')),
        findsOneWidget,
        reason: 'this is not the current result; it has no View History action',
      );
      // Two entries: the seeded one and the reading just taken. Reopening
      // the seeded one must not have written it back.
      expect(rig.historyRepository.saved, hasLength(2));
      expect(savedCopiesOfOlder(rig), 1);
    });

    testWidgets('the system Back gesture does the same', (tester) async {
      final rig = await openSavedFromCurrent(tester);

      await systemBack(tester);

      expect(find.byType(HistoryPage), findsNothing);
      expect(find.byKey(const Key('result_ready')), findsOneWidget);
      expect(find.byKey(const Key('result_history_action')), findsOneWidget);
      expect(rig.historyRepository.saved, hasLength(2));
      expect(savedCopiesOfOlder(rig), 1);
    });

    testWidgets('Back to History still reveals History', (tester) async {
      await openSavedFromCurrent(tester);

      await tester.ensureVisible(
        find.byKey(const Key('result_history_action')),
      );
      await tester.tap(find.byKey(const Key('result_history_action')));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryPage), findsOneWidget);
      // And another saved reading can be chosen from there.
      await tester.tap(savedRow);
      await tester.pumpAndSettle();
      expect(onSavedReading, findsOneWidget);
    });

    testWidgets('Try another direction goes to Home, not History', (
      tester,
    ) async {
      await openSavedFromCurrent(tester);

      await tester.ensureVisible(find.byKey(const Key('result_try_another')));
      await tester.tap(find.byKey(const Key('result_try_another')));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(HistoryPage), findsNothing);
      expect(find.byKey(const Key('result_ready')), findsNothing);
    });

    testWidgets('opening the saved reading never saves it again', (
      tester,
    ) async {
      final rig = await openSavedFromCurrent(tester);
      // The snapshot is on screen. Only two things were ever written: the
      // seeded entry and the reading the app just calculated.
      expect(rig.historyRepository.saved, hasLength(2));
      expect(savedCopiesOfOlder(rig), 1);

      await systemBack(tester);
      await tester.pumpAndSettle();
      expect(rig.historyRepository.saved, hasLength(2));
      expect(
        savedCopiesOfOlder(rig),
        1,
        reason: 'the reopened snapshot was written back to History',
      );
    });
  });

  group('History opened from Home instead', () {
    /// There is no current reading underneath, so leaving a saved reading has
    /// nowhere to skip to and must behave exactly as it did before.
    Future<ReadingTestRig> openSavedFromHome(WidgetTester tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await rig.historyRepository.save(
        HistoryEntry(
          id: 'older-reading',
          reading: fixtureResponse('ready_left_right.json'),
          savedAtUtc: DateTime.utc(2026, 9, 20, 10),
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      final settingsFinder = find.byKey(const Key('home_settings_button'));
      if (settingsFinder.evaluate().isNotEmpty) {
        await tester.tap(settingsFinder);
        await tester.pumpAndSettle();
      }

      await tester.ensureVisible(find.byIcon(Icons.history_rounded));
      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryPage), findsOneWidget);

      await tester.tap(savedRow);
      await tester.pumpAndSettle();
      return rig;
    }

    testWidgets('the close control goes back to History', (tester) async {
      await openSavedFromHome(tester);
      await tester.tap(find.byKey(const Key('result_close')));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryPage), findsOneWidget);
    });

    testWidgets('the system Back gesture goes back to History', (tester) async {
      await openSavedFromHome(tester);
      await systemBack(tester);
      expect(find.byType(HistoryPage), findsOneWidget);
    });

    testWidgets('the whole round trip from Home still works', (tester) async {
      // Home -> History -> saved reading -> back to History -> close History
      // -> Home. Every step of the path that existed before this change, in
      // order, with nothing skipped and nothing stranded.
      final rig = await openSavedFromHome(tester);
      expect(onSavedReading, findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('result_history_action')),
      );
      await tester.tap(find.byKey(const Key('result_history_action')));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryPage), findsOneWidget);

      // Another saved reading can still be chosen from here.
      await tester.tap(savedRow);
      await tester.pumpAndSettle();
      expect(onSavedReading, findsOneWidget);
      await tester.tap(find.byKey(const Key('result_close')));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryPage), findsOneWidget);

      // History's own close still lands on Home.
      await systemBack(tester);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(HistoryPage), findsNothing);
      // Nothing on this path moved: every route behaves as it did before.

      // Nothing was written back on the way through.
      expect(savedCopiesOfOlder(rig), 1);
      expect(rig.historyRepository.saved, hasLength(1));
    });

    testWidgets('Try another direction still goes back to History', (
      tester,
    ) async {
      // Left exactly as it was. The label arguably promises Home here too,
      // but this path was not the one being fixed, and changing where a
      // button lands on a route nobody asked about is how a navigation fix
      // turns into a navigation bug.
      await openSavedFromHome(tester);
      await tester.ensureVisible(find.byKey(const Key('result_try_another')));
      await tester.tap(find.byKey(const Key('result_try_another')));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });
  });

  group('the current result itself', () {
    testWidgets('close and Try another direction both reach Home', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await pumpPastRitual(tester);

      await tester.ensureVisible(find.byKey(const Key('result_try_another')));
      await tester.tap(find.byKey(const Key('result_try_another')));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('the system Back gesture still leaves it normally', (
      tester,
    ) async {
      // Nothing is trapped: the current result has no redirect, so Back is
      // the plain pop it always was.
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await pumpPastRitual(tester);

      await systemBack(tester);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byKey(const Key('result_ready')), findsNothing);
    });
  });
}
