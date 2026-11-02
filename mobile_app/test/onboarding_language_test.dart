import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/locale_controller.dart';
import 'package:decision_compass/data/locale_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// Choosing a language from the country of birth, through the real screen.
///
/// The unit tests next door cover the table and the provenance rules. These
/// cover the thing those cannot: that the rule fires at the right moment in
/// onboarding, that Home is already in the new language when it appears rather
/// than switching after, and that a form which was not accepted — or a profile
/// that was not written — leaves the language alone.
void main() {
  /// Walks the profile step and picks [countryCode] rather than the rig's
  /// default US, because the country is the whole input here.
  Future<void> fillProfile(
    WidgetTester tester, {
    required String countryCode,
    required String flag,
    bool pickDate = true,
  }) async {
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pumpAndSettle();

    if (pickDate) {
      await tester.ensureVisible(find.byKey(const Key('birth_date_value')));
      await tester.tap(find.byKey(const Key('birth_date_value')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('birth_date_type_tab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('birth_date_day')), '01');
      await tester.enterText(find.byKey(const Key('birth_date_month')), '01');
      await tester.enterText(find.byKey(const Key('birth_date_year')), '2000');
      await tester.tap(find.byKey(const Key('birth_date_confirm')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('birth_country')));
      await tester.tap(find.byKey(const Key('birth_country')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, countryCode);
      await tester.pumpAndSettle();
      await tester.tap(find.text(flag).last);
      await tester.pumpAndSettle();
    }

    await answerBirthTime(tester, null);
  }

  Future<void> completeProfile(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pumpAndSettle();
  }

  const vnFlag = '\u{1F1FB}\u{1F1F3}';
  const usFlag = '\u{1F1FA}\u{1F1F8}';
  const inFlag = '\u{1F1EE}\u{1F1F3}';

  final notice = find.byKey(const Key('language_auto_notice'));

  group('after the first profile is created', () {
    testWidgets('a Vietnamese birth country switches the app to Vietnamese', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await fillProfile(tester, countryCode: 'VN', flag: vnFlag);
      await completeProfile(tester);

      expect(rig.localeController.locale, AppLocale.vietnamese);
      expect(rig.localeController.provenance, LocaleProvenance.automatic);
      expect(rig.localeStore.tag, 'vi');
      expect(rig.localeStore.provenanceName, 'automatic');

      // Home itself is in Vietnamese, not English waiting to be swapped.
      final vi = stringsFor(AppLocale.vietnamese);
      expect(find.text(vi.findDirection), findsOneWidget);
      expect(
        find.text(stringsFor(AppLocale.english).findDirection),
        findsNothing,
      );
    });

    testWidgets('the notice names the new language and offers the selector', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await fillProfile(tester, countryCode: 'VN', flag: vnFlag);
      await completeProfile(tester);

      // The switch is silent. A notice used to name the new language and
      // offer the selector; it was dropped on request, so the only thing that
      // announces the change is the app being in it.
      expect(notice, findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(rig.localeController.locale, AppLocale.vietnamese);

      // The globe is still on Home, so the switch is still undoable — that is
      // what makes a silent change recoverable rather than a trap.
      final vi = stringsFor(AppLocale.vietnamese);
      await openLanguageSheet(tester);
      expect(find.text(vi.chooseLanguage), findsOneWidget);
    });

    testWidgets('an English result changes nothing and says nothing', (
      tester,
    ) async {
      // India is deliberately not mapped, so this is the "no idea" path.
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await fillProfile(tester, countryCode: 'IN', flag: inFlag);
      await completeProfile(tester);

      expect(rig.localeController.locale, AppLocale.english);
      expect(notice, findsNothing, reason: 'nothing happened to announce');
      // But the rule is spent, and recorded as spent.
      expect(rig.localeController.provenance, LocaleProvenance.automatic);
      expect(rig.localeStore.provenanceName, 'automatic');
    });

    testWidgets('the profile keeps the country code that was chosen', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await fillProfile(tester, countryCode: 'VN', flag: vnFlag);
      await completeProfile(tester);

      final saved = await rig.profileRepository.load();
      expect(saved!.birthCountryCode, 'VN');
      expect(saved.useCurrentLocation, isFalse);
    });
  });

  group('an explicit choice outranks the country', () {
    testWidgets('a language chosen before onboarding finishes survives', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await tester.pump();
      await switchLanguage(tester, AppLocale.japanese);

      await tester.tap(find.byKey(const Key('continue_to_profile')));
      await tester.pumpAndSettle();
      await fillProfileAfterLanguage(tester, vnFlag);
      await completeProfile(tester);

      expect(rig.localeController.locale, AppLocale.japanese);
      expect(rig.localeController.provenance, LocaleProvenance.manual);
      expect(notice, findsNothing);
    });

    testWidgets('opening the sheet and dismissing it is not a choice', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await tester.pump();

      // Opened, looked at, closed without tapping an option.
      await openLanguageSheet(tester);
      expect(
        find.text(stringsFor(AppLocale.english).chooseLanguage),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(400, 8));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(rig.localeController.provenance, LocaleProvenance.unset);

      await fillProfile(tester, countryCode: 'VN', flag: vnFlag);
      await completeProfile(tester);

      // So the country rule was still free to act.
      expect(rig.localeController.locale, AppLocale.vietnamese);
      expect(rig.localeController.provenance, LocaleProvenance.automatic);
    });

    testWidgets('tapping English while English is showing is a choice', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await tester.pump();
      await switchLanguage(tester, AppLocale.english);

      expect(rig.localeController.provenance, LocaleProvenance.manual);

      await fillProfile(tester, countryCode: 'VN', flag: vnFlag);
      await completeProfile(tester);

      expect(rig.localeController.locale, AppLocale.english);
      expect(notice, findsNothing);
    });
  });

  group('nothing accepted, nothing changed', () {
    testWidgets('an incomplete form does not touch the language', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      // No birth date and no country: the form cannot be accepted.
      await fillProfile(
        tester,
        countryCode: 'VN',
        flag: vnFlag,
        pickDate: false,
      );
      await completeProfile(tester);

      expect(rig.profileRepository.saves, 0);
      expect(rig.localeController.locale, AppLocale.english);
      expect(rig.localeController.provenance, LocaleProvenance.unset);
      expect(rig.localeStore.saves, 0);
    });

    testWidgets('a profile that could not be written does not either', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      rig.profileRepository.failSaves = true;
      await tester.pumpWidget(rig.app);
      await fillProfile(tester, countryCode: 'VN', flag: vnFlag);
      await completeProfile(tester);

      expect(rig.localeController.locale, AppLocale.english);
      expect(rig.localeController.provenance, LocaleProvenance.unset);
      // The reader is told, and is still on the form rather than trapped.
      expect(find.byKey(const Key('profile_save_failed')), findsOneWidget);
      expect(find.byKey(const Key('complete_profile')), findsOneWidget);

      // And it works on the retry.
      rig.profileRepository.failSaves = false;
      await completeProfile(tester);
      expect(rig.localeController.locale, AppLocale.vietnamese);
    });

    testWidgets('repeated taps save once and switch once', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await fillProfile(tester, countryCode: 'VN', flag: vnFlag);

      // Four taps in the same frame, before anything can settle.
      await tester.ensureVisible(find.byKey(const Key('complete_profile')));
      for (var i = 0; i < 4; i++) {
        await tester.tap(
          find.byKey(const Key('complete_profile')),
          warnIfMissed: false,
        );
      }
      await tester.pumpAndSettle();

      expect(rig.profileRepository.saves, 1);
      expect(rig.localeStore.saves, 1);
      expect(rig.localeController.locale, AppLocale.vietnamese);
      // Four taps, one of everything — and nothing announced, because the
      // switch is silent now.
      expect(notice, findsNothing);
    });
  });

  group('when the language cannot be written', () {
    testWidgets('the profile survives and the notice does not lie', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      rig.localeStore.failSaves = true;
      await tester.pumpWidget(rig.app);
      await fillProfile(tester, countryCode: 'VN', flag: vnFlag);
      await completeProfile(tester);

      // The profile is saved and the reader reached Home.
      expect(rig.profileRepository.saves, 1);
      expect(find.byKey(const Key('find_direction')), findsOneWidget);
      // The language applied for this session, and nothing was said about it
      // — including about the write having failed.
      expect(rig.localeController.locale, AppLocale.vietnamese);
      expect(find.byType(SnackBar), findsNothing);
      expect(rig.localeStore.tag, isNull);

      // Which has a consequence worth naming: nothing reached storage, so the
      // next launch finds no record and decides again. It reaches the same
      // answer from the same country, so the reader sees no difference — but
      // it is a retry, not a memory.
      // The phone is left out so this reads storage alone, not the host's
      // locale.
      final restarted = LocaleController(
        store: rig.localeStore,
        detectDeviceLocale: false,
      );
      await restarted.ensureLoaded();
      expect(restarted.locale, AppLocale.english);
      expect(restarted.provenance, LocaleProvenance.unset);
    });
  });

  group('the rule is spent once', () {
    testWidgets('a manual change afterwards wins, and is remembered', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await fillProfile(tester, countryCode: 'VN', flag: vnFlag);
      await completeProfile(tester);
      expect(rig.localeController.locale, AppLocale.vietnamese);

      await switchLanguage(tester, AppLocale.spanish);

      expect(rig.localeController.locale, AppLocale.spanish);
      expect(rig.localeController.provenance, LocaleProvenance.manual);
      expect(rig.localeStore.tag, 'es');
      expect(rig.localeStore.provenanceName, 'manual');
    });

    testWidgets('a second profile with a different country changes nothing', (
      tester,
    ) async {
      // The rig keeps one store across a restart, so this is the recreate
      // case: the rule already ran, and must not run again.
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await fillProfile(tester, countryCode: 'IN', flag: inFlag);
      await completeProfile(tester);
      expect(rig.localeController.provenance, LocaleProvenance.automatic);
      final savesAfterFirst = rig.localeStore.saves;

      final applied = await rig.localeController.applyBirthCountryDefault('VN');

      expect(applied.changedTo, isNull);
      expect(rig.localeController.locale, AppLocale.english);
      expect(rig.localeStore.saves, savesAfterFirst);
    });

    testWidgets('a restart keeps the automatic choice without redeciding', (
      tester,
    ) async {
      final store = InMemoryLocaleStore();
      final first = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localeStore: store,
      );
      await tester.pumpWidget(first.app);
      await fillProfile(tester, countryCode: 'VN', flag: vnFlag);
      await completeProfile(tester);
      expect(store.tag, 'vi');

      // A fresh launch against the same storage.
      final second = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localeStore: store,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(second.app);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(second.localeController.locale, AppLocale.vietnamese);
      expect(second.localeController.provenance, LocaleProvenance.automatic);
    });
  });

  group('the country is never inferred', () {
    testWidgets('a US birth country reads English, whatever the device is', (
      tester,
    ) async {
      // The rig's device timezone is Asia/Ho_Chi_Minh and its clock is local
      // to it. None of that may reach the language: only the code the reader
      // picked on the form does.
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        deviceTimezone: 'Asia/Ho_Chi_Minh',
      );
      await tester.pumpWidget(rig.app);
      await fillProfile(tester, countryCode: 'US', flag: usFlag);
      await completeProfile(tester);

      expect(rig.localeController.locale, AppLocale.english);
      expect(notice, findsNothing);
    });
  });

  group('choosing a language that cannot be written', () {
    testWidgets('it stays switched and says it may not be remembered', (
      tester,
    ) async {
      // The selector used to call `select` without awaiting it. A save that
      // threw became an unhandled Future: the language changed, the failure
      // vanished, and the reader found their choice gone after a restart with
      // nothing ever having said why.
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      rig.localeStore.failSaves = true;
      await tester.pumpWidget(rig.app);
      await tester.pump();

      await switchLanguage(tester, AppLocale.japanese);

      // No unhandled exception reached the zone.
      expect(tester.takeException(), isNull);
      // The choice is honoured for this session.
      expect(rig.localeController.locale, AppLocale.japanese);
      final ja = stringsFor(AppLocale.japanese);
      expect(find.text(ja.chooseLanguage), findsNothing, reason: 'sheet open');
      // And the reader is told, in the language they just chose.
      expect(
        find.byKey(const Key('language_not_saved_notice')),
        findsOneWidget,
      );
      expect(find.text(ja.languageNotSaved), findsOneWidget);
      // Nothing reached storage, and the message does not pretend otherwise.
      expect(rig.localeStore.tag, isNull);
    });

    testWidgets('a successful choice says nothing at all', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await tester.pump();

      await switchLanguage(tester, AppLocale.japanese);

      expect(find.byKey(const Key('language_not_saved_notice')), findsNothing);
      expect(rig.localeStore.tag, 'ja');
      expect(rig.localeStore.provenanceName, 'manual');
    });

    testWidgets('a refused write still counts as the reader having chosen', (
      tester,
    ) async {
      // The provenance lives in memory for this session either way, so the
      // country rule must not then overrule a choice that was made.
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      rig.localeStore.failSaves = true;
      await tester.pumpWidget(rig.app);
      await tester.pump();
      await switchLanguage(tester, AppLocale.japanese);

      expect(rig.localeController.provenance, LocaleProvenance.manual);

      // The notice sits at the bottom of the screen, over the button that
      // continues. Letting it expire first is what a reader would experience;
      // tapping through it is not.
      await tester.pump(const Duration(seconds: 7));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('language_not_saved_notice')), findsNothing);

      // Fixed pumps throughout: the welcome screen's orbit animates forever.
      await tester.tap(find.byKey(const Key('continue_to_profile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await fillProfileAfterLanguage(tester, vnFlag);
      await completeProfile(tester);

      expect(rig.localeController.locale, AppLocale.japanese);
      expect(notice, findsNothing);
    });
  });

  group('welcome screen prominent language card', () {
    testWidgets('shows current language and opens language sheet when tapped', (
      tester,
    ) async {
      final rig = ReadingTestRig();
      await tester.pumpWidget(rig.app);
      await tester.pump();

      expect(find.byKey(const Key('welcome_language_card')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('language_button_label')))
            .data,
        AppLocale.english.nativeName,
      );

      // Tapping the card opens the language sheet
      await tester.tap(find.byKey(const Key('welcome_language_card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      allowCountryNameGap(tester);

      expect(find.byKey(const Key('language_sheet')), findsOneWidget);

      // Select Vietnamese from the sheet
      await tester.tap(
        find.byKey(Key('language_option_${AppLocale.vietnamese.tag}')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(rig.localeController.locale, AppLocale.vietnamese);
      expect(rig.localeController.provenance, LocaleProvenance.manual);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('language_button_label')))
            .data,
        AppLocale.vietnamese.nativeName,
      );
    });
  });

  group('device locale automatic detection on first launch', () {
    Future<LocaleController> loaded(
      WidgetTester tester,
      List<Locale> phone, {
      InMemoryLocaleStore? store,
    }) async {
      tester.platformDispatcher.localesTestValue = phone;
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final controller = LocaleController(
        store: store ?? InMemoryLocaleStore(),
        platformDispatcher: tester.platformDispatcher,
      );
      await controller.ensureLoaded();
      return controller;
    }

    testWidgets('detects Vietnamese device locale when unset', (tester) async {
      final controller = await loaded(tester, [const Locale('vi', 'VN')]);
      expect(controller.locale, AppLocale.vietnamese);
      expect(controller.provenance, LocaleProvenance.device);
    });

    testWidgets('detects Japanese device locale when unset', (tester) async {
      final controller = await loaded(tester, [const Locale('ja', 'JP')]);
      expect(controller.locale, AppLocale.japanese);
      expect(controller.provenance, LocaleProvenance.device);
    });

    testWidgets('respects saved choice over device locale', (tester) async {
      final controller = await loaded(tester, [
        const Locale('vi', 'VN'),
      ], store: InMemoryLocaleStore(tag: 'es', provenanceName: 'manual'));
      expect(controller.locale, AppLocale.spanish);
      expect(controller.provenance, LocaleProvenance.manual);
    });

    // Born in one country, living with a phone in another language: the
    // phone is what the reader reads, so the birth country must not overrule
    // it after the profile step.
    for (final (phone, born, expected) in [
      (const Locale('ko', 'KR'), 'US', AppLocale.korean),
      (const Locale('ja', 'JP'), 'BR', AppLocale.japanese),
      (const Locale('es', 'ES'), 'FR', AppLocale.spanish),
      (const Locale('vi', 'VN'), 'JP', AppLocale.vietnamese),
      (const Locale('en', 'US'), 'MX', AppLocale.english),
    ]) {
      testWidgets('a $phone phone keeps its language when born in $born', (
        tester,
      ) async {
        final store = InMemoryLocaleStore();
        final controller = await loaded(tester, [phone], store: store);
        final result = await controller.applyBirthCountryDefault(born);
        expect(result.changedTo, isNull);
        expect(controller.locale, expected);
        expect(controller.provenance, LocaleProvenance.device);
        expect(store.tag, isNull, reason: 'the phone is followed, not stored');
      });
    }

    testWidgets('a phone in an unbundled language falls back to the country', (
      tester,
    ) async {
      final store = InMemoryLocaleStore();
      final controller = await loaded(tester, [
        const Locale('pt', 'BR'),
      ], store: store);
      expect(controller.locale, AppLocale.english);
      expect(controller.provenance, LocaleProvenance.unset);
      await controller.applyBirthCountryDefault('VN');
      expect(controller.locale, AppLocale.vietnamese);
      expect(controller.provenance, LocaleProvenance.automatic);
      expect(store.tag, 'vi');
    });

    for (final phone in [
      const Locale('zh', 'TW'),
      const Locale('zh', 'HK'),
      const Locale('zh', 'MO'),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      ),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    ]) {
      testWidgets(
        'a Traditional Chinese phone ($phone) never gets Simplified',
        (tester) async {
          final controller = await loaded(tester, [phone]);
          expect(controller.locale, AppLocale.english);
          expect(controller.provenance, LocaleProvenance.unset);
        },
      );
    }

    testWidgets('a Traditional phone moves on to its next bundled language', (
      tester,
    ) async {
      final controller = await loaded(tester, [
        const Locale('zh', 'TW'),
        const Locale('ja', 'JP'),
      ]);
      expect(controller.locale, AppLocale.japanese);
    });

    for (final phone in [
      const Locale('zh', 'CN'),
      const Locale('zh', 'SG'),
      const Locale('zh'),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'SG',
      ),
    ]) {
      testWidgets('a Simplified Chinese phone ($phone) gets Simplified', (
        tester,
      ) async {
        final controller = await loaded(tester, [phone]);
        expect(controller.locale, AppLocale.simplifiedChinese);
      });
    }

    testWidgets('through the real screens: a Korean phone born in the US', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = [const Locale('ko', 'KR')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        detectDeviceLocale: true,
      );
      await tester.pumpWidget(rig.app);
      await tester.pump();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('language_button_label')))
            .data,
        AppLocale.korean.nativeName,
      );
      await fillProfile(tester, countryCode: 'US', flag: usFlag);
      await completeProfile(tester);

      expect(rig.localeController.locale, AppLocale.korean);
      expect(rig.localeController.provenance, LocaleProvenance.device);
      expect(rig.localeStore.tag, isNull);
      expect(
        find.text(stringsFor(AppLocale.korean).findDirection),
        findsOneWidget,
      );
    });
  });
}

/// The profile step, already open, for a test that switched language first.
Future<void> fillProfileAfterLanguage(WidgetTester tester, String flag) async {
  await tester.ensureVisible(find.byKey(const Key('birth_date_value')));
  await tester.tap(find.byKey(const Key('birth_date_value')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('birth_date_type_tab')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('birth_date_day')), '01');
  await tester.enterText(find.byKey(const Key('birth_date_month')), '01');
  await tester.enterText(find.byKey(const Key('birth_date_year')), '2000');
  await tester.tap(find.byKey(const Key('birth_date_confirm')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('birth_country')));
  await tester.tap(find.byKey(const Key('birth_country')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, 'VN');
  await tester.pumpAndSettle();
  await tester.tap(find.text(flag).last);
  await tester.pumpAndSettle();
  await answerBirthTime(tester, null);
}
