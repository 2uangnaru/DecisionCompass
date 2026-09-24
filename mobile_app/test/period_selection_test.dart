import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

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
          reason: '${period.label} must not be selectable on Home',
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
          reason: '${period.label} chip is missing',
        );
      }

      expect(chipFor(tester, TimePeriod.now).selected, isTrue);
      for (final period in TimePeriod.values.skip(1)) {
        expect(
          chipFor(tester, period).selected,
          isFalse,
          reason: '${period.label} must not start selected',
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
        tester
            .getSemantics(find.byKey(const Key('reveal_button')))
            .label
            .contains('Reveal my direction for now'),
        isTrue,
      );

      await tester.tap(periodChip(TimePeriod.evening));
      await tester.pump();

      expect(
        tester
            .getSemantics(find.byKey(const Key('reveal_button')))
            .label
            .contains('Reveal my direction for this evening'),
        isTrue,
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
          reason: '${entry.key.label} must not be sent as another period',
        );
        await pumpPastRitual(tester);
      });
    }

    testWidgets('loading and result both name the period that was sent', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_forward_backward_two_windows.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester, modeLabel: 'FORWARD', periodName: 'evening');

      expect(rig.sentRequest!.period, engine.TimePeriod.evening);
      expect(find.byKey(const Key('loading_period_label')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('loading_period_label'))).data,
        'This Evening',
      );

      await pumpPastRitual(tester);

      // The result reads the response's period, not the ritual selection.
      expect(find.text('Your Luckiest Times This Evening'), findsOneWidget);
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
      expect(find.text('Now'), findsOneWidget);

      await pumpPastRitual(tester);
      expect(
        find.text('This reading reflects your current moment.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('result_lucky_windows')), findsNothing);
    });
  });

  group('periods that are already over', () {
    testWidgets('lock at noon even when the selector was already open', (
      tester,
    ) async {
      var clock = DateTime(2026, 9, 18, 11, 59, 59);
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_study_morning.json'),
        liveLocalClock: () => clock,
      );
      await tester.pumpWidget(rig.app);
      await openRitual(tester);
      await tester.tap(periodChip(TimePeriod.morning));
      await tester.pump();
      expect(chipFor(tester, TimePeriod.morning).selected, isTrue);

      clock = DateTime(2026, 9, 18, 12);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Morning · Passed'), findsOneWidget);
      expect(chipFor(tester, TimePeriod.morning).onSelected, isNull);
      expect(
        find.text('Morning has passed. Choose another time.'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('reveal_button')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(rig.repository.requests, isEmpty);

      await tester.tap(periodChip(TimePeriod.midday));
      await tester.pump();
      expect(chipFor(tester, TimePeriod.midday).selected, isTrue);
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump();
      expect(rig.sentRequest!.period, engine.TimePeriod.midday);
      await pumpPastRitual(tester);
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
          reason: '${period.label} must be disabled once it is over',
        );
        expect(find.text('${period.label} · Passed'), findsOneWidget);
      }
      for (final period in [
        TimePeriod.now,
        TimePeriod.afternoon,
        TimePeriod.evening,
      ]) {
        expect(
          chipFor(tester, period).onSelected,
          isNotNull,
          reason: '${period.label} is not over yet',
        );
        expect(find.text('${period.label} · Passed'), findsNothing);
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

    testWidgets('a period that is still running stays selectable at its edge', (
      tester,
    ) async {
      // 11:59 is the last minute of morning; the boundary must not disable it.
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_study_morning.json'),
        localNow: DateTime(2026, 9, 18, 11, 59),
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
        // Evening runs to midnight, so it never reads as passed.
        expect(chipFor(tester, TimePeriod.evening).onSelected, isNotNull);
        expect(find.text('NOW · Passed'), findsNothing);
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
          reason: '${period.label} cannot be over before the day starts',
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
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
        await tester.binding.setSurfaceSize(size);
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
}
