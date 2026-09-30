import 'dart:convert';
import 'dart:io';

import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/daily_energy_messages.dart';
import 'package:decision_compass/data/in_memory_daily_energy_insight_store.dart';
import 'package:decision_compass/data/in_memory_home_description_store.dart';
import 'package:decision_compass/data/locale_controller.dart';
import 'package:decision_compass/data/locale_store.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/home_descriptions.dart';
import 'package:decision_compass/localized_presentation.dart';
import 'package:decision_compass/localized_rotation.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/history_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// One locale's ARB file, straight off disk.
Map<String, dynamic> arb(String name) =>
    jsonDecode(File('lib/l10n/app_$name.arb').readAsStringSync())
        as Map<String, dynamic>;

Map<String, String> messages(String name) => {
  for (final entry in arb(name).entries)
    if (!entry.key.startsWith('@')) entry.key: entry.value as String,
};

/// The description Home is currently showing.
String? shownDescription(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('home_description'))).data;

Future<void> openHome(WidgetTester tester, ReadingTestRig rig) async {
  await tester.pumpWidget(rig.app);
  await completeOnboarding(tester);
  await tester.pump(); // let the daily-brief future settle
}

/// The tone Home is given in these tests, named once.
const testEnergyLevel = 'steady';

engine.DailyBrief briefWith(String level) => engine.DailyBrief(
  luckyNumber: 4,
  colors: testDailyColors(),
  energy: engine.DailyEnergy(level: level, index: 51, dataCoverage: 1),
);

void main() {
  const productLocales = ['en', 'vi', 'ja', 'es', 'th', 'hi_IN', 'zh_Hans_CN'];

  group('the content pack', () {
    test('every product locale has a file, with its own locale tag', () {
      for (final name in productLocales) {
        expect(
          File('lib/l10n/app_$name.arb').existsSync(),
          isTrue,
          reason: 'app_$name.arb is missing',
        );
        expect(arb(name)['@@locale'], name);
      }
    });

    test('the editorial keys are identical across all seven', () {
      final english = messages('en');
      final translated = messages('vi').keys.toSet();
      expect(translated, english.keys.toSet());
      for (final name in productLocales.skip(1)) {
        expect(
          messages(name).keys.toSet(),
          translated,
          reason: '$name has a different key set',
        );
      }
    });

    test('no value is blank, and only approved terms repeat English', () {
      final english = messages('en');
      for (final name in productLocales.skip(1)) {
        final locale = messages(name);
        for (final entry in locale.entries) {
          expect(
            entry.value.trim(),
            isNotEmpty,
            reason: '$name.${entry.key} is blank',
          );
        }
        final untouched = locale.entries
            .where((e) => e.value == english[e.key])
            .map((e) => e.key)
            .toSet();
        // These Spanish words and proper names are spelled identically in
        // both languages. Keep the allowlist explicit so newly untranslated
        // copy cannot hide behind a count threshold.
        const spanishCoincidences = {
          'choiceNo',
          'colorJade',
          'orbitBaZi',
          'orbitYinYang',
          'orbitZiWei',
          'zodiacAries',
          'zodiacLeo',
          'zodiacLibra',
          'zodiacVirgo',
        };
        expect(
          untouched,
          name == 'es' ? {'appName', ...spanishCoincidences} : {'appName'},
          reason: '$name repeats English for $untouched',
        );
      }
    });

    test('placeholders survive every translation', () {
      final braces = RegExp(r'\{(\w+)\}');
      final english = messages('en');
      for (final name in productLocales) {
        final locale = messages(name);
        for (final entry in locale.entries) {
          expect(
            braces.allMatches(entry.value).map((m) => m.group(1)).toSet(),
            braces
                .allMatches(english[entry.key]!)
                .map((m) => m.group(1))
                .toSet(),
            reason: '$name.${entry.key} lost or invented a placeholder',
          );
        }
      }
    });

    test('the base-language files are exact copies of their parent', () {
      // gen_l10n insists a script/country locale has a base-language file to
      // fall back to. They must not drift into a second, different Hindi.
      for (final pair in const [
        ('hi_IN', ['hi']),
        ('zh_Hans_CN', ['zh', 'zh_Hans']),
      ]) {
        final parent = messages(pair.$1);
        for (final alias in pair.$2) {
          expect(messages(alias), parent, reason: 'app_$alias.arb has drifted');
        }
      }
    });

    test('the rotating banks are complete in every locale', () {
      for (final name in productLocales) {
        final locale = messages(name);
        for (var i = 0; i < homeDescriptions.length; i++) {
          expect(
            locale['homeDescription${i.toString().padLeft(2, '0')}'],
            isNotNull,
            reason: '$name is missing home description $i',
          );
        }
        for (final level in dailyEnergyMessagePools.keys) {
          final prefix = 'energy${level[0].toUpperCase()}${level.substring(1)}';
          for (var i = 0; i < dailyEnergyPoolSize; i++) {
            expect(
              locale['$prefix${i.toString().padLeft(2, '0')}'],
              isNotNull,
              reason: '$name is missing $level insight $i',
            );
          }
        }
      }
    });

    test('the English rotation still says what it always said', () {
      // An install that has already been dealt index 7 must read the same
      // sentence after this change as before it.
      final english = stringsFor(AppLocale.english);
      for (var i = 0; i < homeDescriptions.length; i++) {
        expect(homeDescriptionAt(english, i), homeDescriptions[i]);
      }
      for (final entry in dailyEnergyMessagePools.entries) {
        for (var i = 0; i < entry.value.length; i++) {
          expect(
            dailyEnergyInsightAt(english, entry.key, i),
            entry.value[i],
            reason: '${entry.key} insight $i changed',
          );
        }
      }
    });

    test('a tone this build does not know resolves to nothing', () {
      final english = stringsFor(AppLocale.english);
      expect(dailyEnergyInsightAt(english, 'unavailable', 0), isNull);
      expect(dailyEnergyInsightAt(english, 'sparkling', 0), isNull);
    });
  });

  group('the safety copy', () {
    test('carries no country-specific emergency number, in any locale', () {
      // A number that is right in one country is dangerously wrong in
      // another, and this copy is shown in seven languages.
      final digits = RegExp(r'\b\d{3,4}\b');
      for (final name in productLocales) {
        for (final entry in messages(name).entries) {
          if (!entry.key.startsWith('safety') &&
              !entry.key.startsWith('crisis') &&
              !entry.key.startsWith('importantLimits')) {
            continue;
          }
          expect(
            digits.hasMatch(entry.value),
            isFalse,
            reason: '$name.${entry.key} contains what looks like a number',
          );
        }
      }
    });

    test('drops the old age and liability claims everywhere', () {
      for (final name in productLocales) {
        final locale = messages(name);
        // "100%" survives only where it means "these do not add up to 100%",
        // which is a caveat about the numbers rather than a liability claim.
        final safety = locale.entries
            .where(
              (e) =>
                  e.key.startsWith('safety') ||
                  e.key.startsWith('importantLimits') ||
                  e.key.startsWith('crisis') ||
                  e.key.endsWith('Detail') ||
                  e.key.endsWith('Title'),
            )
            .map((e) => e.value)
            .join(' ');
        expect(safety, isNot(contains('100%')), reason: name);
        expect(
          locale.values.join(' ').toLowerCase(),
          isNot(contains('at least 13')),
          reason: name,
        );
        expect(
          locale.values.join(' '),
          isNot(contains('Assumption of Risk')),
          reason: name,
        );
      }
    });

    test('still names every boundary the sheet shows', () {
      for (final locale in AppLocale.values) {
        final l10n = stringsFor(locale);
        for (final value in [
          l10n.harmTitle,
          l10n.harmDetail,
          l10n.navigationTitle,
          l10n.navigationDetail,
          l10n.politicsTitle,
          l10n.medicalTitle,
          l10n.legalTitle,
          l10n.financeTitle,
          l10n.consentTitle,
          l10n.importantLimitsHeading,
          l10n.importantLimitsBody,
          l10n.crisisSupport,
          l10n.acknowledge,
        ]) {
          expect(value.trim(), isNotEmpty, reason: locale.tag);
        }
      }
    });
  });

  group('presentation keys', () {
    test('every category, mode, period, tone and shade has a name', () {
      for (final locale in AppLocale.values) {
        final l10n = stringsFor(locale);
        for (final category in engine.ReadingCategory.values) {
          expect(categoryLabel(l10n, category).trim(), isNotEmpty);
        }
        for (final mode in DecisionMode.values) {
          expect(modeFirstLabel(l10n, mode).trim(), isNotEmpty);
          expect(modeSecondLabel(l10n, mode).trim(), isNotEmpty);
          expect(modeLoadingPhrase(l10n, mode).trim(), isNotEmpty);
        }
        for (final period in TimePeriod.values) {
          expect(periodLabel(l10n, period).trim(), isNotEmpty);
        }
        for (final level in dailyEnergyMessagePools.keys) {
          expect(energyLevelLabel(l10n, level)?.trim(), isNotEmpty);
        }
        expect(energyLevelLabel(l10n, 'unavailable'), isNull);
        expect(energyLevelLabel(l10n, null), isNull);
        for (final sign in ZodiacSign.values) {
          expect(zodiacLabel(l10n, sign).trim(), isNotEmpty);
        }
        expect(loadingPhrases(l10n, DecisionMode.yesNo), hasLength(7));
        expect(welcomeOrbitLabels(l10n), hasLength(4));
        expect(loadingOrbitLabels(l10n), hasLength(8));
      }
    });

    test('all twenty shade keys have an editorial name in every locale', () {
      const keys = [
        'cedar',
        'jade',
        'sage',
        'mint',
        'ember',
        'solar_coral',
        'rose',
        'blossom',
        'ochre',
        'amber',
        'sand',
        'clay',
        'silver',
        'steel',
        'pearl',
        'champagne',
        'ocean_blue',
        'azure',
        'indigo',
        'mist_blue',
      ];
      for (final locale in AppLocale.values) {
        final l10n = stringsFor(locale);
        final named = <String>{};
        for (final key in keys) {
          final colour = engine.DailyColor(
            key: key,
            // The engine's own English name, which must never be what shows.
            name: 'ENGINE_NAME',
            hex: '#112233',
            element: 'water',
            stem: 8,
          );
          final name = dailyColorName(l10n, colour);
          expect(name, isNot('ENGINE_NAME'), reason: '$key in ${locale.tag}');
          named.add(name);
        }
        expect(named, hasLength(keys.length), reason: locale.tag);
      }
    });

    test('a shade key this build does not know keeps the engine name', () {
      const colour = engine.DailyColor(
        key: 'mulberry',
        name: 'Mulberry',
        hex: '#112233',
        element: 'water',
        stem: 8,
      );
      expect(dailyColorName(stringsFor(AppLocale.thai), colour), 'Mulberry');
    });

    test('the engine winner token translates by the side it names', () {
      for (final locale in AppLocale.values) {
        final l10n = stringsFor(locale);
        for (final mode in DecisionMode.values) {
          final pair = englishChoiceLabels[mode]!;
          expect(
            localizedChoice(l10n, mode, pair.first),
            modeFirstLabel(l10n, mode),
          );
          expect(
            localizedChoice(l10n, mode, pair.second),
            modeSecondLabel(l10n, mode),
          );
          // A token from another build is shown as sent, not guessed at.
          expect(localizedChoice(l10n, mode, 'MAYBE'), 'MAYBE');
        }
      }
    });

    test(
      'each period has one complete luckiest-times heading, and NOW none',
      () {
        for (final locale in AppLocale.values) {
          final l10n = stringsFor(locale);
          expect(luckyTimesHeading(l10n, TimePeriod.now), isNull);
          final headings = <String>{};
          for (final period in TimePeriod.values.skip(1)) {
            final heading = luckyTimesHeading(l10n, period)!;
            expect(heading.trim(), isNotEmpty);
            // A complete sentence, not a frame with a chip label dropped in.
            expect(heading, isNot(contains('{')));
            headings.add(heading);
          }
          expect(headings, hasLength(4), reason: locale.tag);
        }
      },
    );

    test('letter spacing is dropped for the scripts that do not take it', () {
      // Checked through the enum rather than a widget, so it stays true for
      // every call site at once.
      for (final locale in AppLocale.values) {
        final wide = const {
          AppLocale.english,
          AppLocale.vietnamese,
          AppLocale.spanish,
        }.contains(locale);
        expect(_tracking(locale, 2.4), wide ? 2.4 : 0, reason: locale.tag);
      }
    });
  });

  group('numbers', () {
    test('a score keeps its value and takes the local separator', () {
      expect(formatScore(AppLocale.english.intlName, 56.0), '56.0');
      expect(formatScore(AppLocale.spanish.intlName, 56.0), '56,0');
      expect(formatScore(AppLocale.vietnamese.intlName, 56.0), '56,0');
      expect(formatScore(AppLocale.japanese.intlName, 56.0), '56.0');
    });

    test('the two sides still read as adding to 100.0 in every locale', () {
      final percentages = engine.ReadingPercentages({'YES': 522, 'NO': 478});
      for (final locale in AppLocale.values) {
        final values = percentages.values.values.toList();
        expect(values.reduce((a, b) => a + b), 100.0, reason: locale.tag);
        for (final value in values) {
          // Only the separator may differ; the digits never do.
          final formatted = formatScore(locale.intlName, value);
          expect(
            formatted.replaceAll(',', '.'),
            value.toStringAsFixed(1),
            reason: locale.tag,
          );
        }
      }
    });
  });

  group('the language selector', () {
    testWidgets('the welcome screen offers it without opening anything', (
      tester,
    ) async {
      final rig = ReadingTestRig();
      await tester.pumpWidget(rig.app);
      await tester.pump();

      expect(find.byKey(const Key('language_button')), findsOneWidget);
      expect(
        find.text(rig.strings.onboardingLanguageHint),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('language_button_label')))
            .data,
        AppLocale.english.nativeName,
      );
      // No unsolicited startup popup, and no extra required screen.
      expect(find.byKey(const Key('language_sheet')), findsNothing);
      expect(find.byKey(const Key('continue_to_profile')), findsOneWidget);
    });

    testWidgets('the sheet lists all seven, each in its own script', (
      tester,
    ) async {
      final rig = ReadingTestRig();
      await tester.pumpWidget(rig.app);
      await tester.pump();
      await openLanguageSheet(tester);
      allowCountryNameGap(tester);

      expect(find.byKey(const Key('language_sheet')), findsOneWidget);
      for (final locale in AppLocale.values) {
        expect(
          find.byKey(Key('language_option_${locale.tag}')),
          findsOneWidget,
          reason: '${locale.tag} is missing from the sheet',
        );
        expect(find.text(locale.nativeName), findsWidgets);
      }
    });

    testWidgets('choosing one re-renders the welcome screen at once', (
      tester,
    ) async {
      final rig = ReadingTestRig();
      await tester.pumpWidget(rig.app);
      await tester.pump();
      expect(find.text(rig.strings.onboardingTitle), findsOneWidget);

      await switchLanguage(tester, AppLocale.thai);

      final thai = stringsFor(AppLocale.thai);
      expect(find.text(thai.onboardingTitle), findsOneWidget);
      expect(find.text(thai.onboardingLanguageHint), findsOneWidget);
      expect(
        find.text(rig.strings.onboardingLanguageHint),
        findsNothing,
      );
      expect(find.text(thai.continueAction), findsOneWidget);
      expect(find.text(rig.strings.onboardingTitle), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('language_button_label')))
            .data,
        AppLocale.thai.nativeName,
      );
    });

    testWidgets('and the rest of onboarding follows it', (tester) async {
      final rig = ReadingTestRig();
      await tester.pumpWidget(rig.app);
      await tester.pump();
      await switchLanguage(tester, AppLocale.japanese);

      final ja = stringsFor(AppLocale.japanese);
      await tester.tap(find.byKey(const Key('continue_to_profile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(ja.yourProfile), findsOneWidget);
      expect(find.text(ja.buildPattern), findsOneWidget);
      expect(find.text(ja.selectBirthDate), findsOneWidget);
      expect(find.text(ja.createCompass), findsOneWidget);
      // Nothing from the previous language is left behind on the screen.
      expect(
        find.text(stringsFor(AppLocale.english).yourProfile),
        findsNothing,
      );
    });

    testWidgets('the date picker follows it too', (tester) async {
      final rig = ReadingTestRig();
      await tester.pumpWidget(rig.app);
      await tester.pump();
      await switchLanguage(tester, AppLocale.spanish);
      await tester.tap(find.byKey(const Key('continue_to_profile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(find.byKey(const Key('birth_date_value')));
      await tester.tap(find.byKey(const Key('birth_date_value')));
      await tester.pumpAndSettle();

      final material = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      expect(material.cancelButtonLabel, 'Cancelar');
      expect(find.text(material.cancelButtonLabel), findsOneWidget);
    });

    testWidgets('the choice is stored before a profile exists', (tester) async {
      final rig = ReadingTestRig();
      await tester.pumpWidget(rig.app);
      await tester.pump();
      await switchLanguage(tester, AppLocale.hindi);

      expect(rig.localeStore.tag, AppLocale.hindi.tag);
      // The language is remembered before a profile is even created.
      expect(await rig.profileRepository.load(), isNull);
    });

    testWidgets('a restart comes back in the chosen language', (tester) async {
      final store = InMemoryLocaleStore();
      final first = ReadingTestRig(localeStore: store);
      await tester.pumpWidget(first.app);
      await tester.pump();
      await switchLanguage(tester, AppLocale.simplifiedChinese);

      // A new app over the same storage is what a cold start is.
      await tester.pumpWidget(const SizedBox.shrink());
      final restarted = ReadingTestRig(localeStore: store);
      await tester.pumpWidget(restarted.app);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      allowCountryNameGap(tester);

      final zh = stringsFor(AppLocale.simplifiedChinese);
      expect(find.text(zh.onboardingTitle), findsOneWidget);
    });

    testWidgets('it is still reachable from Home afterwards', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await openHome(tester, rig);

      expect(find.byKey(const Key('language_button')), findsOneWidget);
      await switchLanguage(tester, AppLocale.vietnamese);

      final vi = stringsFor(AppLocale.vietnamese);
      expect(find.text(vi.homeTitle), findsOneWidget);
      expect(find.text(vi.findDirection), findsOneWidget);
      expect(find.text(vi.areaQuestion), findsOneWidget);
    });

    test(
      'a stored tag this build does not know falls back to English',
      () async {
        final controller = LocaleController(
          store: InMemoryLocaleStore(tag: 'kl-GL'),
        );
        await controller.ensureLoaded();
        expect(controller.locale, AppLocale.english);
      },
    );

    test('selecting the language already shown writes nothing', () async {
      final store = InMemoryLocaleStore();
      final controller = LocaleController(store: store);
      await controller.ensureLoaded();
      await controller.select(AppLocale.english);
      expect(store.saves, 0);
      await controller.select(AppLocale.thai);
      expect(store.saves, 1);
    });
  });

  group('the rotations across a language switch', () {
    testWidgets('Home shows the same description, translated', (tester) async {
      final store = InMemoryHomeDescriptionStore();
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        descriptionStore: store,
      );
      await openHome(tester, rig);

      final english = shownDescription(tester)!;
      final index = stringsFor(AppLocale.english);
      final dealt = List.generate(
        homeDescriptions.length,
        (i) => homeDescriptionAt(index, i),
      ).indexOf(english);
      expect(dealt, isNot(-1));
      final savesBefore = store.saves;

      await switchLanguage(tester, AppLocale.japanese);

      expect(
        shownDescription(tester),
        homeDescriptionAt(stringsFor(AppLocale.japanese), dealt),
      );
      // Same line, not a reshuffle: nothing was dealt and nothing was saved.
      expect(store.saves, savesBefore);
      final state = await store.load();
      expect(state!.days.values, contains(dealt));
    });

    testWidgets('an opened energy insight keeps its place', (tester) async {
      final insights = InMemoryDailyEnergyInsightStore.ordered(
        coachMarkShown: true,
      );
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        insightStore: insights,
      );
      rig.dailyBriefProvider.response = briefWith(testEnergyLevel);
      await openHome(tester, rig);

      await tester.tap(find.byKey(const Key('daily_energy_info_button')));
      await tester.pumpAndSettle();
      final note = find.byKey(const Key('daily_energy_note'));
      final english = tester.widget<Text>(note).data!;
      final savesBefore = insights.saves;

      // Close the tab first: while it is open its barrier covers the page,
      // which is exactly what it is there for.
      await tester.tap(find.byKey(const Key('daily_energy_note_barrier')));
      await tester.pumpAndSettle();

      await switchLanguage(tester, AppLocale.thai);
      await tester.tap(find.byKey(const Key('daily_energy_info_button')));
      await tester.pumpAndSettle();

      final thai = tester.widget<Text>(note).data!;
      expect(thai, isNot(english));
      // The same sentence, in the other language: its index is unchanged.
      const level = testEnergyLevel;
      final englishIndex = dailyEnergyMessagePools[level]!.indexOf(english);
      expect(englishIndex, isNot(-1));
      expect(
        thai,
        dailyEnergyInsightAt(stringsFor(AppLocale.thai), level, englishIndex),
      );
      // Reopening consumed nothing beyond marking it read the first time.
      expect(insights.saves, savesBefore);
    });
  });

  group('a saved reading reopened in another language', () {
    testWidgets('History rebuilds its labels from the reading, not the text', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_love_evening.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester, periodName: 'evening');
      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();

      // Back to Home, which is where the language control lives after
      // onboarding, then open the saved reading in the new language.
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();
      await switchLanguage(tester, AppLocale.vietnamese);
      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();

      final vi = stringsFor(AppLocale.vietnamese);
      expect(find.text(vi.yourReadings), findsOneWidget);
      expect(
        find.textContaining(categoryLabel(vi, engine.ReadingCategory.love)),
        findsWidgets,
      );
      expect(
        find.textContaining(
          formatDate(AppLocale.vietnamese.intlName, DateTime(2026, 9, 18)),
        ),
        findsWidgets,
      );
      // The engine's English winner never reaches the screen.
      expect(find.textContaining('YES'), findsNothing);
    });

    testWidgets('an old snapshot still shows the side the engine chose', (
      tester,
    ) async {
      final rig = ReadingTestRig();
      final reading = fixtureResponse(
        'ready_commit_withdraw_two_windows.json',
      );
      await tester.pumpWidget(
        localizedApp(
          locale: AppLocale.japanese,
          home: ResultPage(
            reading: reading,
            dependencies: rig.dependencies,
            autoSave: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      allowCountryNameGap(tester);

      final ja = stringsFor(AppLocale.japanese);
      expect(
        tester.widget<Text>(find.byKey(const Key('result_winner_label'))).data,
        modeFirstLabel(ja, DecisionMode.commitWithdraw),
      );
      // The heading is one complete Japanese sentence, not a frame.
      expect(find.text(ja.luckyTimesEvening), findsOneWidget);
      expect(
        find.byKey(const Key('result_lucky_times_caveat')),
        findsOneWidget,
      );
    });

    testWidgets('an empty History speaks the chosen language', (tester) async {
      final rig = ReadingTestRig();
      await tester.pumpWidget(
        localizedApp(
          locale: AppLocale.hindi,
          home: HistoryPage(dependencies: rig.dependencies),
        ),
      );
      await tester.pumpAndSettle();
      allowCountryNameGap(tester);

      final hi = stringsFor(AppLocale.hindi);
      expect(find.text(hi.noReadings), findsOneWidget);
      expect(find.text(hi.historySnapshot), findsOneWidget);
    });
  });
}

/// Mirrors `trackingFor` without needing a BuildContext.
double _tracking(AppLocale locale, double latin) => switch (locale) {
  AppLocale.thai ||
  AppLocale.hindi ||
  AppLocale.japanese ||
  AppLocale.simplifiedChinese => 0,
  AppLocale.english || AppLocale.vietnamese || AppLocale.spanish => latin,
};
