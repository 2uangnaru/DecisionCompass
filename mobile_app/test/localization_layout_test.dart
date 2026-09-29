import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/history_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/widgets/responsible_use_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// Every screen, in every language, on a narrow Android phone at the text
/// scales the accessibility settings actually reach.
///
/// These load the **real bundled fonts** rather than the placeholder the test
/// framework normally substitutes, so the measurements are the fonts' own
/// metrics: Thai marks, Devanagari conjuncts, kana and Han all occupy the
/// widths and heights they will occupy on a device. What this still cannot
/// establish is what the pixels look like — whether a tone mark collides with
/// a descender is a question for a screen, and is called out in the report.
void main() {
  setUpAll(loadBundledFonts);

  final profile = AppProfile(
    userName: 'Alex',
    birthDate: DateTime(1998, 6, 21),
    birthCountryCode: 'US',
    zodiacSign: ZodiacSign.cancer,
    useCurrentLocation: false,
    safetyAcknowledged: true,
  );

  /// A 360dp phone, the narrowest Android layout the product targets.
  const narrow = Size(360, 640);

  /// Anything left unconsumed here is a real layout failure — an overflow, a
  /// missing glyph assert — except the framework's own note that
  /// `CountryLocalizations` does not cover every locale, which is deliberate.
  void expectNoLayoutTrouble(WidgetTester tester, String where) {
    final thrown = tester.takeException();
    if (thrown == null) return;
    if ('$thrown'.contains('is not supported by all of its localization')) {
      return;
    }
    fail('$where: $thrown');
  }

  Future<void> sized(
    WidgetTester tester,
    double scale,
    Future<void> Function() body,
  ) async {
    useScreen(tester, size: narrow, textScale: scale);
    await body();
  }

  for (final locale in AppLocale.values) {
    for (final scale in const [1.0, 1.3, 1.5]) {
      final at = '${locale.tag} at ${narrow.width.toInt()}dp × $scale';

      testWidgets('the welcome and profile steps hold together, $at', (
        tester,
      ) async {
        await sized(tester, scale, () async {
          final rig = ReadingTestRig(locale: locale);
          await tester.pumpWidget(rig.app);
          await tester.pump();
          expectNoLayoutTrouble(tester, 'welcome $at');

          // The language control stays reachable and readable.
          expect(find.byKey(const Key('language_button')), findsOneWidget);
          expect(
            tester.getSize(find.byKey(const Key('language_button'))).height,
            greaterThanOrEqualTo(48),
            reason: 'language control below the 48dp target, $at',
          );

          await tester.tap(find.byKey(const Key('continue_to_profile')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expectNoLayoutTrouble(tester, 'profile $at');
        });
      });

      testWidgets('Home holds together, $at', (tester) async {
        await sized(tester, scale, () async {
          final rig = ReadingTestRig(
            locale: locale,
            response: fixtureResponse('ready_yes_no_now.json'),
          );
          rig.dailyBriefProvider.response = engine.DailyBrief(
            luckyNumber: 7,
            colors: testDailyColors(),
            energy: const engine.DailyEnergy(
              level: 'radiant',
              index: 71,
              dataCoverage: 1,
            ),
          );
          await tester.pumpWidget(rig.app);
          await completeOnboarding(tester);
          await tester.pump();
          expectNoLayoutTrouble(tester, 'Home $at');

          // The category chips wrap rather than spilling off a 360dp screen.
          for (final key in const [
            'category_general',
            'category_love',
            'category_money',
          ]) {
            final chip = find.byKey(Key(key));
            await tester.ensureVisible(chip);
            expect(
              tester.getSize(chip).width,
              lessThanOrEqualTo(narrow.width),
              reason: '$key is wider than the screen, $at',
            );
          }
          expectNoLayoutTrouble(tester, 'Home chips $at');
        });
      });

      testWidgets('the Reveal screen holds together, $at', (tester) async {
        await sized(tester, scale, () async {
          final rig = ReadingTestRig(
            response: fixtureResponse('ready_yes_no_now.json'),
          );
          await tester.pumpWidget(
            localizedApp(
              locale: locale,
              home: RitualPage(
                mode: DecisionMode.keepLetGo,
                period: TimePeriod.now,
                category: engine.ReadingCategory.study,
                profile: profile,
                dependencies: rig.dependencies,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expectNoLayoutTrouble(tester, 'Reveal $at');

          // All five period chips are still offered and still tappable.
          for (final period in TimePeriod.values) {
            expect(
              find.byKey(Key('ritual_period_${period.name}')),
              findsOneWidget,
              reason: '${period.name} chip is missing, $at',
            );
          }
          // The responsible-use note is never cut short.
          final note = tester.widget<Text>(
            find.byKey(const Key('ritual_responsible_use_note')),
          );
          expect(note.maxLines, isNull, reason: 'safety note clamped, $at');
          expect(note.overflow, isNot(TextOverflow.ellipsis));
        });
      });

      testWidgets('the Result screen holds together, $at', (tester) async {
        await sized(tester, scale, () async {
          final rig = ReadingTestRig();
          await tester.pumpWidget(
            localizedApp(
              locale: locale,
              home: ResultPage(
                reading: fixtureResponse(
                  'ready_forward_backward_two_windows.json',
                ),
                dependencies: rig.dependencies,
                autoSave: false,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expectNoLayoutTrouble(tester, 'Result $at');

          // The winning choice stays the dominant element, whatever the
          // language does to its length.
          final winner = tester.getSize(
            find.byKey(const Key('result_winner_box')),
          );
          final percent = tester.getSize(
            find.byKey(const Key('result_winner_percent')),
          );
          expect(
            winner.height,
            greaterThan(percent.height),
            reason: 'the percentage outgrew its choice, $at',
          );
          // Shrink-to-fit must not shrink it into illegibility.
          expect(
            winner.height,
            greaterThanOrEqualTo(28),
            reason: 'the winning choice rendered ${winner.height}dp tall, $at',
          );
          expect(
            winner.width,
            lessThanOrEqualTo(narrow.width),
            reason: 'the winning choice is wider than the screen, $at',
          );

          final caveat = find.byKey(const Key('result_lucky_times_caveat'));
          await tester.ensureVisible(caveat);
          expect(tester.widget<Text>(caveat).maxLines, isNull);
          expectNoLayoutTrouble(tester, 'Result caveats $at');
        });
      });

      testWidgets('the safety sheet holds together, $at', (tester) async {
        await sized(tester, scale, () async {
          await tester.pumpWidget(
            localizedApp(
              locale: locale,
              home: const Scaffold(body: ResponsibleUseSheet()),
            ),
          );
          await tester.pumpAndSettle();
          expectNoLayoutTrouble(tester, 'safety sheet $at');

          // Every word of it has to be reachable: a boundary the reader
          // cannot finish reading is not a boundary. Nothing is clamped, and
          // nothing is ellipsised.
          for (final text in tester.widgetList<Text>(find.byType(Text))) {
            expect(
              text.maxLines,
              isNull,
              reason: 'safety copy clamped to ${text.maxLines} lines, $at',
            );
            expect(
              text.overflow,
              isNot(TextOverflow.ellipsis),
              reason: 'safety copy ellipsised, $at',
            );
          }
          expect(find.byKey(const Key('important_limits')), findsOneWidget);
          expect(find.byKey(const Key('crisis_support')), findsOneWidget);
        });
      });

      testWidgets('History holds together, $at', (tester) async {
        await sized(tester, scale, () async {
          final rig = ReadingTestRig();
          await rig.historyRepository.save(
            historyEntryFor(fixtureResponse('ready_love_evening.json')),
          );
          await tester.pumpWidget(
            localizedApp(
              locale: locale,
              home: HistoryPage(dependencies: rig.dependencies),
            ),
          );
          await tester.pumpAndSettle();
          expectNoLayoutTrouble(tester, 'History $at');
          expect(find.byKey(const Key('history_list')), findsOneWidget);
        });
      });
    }
  }
}
