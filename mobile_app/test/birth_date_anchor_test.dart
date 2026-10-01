import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/widgets/birth_date_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// The wheel's starting position is not an answer.
///
/// The sheet opens anchored on 1 January 2000 so its three columns are not
/// blank. That is a visual anchor. Returning it because the reader pressed
/// Continue without ever touching the wheel would save a birth date they
/// never gave — and a birth date is the one input where a plausible-looking
/// default is worse than none, because nothing downstream can tell the
/// difference between a real 1 January 2000 and an untouched wheel.
///
/// What is tracked is therefore whether the reader *interacted*, never
/// whether the value differs from the anchor: somebody born on 1 January 2000
/// has to be able to confirm that date like anyone else.
void main() {
  /// The anchor the sheet opens on when no date has been saved.
  final anchor = DateTime(2000);

  /// A fixed "today", so the sheet's upper bound does not drift with the
  /// clock the suite happens to run on.
  final today = DateTime(2026, 9, 30);

  Future<DateTime? Function()> openSheet(
    WidgetTester tester, {
    DateTime? initialDate,
  }) async {
    DateTime? result;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<DateTime>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BirthDatePickerSheet(
                    initialDate: initialDate,
                    lastDate: today,
                  ),
                );
                closed = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(closed, isFalse, reason: 'the sheet should be open');
    return () => result;
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
  }

  /// Drags one wheel column by [rows] items, the way a finger would.
  ///
  /// A drag is what the sheet listens for: it marks the wheel answered even
  /// when the column settles back where it started, which is what lets
  /// somebody born on the anchor date confirm it.
  Future<void> spinWheel(
    WidgetTester tester,
    String column, {
    int rows = 1,
  }) async {
    await tester.drag(
      find.byKey(Key('birth_date_${column}_wheel')),
      // Negative moves the list up, which advances the value. 44 is the
      // column's itemExtent.
      Offset(0, -44.0 * rows),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  String feedback(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('birth_date_feedback'))).data!;

  group('a new reader who has not chosen anything', () {
    testWidgets('Continue neither closes the sheet nor saves the anchor', (
      tester,
    ) async {
      final result = await openSheet(tester);

      // The anchor is on screen, but the feedback does not read it back as a
      // chosen date.
      expect(feedback(tester), 'Select your date of birth');

      await tapContinue(tester);

      // Still open, still nothing saved.
      expect(find.byKey(const Key('birth_date_sheet')), findsOneWidget);
      expect(result(), isNull);
      // The prompt is the existing one, not an "invalid date" complaint:
      // nothing is wrong with the anchor, it simply has not been chosen.
      expect(feedback(tester), 'Select your date of birth');
      expect(find.text('Enter a valid date from 1900 to today.'), findsNothing);
    });

    testWidgets('pressing Continue repeatedly still saves nothing', (
      tester,
    ) async {
      final result = await openSheet(tester);
      for (var i = 0; i < 3; i++) {
        await tapContinue(tester);
      }
      expect(find.byKey(const Key('birth_date_sheet')), findsOneWidget);
      expect(result(), isNull);
    });

    testWidgets('the refusal is announced, not silent', (tester) async {
      // Without a live region a screen-reader user taps Continue, nothing
      // moves, and nothing is said. The handle is what Flutter announces
      // through.
      final semantics = tester.ensureSemantics();
      await openSheet(tester);
      await tapContinue(tester);

      expect(
        find.semantics.byLabel('Select your date of birth'),
        isSemantics(isLiveRegion: true),
        reason: 'the prompt must announce itself when Continue does nothing',
      );
      semantics.dispose();
    });
  });

  group('an intentional choice', () {
    testWidgets('spinning each wheel confirms the chosen date', (
      tester,
    ) async {
      // The case the fix must handle: somebody born on 1 January 2000.
      // They move each wheel from placeholder '--' to 1 / 1 / 2000.
      final result = await openSheet(tester);
      await spinWheel(tester, 'day', rows: 1);
      await spinWheel(tester, 'month', rows: 1);
      await spinWheel(tester, 'year', rows: 1);

      expect(feedback(tester), isNot('Select your date of birth'));
      await tapContinue(tester);
      expect(result(), anchor);
    });

    testWidgets('a drag that settles back on placeholder keeps it unselected', (
      tester,
    ) async {
      // A nudge too small to change the selected index: 20 is under half the
      // 44dp itemExtent, so the column snaps back to '--'.
      final result = await openSheet(tester);
      await tester.drag(
        find.byKey(const Key('birth_date_day_wheel')),
        const Offset(0, -20),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tapContinue(tester);
      expect(result(), isNull);
      expect(feedback(tester), 'Select your date of birth');
    });

    testWidgets('spinning to a different date confirms that date', (
      tester,
    ) async {
      final result = await openSheet(tester);
      await spinWheel(tester, 'day', rows: 21);
      await spinWheel(tester, 'month', rows: 1);
      await spinWheel(tester, 'year', rows: 1);
      await tapContinue(tester);
      expect(result(), DateTime(2000, 1, 21));
    });

    testWidgets('the accessible adjust action is an intentional choice too', (
      tester,
    ) async {
      // How somebody using a screen reader moves the wheel. A wheel column is
      // not a scrollable list to assistive technology — `ListWheelScrollView`
      // publishes `increase`/`decrease`, the adjustable model, so TalkBack
      // offers "swipe up to increase" rather than a scroll. That action moves
      // the selected row, which is the signal the sheet already acts on, so
      // the accessible path needs no separate handling.
      final semantics = tester.ensureSemantics();
      final result = await openSheet(tester);

      final adjustable = find.semantics.byAction(SemanticsAction.increase);
      expect(
        adjustable,
        findsWidgets,
        reason: 'no column offered an accessible way to change its value',
      );
      tester.semantics.performAction(
        adjustable.at(0),
        SemanticsAction.increase,
      );
      tester.semantics.performAction(
        adjustable.at(1),
        SemanticsAction.increase,
      );
      tester.semantics.performAction(
        adjustable.at(2),
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();

      expect(feedback(tester), isNot('Select your date of birth'));
      await tapContinue(tester);
      expect(result(), isNotNull);
      semantics.dispose();
    });
  });

  group('switching modes does not answer for the reader', () {
    testWidgets('an untouched anchor leaves the typed fields blank', (
      tester,
    ) async {
      final result = await openSheet(tester);
      await tester.tap(find.byKey(const Key('birth_date_type_tab')));
      await tester.pumpAndSettle();

      for (final part in const ['day', 'month', 'year']) {
        expect(
          tester
              .widget<TextField>(find.byKey(Key('birth_date_$part')))
              .controller!
              .text,
          isEmpty,
          reason: '$part was filled in from an anchor nobody chose',
        );
      }
      await tapContinue(tester);
      expect(find.byKey(const Key('birth_date_sheet')), findsOneWidget);
      expect(result(), isNull);
    });

    testWidgets('round-tripping both tabs still saves nothing', (tester) async {
      final result = await openSheet(tester);
      await tester.tap(find.byKey(const Key('birth_date_type_tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('birth_date_scroll_tab')));
      await tester.pumpAndSettle();

      expect(feedback(tester), 'Select your date of birth');
      await tapContinue(tester);
      expect(result(), isNull);
    });

    testWidgets('a typed date carries to the wheel and stays an answer', (
      tester,
    ) async {
      // The reverse case: the reader did answer, by typing. Moving that to
      // the wheel must not demote it back to "untouched".
      final result = await openSheet(tester);
      await tester.tap(find.byKey(const Key('birth_date_type_tab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('birth_date_day')), '15');
      await tester.enterText(find.byKey(const Key('birth_date_month')), '08');
      await tester.enterText(find.byKey(const Key('birth_date_year')), '1995');
      await tester.tap(find.byKey(const Key('birth_date_scroll_tab')));
      await tester.pumpAndSettle();

      await tapContinue(tester);
      expect(result(), DateTime(1995, 8, 15));
    });

    testWidgets('an incomplete typed date does not carry to the wheel', (
      tester,
    ) async {
      final result = await openSheet(tester);
      await tester.tap(find.byKey(const Key('birth_date_type_tab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('birth_date_day')), '15');
      await tester.tap(find.byKey(const Key('birth_date_scroll_tab')));
      await tester.pumpAndSettle();

      expect(feedback(tester), 'Select your date of birth');
      await tapContinue(tester);
      expect(result(), isNull);
    });
  });

  group('manual entry still demands a whole date', () {
    testWidgets('an incomplete date is refused', (tester) async {
      final result = await openSheet(tester);
      await tester.tap(find.byKey(const Key('birth_date_type_tab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('birth_date_day')), '21');
      await tester.enterText(find.byKey(const Key('birth_date_month')), '06');
      await tapContinue(tester);

      expect(find.byKey(const Key('birth_date_sheet')), findsOneWidget);
      expect(result(), isNull);
    });

    testWidgets('an impossible date is refused and says so', (tester) async {
      final result = await openSheet(tester);
      await tester.tap(find.byKey(const Key('birth_date_type_tab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('birth_date_day')), '31');
      await tester.enterText(find.byKey(const Key('birth_date_month')), '02');
      await tester.enterText(find.byKey(const Key('birth_date_year')), '1999');
      await tester.pumpAndSettle();
      await tapContinue(tester);

      // A wrong date gets the invalid message; an unchosen one gets the
      // prompt. They are different problems and read differently.
      expect(feedback(tester), 'Enter a valid date from 1900 to today.');
      expect(result(), isNull);
    });
  });

  group('an existing saved date', () {
    testWidgets('Continue without changing anything keeps it', (tester) async {
      final result = await openSheet(
        tester,
        initialDate: DateTime(1998, 6, 21),
      );
      // It is already an answer, so it reads back as one from the first frame.
      expect(feedback(tester), isNot('Select your date of birth'));
      await tapContinue(tester);
      expect(result(), DateTime(1998, 6, 21));
    });

    testWidgets('Cancel returns nothing, so the profile is untouched', (
      tester,
    ) async {
      final result = await openSheet(
        tester,
        initialDate: DateTime(1998, 6, 21),
      );
      await tester.tap(find.byKey(const Key('birth_date_cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('birth_date_sheet')), findsNothing);
      // The caller keeps whatever it had: `showBirthDatePicker` returning null
      // is what "unchanged" looks like on this boundary.
      expect(result(), isNull);
    });

    testWidgets('Cancel after spinning the wheel still returns nothing', (
      tester,
    ) async {
      final result = await openSheet(
        tester,
        initialDate: DateTime(1998, 6, 21),
      );
      await spinWheel(tester, 'day', rows: 3);
      await tester.tap(find.byKey(const Key('birth_date_cancel')));
      await tester.pumpAndSettle();
      expect(result(), isNull);
    });

    testWidgets('Cancel with nothing saved also returns nothing', (
      tester,
    ) async {
      final result = await openSheet(tester);
      await tester.tap(find.byKey(const Key('birth_date_cancel')));
      await tester.pumpAndSettle();
      expect(result(), isNull);
    });

    testWidgets('a saved date outside the range is not treated as an answer', (
      tester,
    ) async {
      // The wheel cannot show it, so it falls back to the anchor — and an
      // anchor is never an answer, however it came to be showing.
      final result = await openSheet(tester, initialDate: DateTime(2099, 1, 1));
      expect(find.byType(CupertinoPicker), findsNWidgets(3));
      expect(feedback(tester), 'Select your date of birth');
      await tapContinue(tester);
      expect(result(), isNull);
    });
  });
}
