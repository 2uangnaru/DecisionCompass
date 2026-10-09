import 'package:country_picker/country_picker.dart';
import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/country_names.dart';
import 'package:decision_compass/data/country_names_data.dart';
import 'package:decision_compass/local_engine/time/tzdb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// The birth-country picker names countries in the reader's own language.
///
/// The ISO 3166-1 alpha-2 code is what a reading is calculated from, and it
/// never changes; only the word beside it does.
void main() {
  /// Opens the picker from the profile step, in [locale].
  Future<void> openPicker(WidgetTester tester, AppLocale locale) async {
    final rig = ReadingTestRig(locale: locale);
    await tester.pumpWidget(rig.app);
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byKey(const Key('birth_country')));
    await tester.tap(find.byKey(const Key('birth_country')));
    await tester.pumpAndSettle();
  }

  /// The list only builds the rows it can show, and there are 246 of them,
  /// so every assertion narrows it first.
  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField).last, query);
    await tester.pumpAndSettle();
  }

  /// Text inside the country list, which excludes the search field the query
  /// was just typed into.
  Finder inList(String text) =>
      find.descendant(of: find.byType(ListView), matching: find.text(text));

  group('the bundled CLDR tables', () {
    test('cover every country the picker offers, in all three languages', () {
      // The list shows the intersection of what `country_picker` knows and
      // what the calculation engine can resolve a timezone for, so that
      // intersection is the set that has to be named.
      final offered = tzdbCountries()
          .where(countryNamesVI.containsKey)
          .toList();
      expect(offered.length, greaterThan(200));
      for (final table in [countryNamesVI, countryNamesTH, countryNamesHI]) {
        expect(table, hasLength(countryNamesVI.length));
        for (final code in offered) {
          expect(table[code]?.trim(), isNotEmpty, reason: '$code has no name');
        }
      }
      // Every code the picker itself offers is covered, so nothing can fall
      // back to English mid-list.
      for (final code in countryNamesVI.keys) {
        expect(countryNamesTH[code], isNotNull, reason: code);
        expect(countryNamesHI[code], isNotNull, reason: code);
      }
    });

    test('Hindi is Hindi, not the package\'s Nepali list', () {
      // `country_picker` answers a Hindi locale from `np.dart`, whose spelling
      // is Nepali: `फ्रान्स` for France where Hindi writes `फ़्रांस`, and
      // `थाइल्यान्ड` where Hindi writes `थाईलैंड`. These are the CLDR Hindi
      // forms, which is what the rest of an Indian reader's phone uses.
      expect(countryNamesHI['FR'], 'फ़्रांस');
      expect(countryNamesHI['TH'], 'थाईलैंड');
      expect(countryNamesHI['IN'], 'भारत');

      // And the package really would have said something else.
      final nepali = CountryLocalizations(const Locale('hi'))
          .countryName(countryCode: 'FR');
      expect(nepali, isNot(countryNamesHI['FR']));
    });

    test('every language the app offers can name a country', () {
      // No half-translated birth-country screen in any of the seven.
      for (final locale in AppLocale.values) {
        expect(
          CompassCountryLocalizations.covers(locale.locale),
          isTrue,
          reason: locale.tag,
        );
        expect(
          CompassCountryLocalizations(locale.locale)
              .countryName(countryCode: 'VN'),
          isNotNull,
          reason: locale.tag,
        );
      }
    });

    test('the five the package serves still come from the package', () {
      // Only the three it cannot serve are overridden; nothing else changes.
      for (final tag in ['en', 'es', 'ja', 'zh', 'ko']) {
        final ours = CompassCountryLocalizations(Locale(tag));
        expect(
          ours.countryName(countryCode: 'VN'),
          CountryLocalizations(Locale(tag)).countryName(countryCode: 'VN'),
          reason: tag,
        );
      }
    });
  });

  group('the picker', () {
    for (final entry in const [
      (AppLocale.vietnamese, 'Việt Nam', 'Thái Lan'),
      (AppLocale.thai, 'ไทย', 'เวียดนาม'),
      (AppLocale.hindi, 'भारत', 'वियतनाम'),
    ]) {
      final (locale, own, other) = entry;

      testWidgets('names countries in ${locale.tag}, not in English', (
        tester,
      ) async {
        await openPicker(tester, locale);
        await search(tester, 'VN');
        expect(
          inList(
            other == 'เวียดนาม' || other == 'वियतनाम' ? other : 'Việt Nam',
          ),
          findsOneWidget,
        );
        // The English name is not what the reader sees.
        expect(inList('Viet Nam'), findsNothing);

        await search(tester, 'TH');
        expect(
          inList(
            CompassCountryLocalizations(locale.locale)
                .countryName(countryCode: 'TH')!,
          ),
          findsOneWidget,
        );
        expect(inList('Thailand'), findsNothing);
      });

      testWidgets('searches by the localized name in ${locale.tag}', (
        tester,
      ) async {
        await openPicker(tester, locale);
        // The reader types their own language, not a transliteration.
        await search(tester, own);
        expect(inList(own), findsOneWidget);
        expect(inList(other), findsNothing);
      });

      testWidgets('keeps the ISO code as a search alias in ${locale.tag}', (
        tester,
      ) async {
        await openPicker(tester, locale);
        await search(tester, 'VN');
        expect(
          inList(
            CompassCountryLocalizations(locale.locale)
                .countryName(countryCode: 'VN')!,
          ),
          findsOneWidget,
        );
      });

      testWidgets('keeps the English name as a search alias in ${locale.tag}', (
        tester,
      ) async {
        await openPicker(tester, locale);
        // `country_picker` matches its own English `name` too, so a reader who
        // only knows the English spelling can still find the country — but the
        // row is still labelled in their language.
        await search(tester, 'Thailand');
        expect(inList('Thailand'), findsNothing);
        expect(
          inList(
            CompassCountryLocalizations(locale.locale)
                .countryName(countryCode: 'TH')!,
          ),
          findsOneWidget,
        );
      });

      testWidgets('selecting one stores the ISO code, in ${locale.tag}', (
        tester,
      ) async {
        await openPicker(tester, locale);
        await search(tester, 'VN');
        // The flag reads the same in every language, so tapping by it does
        // not depend on the name.
        await tester.tap(inList('\u{1F1FB}\u{1F1F3}'));
        await tester.pumpAndSettle();

        final localized = CompassCountryLocalizations(locale.locale)
            .countryName(countryCode: 'VN')!;
        expect(
          tester
              .widget<Text>(find.byKey(const Key('birth_country_value')))
              .data,
          localized,
        );
      });
    }

    test('in English, KR is named Korea, not South Korea', () {
      final l10n = CompassCountryLocalizations(const Locale('en'));
      expect(l10n.countryName(countryCode: 'KR'), 'Korea');
    });

    testWidgets(
      'in English, searching Korea finds Korea and South Korea query also resolves',
      (tester) async {
        await openPicker(tester, AppLocale.english);
        await search(tester, 'Korea');
        expect(inList('Korea'), findsOneWidget);
        expect(inList('South Korea'), findsNothing);

        await search(tester, 'South Korea');
        expect(inList('Korea'), findsOneWidget);
      },
    );

    testWidgets(
      'in Vietnamese, searching Korea, South Korea, or han quoc finds Hàn Quốc',
      (tester) async {
        await openPicker(tester, AppLocale.vietnamese);
        await search(tester, 'Korea');
        expect(inList('Hàn Quốc'), findsOneWidget);

        await search(tester, 'South Korea');
        expect(inList('Hàn Quốc'), findsOneWidget);

        await search(tester, 'han quoc');
        expect(inList('Hàn Quốc'), findsOneWidget);

        await tester.tap(inList('\u{1F1F0}\u{1F1F7}'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(find.byKey(const Key('birth_country_value')))
              .data,
          'Hàn Quốc',
        );
      },
    );
  });
}
