import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// What the reader turns on the two dials is what the engine is asked about.
///
/// The existing end-to-end coverage in `reading_flow_test.dart` reaches the
/// engine through the date picker's *typing* tab, because that is the easiest
/// thing to drive from a test. But the wheel is the tab the sheet opens on, so
/// it is the path almost every reader takes, and it was rewritten twice in two
/// days — once for the gold styling and the zodiac badge, once to stop the
/// 01/01/2000 anchor being returned as an answer.
///
/// So these drive the wheel and the clock face the way a finger would, and
/// then assert on `ReadingRequest.profile` — the actual payload — rather than
/// on anything the screen happens to be showing.
/// The ritual floor is 4.2-5.2s; this clears any draw of the jitter.
Future<void> pumpPastRitual(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pumpAndSettle();
}

void main() {
  /// Drags one date-wheel column by [rows] items.
  Future<void> spin(WidgetTester tester, String column, int rows) async {
    await tester.drag(
      find.byKey(Key('birth_date_$column\_wheel')),
      Offset(0, -44.0 * rows), // 44 is the column's itemExtent
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Opens the date sheet from the profile step, spins to a date, confirms.
  ///
  /// The wheel opens anchored on 01/01/2000, so advancing day/month/year by
  /// `d`, `m`, `y` rows lands on a known date without reading anything off
  /// the screen.
  Future<void> pickOnWheel(
    WidgetTester tester, {
    required int days,
    required int months,
    required int years,
  }) async {
    await tester.ensureVisible(find.byKey(const Key('birth_date_value')));
    await tester.tap(find.byKey(const Key('birth_date_value')));
    await tester.pumpAndSettle();

    // No tab tap: the wheel is what the sheet opens on.
    expect(
      find.byKey(const Key('birth_date_day_wheel')),
      findsOneWidget,
      reason: 'the sheet no longer opens on the wheel',
    );
    // Each column starts on placeholder dashes, so offset by 1 row from anchor.
    await spin(tester, 'year', years + 1);
    await spin(tester, 'month', months + 1);
    await spin(tester, 'day', days + 1);

    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('birth_date_sheet')),
      findsNothing,
      reason: 'the sheet refused a date the reader had chosen on the wheel',
    );
  }

  Future<void> pickCountryUS(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('birth_country')));
    await tester.tap(find.byKey(const Key('birth_country')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'US');
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u{1F1FA}\u{1F1F8}').last);
    await tester.pumpAndSettle();
  }

  testWidgets('a date chosen on the wheel is the date the engine is asked '
      'about', (tester) async {
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pumpAndSettle();

    // 01/01/2000 + 20 years + 5 months + 14 days = 15 June 2020.
    await pickOnWheel(tester, days: 14, months: 5, years: 20);
    await pickCountryUS(tester);
    await answerBirthTime(tester, null);

    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pumpAndSettle();
    await revealReading(tester);
    await tester.pump();

    final profile = rig.sentRequest!.profile;
    expect(profile.birthDate, '2020-06-15');
    expect(profile.birthCountry, 'US');
    // Not answered, so it must travel as null rather than as a default hour.
    expect(profile.birthTime, isNull);

    await pumpPastRitual(tester);
  });

  testWidgets('a time chosen on the clock face travels as HH:mm', (
    tester,
  ) async {
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pumpAndSettle();

    await pickOnWheel(tester, days: 20, months: 0, years: 25);
    await pickCountryUS(tester);
    // Drives the real birth-time control, not a synthetic value.
    await answerBirthTime(tester, const TimeOfDay(hour: 7, minute: 45));

    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pumpAndSettle();
    await revealReading(tester);
    await tester.pump();

    final profile = rig.sentRequest!.profile;
    expect(profile.birthDate, '2025-01-21');
    expect(profile.birthTime, '07:45');

    await pumpPastRitual(tester);
  });

  testWidgets('the wheel date survives a restart and is sent again', (
    tester,
  ) async {
    // The picker writes into the profile, the profile is persisted, and the
    // persisted value is what a later reading sends. A date that only lived
    // in the widget would pass the first two tests and fail here.
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pumpAndSettle();
    await pickOnWheel(tester, days: 10, months: 2, years: 22);
    await pickCountryUS(tester);
    await answerBirthTime(tester, const TimeOfDay(hour: 23, minute: 5));
    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pumpAndSettle();

    // Restart against the same storage.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(rig.app);
    await tester.pumpAndSettle();

    await revealReading(tester);
    await tester.pump();

    final profile = rig.sentRequest!.profile;
    expect(profile.birthDate, '2022-03-11');
    expect(profile.birthTime, '23:05');

    await pumpPastRitual(tester);
  });

  testWidgets('an untouched wheel sends nothing, because it answers nothing', (
    tester,
  ) async {
    // The anchor fix, checked where it actually matters: not "the sheet stays
    // open", but "no birth date reached the engine".
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('birth_date_value')));
    await tester.tap(find.byKey(const Key('birth_date_value')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();

    // The sheet is still open and nothing was chosen.
    expect(find.byKey(const Key('birth_date_sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('birth_date_cancel')));
    await tester.pumpAndSettle();

    await pickCountryUS(tester);
    await answerBirthTime(tester, null);
    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pumpAndSettle();

    // Onboarding refused to finish, so no reading could have been requested
    // with a date nobody gave.
    expect(rig.repository.requests, isEmpty);
    expect(
      find.byKey(const Key('birth_date_value')),
      findsOneWidget,
      reason: 'onboarding advanced without a birth date',
    );
  });

  testWidgets('the wheel cannot be spun into the future', (tester) async {
    // Over-spinning the year column by decades lands on the current year, not
    // beyond it, so no future birth date can reach the engine. Found by
    // getting this test's own arithmetic wrong, which is as good a way as any.
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pumpAndSettle();

    await pickOnWheel(tester, days: 0, months: 0, years: 60);
    await pickCountryUS(tester);
    await answerBirthTime(tester, null);
    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pumpAndSettle();
    await revealReading(tester);
    await tester.pump();

    // The rig's clock is 2026-09-18, so the year column stops at 2026.
    expect(rig.sentRequest!.profile.birthDate, '2026-01-01');

    await pumpPastRitual(tester);
  });

  testWidgets('every category carries the same wheel-chosen profile', (
    tester,
  ) async {
    // The profile must not depend on which area the reading is for; the
    // category travels beside it, not instead of it.
    for (final category in [
      engine.ReadingCategory.love,
      engine.ReadingCategory.money,
    ]) {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(rig.app);
      await tester.pump();
      await tester.tap(find.byKey(const Key('continue_to_profile')));
      await tester.pumpAndSettle();
      await pickOnWheel(tester, days: 0, months: 0, years: 18);
      await pickCountryUS(tester);
      await answerBirthTime(tester, null);
      await tester.ensureVisible(find.byKey(const Key('complete_profile')));
      await tester.tap(find.byKey(const Key('complete_profile')));
      await tester.pumpAndSettle();

      await revealReading(tester, category: category);
      await tester.pump();

      expect(rig.sentRequest!.profile.birthDate, '2018-01-01');
      expect(rig.sentRequest!.category, category);
      await pumpPastRitual(tester);
    }
  });
}
