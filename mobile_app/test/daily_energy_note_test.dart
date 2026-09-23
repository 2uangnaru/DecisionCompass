import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/widgets/daily_energy_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'data/fixture_loader.dart';
import 'reading_test_rig.dart';

/// The ritual floor is 4.2–5.2s, so this clears any draw of the jitter.
Future<void> pumpPastRitual(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pumpAndSettle();
}

const quietSentence =
    'Today’s symbolic energy turns inward, making space for quiet reflection.';
const steadySentence =
    'Today’s symbolic energy keeps an even, grounded rhythm.';
const flowingSentence =
    'Today’s symbolic energy moves with the tide; the change signal takes '
    'the lead.';
const brightSentence =
    'Today’s symbolic energy shines with momentum and room for expression.';

final infoButton = find.byKey(const Key('daily_energy_info_button'));
final note = find.byKey(const Key('daily_energy_note'));

engine.DailyBrief briefWith(String level) => engine.DailyBrief(
  luckyNumber: 4,
  colorInspiration: 'ocean_blue',
  energy: engine.DailyEnergy(level: level, index: 51, dataCoverage: 1),
);

/// Home, with today's brief already resolved.
Future<ReadingTestRig> pumpHome(
  WidgetTester tester, {
  required String level,
  DateTime? localNow,
}) async {
  final rig = ReadingTestRig(
    response: fixtureResponse('ready_yes_no_now.json'),
    localNow: localNow ?? DateTime(2026, 9, 18, 7),
  );
  rig.dailyBriefProvider.response = briefWith(level);
  await tester.pumpWidget(rig.app);
  await completeOnboarding(tester);
  await tester.pump(); // let the daily-brief future settle
  return rig;
}

void main() {
  group('the copy behind the button', () {
    test('every tone has its own sentence and unavailable has none', () {
      const levels = [
        'quiet',
        'soft',
        'steady',
        'lively',
        'bright',
        'radiant',
        'focused',
        'flowing',
      ];
      final sentences = levels.map(dailyEnergyMessage).toList();
      for (var i = 0; i < levels.length; i++) {
        expect(sentences[i], isNotNull, reason: '${levels[i]} has no sentence');
      }
      expect(
        sentences.toSet(),
        hasLength(levels.length),
        reason: 'two tones share a sentence',
      );
      // Nothing to explain, so nothing offers to explain it.
      expect(dailyEnergyMessage('unavailable'), isNull);
      expect(dailyEnergyMessage(null), isNull);
      expect(dailyEnergyMessage('not_a_level'), isNull);
    });
  });

  group('Home', () {
    testWidgets('the button opens a tab beside it and closes it again', (
      tester,
    ) async {
      await pumpHome(tester, level: 'quiet');
      expect(find.text('QUIET'), findsOneWidget);
      expect(note, findsNothing);
      final card = find.byKey(const Key('daily_signals_content'));
      final closed = tester.getSize(card).height;

      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      expect(note, findsOneWidget);
      expect(find.text(quietSentence), findsOneWidget);
      // It floats over the page, so nothing underneath it moves.
      expect(tester.getSize(card).height, closed);

      await tester.tap(infoButton);
      await tester.pumpAndSettle();
      expect(note, findsNothing);
      expect(find.text(quietSentence), findsNothing);
      expect(tester.getSize(card).height, closed);
    });

    testWidgets('the tab fills the empty band to the right of the icon', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(720, 900));
      await pumpHome(tester, level: 'quiet');
      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      final icon = tester.getRect(infoButton);
      final tab = tester.getRect(note);
      // Beside the icon, not below it: the row's own space is used first.
      expect(
        tab.left,
        greaterThanOrEqualTo(icon.right),
        reason: 'the tab should sit in the band to the right',
      );
      expect(tab.left - icon.right, lessThan(40));
      // It grows upward from the icon into the empty band, so it never hangs
      // over whatever the row sits above.
      expect(
        tab.bottom,
        lessThanOrEqualTo(icon.bottom + 1),
        reason: 'the tab must not reach below the energy row',
      );
      expect(tab.bottom, greaterThan(icon.top));
      // Inside the screen, and small — a tab, not a panel.
      expect(tab.top, greaterThanOrEqualTo(0));
      expect(tab.right, lessThanOrEqualTo(720));
      expect(tab.width, lessThanOrEqualTo(270));
    });

    testWidgets('the open tab leaves the signal tiles uncovered', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(720, 900));
      await pumpHome(tester, level: 'focused'); // the longest sentence
      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      final tab = tester.getRect(note);
      for (final label in ['Lucky number today:', 'Your color today:']) {
        expect(
          tab.overlaps(tester.getRect(find.text(label))),
          isFalse,
          reason: 'the tab covers $label',
        );
      }
    });

    testWidgets('it drops under the icon when the band is too narrow', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await pumpHome(tester, level: 'quiet');
      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      final icon = tester.getRect(infoButton);
      final tab = tester.getRect(note);
      expect(
        tab.top,
        greaterThanOrEqualTo(icon.bottom),
        reason: 'no room beside it on a phone, so it goes below',
      );
      expect(tab.top - icon.bottom, lessThan(40));
      expect(tab.left, greaterThanOrEqualTo(0));
      expect(tab.right, lessThanOrEqualTo(360));
    });

    testWidgets('tapping outside the tab closes it', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await pumpHome(tester, level: 'quiet');
      await tester.tap(infoButton);
      await tester.pumpAndSettle();
      final tab = tester.getRect(note);
      expect(note, findsOneWidget);

      // Well clear of the tab, and still on screen.
      final outside = Offset(180, tab.bottom + 120);
      expect(tab.contains(outside), isFalse);
      await tester.tapAt(outside);
      await tester.pumpAndSettle();
      expect(note, findsNothing);
    });

    testWidgets('scrolling the page closes it', (tester) async {
      await pumpHome(tester, level: 'quiet');
      await tester.tap(infoButton);
      await tester.pumpAndSettle();
      expect(note, findsOneWidget);

      await tester.drag(
        find.text('Caught between choices?'),
        const Offset(0, -140),
      );
      await tester.pumpAndSettle();
      expect(note, findsNothing);
    });

    testWidgets('it shows only the current label, with no sheet or overlay', (
      tester,
    ) async {
      await pumpHome(tester, level: 'quiet');
      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      // A tab, not a route: nothing was pushed over the page.
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const Key('daily_energy_info_sheet')), findsNothing);
      // Home is still fully on screen behind it.
      expect(find.byKey(const Key('find_direction')), findsOneWidget);

      // No title, no list of the other seven tones, no disclaimer.
      expect(find.text('TODAY’S ENERGY'), findsNothing);
      expect(find.textContaining('A symbolic reflection'), findsNothing);
      for (final other in [steadySentence, flowingSentence, brightSentence]) {
        expect(find.text(other), findsNothing);
      }
      for (final label in ['SOFT', 'STEADY', 'LIVELY', 'BRIGHT', 'FLOWING']) {
        expect(find.text(label), findsNothing);
      }
    });

    testWidgets('a new local day closes yesterday’s sentence and offers its '
        'own', (tester) async {
      final rig = await pumpHome(
        tester,
        level: 'steady',
        localNow: DateTime(2026, 9, 18, 20),
      );
      await tester.tap(infoButton);
      await tester.pumpAndSettle();
      expect(find.text(steadySentence), findsOneWidget);

      rig.localClock = DateTime(2026, 9, 19, 7);
      rig.dailyBriefProvider.response = briefWith('flowing');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(); // resolve the replacement FutureBuilder snapshot
      await tester.pumpAndSettle();

      expect(find.text('FLOWING'), findsOneWidget);
      // An insight belongs to one date and tone. Yesterday's cannot linger,
      // and today's is not shown until it is opened.
      expect(
        find.text(steadySentence),
        findsNothing,
        reason: 'yesterday’s sentence must not outlive its label',
      );
      expect(note, findsNothing);

      await tester.tap(infoButton);
      await tester.pumpAndSettle();
      expect(find.text(flowingSentence), findsOneWidget);
    });

    testWidgets('a day with no energy offers no button', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 7),
      );
      rig.dailyBriefProvider.response = const engine.DailyBrief(
        luckyNumber: 4,
        colorInspiration: 'ocean_blue',
        energy: engine.DailyEnergy(
          level: 'unavailable',
          index: null,
          dataCoverage: 0.1,
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await tester.pump();

      expect(find.text('—'), findsWidgets);
      expect(infoButton, findsNothing);
      expect(note, findsNothing);
    });
  });

  group('the result card', () {
    Finder inBrief(Finder matching) => find.descendant(
      of: find.byKey(const Key('result_daily_brief')),
      matching: matching,
    );

    testWidgets('the button reveals the sentence in place and hides it again', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await pumpPastRitual(tester);

      // This fixture's engine-calculated day is BRIGHT.
      expect(
        inBrief(find.byKey(const Key('result_daily_energy_label'))),
        findsOneWidget,
      );
      expect(find.text('BRIGHT'), findsOneWidget);
      expect(note, findsNothing);
      final card = find.byKey(const Key('result_daily_brief'));
      final closed = tester.getSize(card).height;

      await tester.tap(inBrief(infoButton));
      await tester.pumpAndSettle();

      expect(note, findsOneWidget);
      expect(tester.getSize(card).height, closed);
      expect(find.text(brightSentence), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text(quietSentence), findsNothing);

      await tester.tap(inBrief(infoButton));
      await tester.pumpAndSettle();
      expect(note, findsNothing);
      expect(find.text(brightSentence), findsNothing);
      expect(tester.getSize(card).height, closed);
    });

    testWidgets('a reading with no energy offers no button', (tester) async {
      // The engine cannot be asked for an unavailable day on demand, so the
      // committed fixture is patched at the one field under test.
      final json = readFixture('ready_yes_no_now.json');
      (json['dailyBrief']! as Map<String, dynamic>)['energy'] = {
        'level': 'unavailable',
        'index': null,
        'dataCoverage': 0.1,
      };
      final rig = ReadingTestRig(
        response: engine.ReadingResponse.fromJson(json),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await pumpPastRitual(tester);

      expect(find.byKey(const Key('result_daily_brief')), findsOneWidget);
      expect(inBrief(infoButton), findsNothing);
      expect(note, findsNothing);
    });
  });

  group('narrow and common Android window sizes', () {
    const sizes = [
      Size(360, 640),
      Size(390, 844),
      Size(412, 915),
      Size(800, 1280),
    ];

    testWidgets('Home fits with the sentence open', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in sizes) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.binding.setSurfaceSize(size);
        // FOCUSED carries the longest sentence of the eight.
        await pumpHome(tester, level: 'focused');
        expect(tester.takeException(), isNull, reason: 'Home failed at $size');

        await tester.tap(infoButton);
        await tester.pumpAndSettle();
        expect(note, findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'the sentence overflowed at $size',
        );
      }
    });

    testWidgets('the result card fits with the sentence open', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final inBrief = find.descendant(
        of: find.byKey(const Key('result_daily_brief')),
        matching: infoButton,
      );

      for (final size in sizes) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.binding.setSurfaceSize(size);
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
        );
        await tester.pumpWidget(rig.app);
        await tester.pump();
        await completeOnboarding(tester);
        await revealReading(tester);
        await pumpPastRitual(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'the result card failed at $size',
        );

        // The brief sits below the fold on a short phone.
        await tester.ensureVisible(inBrief);
        await tester.pumpAndSettle();
        await tester.tap(inBrief);
        await tester.pumpAndSettle();
        expect(find.text(brightSentence), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'the sentence overflowed at $size',
        );
      }
    });
  });
}
