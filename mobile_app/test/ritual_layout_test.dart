import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// The Reveal screen's vertical composition, mounted on its own.
///
/// Onboarding overflows at larger text scales — a pre-existing problem on that
/// screen — so these mount `RitualPage` directly rather than walking through
/// it. That keeps the assertions about this screen and nothing else.
void main() {
  final profile = AppProfile(
    userName: 'Alex',
    birthDate: DateTime(1998, 6, 21),
    birthCountryCode: 'US',
    zodiacSign: ZodiacSign.cancer,
    useCurrentLocation: false,
    safetyAcknowledged: true,
  );

  Future<void> pumpRitual(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCompassTheme(),
        home: RitualPage(
          mode: DecisionMode.yesNo,
          period: TimePeriod.now,
          category: engine.ReadingCategory.general,
          profile: profile,
          dependencies: rig.dependencies,
        ),
      ),
    );
    // The reveal circle breathes forever, so this steps rather than settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  const sizes = <Size>[Size(360, 640), Size(393, 873), Size(505, 897)];

  for (final size in sizes) {
    for (final scale in <double>[1.0, 1.3]) {
      testWidgets('holds together at $size at text scale $scale', (
        tester,
      ) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpRitual(tester, size: size, textScale: scale);

        expect(tester.takeException(), isNull, reason: 'at $size / $scale');

        // Every part of the hierarchy is present, and the footer that only
        // repeated the badge and the chips is gone.
        expect(find.byKey(const Key('ritual_category_badge')), findsOneWidget);
        expect(find.byKey(const Key('ritual_period_selector')), findsOneWidget);
        expect(find.byKey(const Key('reveal_button')), findsOneWidget);
        expect(
          find.byKey(const Key('ritual_responsible_use_note')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('ritual_reading_summary')), findsNothing);
      });
    }
  }

  testWidgets('the circle is not marooned behind a large empty gap', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    // The tall screen the gap was worst on.
    const size = Size(505, 897);
    await pumpRitual(tester, size: size);

    final chips = tester.getRect(
      find.byKey(const Key('ritual_period_selector')),
    );
    final circle = tester.getRect(find.byKey(const Key('reveal_button')));
    final title = tester.getRect(find.byKey(const Key('ritual_ready_title')));
    final note = tester.getRect(
      find.byKey(const Key('ritual_responsible_use_note')),
    );

    expect(circle.top, greaterThan(chips.bottom));
    // A tall screen must not put a large empty band between chips and Reveal.
    final above = circle.top - chips.bottom;
    expect(
      above,
      lessThanOrEqualTo(56),
      reason: 'the gap before the circle is ${above.toStringAsFixed(0)}dp',
    );
    // Order is what it claims to be, top to bottom.
    expect(circle.bottom, lessThan(note.top));
    expect(
      title.top - circle.bottom,
      lessThanOrEqualTo(32),
      reason: 'Reveal and its instruction must stay together',
    );
    expect(
      note.top - title.bottom,
      lessThan(65),
      reason: 'supporting copy must remain in the hero group',
    );
    expect(note.bottom, lessThanOrEqualTo(size.height));
    // And the circle stays inside the screen.
    expect(circle.left, greaterThanOrEqualTo(0));
    expect(circle.right, lessThanOrEqualTo(size.width));
  });

  testWidgets('the circle grows with the screen rather than jumping', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final widths = <double>[];
    for (final size in sizes) {
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpRitual(tester, size: size);
      widths.add(tester.getRect(find.byKey(const Key('reveal_button'))).width);
    }
    // Sized from the space available, so a taller screen never gets a smaller
    // control.
    for (var i = 1; i < widths.length; i++) {
      expect(widths[i], greaterThanOrEqualTo(widths[i - 1]));
    }
    expect(widths.first, greaterThan(100));
    expect(widths.last, lessThanOrEqualTo(230));
  });

  testWidgets('it scrolls rather than overflowing when it cannot fit', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpRitual(tester, size: const Size(320, 480), textScale: 1.3);

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    // Everything remains reachable.
    await tester.ensureVisible(
      find.byKey(const Key('ritual_responsible_use_note')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the disclaimer is readable, not fine print', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpRitual(tester, size: const Size(393, 873));

    final note = tester.widget<Text>(
      find.byKey(const Key('ritual_responsible_use_note')),
    );
    expect(note.style!.fontSize, greaterThanOrEqualTo(12));
    expect(note.data, contains('everyday reflection only'));
    expect(note.data, contains('Never for medical'));
  });

  testWidgets('one tap still reveals, and NOW is still the default', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpRitual(tester, size: const Size(393, 873));

    final now = tester.widget<ChoiceChip>(
      find.byKey(const Key('ritual_period_now')),
    );
    expect(now.selected, isTrue);

    await tester.tap(find.byKey(const Key('reveal_button')));
    await tester.pump(const Duration(milliseconds: 380));
    await tester.pump();
    // The single tap moved the flow on to loading.
    expect(find.byKey(const Key('loading_tap_surface')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 5400));
    await tester.pumpAndSettle();
  });
}
