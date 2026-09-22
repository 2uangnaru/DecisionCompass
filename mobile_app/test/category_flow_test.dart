import 'package:decision_compass/category_presentation.dart';
import 'package:decision_compass/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

Future<void> pumpPastRitual(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pumpAndSettle();
}

void main() {
  group('Home category selector', () {
    testWidgets('offers all seven areas and starts on Overall', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      expect(find.byKey(const Key('category_selector')), findsOneWidget);
      expect(categoryChoices, hasLength(ReadingCategory.values.length));
      for (final choice in categoryChoices) {
        await tester.ensureVisible(find.byKey(Key(choice.testKey)));
        expect(find.byKey(Key(choice.testKey)), findsOneWidget);
        expect(find.text(choice.label), findsWidgets);
      }

      // Default selection is visible in the summary line.
      expect(find.textContaining('Overall'), findsWidgets);

      // Wire values are never rendered.
      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' | ');
      for (final category in ReadingCategory.values) {
        expect(
          rendered.contains(category.wireValue),
          isFalse,
          reason: 'wire value ${category.wireValue} must not be shown',
        );
      }
    });

    testWidgets('shows the agreed positioning copy without overclaiming', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      expect(find.byKey(const Key('home_positioning')), findsOneWidget);
      expect(find.text('A COMPASS FOR UNCERTAIN MOMENTS'), findsOneWidget);
      expect(find.text('Caught between choices?'), findsOneWidget);
      expect(find.textContaining('not a command'), findsOneWidget);
      expect(find.text('What area is this about?'), findsOneWidget);
      expect(find.text('Which direction do you need?'), findsOneWidget);

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => (text.data ?? '').toLowerCase())
          .join(' | ');
      for (final forbidden in [
        'guarantee',
        'accurate prediction',
        'the universe knows',
        'will tell you what to do',
        'bad day',
        'dangerous time',
      ]) {
        expect(
          rendered.contains(forbidden),
          isFalse,
          reason: 'claimed "$forbidden"',
        );
      }
    });
  });

  group('the selected category reaches the request', () {
    for (final category in ReadingCategory.values) {
      testWidgets('${category.wireValue} travels end to end', (tester) async {
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(rig.app);
        await completeOnboarding(tester);
        await revealReading(tester, category: category);
        await tester.pump();

        // Typed value, not a label match.
        expect(rig.sentRequest!.category, category);
        await pumpPastRitual(tester);
      });
    }

    testWidgets('mode and period still travel alongside the category', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(
        tester,
        category: ReadingCategory.money,
        modeLabel: 'KEEP',
        periodName: 'evening',
      );
      await tester.pump();

      final request = rig.sentRequest!;
      expect(request.category, ReadingCategory.money);
      expect(request.mode, DecisionMode.keepLetGo);
      expect(request.period, TimePeriod.evening);
      await pumpPastRitual(tester);
    });
  });

  group('category context through the experience', () {
    testWidgets('Ritual and Loading name the selected area', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_love_evening.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      // Select Love, then step to the ritual only.
      await tester.ensureVisible(find.byKey(const Key('category_love')));
      await tester.tap(find.byKey(const Key('category_love')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('find_direction')));
      await tester.tap(find.byKey(const Key('find_direction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byKey(const Key('ritual_category_badge')), findsOneWidget);
      expect(find.text('Love & Relationships'), findsWidgets);

      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump();

      expect(find.byKey(const Key('loading_category_label')), findsOneWidget);
      expect(find.text('Reading for Love & Relationships'), findsOneWidget);
      expect(rig.sentRequest!.category, ReadingCategory.love);

      await pumpPastRitual(tester);
      expect(find.byKey(const Key('result_category_badge')), findsOneWidget);
    });

    testWidgets('Result trusts the response category over the UI selection', (
      tester,
    ) async {
      // The UI stays on Overall, but the response says love.
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_love_evening.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await tester.pump();
      expect(rig.sentRequest!.category, ReadingCategory.general);

      await pumpPastRitual(tester);

      final badge = find.descendant(
        of: find.byKey(const Key('result_category_badge')),
        matching: find.text('Love & Relationships'),
      );
      expect(
        badge,
        findsOneWidget,
        reason: 'must echo the response, not the selection',
      );
      expect(find.text('Overall'), findsNothing);
    });

    testWidgets('an other-category reading is labelled as its own area', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_other_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester, category: ReadingCategory.other);
      await tester.pump();
      expect(rig.sentRequest!.category, ReadingCategory.other);

      await pumpPastRitual(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('result_category_badge')),
          matching: find.text('Something Else'),
        ),
        findsOneWidget,
      );
    });
  });

  group('navigation and layout', () {
    testWidgets('leaving the ritual keeps the chosen area on Home', (
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
      await tester.ensureVisible(find.byKey(const Key('find_direction')));
      await tester.tap(find.byKey(const Key('find_direction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Study & Growth'), findsWidgets);

      // Back out of the ritual without revealing.
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category_selector')), findsOneWidget);
      expect(find.textContaining('Study & Growth'), findsWidgets);

      await revealReading(tester);
      await tester.pump();
      expect(rig.sentRequest!.category, ReadingCategory.study);
      await pumpPastRitual(tester);
    });

    testWidgets('every category card meets the 48dp minimum touch target', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 640));
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      for (final choice in categoryChoices) {
        final card = find.byKey(Key(choice.testKey));
        await tester.ensureVisible(card);
        final height = tester.getSize(card).height;
        expect(
          height,
          greaterThanOrEqualTo(48.0),
          reason: '${choice.label} target is only ${height}dp tall',
        );
      }

      // A selected card draws a thicker border; it must still clear the floor.
      await tester.ensureVisible(find.byKey(const Key('category_money')));
      await tester.tap(find.byKey(const Key('category_money')));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('category_money'))).height,
        greaterThanOrEqualTo(48.0),
      );

      // Taller cards must not overflow the compact layout.
      expect(tester.takeException(), isNull);
    });

    testWidgets('the selector fits common Android window sizes', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const sizes = [
        Size(360, 640),
        Size(390, 844),
        Size(412, 915),
        Size(800, 1280),
      ];

      for (final size in sizes) {
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(rig.app);
        await tester.pump();
        await completeOnboarding(tester);

        expect(tester.takeException(), isNull, reason: 'Home failed at $size');
        await tester.ensureVisible(find.byKey(const Key('category_other')));
        await tester.tap(find.byKey(const Key('category_other')));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'category selector overflowed at $size',
        );

        await revealReading(tester);
        await tester.pump();
        expect(rig.sentRequest!.category, ReadingCategory.other);
        await pumpPastRitual(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Result failed at $size',
        );
      }
    });
  });
}
