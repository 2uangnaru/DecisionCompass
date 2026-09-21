import 'package:decision_compass/app.dart';
import 'package:decision_compass/mock_reading_engine.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/widgets/celestial_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('zodiac avatar follows the entered birth date', () {
    expect(zodiacForDate(DateTime(2000, 3, 21)), ZodiacSign.aries);
    expect(zodiacForDate(DateTime(2000, 6, 21)), ZodiacSign.cancer);
    expect(zodiacForDate(DateTime(2000, 12, 22)), ZodiacSign.capricorn);
    expect(zodiacForDate(DateTime(2000, 2, 19)), ZodiacSign.pisces);
    expect(ZodiacSign.aries.assetPath, 'assets/zodiac/zodiac_01_aries.png');
  });

  testWidgets('zodiac avatar renders the artwork for the selected sign', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ZodiacAvatar(sign: ZodiacSign.capricorn)),
      ),
    );

    expect(find.byKey(const Key('zodiac_avatar_capricorn')), findsOneWidget);
    final image = tester.widget<Image>(
      find.byKey(const Key('zodiac_avatar_capricorn')),
    );
    expect(
      (image.image as AssetImage).assetName,
      'assets/zodiac/zodiac_10_capricorn.png',
    );
  });

  test('mock result always produces complementary percentages', () {
    for (final mode in DecisionMode.values) {
      final result = createMockReading(mode, TimePeriod.evening);
      expect(result.winnerPercent + result.counterpartPercent, 100);
      expect(result.windows, hasLength(2));
    }
  });

  testWidgets('onboarding reaches Home', (tester) async {
    await tester.pumpWidget(const DecisionCompassApp());
    expect(find.text('Read the moment\nwhere you are.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('allow_location')));
    await tester.pumpAndSettle();
    expect(find.text('Build your personal pattern.'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pumpAndSettle();
    expect(find.text('A choice is on your mind.'), findsOneWidget);
    expect(find.text('Find My Direction'), findsOneWidget);
  });

  testWidgets('double tap during loading shows reassurance then result', (
    tester,
  ) async {
    await tester.pumpWidget(const DecisionCompassApp());
    await tester.tap(find.byKey(const Key('allow_location')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('find_direction')));
    await tester.tap(find.byKey(const Key('find_direction')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const Key('reveal_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reveal_button')));
    await tester.pump(const Duration(milliseconds: 380));
    await tester.pump();
    expect(find.byKey(const Key('loading_tap_surface')), findsOneWidget);

    await tester.tap(find.byKey(const Key('loading_tap_surface')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('loading_tap_surface')));
    await tester.pump();
    expect(
      find.text(
        'Give me a moment — I’m still bringing your cosmic signals into focus.',
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('YOUR DIRECTION'), findsOneWidget);
    expect(find.text('YES'), findsOneWidget);
    expect(find.text('64%'), findsOneWidget);
  });

  testWidgets('core flow renders on common Android window sizes', (
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
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const DecisionCompassApp());
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Failed at $size');
      expect(find.text('Read the moment\nwhere you are.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('allow_location')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('complete_profile')));
      await tester.tap(find.byKey(const Key('complete_profile')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('find_direction')));
      expect(tester.takeException(), isNull, reason: 'Home failed at $size');

      await tester.tap(find.byKey(const Key('find_direction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull, reason: 'Ritual failed at $size');

      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Loading failed at $size');

      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: 'Result failed at $size');
      expect(find.text('YOUR DIRECTION'), findsOneWidget);
    }
  });
}
