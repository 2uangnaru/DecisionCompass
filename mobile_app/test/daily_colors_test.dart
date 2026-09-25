import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/local_engine/colors.dart';
import 'package:decision_compass/local_engine/core/core.dart';
import 'package:decision_compass/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// Mirrors `calculation-engine/test/colors.test.js`. Node/Dart parity across
/// real readings is covered by `local_engine/edge_readings_parity_test.dart`;
/// these pin the rule itself on the Dart side.
void main() {
  group('the palette', () {
    test('is twenty distinct colours, two per stem', () {
      expect(palette, hasLength(10));
      final keys = <String>[], hexes = <String>[], names = <String>[];
      for (final pair in palette) {
        expect(pair, hasLength(2));
        for (final shade in pair) {
          expect(RegExp(r'^#[0-9A-F]{6}$').hasMatch(shade.hex), isTrue);
          keys.add(shade.key);
          hexes.add(shade.hex);
          names.add(shade.name);
        }
      }
      expect(keys.toSet(), hasLength(20));
      expect(hexes.toSet(), hasLength(20));
      expect(names.toSet(), hasLength(20));
    });

    test('every stem sits in an element that holds it', () {
      expect(stemElements, hasLength(10));
      elementStems.forEach((element, stems) {
        expect(stems, hasLength(2));
        for (final stem in stems) {
          expect(stemElements[stem], element);
        }
      });
      // The generating cycle is one five-step loop.
      var element = 'wood';
      final walked = <String>{};
      for (var i = 0; i < 5; i++) {
        walked.add(element);
        element = generates[element]!;
      }
      expect(element, 'wood');
      expect(walked, hasLength(5));
    });
  });

  group('the selection rule', () {
    List<ColorSegment> segmentOf(double a, {double coverage = 1}) => [
      (
        duration: 3600,
        modules: <String, Evidence>{
          'B': Evidence(a, 0, coverage),
          'Z': Evidence(a, 0, coverage),
          'W': Evidence(a, 0, coverage),
          'N': Evidence(a, 0, coverage),
        },
      ),
    ];

    test('the lead family is the day stem, whatever the signal', () {
      for (var stem = 0; stem < 10; stem++) {
        for (final signal in [-0.6, 0.6]) {
          final colors = dailyColors(segmentOf(signal), stem, 1);
          final lead = colors['lead']! as Map<String, Object?>;
          expect(lead['stem'], stem);
          expect(lead['element'], stemElements[stem]);
        }
      }
    });

    test('the lead shade follows the sign of the signal', () {
      final positive = dailyColors(segmentOf(0.6), 0, 1);
      final negative = dailyColors(segmentOf(-0.6), 0, 1);
      expect(
        (positive['lead']! as Map)['key'],
        isNot((negative['lead']! as Map)['key']),
        reason: 'both signs picked the same shade',
      );
    });

    test('supporting is always the generated family, never the lead one', () {
      for (var stem = 0; stem < 10; stem++) {
        final colors = dailyColors(segmentOf(0.2), stem, 3);
        final lead = colors['lead']! as Map<String, Object?>;
        final supporting = colors['supporting']! as Map<String, Object?>;
        expect(supporting['element'], generates[lead['element']]);
        expect(supporting['element'], isNot(lead['element']));
        expect(supporting['hex'], isNot(lead['hex']));
      }
    });

    test('the supporting shade follows the personal day parity', () {
      final odd = dailyColors(segmentOf(0.2), 0, 3);
      final even = dailyColors(segmentOf(0.2), 0, 4);
      expect(
        (odd['supporting']! as Map)['key'],
        isNot((even['supporting']! as Map)['key']),
      );
    });

    test('a module with no coverage does not vote', () {
      final full = <String, Evidence>{
        'B': Evidence(.5, 0, 1),
        'Z': Evidence(.5, 0, 1),
        'W': Evidence(.5, 0, 1),
        'N': Evidence(.5, 0, 1),
      };
      expect(colorSignal(full, leadWeights), closeTo(.5, 1e-12));
      final partial = <String, Evidence>{
        'B': Evidence(.5, 0, 1),
        'Z': Evidence(.5, 0, 0),
        'W': Evidence(.5, 0, 1),
        'N': Evidence(.5, 0, 0),
      };
      expect(colorSignal(partial, leadWeights), closeTo(.5, 1e-12));
      expect(colorSignal(const <String, Evidence>{}, supportWeights), 0);
    });

    test('day modules are weighted by elapsed seconds', () {
      final modules = dailyModules([
        (duration: 3600, modules: {'B': Evidence(1, 0, 1)}),
        (duration: 10800, modules: {'B': Evidence(-1, 0, 1)}),
      ]);
      expect(modules['B']!.a, closeTo(-.5, 1e-12));
      expect(() => dailyModules(const []), throwsA(isA<EngineFailure>()));
      expect(
        () => dailyModules([
          (duration: 0, modules: {'B': Evidence(0, 0, 1)}),
        ]),
        throwsA(isA<EngineFailure>()),
      );
    });

    test('an out-of-range stem is refused', () {
      expect(
        () => dailyColors(segmentOf(0), 10, 1),
        throwsA(isA<EngineFailure>()),
      );
      expect(
        () => dailyColors(segmentOf(0), -1, 1),
        throwsA(isA<EngineFailure>()),
      );
    });
  });

  group('the DTO', () {
    test('refuses a pair that is not actually two colours', () {
      Map<String, Object?> color(
        String key,
        String hex,
        String element,
        int stem,
      ) => {
        'key': key,
        'name': key,
        'hex': hex,
        'element': element,
        'stem': stem,
      };
      expect(
        () => engine.DailyColors.fromJson({
          'lead': color('a', '#112233', 'wood', 0),
          'supporting': color('b', '#445566', 'wood', 1),
        }),
        throwsA(isA<engine.ReadingDtoException>()),
        reason: 'the same family twice is not a pairing',
      );
      expect(
        () => engine.DailyColors.fromJson({
          'lead': color('a', '#112233', 'wood', 0),
          'supporting': color('b', '#112233', 'fire', 2),
        }),
        throwsA(isA<engine.ReadingDtoException>()),
        reason: 'the same hex twice is not two swatches',
      );
      expect(
        () => engine.DailyColors.fromJson({
          'lead': color('a', 'not-a-hex', 'wood', 0),
          'supporting': color('b', '#445566', 'fire', 2),
        }),
        throwsA(isA<engine.ReadingDtoException>()),
      );
      expect(
        () => engine.DailyColors.fromJson({
          'lead': color('a', '#112233', 'plasma', 0),
          'supporting': color('b', '#445566', 'fire', 2),
        }),
        throwsA(isA<engine.ReadingDtoException>()),
      );
    });

    test('turns a hex into an opaque colour', () {
      const color = engine.DailyColor(
        key: 'ocean_blue',
        name: 'Ocean Blue',
        hex: '#66A9D2',
        element: 'water',
        stem: 8,
      );
      expect(color.argb, 0xFF66A9D2);
    });
  });

  group('on Home', () {
    testWidgets('shows both swatches and names without role captions', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 7),
      );
      rig.dailyBriefProvider.response = engine.DailyBrief(
        luckyNumber: 4,
        colors: testDailyColors(),
        energy: const engine.DailyEnergy(
          level: 'steady',
          index: 51,
          dataCoverage: 1,
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await tester.pump();

      expect(find.text('Your colors today:'), findsOneWidget);
      expect(find.byKey(const Key('daily_color_lead')), findsOneWidget);
      expect(find.byKey(const Key('daily_color_supporting')), findsOneWidget);
      expect(find.text('Ocean Blue'), findsOneWidget);
      expect(find.text('Cedar'), findsOneWidget);
      expect(find.text('Lead'), findsNothing);
      expect(find.text('Supporting'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a 360dp phone with both swatches', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 640));
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 7),
      );
      rig.dailyBriefProvider.response = engine.DailyBrief(
        luckyNumber: 4,
        // The longest names in the palette.
        colors: testDailyColors(
          leadName: 'Solar Coral',
          supportingName: 'Champagne',
          supportingHex: '#E4D5B5',
        ),
        energy: const engine.DailyEnergy(
          level: 'steady',
          index: 51,
          dataCoverage: 1,
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await tester.pump();

      expect(tester.takeException(), isNull);
      final card = tester.getRect(
        find.byKey(const Key('daily_signals_content')),
      );
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(360));
      final lead = tester.getRect(find.byKey(const Key('daily_color_lead')));
      final supporting = tester.getRect(
        find.byKey(const Key('daily_color_supporting')),
      );
      expect((lead.top - supporting.top).abs(), lessThan(2));
      expect(lead.right, lessThan(supporting.left));
    });
  });

  group('percentages read to one decimal', () {
    testWidgets('a result shows one decimal and the pair sums to 100.0', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();

      expect(find.text('56.0%'), findsOneWidget);
      expect(find.text('NO  44.0%'), findsOneWidget);
      // Never a bare integer percentage on the headline split.
      expect(find.text('56%'), findsNothing);
      expect(find.text('NO  44%'), findsNothing);
      final winner = tester.widget<Text>(
        find.byKey(const Key('result_winner_label')),
      );
      final heading = tester.widget<Text>(
        find.byKey(const Key('result_direction_heading')),
      );
      final percent = tester.widget<Text>(find.text('56.0%'));
      expect(heading.style!.fontSize, lessThanOrEqualTo(18));
      expect(winner.style!.fontSize, 114);
      expect(winner.style!.fontSize, greaterThan(percent.style!.fontSize!));
      expect(winner.style!.color, CompassColors.blueLight);
    });

    test('the DTO keeps tenths so the pair is exact', () {
      final response = fixtureResponse('ready_yes_no_now.json');
      final percentages = response.percentages!;
      expect(percentages.tenths.values.reduce((a, b) => a + b), 1000);
      expect(percentages['YES'], 56.0);
      expect(percentages.display('YES'), '56.0');
      expect(percentages.display('NO'), '44.0');
      expect(percentages.display('MAYBE'), isNull);
    });
  });
}
