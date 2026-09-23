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
    testWidgets('the button reveals one sentence in place and hides it again', (
      tester,
    ) async {
      await pumpHome(tester, level: 'quiet');
      expect(find.text('QUIET'), findsOneWidget);
      expect(note, findsNothing);
      final card = find.byKey(const Key('daily_signals_content'));
      final collapsed = tester.getSize(card).height;

      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      expect(note, findsOneWidget);
      expect(find.text(quietSentence), findsOneWidget);
      // The card grew to hold the sentence rather than covering anything.
      expect(tester.getSize(card).height, greaterThan(collapsed));

      await tester.tap(infoButton);
      await tester.pumpAndSettle();
      expect(note, findsNothing);
      expect(find.text(quietSentence), findsNothing);
      expect(tester.getSize(card).height, collapsed);
    });

    testWidgets('it shows only the current label, with no sheet or overlay', (
      tester,
    ) async {
      await pumpHome(tester, level: 'quiet');
      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      // Nothing is layered over the page. (A MaterialApp always carries one
      // ModalBarrier for its own route, so that is not the signal here.)
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(PopupMenuButton<Object>), findsNothing);
      expect(find.byKey(const Key('daily_energy_info_sheet')), findsNothing);

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

    testWidgets('an open sentence follows the label onto a new local day', (
      tester,
    ) async {
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
      expect(find.text(flowingSentence), findsOneWidget);
      expect(
        find.text(steadySentence),
        findsNothing,
        reason: 'yesterday’s sentence must not outlive its label',
      );
      expect(note, findsOneWidget, reason: 'it should not collapse by itself');
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
      expect(inBrief(note), findsNothing);
      final card = find.byKey(const Key('result_daily_brief'));
      final collapsed = tester.getSize(card).height;

      await tester.tap(inBrief(infoButton));
      await tester.pumpAndSettle();

      expect(inBrief(note), findsOneWidget);
      expect(tester.getSize(card).height, greaterThan(collapsed));
      expect(find.text(brightSentence), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text(quietSentence), findsNothing);

      await tester.tap(inBrief(infoButton));
      await tester.pumpAndSettle();
      expect(inBrief(note), findsNothing);
      expect(find.text(brightSentence), findsNothing);
      expect(tester.getSize(card).height, collapsed);
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
      expect(inBrief(note), findsNothing);
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
