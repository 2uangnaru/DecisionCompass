import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// The birth-time dialog: one ring of 1–12, a localized AM/PM control, an
/// answer that starts as no answer at all, and a 24-hour value for the engine.
void main() {
  // Layout is measured here, so it is measured in the fonts the app ships.
  setUpAll(loadBundledFonts);

  /// The profile step with the birth-time control on and the dialog open.
  Future<ReadingTestRig> openDialog(
    WidgetTester tester, {
    AppLocale locale = AppLocale.english,
    bool use24HourClock = false,
    double textScale = 1.0,
    bool fillProfile = false,
  }) async {
    useScreen(tester, textScale: textScale);
    // The phone's own clock preference must not change the ring, so it is set
    // at the platform level where the dialog can actually see it.
    tester.platformDispatcher.alwaysUse24HourFormatTestValue = use24HourClock;
    addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);

    final rig = ReadingTestRig(locale: locale);
    await tester.pumpWidget(
      localizedApp(
        locale: locale,
        home: OnboardingPage(dependencies: rig.dependencies),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pumpAndSettle();
    if (fillProfile) await fillDateAndCountry(tester);
    await tester.ensureVisible(find.byKey(const Key('birth_time_picker')));
    await tester.tap(find.byKey(const Key('birth_time_picker')));
    await tester.pumpAndSettle();
    return rig;
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('birth_time_value'))).data!;

  String unanswered(AppLocale locale) => stringsFor(locale).selectBirthTime;

  final confirm = find.byKey(const Key('birth_time_confirm'));

  bool confirmEnabled(WidgetTester tester) =>
      tester.widget<TextButton>(confirm).onPressed != null;

  /// Activates a widget the way a screen reader does: a semantics action,
  /// with no pointer and no key anywhere in it.
  void tapThroughSemantics(WidgetTester tester, Finder finder) {
    final node = tester.getSemantics(finder);
    node.owner!.performAction(node.id, SemanticsAction.tap);
  }

  group('the ring', () {
    testWidgets('is one ring of 1 to 12, with no 0 to 23 anywhere', (
      tester,
    ) async {
      await openDialog(tester);

      for (var hour = 1; hour <= 12; hour++) {
        expect(
          find.byKey(Key('birth_time_hour_$hour')),
          findsOneWidget,
          reason: 'hour $hour is missing from the ring',
        );
      }
      // Twelve positions, and only twelve: no second ring of 13–23 and no 0.
      for (final absent in [0, 13, 18, 23]) {
        expect(
          find.byKey(Key('birth_time_hour_$absent')),
          findsNothing,
          reason: '$absent belongs to the double ring this replaced',
        );
      }
    });

    testWidgets('keeps its twelve hours when the phone is set to 24-hour', (
      tester,
    ) async {
      await openDialog(tester, use24HourClock: true);
      expect(find.byKey(const Key('birth_time_hour_12')), findsOneWidget);
      expect(find.byKey(const Key('birth_time_hour_23')), findsNothing);
      expect(find.byKey(const Key('birth_time_am')), findsOneWidget);
      expect(find.byKey(const Key('birth_time_pm')), findsOneWidget);
    });

    testWidgets('switches to a single minute ring once the hour is chosen', (
      tester,
    ) async {
      await openDialog(tester);
      await tester.tap(find.byKey(const Key('birth_time_hour_9')));
      await tester.pumpAndSettle();

      for (var minute = 0; minute < 60; minute += 5) {
        expect(
          find.byKey(Key('birth_time_minute_$minute')),
          findsOneWidget,
          reason: 'minute $minute is missing',
        );
      }
      // Still one ring: the hours are gone while the minutes are showing.
      expect(find.byKey(const Key('birth_time_hour_9')), findsNothing);
    });

    for (final locale in AppLocale.values) {
      testWidgets('names AM and PM in ${locale.tag}', (tester) async {
        await openDialog(tester, locale: locale, use24HourClock: true);
        final material = MaterialLocalizations.of(
          tester.element(find.byKey(const Key('birth_time_dialog'))),
        );
        final amExpected =
            locale == AppLocale.vietnamese
                ? 'AM'
                : material.anteMeridiemAbbreviation;
        final pmExpected =
            locale == AppLocale.vietnamese
                ? 'PM'
                : material.postMeridiemAbbreviation;
        expect(
          find.text(amExpected),
          findsOneWidget,
          reason: locale.tag,
        );
        expect(
          find.text(pmExpected),
          findsOneWidget,
          reason: locale.tag,
        );
        // Cancel and OK are this language's words for them too.
        expect(find.text(material.cancelButtonLabel), findsOneWidget);
        expect(find.text(material.okButtonLabel), findsOneWidget);
      });
    }
  });

  group('nothing is chosen until the reader chooses it', () {
    testWidgets('the dialog opens with no time and OK disabled', (
      tester,
    ) async {
      await openDialog(tester);

      expect(confirmEnabled(tester), isFalse);
      // Neither half shows a plausible number nobody picked.
      for (final half in ['hour', 'minute']) {
        expect(
          find.descendant(
            of: find.byKey(Key('birth_time_header_$half')),
            matching: find.text('--'),
          ),
          findsOneWidget,
          reason: '$half is showing something',
        );
      }
      for (final invented in ['09', '9', '00', '12']) {
        expect(
          find.descendant(
            of: find.byKey(const Key('birth_time_header_hour')),
            matching: find.text(invented),
          ),
          findsNothing,
          reason: invented,
        );
      }
    });

    testWidgets('a tap on blank dialog space answers nothing', (tester) async {
      final rig = await openDialog(tester, fillProfile: true);

      // The hub of the dial is empty space between the numbers.
      final content = tester.getRect(
        find.byKey(const Key('birth_time_content')),
      );
      await tester.tapAt(content.center);
      await tester.pumpAndSettle();
      expect(confirmEnabled(tester), isFalse);

      // So is the margin beside the dial.
      await tester.tapAt(content.centerLeft + const Offset(6, 0));
      await tester.pumpAndSettle();
      expect(confirmEnabled(tester), isFalse);

      await tester.tap(confirm);
      await tester.pumpAndSettle();
      // The dialog is still open, because OK does nothing yet.
      expect(find.byKey(const Key('birth_time_dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('birth_time_cancel')));
      await tester.pumpAndSettle();
      expect(fieldText(tester), unanswered(AppLocale.english));
      await completeProfileStep(tester);
      expect(find.byKey(const Key('birth_time_required')), findsOneWidget);
      expect(await rig.profileRepository.load(), isNull);
    });

    testWidgets('navigation keys answer nothing', (tester) async {
      final rig = await openDialog(tester, fillProfile: true);

      for (final key in [
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.tab,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }
      expect(
        confirmEnabled(tester),
        isFalse,
        reason: 'moving focus around was taken as a choice',
      );

      await tester.tap(find.byKey(const Key('birth_time_cancel')));
      await tester.pumpAndSettle();
      expect(fieldText(tester), unanswered(AppLocale.english));
      await completeProfileStep(tester);
      expect(await rig.profileRepository.load(), isNull);
    });

    testWidgets('the entry-mode button answers nothing', (tester) async {
      final rig = await openDialog(tester, fillProfile: true);

      await tester.tap(find.byKey(const Key('birth_time_entry_mode')));
      await tester.pumpAndSettle();
      // Typed entry, and both fields are empty rather than pre-filled.
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('birth_time_hour_field')))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('birth_time_minute_field')))
            .controller!
            .text,
        isEmpty,
      );
      expect(confirmEnabled(tester), isFalse);

      // Back to the dial, still nothing chosen.
      await tester.tap(find.byKey(const Key('birth_time_entry_mode')));
      await tester.pumpAndSettle();
      expect(confirmEnabled(tester), isFalse);

      await tester.tap(find.byKey(const Key('birth_time_cancel')));
      await tester.pumpAndSettle();
      await completeProfileStep(tester);
      expect(await rig.profileRepository.load(), isNull);
    });

    testWidgets('choosing only the hour is still not an answer', (
      tester,
    ) async {
      await openDialog(tester);
      await tester.tap(find.byKey(const Key('birth_time_hour_9')));
      await tester.pumpAndSettle();
      expect(confirmEnabled(tester), isFalse);
    });

    testWidgets('AM on its own is not an answer', (tester) async {
      await openDialog(tester);
      await tester.tap(find.byKey(const Key('birth_time_am')));
      await tester.pumpAndSettle();
      expect(confirmEnabled(tester), isFalse);
    });

    testWidgets('Cancel after a full choice answers nothing', (tester) async {
      final rig = await openDialog(tester, fillProfile: true);
      await chooseTimeInDialog(tester, const TimeOfDay(hour: 16, minute: 20));
      expect(confirmEnabled(tester), isTrue);

      await tester.tap(find.byKey(const Key('birth_time_cancel')));
      await tester.pumpAndSettle();

      expect(fieldText(tester), unanswered(AppLocale.english));
      await completeProfileStep(tester);
      expect(find.byKey(const Key('birth_time_required')), findsOneWidget);
      expect(await rig.profileRepository.load(), isNull);
    });
  });

  group('choosing 9:00 AM', () {
    testWidgets('by touch is accepted', (tester) async {
      final rig = await openDialog(tester, fillProfile: true);
      await chooseTimeInDialog(tester, const TimeOfDay(hour: 9, minute: 0));
      expect(confirmEnabled(tester), isTrue);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(fieldText(tester), isNot(unanswered(AppLocale.english)));
      expect(find.byKey(const Key('birth_time_required')), findsNothing);
      await completeProfileStep(tester);
      expect((await rig.profileRepository.load())!.birthTime, '09:00');
    });

    testWidgets('by keyboard is accepted', (tester) async {
      final rig = await openDialog(tester, fillProfile: true);
      await tester.tap(find.byKey(const Key('birth_time_entry_mode')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('birth_time_hour_field')),
        '9',
      );
      await tester.enterText(
        find.byKey(const Key('birth_time_minute_field')),
        '00',
      );
      await tester.pumpAndSettle();
      expect(confirmEnabled(tester), isTrue);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      await completeProfileStep(tester);
      expect((await rig.profileRepository.load())!.birthTime, '09:00');
    });

    testWidgets('through screen-reader semantics is accepted', (tester) async {
      final handle = tester.ensureSemantics();
      final rig = await openDialog(tester, fillProfile: true);

      // No pointer and no key anywhere in this: the hour, the minute and AM
      // are all activated the way an assistive technology activates them.
      tapThroughSemantics(tester, find.byKey(const Key('birth_time_hour_9')));
      await tester.pumpAndSettle();
      tapThroughSemantics(tester, find.byKey(const Key('birth_time_minute_0')));
      await tester.pumpAndSettle();
      tapThroughSemantics(tester, find.byKey(const Key('birth_time_am')));
      await tester.pumpAndSettle();

      expect(confirmEnabled(tester), isTrue);
      tapThroughSemantics(tester, confirm);
      await tester.pumpAndSettle();

      expect(fieldText(tester), isNot(unanswered(AppLocale.english)));
      await completeProfileStep(tester);
      expect((await rig.profileRepository.load())!.birthTime, '09:00');
      handle.dispose();
    });

    testWidgets('the ring exposes its hours to a screen reader at all', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openDialog(tester);
      // Material's own dial is wrapped in `ExcludeSemantics`, so none of this
      // is reachable there. Every hour here is a real, selectable button.
      for (var hour = 1; hour <= 12; hour++) {
        final data = tester
            .getSemantics(find.byKey(Key('birth_time_hour_$hour')))
            .getSemanticsData();
        expect(data.label, '$hour', reason: 'hour $hour has no label');
        expect(
          data.flagsCollection.isButton,
          isTrue,
          reason: 'hour $hour is not a button',
        );
        expect(
          data.hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'hour $hour cannot be activated',
        );
      }
      handle.dispose();
    });
  });

  group('editing an answer', () {
    testWidgets('reopens on it, and confirming unchanged keeps it', (
      tester,
    ) async {
      final rig = await openDialog(tester, fillProfile: true);
      await chooseTimeInDialog(tester, const TimeOfDay(hour: 16, minute: 20));
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      final chosen = fieldText(tester);

      await tester.tap(find.byKey(const Key('birth_time_picker')));
      await tester.pumpAndSettle();
      // Already answered, so OK is live straight away.
      expect(confirmEnabled(tester), isTrue);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(fieldText(tester), chosen);
      await completeProfileStep(tester);
      expect((await rig.profileRepository.load())!.birthTime, '16:20');
    });

    testWidgets('turning the control off continues without a time', (
      tester,
    ) async {
      final rig = await openDialog(tester, fillProfile: true);
      await tester.tap(find.byKey(const Key('birth_time_cancel')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('knows_birth_time')));
      await tester.tap(find.byKey(const Key('knows_birth_time')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('birth_time_required')), findsNothing);

      await completeProfileStep(tester);
      final saved = await rig.profileRepository.load();
      expect(saved, isNotNull);
      expect(saved!.birthTime, isNull);
    });
  });

  group('what reaches the engine is 24-hour', () {
    Future<String?> pick(WidgetTester tester, TimeOfDay time) async {
      final rig = await openDialog(tester, fillProfile: true);
      await chooseTimeInDialog(tester, time);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      await completeProfileStep(tester);
      return (await rig.profileRepository.load())?.birthTime;
    }

    testWidgets('12:00 AM is stored as 00:00', (tester) async {
      expect(await pick(tester, const TimeOfDay(hour: 0, minute: 0)), '00:00');
    });

    testWidgets('12:00 PM is stored as 12:00', (tester) async {
      expect(await pick(tester, const TimeOfDay(hour: 12, minute: 0)), '12:00');
    });

    testWidgets('12:30 AM is stored as 00:30', (tester) async {
      expect(await pick(tester, const TimeOfDay(hour: 0, minute: 30)), '00:30');
    });

    testWidgets('11:55 PM is stored as 23:55', (tester) async {
      expect(
        await pick(tester, const TimeOfDay(hour: 23, minute: 55)),
        '23:55',
      );
    });

    testWidgets('an exact minute can be typed', (tester) async {
      final rig = await openDialog(tester, fillProfile: true);
      await tester.tap(find.byKey(const Key('birth_time_entry_mode')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('birth_time_hour_field')),
        '1',
      );
      await tester.enterText(
        find.byKey(const Key('birth_time_minute_field')),
        '07',
      );
      await tester.pumpAndSettle();
      await tapDayPeriod(tester, DayPeriod.am);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      await completeProfileStep(tester);
      expect((await rig.profileRepository.load())!.birthTime, '01:07');
    });

    testWidgets('an impossible typed hour is not an answer', (tester) async {
      await openDialog(tester);
      await tester.tap(find.byKey(const Key('birth_time_entry_mode')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('birth_time_hour_field')),
        '99',
      );
      await tester.enterText(
        find.byKey(const Key('birth_time_minute_field')),
        '00',
      );
      await tester.pumpAndSettle();
      expect(confirmEnabled(tester), isFalse);
    });

    test('the two conversions that catch people out, stated plainly', () {
      String stored(TimeOfDay time) =>
          '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
      expect(stored(const TimeOfDay(hour: 0, minute: 0)), '00:00');
      expect(stored(const TimeOfDay(hour: 12, minute: 0)), '12:00');
      expect(const TimeOfDay(hour: 0, minute: 0).period, DayPeriod.am);
      expect(const TimeOfDay(hour: 12, minute: 0).period, DayPeriod.pm);
      expect(const TimeOfDay(hour: 0, minute: 0).hourOfPeriod, 12);
      expect(const TimeOfDay(hour: 12, minute: 0).hourOfPeriod, 12);
    });
  });

  group('the dialog fits a narrow phone', () {
    for (final scale in const [1.0, 1.3, 1.5]) {
      testWidgets('at a real 360dp viewport and text scale $scale', (
        tester,
      ) async {
        await openDialog(tester, textScale: scale);
        expect(tester.takeException(), isNull);

        final screen = Offset.zero & const Size(360, 640);
        final parts = <String, Finder>{
          'the dialog content': find.byKey(const Key('birth_time_content')),
          'the chosen hour': find.byKey(const Key('birth_time_header_hour')),
          'AM': find.byKey(const Key('birth_time_am')),
          'PM': find.byKey(const Key('birth_time_pm')),
          'OK': confirm,
          'Cancel': find.byKey(const Key('birth_time_cancel')),
          'the twelve': find.byKey(const Key('birth_time_hour_12')),
          'the six': find.byKey(const Key('birth_time_hour_6')),
          'the nine': find.byKey(const Key('birth_time_hour_9')),
        };
        for (final part in parts.entries) {
          expect(part.value, findsOneWidget, reason: '${part.key} at $scale');
          final box = tester.getRect(part.value);
          expect(
            screen.contains(box.topLeft) && screen.contains(box.bottomRight),
            isTrue,
            reason: '${part.key} is off screen at $scale: $box',
          );
        }

        // Every hour keeps a 48dp target, and no two sit closer together
        // than that — the spacing is what stops one finger hitting two.
        final centres = <Offset>[];
        for (var hour = 1; hour <= 12; hour++) {
          final box = tester.getRect(find.byKey(Key('birth_time_hour_$hour')));
          expect(
            box.shortestSide,
            closeTo(48, 0.01),
            reason: 'hour $hour has a $scale-scale target of ${box.size}',
          );
          for (final other in centres) {
            expect(
              (box.center - other).distance,
              greaterThanOrEqualTo(48),
              reason: 'two hours are less than 48dp apart at $scale',
            );
          }
          centres.add(box.center);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
