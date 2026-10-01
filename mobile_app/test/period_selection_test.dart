import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/localized_presentation.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/reading_mapping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// A period's English chip label. The enum carries no display text any more:
/// the words come from the active language, and these tests run in English.
String label(TimePeriod period) =>
    periodLabel(stringsFor(AppLocale.english), period);

/// The ritual floor is 4.2–5.2s, so this clears any draw of the jitter.
Future<void> pumpPastRitual(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pumpAndSettle();
}

/// Walks onboarding and Home, stopping on the ritual screen.
Future<void> openRitual(WidgetTester tester) async {
  await completeOnboarding(tester);
  await tester.ensureVisible(find.byKey(const Key('find_direction')));
  await tester.tap(find.byKey(const Key('find_direction')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

Finder periodChip(TimePeriod period) =>
    find.byKey(Key('ritual_period_${period.name}'));

ChoiceChip chipFor(WidgetTester tester, TimePeriod period) =>
    tester.widget<ChoiceChip>(periodChip(period));

void main() {
  group('Home no longer asks when', () {
    testWidgets('renders no period selector and no period in the summary', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      expect(find.text('When are you considering it?'), findsNothing);
      for (final period in TimePeriod.values) {
        expect(
          find.byKey(Key('period_${period.name}')),
          findsNothing,
          reason: '${label(period)} must not be selectable on Home',
        );
        expect(periodChip(period), findsNothing);
      }
      // The other two selectors and the CTA are untouched.
      expect(find.byKey(const Key('category_selector')), findsOneWidget);
      expect(find.text('Which direction do you need?'), findsNothing);
      expect(find.byKey(const Key('find_direction')), findsOneWidget);
      expect(find.text('Overall  •  YES / NO'), findsOneWidget);
    });
  });

  group('the ritual asks when', () {
    testWidgets('offers all five periods and opens on NOW', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);

      expect(find.byKey(const Key('ritual_period_selector')), findsOneWidget);
      expect(find.text('When are you considering it?'), findsOneWidget);
      for (final period in TimePeriod.values) {
        expect(
          periodChip(period),
          findsOneWidget,
          reason: '${label(period)} chip is missing',
        );
      }

      expect(chipFor(tester, TimePeriod.now).selected, isTrue);
      for (final period in TimePeriod.values.skip(1)) {
        expect(
          chipFor(tester, period).selected,
          isFalse,
          reason: '${label(period)} must not start selected',
        );
      }
      // The old footer repeated the badge and the chips; the hierarchy above
      // carries that now.
      expect(find.byKey(const Key('ritual_reading_summary')), findsNothing);
      expect(find.byKey(const Key('ritual_category_badge')), findsOneWidget);
    });

    testWidgets('the reveal control names the chosen period', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_love_evening.json'),
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);

      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byKey(const Key('reveal_button'))).label,
        contains(label(TimePeriod.now)),
      );

      await tester.tap(periodChip(TimePeriod.evening));
      await tester.pump();

      expect(
        tester.getSemantics(find.byKey(const Key('reveal_button'))).label,
        contains(label(TimePeriod.evening)),
      );
      // …and stops naming the one it was opened on.
      expect(
        tester.getSemantics(find.byKey(const Key('reveal_button'))).label,
        isNot(contains(label(TimePeriod.now))),
      );
      expect(find.byKey(const Key('ritual_reading_summary')), findsNothing);
      handle.dispose();
    });
  });

  group('the chosen period travels the whole flow', () {
    const cases = {
      TimePeriod.now: engine.TimePeriod.now,
      TimePeriod.morning: engine.TimePeriod.morning,
      TimePeriod.midday: engine.TimePeriod.midday,
      TimePeriod.afternoon: engine.TimePeriod.afternoon,
      TimePeriod.evening: engine.TimePeriod.evening,
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key.name} reaches the request as its own period', (
        tester,
      ) async {
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(rig.app);
        await openRitual(tester);

        await tester.tap(periodChip(entry.key));
        await tester.pump();
        expect(chipFor(tester, entry.key).selected, isTrue);

        await tester.tap(find.byKey(const Key('reveal_button')));
        await tester.pump(const Duration(milliseconds: 380));
        await tester.pump();

        expect(
          rig.sentRequest!.period,
          entry.value,
          reason: '${label(entry.key)} must not be sent as another period',
        );
        await pumpPastRitual(tester);
      });
    }

    testWidgets('loading and result both name the period that was sent', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_commit_withdraw_two_windows.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester, modeLabel: 'COMMIT', periodName: 'evening');

      expect(rig.sentRequest!.period, engine.TimePeriod.evening);
      expect(find.byKey(const Key('loading_period_label')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('loading_period_label'))).data,
        label(TimePeriod.evening),
      );

      await pumpPastRitual(tester);

      // The result reads the response's period, not the ritual selection.
      expect(
        find.text(stringsFor(AppLocale.english).luckyTimesEvening),
        findsOneWidget,
      );
      expect(find.byKey(const Key('result_lucky_windows')), findsOneWidget);
    });

    testWidgets('a NOW reading still explains the current moment', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);

      expect(rig.sentRequest!.period, engine.TimePeriod.now);
      expect(find.text(label(TimePeriod.now)), findsWidgets);

      await pumpPastRitual(tester);
      expect(find.byKey(const Key('result_action_guidance')), findsOneWidget);
      expect(find.byKey(const Key('result_lucky_windows')), findsNothing);
    });
  });

  group('periods that are already over', () {
    testWidgets('close at the cutoff even when the selector was already open', (
      tester,
    ) async {
      // A second before morning drops under its 90-minute cutoff.
      var clock = DateTime(2026, 9, 18, 10, 29, 59);
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_study_morning.json'),
        liveLocalClock: () => clock,
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);
      await tester.tap(periodChip(TimePeriod.morning));
      await tester.pump();
      expect(chipFor(tester, TimePeriod.morning).selected, isTrue);

      clock = DateTime(2026, 9, 18, 10, 30);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      // Still running, so it must not claim to have passed.
      expect(find.text('Morning · Too little time'), findsOneWidget);
      expect(find.text('Morning · Passed'), findsNothing);
      expect(chipFor(tester, TimePeriod.morning).onSelected, isNull);
      // The selection falls back to NOW rather than to another named period.
      expect(chipFor(tester, TimePeriod.now).selected, isTrue);
      expect(
        find.text(
          'There is not enough time left in Morning today. Choose another time.',
        ),
        findsOneWidget,
      );
      // Nothing was asked of the engine on the strength of the expired choice.
      expect(rig.repository.requests, isEmpty);

      // A period that has not started is unaffected, and still travels.
      await tester.tap(periodChip(TimePeriod.midday));
      await tester.pump();
      expect(chipFor(tester, TimePeriod.midday).selected, isTrue);
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump();
      expect(rig.sentRequest!.period, engine.TimePeriod.midday);
      await pumpPastRitual(tester);
    });

    testWidgets('a Reveal tap revalidates against its own instant', (
      tester,
    ) async {
      // The chips were painted while morning was still open. The clock then
      // crosses the cutoff with no frame in between, so the screen is stale
      // and morning is still the selection when the tap lands.
      var clock = DateTime(2026, 9, 18, 10, 29, 59);
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_study_morning.json'),
        liveLocalClock: () => clock,
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);
      await tester.tap(periodChip(TimePeriod.morning));
      await tester.pump();
      expect(chipFor(tester, TimePeriod.morning).selected, isTrue);

      // No pump: the UI still believes morning is available.
      clock = DateTime(2026, 9, 18, 10, 31);
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump();

      // Nothing was asked of the engine and nothing was captured — so nothing
      // could have consumed an unlock or played an ad either.
      expect(rig.repository.requests, isEmpty);
      expect(rig.contextProvider.captures, isEmpty);
      // The stale choice was dropped for NOW rather than quietly swapped for
      // a different named period.
      expect(chipFor(tester, TimePeriod.now).selected, isTrue);
      expect(
        find.text(
          'There is not enough time left in Morning today. Choose another time.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('returning from the background drops an expired choice', (
      tester,
    ) async {
      var clock = DateTime(2026, 9, 18, 10, 0);
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_study_morning.json'),
        liveLocalClock: () => clock,
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);
      await tester.tap(periodChip(TimePeriod.morning));
      await tester.pump();
      expect(chipFor(tester, TimePeriod.morning).selected, isTrue);

      // Away for an hour, back after morning closed. No timer fired while the
      // app was not running.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      clock = DateTime(2026, 9, 18, 11, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(chipFor(tester, TimePeriod.morning).onSelected, isNull);
      expect(find.text('Morning · Too little time'), findsOneWidget);
      expect(chipFor(tester, TimePeriod.now).selected, isTrue);
      expect(
        find.text(
          'There is not enough time left in Morning today. Choose another time.',
        ),
        findsOneWidget,
      );
      expect(rig.repository.requests, isEmpty);
    });

    testWidgets('a stale chip cannot select morning after noon', (
      tester,
    ) async {
      var clock = DateTime(2026, 9, 18, 11, 59, 59);
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        liveLocalClock: () => clock,
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);

      clock = DateTime(2026, 9, 18, 12);
      await tester.tap(periodChip(TimePeriod.morning));
      await tester.pump();
      expect(chipFor(tester, TimePeriod.morning).selected, isFalse);
      expect(chipFor(tester, TimePeriod.morning).onSelected, isNull);
      expect(chipFor(tester, TimePeriod.now).selected, isTrue);
    });

    testWidgets('are muted, marked Passed and cannot be chosen', (
      tester,
    ) async {
      // 15:00 local: morning [6,12) and midday [12,14) are behind the user;
      // afternoon [14,18) is still running.
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 15),
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);

      for (final period in [TimePeriod.morning, TimePeriod.midday]) {
        expect(
          chipFor(tester, period).onSelected,
          isNull,
          reason: '${label(period)} must be disabled once it is over',
        );
        expect(find.text('${label(period)} · Passed'), findsOneWidget);
      }
      for (final period in [
        TimePeriod.now,
        TimePeriod.afternoon,
        TimePeriod.evening,
      ]) {
        expect(
          chipFor(tester, period).onSelected,
          isNotNull,
          reason: '${label(period)} is not over yet',
        );
        expect(find.text('${label(period)} · Passed'), findsNothing);
      }

      // Tapping an elapsed chip changes nothing at all.
      await tester.tap(periodChip(TimePeriod.morning));
      await tester.pump();
      expect(chipFor(tester, TimePeriod.morning).selected, isFalse);
      expect(chipFor(tester, TimePeriod.now).selected, isTrue);

      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump();
      expect(rig.sentRequest!.period, engine.TimePeriod.now);
      await pumpPastRitual(tester);
    });

    testWidgets('a period stays selectable right up to its cutoff', (
      tester,
    ) async {
      // 10:29 leaves morning 91 minutes: one minute more than its cutoff, so
      // it is still offered and a reading still goes through.
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_study_morning.json'),
        localNow: DateTime(2026, 9, 18, 10, 29),
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);

      expect(chipFor(tester, TimePeriod.morning).onSelected, isNotNull);
      await tester.tap(periodChip(TimePeriod.morning));
      await tester.pump();
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump();

      expect(rig.sentRequest!.period, engine.TimePeriod.morning);
      await pumpPastRitual(tester);
    });

    testWidgets('NOW is selectable at every hour of the day', (tester) async {
      for (final hour in [0, 6, 12, 14, 18, 23]) {
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
          localNow: DateTime(2026, 9, 18, hour, 59),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(rig.app);
        await openRitual(tester);

        expect(
          chipFor(tester, TimePeriod.now).onSelected,
          isNotNull,
          reason: 'NOW must stay available at ${hour}h',
        );
        expect(chipFor(tester, TimePeriod.now).selected, isTrue);
        expect(find.text('NOW · Passed'), findsNothing);
        expect(find.text('NOW · Too little time'), findsNothing);

        // Evening runs to midnight, so it never reads as *passed* — but it
        // does close 90 minutes before that, like every other period.
        expect(find.text('Evening · Passed'), findsNothing);
        expect(
          chipFor(tester, TimePeriod.evening).onSelected,
          hour == 23 ? isNull : isNotNull,
          reason: 'evening at ${hour}h59',
        );
      }
    });

    test('elapsed is decided by the engine period bounds', () {
      expect(TimePeriod.now.localHours, isNull);
      expect(TimePeriod.morning.localHours, (6, 12));
      expect(TimePeriod.midday.localHours, (12, 14));
      expect(TimePeriod.afternoon.localHours, (14, 18));
      expect(TimePeriod.evening.localHours, (18, 24));

      final noon = DateTime(2026, 9, 18, 12);
      expect(TimePeriod.now.hasElapsedAt(noon), isFalse);
      expect(TimePeriod.morning.hasElapsedAt(noon), isTrue);
      expect(TimePeriod.midday.hasElapsedAt(noon), isFalse);

      final lastMinute = DateTime(2026, 9, 18, 23, 59);
      expect(TimePeriod.evening.hasElapsedAt(lastMinute), isFalse);
      expect(TimePeriod.afternoon.hasElapsedAt(lastMinute), isTrue);

      final midnight = DateTime(2026, 9, 18);
      for (final period in TimePeriod.values) {
        expect(
          period.hasElapsedAt(midnight),
          isFalse,
          reason: '${label(period)} cannot be over before the day starts',
        );
      }
    });
  });

  group('navigation and layout', () {
    testWidgets('leaving the ritual keeps the area and direction on Home', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      await tester.ensureVisible(find.byKey(const Key('category_study')));
      await tester.tap(find.byKey(const Key('category_study')));
      await tester.pump();
      await tester.ensureVisible(find.text('KEEP').first);
      await tester.tap(find.text('KEEP').first);
      await tester.pump();
      expect(find.text('Study & Growth  •  KEEP / LET GO'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('find_direction')));
      await tester.tap(find.byKey(const Key('find_direction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.tap(periodChip(TimePeriod.afternoon));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Both Home selections survived; the period went back to its default.
      expect(find.text('Study & Growth  •  KEEP / LET GO'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('find_direction')));
      await tester.tap(find.byKey(const Key('find_direction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(chipFor(tester, TimePeriod.now).selected, isTrue);

      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump();
      final request = rig.sentRequest!;
      expect(request.category, engine.ReadingCategory.study);
      expect(request.mode, engine.DecisionMode.keepLetGo);
      expect(request.period, engine.TimePeriod.now);
      await pumpPastRitual(tester);
    });

    testWidgets('the ritual selector fits common Android window sizes', (
      tester,
    ) async {
      const sizes = [
        Size(360, 640),
        Size(390, 844),
        Size(412, 915),
        Size(800, 1280),
      ];

      // 18:00 is the worst case the selector has to render: morning, midday
      // and afternoon all wear the wider "· Passed" label.
      for (final size in sizes) {
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_love_evening.json'),
          localNow: DateTime(2026, 9, 18, 18),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        useScreen(tester, size: size);
        await tester.pumpWidget(rig.app);
        await tester.pump();
        await openRitual(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: 'ritual failed at $size',
        );
        expect(find.byKey(const Key('ritual_period_selector')), findsOneWidget);
        for (final period in TimePeriod.values) {
          expect(
            periodChip(period),
            findsOneWidget,
            reason: 'missing at $size',
          );
        }
        expect(find.text('Afternoon · Passed'), findsOneWidget);

        await tester.tap(periodChip(TimePeriod.evening));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'period selector overflowed at $size',
        );

        await tester.tap(find.byKey(const Key('reveal_button')));
        await tester.pump(const Duration(milliseconds: 380));
        await tester.pump();
        expect(rig.sentRequest!.period, engine.TimePeriod.evening);

        await pumpPastRitual(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'result failed at $size',
        );
      }
    });
  });

  group('until the reader\'s own time zone is known', () {
    /// How much of Morning is left is a question about the reader's clock.
    /// Until the app has read that clock it has no answer, and the one answer
    /// it must not give is "plenty".
    testWidgets('a slow lookup withholds the named periods, not NOW', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        timezoneDelay: const Duration(seconds: 2),
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);

      for (final period in TimePeriod.values) {
        if (period == TimePeriod.now) continue;
        expect(
          chipFor(tester, period).onSelected,
          isNull,
          reason: '${label(period)} was offered before the zone was known',
        );
        expect(
          find.text('${label(period)} · Checking time zone'),
          findsOneWidget,
        );
        // And it does not claim a reason it has not established.
        expect(find.text('${label(period)} · Passed'), findsNothing);
        expect(find.text('${label(period)} · Too little time'), findsNothing);
      }
      // NOW needs no clock but the tap's own, so it is never withheld.
      expect(chipFor(tester, TimePeriod.now).onSelected, isNotNull);
      expect(chipFor(tester, TimePeriod.now).selected, isTrue);
      // Still in flight, so nothing to retry yet.
      expect(find.byKey(const Key('ritual_timezone_retry')), findsNothing);

      // The zone arrives and every chip becomes answerable.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      for (final period in TimePeriod.values) {
        expect(
          chipFor(tester, period).onSelected,
          isNotNull,
          reason: '${label(period)} stayed shut after the zone resolved',
        );
      }
      expect(find.textContaining('Checking time zone'), findsNothing);
    });

    testWidgets('a Reveal during the lookup sends nothing but NOW', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        timezoneDelay: const Duration(seconds: 2),
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);

      // NOW is the selection and it is valid, so this is a real reading.
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump();
      expect(rig.sentRequest!.period, engine.TimePeriod.now);
      await pumpPastRitual(tester);
    });

    testWidgets('a failed lookup says so and offers to look again', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_study_morning.json'),
        localNow: DateTime(2026, 9, 18, 9),
        timezoneFailures: 1,
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);
      await tester.pump();

      expect(
        find.text('${label(TimePeriod.morning)} · Time zone unknown'),
        findsOneWidget,
      );
      expect(chipFor(tester, TimePeriod.morning).onSelected, isNull);
      expect(find.byKey(const Key('ritual_timezone_retry')), findsOneWidget);
      expect(
        find.text(
          'Your time zone could not be read, so only NOW is available. '
          'Try again to choose a period.',
        ),
        findsOneWidget,
      );
      // NOW survives: it is the one period that needs no clock.
      expect(chipFor(tester, TimePeriod.now).onSelected, isNotNull);

      // The second lookup succeeds, and morning — open at 09:00 — comes back.
      await tester.tap(find.byKey(const Key('ritual_timezone_retry_button')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('ritual_timezone_retry')), findsNothing);
      expect(chipFor(tester, TimePeriod.morning).onSelected, isNotNull);
      await tester.tap(periodChip(TimePeriod.morning));
      await tester.pump();
      expect(chipFor(tester, TimePeriod.morning).selected, isTrue);
    });

    testWidgets('a lookup that fails at the tap stops the reading', (
      tester,
    ) async {
      // The zone resolves when the screen opens, so Morning is selectable and
      // genuinely open at 09:00. The lookup at the Reveal tap then fails —
      // which is how a device whose zone has just changed behaves — and the
      // screen no longer knows which clock to judge Morning by.
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_study_morning.json'),
        localNow: DateTime(2026, 9, 18, 9),
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);
      await tester.tap(periodChip(TimePeriod.morning));
      await tester.pump();
      expect(chipFor(tester, TimePeriod.morning).selected, isTrue);

      rig.contextProvider.timezoneFailures = 1;
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump();
      await tester.pump();

      // Nothing was calculated and nothing was captured, so nothing could
      // have consumed an unlock or played an ad either.
      expect(rig.repository.requests, isEmpty);
      expect(rig.contextProvider.captures, isEmpty);
      // The selection fell back to NOW rather than to another named period,
      // and the screen says why instead of looking broken.
      expect(chipFor(tester, TimePeriod.now).selected, isTrue);
      expect(find.byKey(const Key('ritual_timezone_retry')), findsOneWidget);
      // The zone read before the tap is discarded rather than kept as a
      // guess: every named period is unanswerable again.
      expect(
        find.text('${label(TimePeriod.morning)} · Time zone unknown'),
        findsOneWidget,
      );
    });
  });

  group('a Reveal exactly at a cutoff', () {
    /// (period, the local minute its cutoff falls on).
    const cutoffs = <(TimePeriod, (int, int))>[
      (TimePeriod.morning, (10, 30)),
      (TimePeriod.midday, (13, 0)),
      (TimePeriod.afternoon, (16, 30)),
      (TimePeriod.evening, (22, 30)),
    ];

    for (final (period, (hour, minute)) in cutoffs) {
      testWidgets('${period.name} is refused on its cutoff minute', (
        tester,
      ) async {
        // Selected a minute before the cutoff, revealed exactly on it, with
        // no frame in between. The chips were painted while it was open, so
        // only the tap's own revalidation can catch this.
        var clock = DateTime(
          2026,
          9,
          18,
          hour,
          minute,
        ).subtract(const Duration(minutes: 1));
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_study_morning.json'),
          liveLocalClock: () => clock,
        );
        await tester.pumpWidget(rig.app);
        await openRitual(tester);
        await tester.tap(periodChip(period));
        await tester.pump();
        expect(chipFor(tester, period).selected, isTrue);

        clock = DateTime(2026, 9, 18, hour, minute);
        await tester.tap(find.byKey(const Key('reveal_button')));
        await tester.pump();
        await tester.pump();

        expect(rig.repository.requests, isEmpty);
        expect(rig.contextProvider.captures, isEmpty);
        expect(chipFor(tester, TimePeriod.now).selected, isTrue);
        expect(
          find.text(
            'There is not enough time left in ${label(period)} today. '
            'Choose another time.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('${period.name} still travels a minute before it', (
        tester,
      ) async {
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_study_morning.json'),
          localNow: DateTime(
            2026,
            9,
            18,
            hour,
            minute,
          ).subtract(const Duration(minutes: 1)),
        );
        await tester.pumpWidget(rig.app);
        await openRitual(tester);
        await tester.tap(periodChip(period));
        await tester.pump();
        await tester.tap(find.byKey(const Key('reveal_button')));
        await tester.pump(const Duration(milliseconds: 380));
        await tester.pump();

        expect(rig.sentRequest!.period, toEnginePeriod(period));
        await pumpPastRitual(tester);
      });
    }
  });
}
