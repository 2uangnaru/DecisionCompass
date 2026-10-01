import 'dart:convert';

import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/birth_country_language.dart';
import 'package:decision_compass/data/locale_controller.dart';
import 'package:decision_compass/data/locale_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// The one language decision the app makes without being asked.
///
/// Two separate things are checked here: the table itself, which is a claim
/// about countries, and the provenance rules, which are a claim about who gets
/// the last word. The second matters more — a wrong guess about a country is a
/// tap away from being fixed, but a guess that keeps overruling the fix is not.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the country table', () {
    test('the four single-language countries map as written', () {
      expect(languageForBirthCountry('VN'), AppLocale.vietnamese);
      expect(languageForBirthCountry('JP'), AppLocale.japanese);
      expect(languageForBirthCountry('TH'), AppLocale.thai);
      expect(languageForBirthCountry('CN'), AppLocale.simplifiedChinese);
    });

    test('all nineteen Spanish-speaking countries map to Spanish', () {
      // Listed out rather than read back from the same set the code uses: a
      // test that imports the answer proves only that the set exists.
      const expected = [
        'ES',
        'MX',
        'AR',
        'CO',
        'CL',
        'PE',
        'VE',
        'EC',
        'GT',
        'CU',
        'BO',
        'DO',
        'HN',
        'PY',
        'SV',
        'NI',
        'CR',
        'PA',
        'UY',
      ];
      for (final code in expected) {
        expect(
          languageForBirthCountry(code),
          AppLocale.spanish,
          reason: '$code should read Spanish',
        );
      }
      expect(expected, hasLength(19));
      expect(birthCountryLanguages, hasLength(23));
    });

    test('multilingual and traditional-script countries stay English', () {
      // The absences that matter, asserted rather than only commented.
      //
      // India has more than twenty official languages, so Hindi for everyone
      // born there would be a guess about a person. Taiwan, Hong Kong and
      // Macau read traditional characters, which this app does not bundle —
      // Simplified would be worse than English, not better.
      for (final code in ['IN', 'TW', 'HK', 'MO', 'SG', 'CA', 'BE', 'CH']) {
        expect(
          languageForBirthCountry(code),
          AppLocale.english,
          reason: '$code must not be guessed at',
        );
      }
      // Portuguese-speaking Brazil is not in the Spanish list.
      expect(languageForBirthCountry('BR'), AppLocale.english);
    });

    test('no country maps to Hindi at all', () {
      expect(birthCountryLanguages.values, isNot(contains(AppLocale.hindi)));
    });

    test('anything unrecognisable reads as English rather than throwing', () {
      for (final code in ['', ' ', 'XX', 'ZZZ', '??', 'usa']) {
        expect(languageForBirthCountry(code), AppLocale.english);
      }
    });

    test('case and surrounding space do not change the answer', () {
      // It reads a stored profile field, not a literal.
      for (final code in ['vn', 'Vn', ' VN ', '\tvn\n']) {
        expect(languageForBirthCountry(code), AppLocale.vietnamese);
      }
    });
  });

  group('who gets the last word', () {
    LocaleController controllerWith(InMemoryLocaleStore store) =>
        LocaleController(store: store);

    test('the rule runs when nobody has chosen', () async {
      final store = InMemoryLocaleStore();
      final controller = controllerWith(store);
      await controller.ensureLoaded();
      expect(controller.provenance, LocaleProvenance.unset);

      final outcome = await controller.applyBirthCountryDefault('VN');

      expect(outcome.changedTo, AppLocale.vietnamese);
      expect(outcome.saved, isTrue);
      expect(controller.locale, AppLocale.vietnamese);
      expect(controller.provenance, LocaleProvenance.automatic);
      expect(store.tag, 'vi');
      expect(store.provenanceName, 'automatic');
    });

    test('an English result still spends the rule', () async {
      // The visible language does not move, but the decision has been made.
      // Recording anything else would let it run again on the next profile.
      final store = InMemoryLocaleStore();
      final controller = controllerWith(store);
      await controller.ensureLoaded();

      final outcome = await controller.applyBirthCountryDefault('IN');

      expect(outcome.changedTo, isNull, reason: 'nothing visible changed');
      expect(outcome.saved, isTrue);
      expect(controller.provenance, LocaleProvenance.automatic);
      expect(store.tag, 'en');
      expect(store.provenanceName, 'automatic');
    });

    test('it does not run twice', () async {
      final store = InMemoryLocaleStore();
      final controller = controllerWith(store);
      await controller.ensureLoaded();
      await controller.applyBirthCountryDefault('IN');
      final savesAfterFirst = store.saves;

      // A second profile, created later, with a different country.
      final again = await controller.applyBirthCountryDefault('VN');

      expect(again.changedTo, isNull);
      expect(controller.locale, AppLocale.english);
      expect(store.saves, savesAfterFirst, reason: 'it wrote again');
    });

    test('a manual choice stops it, permanently', () async {
      final store = InMemoryLocaleStore();
      final controller = controllerWith(store);
      await controller.ensureLoaded();
      await controller.select(AppLocale.japanese);

      final outcome = await controller.applyBirthCountryDefault('VN');

      expect(outcome.changedTo, isNull);
      expect(controller.locale, AppLocale.japanese);
      expect(controller.provenance, LocaleProvenance.manual);
    });

    test('tapping the language already showing is still a choice', () async {
      // The case an early `if (locale == _locale) return` would have thrown
      // away. Nothing moves on screen, but the reader has said "this one",
      // and the country rule has to leave them alone afterwards.
      final store = InMemoryLocaleStore();
      final controller = controllerWith(store);
      await controller.ensureLoaded();
      expect(controller.locale, AppLocale.english);

      await controller.select(AppLocale.english);

      expect(controller.provenance, LocaleProvenance.manual);
      expect(store.provenanceName, 'manual');

      final outcome = await controller.applyBirthCountryDefault('VN');
      expect(outcome.changedTo, isNull);
      expect(controller.locale, AppLocale.english);
    });

    test(
      'choosing another language and coming back to English sticks',
      () async {
        final store = InMemoryLocaleStore();
        final controller = controllerWith(store);
        await controller.ensureLoaded();

        await controller.select(AppLocale.thai);
        await controller.select(AppLocale.english);

        expect(controller.locale, AppLocale.english);
        expect(controller.provenance, LocaleProvenance.manual);
        expect(store.tag, 'en');

        final outcome = await controller.applyBirthCountryDefault('TH');
        expect(
          outcome.changedTo,
          isNull,
          reason: 'their English was overruled',
        );
        expect(controller.locale, AppLocale.english);
      },
    );

    test('a manual choice after the rule overrides it', () async {
      final store = InMemoryLocaleStore();
      final controller = controllerWith(store);
      await controller.ensureLoaded();
      await controller.applyBirthCountryDefault('VN');
      expect(controller.locale, AppLocale.vietnamese);

      await controller.select(AppLocale.english);

      expect(controller.locale, AppLocale.english);
      expect(controller.provenance, LocaleProvenance.manual);
      // And it stays that way across a restart.
      final restarted = controllerWith(store);
      await restarted.ensureLoaded();
      expect(restarted.locale, AppLocale.english);
      expect(restarted.provenance, LocaleProvenance.manual);
    });
  });

  group('across a restart', () {
    test('an automatic choice is remembered as automatic', () async {
      final store = InMemoryLocaleStore();
      final first = LocaleController(store: store);
      await first.ensureLoaded();
      await first.applyBirthCountryDefault('JP');

      final second = LocaleController(store: store);
      await second.ensureLoaded();

      expect(second.locale, AppLocale.japanese);
      expect(second.provenance, LocaleProvenance.automatic);
      // And the rule still does not run a second time.
      expect((await second.applyBirthCountryDefault('TH')).changedTo, isNull);
      expect(second.locale, AppLocale.japanese);
    });

    test('a language saved by an older build counts as manual', () async {
      // The migration case. Before provenance existed the only way a tag got
      // written was a reader tapping an option, so reading it as anything
      // else would switch an existing reader's language on first launch
      // after the update.
      final store = InMemoryLocaleStore(tag: 'ja', provenanceName: null);
      final controller = LocaleController(store: store);
      await controller.ensureLoaded();

      expect(controller.locale, AppLocale.japanese);
      expect(controller.provenance, LocaleProvenance.manual);

      final outcome = await controller.applyBirthCountryDefault('VN');
      expect(outcome.changedTo, isNull);
      expect(controller.locale, AppLocale.japanese);
    });

    test('an unreadable saved tag leaves the rule free to run', () async {
      // A tag from a build that offered a language this one does not. There
      // is no language to preserve, so there is nothing to protect.
      final store = InMemoryLocaleStore(tag: 'xx-YY', provenanceName: 'manual');
      final controller = LocaleController(store: store);
      await controller.ensureLoaded();

      expect(controller.locale, AppLocale.english);
      expect(controller.provenance, LocaleProvenance.unset);
      expect(
        (await controller.applyBirthCountryDefault('TH')).changedTo,
        AppLocale.thai,
      );
    });
  });

  group('when the language cannot be written', () {
    test('it still applies, and says it was not saved', () async {
      final store = InMemoryLocaleStore(failSaves: true);
      final controller = LocaleController(store: store);
      await controller.ensureLoaded();

      final outcome = await controller.applyBirthCountryDefault('VN');

      // Applied for this session — undoing it would be a second surprise on
      // top of the first.
      expect(controller.locale, AppLocale.vietnamese);
      expect(outcome.changedTo, AppLocale.vietnamese);
      // But the caller is told the truth, and does not claim it was saved.
      expect(outcome.saved, isFalse);
      expect(store.tag, isNull);
    });

    test('the next launch finds nothing stored and may try again', () async {
      // The honest consequence of the write having failed: nothing was
      // recorded, so nothing is remembered.
      final store = InMemoryLocaleStore(failSaves: true);
      final controller = LocaleController(store: store);
      await controller.ensureLoaded();
      await controller.applyBirthCountryDefault('VN');

      store.failSaves = false;
      final restarted = LocaleController(store: store);
      await restarted.ensureLoaded();
      expect(restarted.locale, AppLocale.english);
      expect(restarted.provenance, LocaleProvenance.unset);
    });
  });

  group('the stored record', () {
    // SharedPreferences is driven through its mock store, so these exercise
    // the real `SharedPreferencesLocaleStore` — the JSON shape, the legacy
    // key and the return value of `setString` — rather than the in-memory
    // double that stands in for it everywhere else.
    const store = SharedPreferencesLocaleStore();

    test('a language and its reason are written as one value', () async {
      SharedPreferences.setMockInitialValues({});
      await store.save(AppLocale.thai, LocaleProvenance.automatic);

      final prefs = await SharedPreferences.getInstance();
      // One key, so there is no window in which the two disagree.
      expect(prefs.getKeys().where((k) => k.startsWith('app_locale')), [
        'app_locale_v2',
      ]);
      expect(jsonDecode(prefs.getString('app_locale_v2')!), {
        'tag': 'th',
        'provenance': 'automatic',
      });

      final read = await store.load();
      expect(read.locale, AppLocale.thai);
      expect(read.provenance, LocaleProvenance.automatic);
    });

    test(
      'a tag left by an older build still counts as a manual choice',
      () async {
        // The migration that matters: an existing reader who chose Japanese
        // before provenance existed must not be switched by the country rule
        // on their first launch after the update.
        SharedPreferences.setMockInitialValues({'app_locale_v1': 'ja'});

        final read = await store.load();

        expect(read.locale, AppLocale.japanese);
        expect(read.provenance, LocaleProvenance.manual);
      },
    );

    test('the record wins over a stale legacy tag', () async {
      SharedPreferences.setMockInitialValues({
        'app_locale_v1': 'ja',
        'app_locale_v2': jsonEncode({'tag': 'th', 'provenance': 'automatic'}),
      });

      final read = await store.load();

      expect(read.locale, AppLocale.thai);
      expect(read.provenance, LocaleProvenance.automatic);
    });

    test('an unreadable record falls back to the legacy tag', () async {
      SharedPreferences.setMockInitialValues({
        'app_locale_v1': 'ja',
        'app_locale_v2': 'not json at all',
      });

      final read = await store.load();

      expect(read.locale, AppLocale.japanese);
      expect(read.provenance, LocaleProvenance.manual);
    });

    test(
      'an unreadable record with nothing behind it reads as nothing',
      () async {
        SharedPreferences.setMockInitialValues({'app_locale_v2': '{]'});
        final read = await store.load();
        expect(read.locale, isNull);
        expect(read.provenance, LocaleProvenance.unset);
      },
    );

    test(
      'a record naming an unknown language reads as nothing saved',
      () async {
        SharedPreferences.setMockInitialValues({
          'app_locale_v2': jsonEncode({'tag': 'xx-YY', 'provenance': 'manual'}),
        });
        final read = await store.load();
        expect(read.locale, isNull);
        expect(read.provenance, LocaleProvenance.unset);
      },
    );

    test('a record naming an unknown provenance reads as manual', () async {
      // Written by a build this one does not understand. Manual is the
      // reading that changes nothing on the reader's behalf.
      SharedPreferences.setMockInitialValues({
        'app_locale_v2': jsonEncode({'tag': 'th', 'provenance': 'inherited'}),
      });
      final read = await store.load();
      expect(read.locale, AppLocale.thai);
      expect(read.provenance, LocaleProvenance.manual);
    });

    test('nothing stored at all reads as unset', () async {
      SharedPreferences.setMockInitialValues({});
      final read = await store.load();
      expect(read.locale, isNull);
      expect(read.provenance, LocaleProvenance.unset);
    });

    group('a record that cannot be trusted', () {
      // Every one of these is *valid JSON* — which is what makes them
      // dangerous. The decoder used to cast `tag` with `as String?`, and a
      // cast that fails throws a TypeError, not a FormatException. It escaped
      // the decoder, escaped `load`, and took the first frame with it: the app
      // would not start, over a value a single damaged write could produce,
      // with the legacy locale sitting unread right beside it.
      //
      // The rule for all of them is the same as for unparseable text: fall
      // back to the legacy tag, and to nothing if there is none.
      const malformed = <String, Object?>{
        'a numeric tag': {'tag': 123, 'provenance': 'manual'},
        'a boolean tag': {'tag': true, 'provenance': 'manual'},
        'a null tag': {'tag': null, 'provenance': 'manual'},
        'a list tag': {
          'tag': ['ja'],
          'provenance': 'manual',
        },
        'a nested-object tag': {
          'tag': {'value': 'ja'},
          'provenance': 'manual',
        },
        'no tag at all': {'provenance': 'manual'},
        // A bad *provenance* is not in this list: the language is still
        // legible, so the record is usable. That case is checked on its own
        // below, and it must not be discarded.
        'a list record': ['ja', 'manual'],
        'a bare string record': 'ja',
        'a bare number record': 42,
      };

      malformed.forEach((name, record) {
        test('$name falls back to the legacy locale', () async {
          SharedPreferences.setMockInitialValues({
            'app_locale_v1': 'ja',
            'app_locale_v2': jsonEncode(record),
          });

          final read = await store.load();

          // The legacy tag is reached, and the migration rule still applies
          // to it: a language saved before provenance existed was chosen by
          // hand.
          expect(read.locale, AppLocale.japanese, reason: name);
          expect(read.provenance, LocaleProvenance.manual, reason: name);
        });

        test('$name reads as nothing saved when there is no legacy', () async {
          SharedPreferences.setMockInitialValues({
            'app_locale_v2': jsonEncode(record),
          });

          final read = await store.load();

          expect(read.locale, isNull, reason: name);
          expect(read.provenance, LocaleProvenance.unset, reason: name);
        });
      });

      test('a numeric provenance keeps a valid tag, read as manual', () async {
        // The one malformed field that is not fatal: the language is still
        // legible, and an unreadable reason is read the way an absent one is.
        SharedPreferences.setMockInitialValues({
          'app_locale_v2': jsonEncode({'tag': 'th', 'provenance': 7}),
        });

        final read = await store.load();

        expect(read.locale, AppLocale.thai);
        expect(read.provenance, LocaleProvenance.manual);
      });

      test('unparseable text behaves identically', () async {
        for (final raw in ['', 'not json', '{', '{"tag":', '[1,2']) {
          SharedPreferences.setMockInitialValues({
            'app_locale_v1': 'ja',
            'app_locale_v2': raw,
          });
          final read = await store.load();
          expect(read.locale, AppLocale.japanese, reason: raw);
          expect(read.provenance, LocaleProvenance.manual, reason: raw);
        }
      });

      test('a controller starts rather than throwing on any of them', () async {
        // The failure this is really about: `load` throwing means the first
        // frame never renders.
        for (final raw in [
          jsonEncode({'tag': 123}),
          jsonEncode(['ja']),
          'not json',
        ]) {
          SharedPreferences.setMockInitialValues({'app_locale_v2': raw});
          final controller = LocaleController(store: store);
          await expectLater(controller.ensureLoaded(), completes);
          expect(controller.locale, AppLocale.english, reason: raw);
          expect(controller.provenance, LocaleProvenance.unset, reason: raw);
          // And the country rule is free to act, because nothing was chosen.
          expect(
            (await controller.applyBirthCountryDefault('VN')).changedTo,
            AppLocale.vietnamese,
            reason: raw,
          );
        }
      });
    });

    test('a write that returns false is a failure, not a success', () async {
      // `setString` reports failure by returning false rather than by
      // throwing, so an unchecked call cannot tell the two apart. This swaps
      // in a platform store that refuses every write, which is the one way to
      // reach that branch without a device whose disk is actually full.
      final real = SharedPreferencesStorePlatform.instance;
      addTearDown(() => SharedPreferencesStorePlatform.instance = real);
      // `setMockInitialValues` installs a store of its own, so the refusing
      // one has to go in after it or it is replaced before it is used.
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = _RefusingStore();

      await expectLater(
        store.save(AppLocale.thai, LocaleProvenance.manual),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'a controller reports that refusal rather than swallowing it',
      () async {
        final real = SharedPreferencesStorePlatform.instance;
        addTearDown(() => SharedPreferencesStorePlatform.instance = real);
        // Same ordering trap as above: the mock store goes in first.
        SharedPreferences.setMockInitialValues({});
        SharedPreferencesStorePlatform.instance = _RefusingStore();

        final controller = LocaleController(store: store);
        await controller.ensureLoaded();

        // The country rule turns it into a reportable outcome...
        final outcome = await controller.applyBirthCountryDefault('TH');
        expect(outcome.changedTo, AppLocale.thai);
        expect(outcome.saved, isFalse);
        expect(controller.locale, AppLocale.thai);

        // ...and an explicit choice lets it out, for the selector to catch.
        await expectLater(
          controller.select(AppLocale.japanese),
          throwsA(isA<StateError>()),
        );
        expect(
          controller.locale,
          AppLocale.japanese,
          reason: 'it still applied',
        );
      },
    );
  });
}

/// A platform store that refuses every write, the way a full or locked disk
/// does: by returning false rather than by throwing.
class _RefusingStore extends SharedPreferencesStorePlatform {
  final Map<String, Object> _values = <String, Object>{};

  @override
  Future<bool> clear() async => false;

  @override
  Future<Map<String, Object>> getAll() async => _values;

  @override
  Future<bool> remove(String key) async => false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}
