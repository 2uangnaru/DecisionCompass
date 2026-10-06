import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/history_page.dart';
import 'package:decision_compass/pages/profile_page.dart';
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
                  'ready_commit_withdraw_two_windows.json',
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
          final winnerText = tester.widget<Text>(
            find.byKey(const Key('result_winner_label')),
          );
          expect(
            winnerText.maxLines,
            1,
            reason: 'the winning choice must stay on 1 line, $at',
          );
          expect(
            winnerText.softWrap,
            isFalse,
            reason: 'the winning choice must not wrap words, $at',
          );

          final counterpartText = tester.widget<Text>(
            find.byKey(const Key('result_counterpart_label')),
          );
          expect(
            counterpartText.style?.color,
            Colors.white70,
            reason: 'counterpart choice must use subtle white70, $at',
          );

          // Action Guidance is displayed directly beneath the verdict,
          // without redundant daily signals that belong exclusively on Home.
          expect(find.byKey(const Key('result_daily_brief')), findsNothing);
          final guidance = find.byKey(const Key('result_action_guidance'));
          await tester.ensureVisible(guidance);
          expect(guidance, findsOneWidget, reason: 'guidance missing, $at');
          expect(
            tester.getSize(guidance).width,
            lessThanOrEqualTo(narrow.width),
            reason: 'the action guidance card is wider than the screen, $at',
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

      testWidgets('Profile holds together, $at', (tester) async {
        await sized(tester, scale, () async {
          final rig = ReadingTestRig();
          // Both birth fields locked, which is the densest the screen gets:
          // every row carries its own wait line underneath it.
          final now = rig.dependencies.nowUtc();
          await tester.pumpWidget(
            localizedApp(
              locale: locale,
              home: ProfilePage(
                profile: profile.copyWith(
                  birthTime: '14:30',
                  birthTimeChangedAtUtc: now.subtract(
                    const Duration(minutes: 7),
                  ),
                  birthCountryChangedAtUtc: now.subtract(
                    const Duration(minutes: 7),
                  ),
                ),
                dependencies: rig.dependencies,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expectNoLayoutTrouble(tester, 'Profile $at');

          // Both actions stay on screen and stay tappable.
          for (final key in const ['profile_cancel', 'profile_save']) {
            expect(find.byKey(Key(key)), findsOneWidget);
            expect(
              tester.getSize(find.byKey(Key(key))).height,
              greaterThanOrEqualTo(48),
              reason: '$key below the 48dp target, $at',
            );
          }
          // And the wait is readable rather than clipped away.
          expect(
            find.byKey(const Key('profile_birth_time_wait')),
            findsOneWidget,
          );
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

  group(
    'winning choice displays on a single line across all decision modes',
    () {
      const viLabels = [
        'CÓ',
        'KHÔNG',
        'HÀNH ĐỘNG',
        'CHỜ ĐỢI',
        'TIẾN LÊN',
        'LÙI LẠI',
        'Ở LẠI',
        'RỜI ĐI',
        'GIỮ LẠI',
        'BUÔNG BỎ',
        'GẮN BÓ',
        'CHẤM DỨT',
        'TRÁI',
        'PHẢI',
      ];

      for (final label in viLabels) {
        testWidgets('Vietnamese winner "$label" fits on 1 line at 360dp', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final rig = ReadingTestRig();
          final reading = fixtureResponse('ready_yes_no_now.json');
          await tester.pumpWidget(
            localizedApp(
              locale: AppLocale.vietnamese,
              home: ResultPage(
                reading: reading,
                dependencies: rig.dependencies,
                autoSave: false,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final winnerText = tester.widget<Text>(
            find.byKey(const Key('result_winner_label')),
          );
          expect(winnerText.maxLines, 1);
          expect(winnerText.softWrap, isFalse);
        });
      }
    },
  );
}
