import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// What the reader turns on the two dials is what the engine is asked about.
///
/// The other end-to-end coverage reaches the engine through the date picker's
/// *typing* tab, because that is the easiest thing to drive from a test. The
/// wheel is the tab the sheet opens on, so it is the path almost every reader
/// takes, and both pickers were rewritten repeatedly over two days. These
/// drive the wheels the way a finger would and then assert on
/// `ReadingRequest.profile` — the actual payload — rather than on anything the
/// screen happens to be showing.
///
/// Each column opens on a `--` placeholder rather than on a date, so every
/// column has to be touched before Continue will commit anything. One row of
/// travel on each lands on 1 January 2000; that is measured, not assumed, and
/// `the sheet refuses a half-answered wheel` below is what fails first if the
/// scheme changes again.

/// The ritual floor is 4.2-5.2s; this clears any draw of the jitter.
Future<void> pumpPastRitual(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pumpAndSettle();
}

void main() {
  /// Drags one date-wheel column by [rows] items. 44 is the itemExtent.
  Future<void> spin(WidgetTester tester, String column, int rows) async {
    await tester.drag(
      find.byKey(Key('birth_date_${column}_wheel')),
      Offset(0, -44.0 * rows),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDateSheet(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('birth_date_value')));
    await tester.tap(find.byKey(const Key('birth_date_value')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('birth_date_day_wheel')),
      findsOneWidget,
      reason: 'the sheet no longer opens on the wheel',
    );
  }

  /// Spins all three columns and confirms. [years] 1 is 2000, 2 is 2001, and
  /// so on, capped at the current year.
  Future<void> pickOnWheel(
    WidgetTester tester, {
    required int days,
    required int months,
    required int years,
  }) async {
    await openDateSheet(tester);
    await spin(tester, 'year', years);
    await spin(tester, 'month', months);
    await spin(tester, 'day', days);
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

  Future<void> startProfileStep(WidgetTester tester) async {
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pumpAndSettle();
  }

  Future<void> finishOnboarding(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pumpAndSettle();
  }

  testWidgets('a date chosen on the wheel is the date the engine is asked '
      'about', (tester) async {
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await startProfileStep(tester);

    await pickOnWheel(tester, days: 15, months: 6, years: 1);
    await pickCountryUS(tester);
    await answerBirthTime(tester, null);
    await finishOnboarding(tester);
    await revealReading(tester);
    await tester.pump();

    final profile = rig.sentRequest!.profile;
    expect(profile.birthDate, '2000-06-15');
    expect(profile.birthCountry, 'US');
    // Not answered, so it must travel as null rather than as a default hour.
    expect(profile.birthTime, isNull);

    await pumpPastRitual(tester);
  });

  testWidgets('the screen and the engine agree on which date was chosen', (
    tester,
  ) async {
    // The invariant, stated without a literal: whatever the wheel committed is
    // shown on the profile step *and* sent to the engine, and the two are the
    // same date. This survives any future change to where the wheel opens.
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await startProfileStep(tester);
    await pickOnWheel(tester, days: 9, months: 11, years: 24);

    final shown = tester
        .widget<Text>(find.byKey(const Key('birth_date_value')))
        .data!;
    expect(shown, isNot(contains('--')), reason: 'no date was committed');

    await pickCountryUS(tester);
    await answerBirthTime(tester, null);
    await finishOnboarding(tester);
    await revealReading(tester);
    await tester.pump();

    final sent = DateTime.parse(rig.sentRequest!.profile.birthDate);
    expect(shown, contains('${sent.year}'));
    expect(shown, contains('${sent.day}'));

    await pumpPastRitual(tester);
  });

  testWidgets('a time chosen on the clock face travels as HH:mm', (
    tester,
  ) async {
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await startProfileStep(tester);

    await pickOnWheel(tester, days: 21, months: 1, years: 26);
    await pickCountryUS(tester);
    // Drives the real birth-time control, not a synthetic value.
    await answerBirthTime(tester, const TimeOfDay(hour: 7, minute: 45));
    await finishOnboarding(tester);
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
    // persisted value is what a later reading sends. A date that only lived in
    // the widget would pass the first test and fail here.
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await startProfileStep(tester);
    await pickOnWheel(tester, days: 11, months: 3, years: 23);
    await pickCountryUS(tester);
    await answerBirthTime(tester, const TimeOfDay(hour: 23, minute: 5));
    await finishOnboarding(tester);

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
    // Checked where it actually matters: not "the sheet stays open", but "no
    // birth date reached the engine".
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await startProfileStep(tester);

    await openDateSheet(tester);
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('birth_date_sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('birth_date_cancel')));
    await tester.pumpAndSettle();

    await pickCountryUS(tester);
    await answerBirthTime(tester, null);
    await finishOnboarding(tester);

    // Onboarding refused to finish, so no reading could have been requested
    // with a date nobody gave.
    expect(rig.repository.requests, isEmpty);
    expect(
      find.byKey(const Key('birth_date_value')),
      findsOneWidget,
      reason: 'onboarding advanced without a birth date',
    );
  });

  testWidgets('the sheet refuses a half-answered wheel', (tester) async {
    // Two columns chosen, one still on its placeholder. This is the test that
    // fails first if the placeholder scheme changes, which is what keeps the
    // row arithmetic in the tests above honest.
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await startProfileStep(tester);

    await openDateSheet(tester);
    await spin(tester, 'year', 20);
    await spin(tester, 'month', 4);
    // The day column is never touched.
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('birth_date_sheet')),
      findsOneWidget,
      reason: 'a partly answered wheel was accepted as a whole date',
    );
  });

  testWidgets('the wheel cannot be spun into the future', (tester) async {
    // Over-spinning the year column by a century lands on the current year,
    // not beyond it, so no future birth date can reach the engine. Asserted
    // against the real clock, because the sheet's upper bound is today.
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await startProfileStep(tester);

    await pickOnWheel(tester, days: 1, months: 1, years: 400);
    await pickCountryUS(tester);
    await answerBirthTime(tester, null);
    await finishOnboarding(tester);
    await revealReading(tester);
    await tester.pump();

    final sent = DateTime.parse(rig.sentRequest!.profile.birthDate);
    expect(sent.year, DateTime.now().year);
    expect(sent.isAfter(DateTime.now()), isFalse);

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
      await startProfileStep(tester);
      await pickOnWheel(tester, days: 1, months: 1, years: 19);
      await pickCountryUS(tester);
      await answerBirthTime(tester, null);
      await finishOnboarding(tester);

      await revealReading(tester, category: category);
      await tester.pump();

      expect(rig.sentRequest!.profile.birthDate, '2018-01-01');
      expect(rig.sentRequest!.category, category);
      await pumpPastRitual(tester);
    }
  });
}
