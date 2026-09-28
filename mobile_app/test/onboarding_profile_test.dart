import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/localized_presentation.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// The two answers onboarding asks for that have a "no answer" state: the
/// reader's name, and whether they know their birth time.
void main() {
  AppProfile profileWith({String? userName, String? birthTime}) => AppProfile(
    userName: userName,
    birthDate: DateTime(1998, 6, 21),
    birthTime: birthTime,
    birthCountryCode: 'US',
    zodiacSign: ZodiacSign.cancer,
    useCurrentLocation: false,
  );

  /// Mounts onboarding on its own, on the profile step.
  Future<void> openProfileStep(
    WidgetTester tester, {
    AppProfile? initialProfile,
    AppLocale locale = AppLocale.english,
    ReadingTestRig? rig,
  }) async {
    final dependencies = (rig ?? ReadingTestRig(locale: locale)).dependencies;
    await tester.pumpWidget(
      localizedApp(
        locale: locale,
        home: OnboardingPage(
          dependencies: dependencies,
          initialProfile: initialProfile,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('the reader\'s name', () {
    test('a blank name is stored as a state, not as a word', () {
      final anonymous = profileWith();
      expect(anonymous.userName, isNull);
      expect(anonymous.hasDefaultName, isTrue);
      // The record says nothing about a name at all, rather than naming one
      // language's word for the default.
      expect(anonymous.toJson().containsKey('userName'), isFalse);
      expect(anonymous.toJson().toString(), isNot(contains('Explorer')));
    });

    test('a name the reader typed is stored exactly', () {
      final named = profileWith(userName: 'Linh');
      expect(named.hasDefaultName, isFalse);
      expect(named.toJson()['userName'], 'Linh');
      expect(AppProfile.fromJson(named.toJson()).userName, 'Linh');
    });

    test('the default resolves in whatever language is active', () {
      final anonymous = profileWith();
      final seen = <String>{};
      for (final locale in AppLocale.values) {
        final name = profileDisplayName(stringsFor(locale), anonymous);
        expect(name.trim(), isNotEmpty, reason: locale.tag);
        seen.add(name);
      }
      // Not the same word everywhere — it really is being translated.
      expect(seen.length, greaterThan(1));
      expect(
        profileDisplayName(stringsFor(AppLocale.english), anonymous),
        'Explorer',
      );
    });

    test('a typed name is never translated, in any language', () {
      final named = profileWith(userName: 'Explorer Jones');
      for (final locale in AppLocale.values) {
        expect(
          profileDisplayName(stringsFor(locale), named),
          'Explorer Jones',
          reason: locale.tag,
        );
      }
    });

    test('an older record that literally says Explorer keeps it', () {
      // Written before the default-name state existed. Guessing that this was
      // really a default would rename anyone who typed the word on purpose,
      // so a stored name is always taken at face value.
      final restored = AppProfile.fromJson(const {
        'userName': 'Explorer',
        'birthDate': '1998-06-21',
        'birthCountryCode': 'US',
        'useCurrentLocation': false,
        'safetyAcknowledged': true,
      });
      expect(restored.userName, 'Explorer');
      expect(restored.hasDefaultName, isFalse);
      expect(
        profileDisplayName(stringsFor(AppLocale.thai), restored),
        'Explorer',
      );
    });

    testWidgets('leaving it blank greets in the language of the moment', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await tester.pump();

      expect(find.text(rig.strings.defaultUserName), findsOneWidget);
      // Nothing was written to storage under a name.
      final saved = await rig.profileRepository.load();
      expect(saved!.userName, isNull);

      await switchLanguage(tester, AppLocale.japanese);
      final ja = stringsFor(AppLocale.japanese);
      expect(find.text(ja.defaultUserName), findsOneWidget);
      expect(find.text(rig.strings.defaultUserName), findsNothing);
      // The switch changed the greeting, not the stored profile.
      expect((await rig.profileRepository.load())!.userName, isNull);
    });

    testWidgets('and survives a restart in the language chosen then', (
      tester,
    ) async {
      final first = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(first.app);
      await completeOnboarding(tester);
      await tester.pump();
      await switchLanguage(tester, AppLocale.vietnamese);

      // A new app over the same storage is what a cold start is.
      await tester.pumpWidget(const SizedBox.shrink());
      final restarted = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localeStore: first.localeStore,
      );
      await restarted.profileRepository.save(
        (await first.profileRepository.load())!,
      );
      await tester.pumpWidget(restarted.app);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text(stringsFor(AppLocale.vietnamese).defaultUserName),
        findsOneWidget,
      );
    });

    testWidgets('a typed name is greeted as typed after a switch', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await tester.pump();
      await tester.tap(find.byKey(const Key('continue_to_profile')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('name_field')), 'Aroon');
      await tester.pumpAndSettle();
      await fillDateAndCountry(tester);
      await answerBirthTime(tester, null);
      await completeProfileStep(tester);

      expect(find.text('Aroon'), findsOneWidget);
      expect((await rig.profileRepository.load())!.userName, 'Aroon');

      await switchLanguage(tester, AppLocale.thai);
      expect(find.text('Aroon'), findsOneWidget);
      expect(
        find.text(stringsFor(AppLocale.thai).defaultUserName),
        findsNothing,
      );
    });
  });

  group('the birth-time control', () {
    testWidgets('is on for a new profile, with nothing filled in', (
      tester,
    ) async {
      await openProfileStep(tester);

      final control = tester.widget<SwitchListTile>(
        find.byKey(const Key('knows_birth_time')),
      );
      expect(control.value, isTrue);
      // Stated affirmatively, so the reader is agreeing with it rather than
      // turning off a negative.
      expect(
        find.text(stringsFor(AppLocale.english).knowBirthTime),
        findsOneWidget,
      );

      // The picker is already open for business, and shows a prompt rather
      // than a plausible-looking hour nobody chose.
      expect(find.byKey(const Key('birth_time_picker')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('birth_time_value'))).data,
        stringsFor(AppLocale.english).selectBirthTime,
      );
      for (final invented in ['00:00', '12:00', '12:00 AM', '2:30 PM']) {
        expect(find.textContaining(invented), findsNothing, reason: invented);
      }
    });

    testWidgets('blocks Continue while it is on and no time is chosen', (
      tester,
    ) async {
      final rig = ReadingTestRig();
      await openProfileStep(tester, rig: rig);
      await fillDateAndCountry(tester);

      await tester.ensureVisible(find.byKey(const Key('complete_profile')));
      await tester.tap(find.byKey(const Key('complete_profile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('birth_time_required')), findsOneWidget);
      expect(
        find.text(stringsFor(AppLocale.english).birthTimeRequired),
        findsOneWidget,
      );
      // Still on the profile step, and nothing was saved.
      expect(find.byKey(const Key('complete_profile')), findsOneWidget);
      expect(await rig.profileRepository.load(), isNull);
    });

    testWidgets('says so in the reader\'s language', (tester) async {
      final rig = ReadingTestRig(locale: AppLocale.hindi);
      await openProfileStep(tester, rig: rig, locale: AppLocale.hindi);
      await fillDateAndCountry(tester);
      await tester.ensureVisible(find.byKey(const Key('complete_profile')));
      await tester.tap(find.byKey(const Key('complete_profile')));
      await tester.pumpAndSettle();

      expect(
        find.text(stringsFor(AppLocale.hindi).birthTimeRequired),
        findsOneWidget,
      );
      expect(
        find.text(stringsFor(AppLocale.english).birthTimeRequired),
        findsNothing,
      );
    });

    testWidgets('passes a chosen time through as HH:mm', (tester) async {
      final rig = ReadingTestRig();
      await openProfileStep(tester, rig: rig);
      await fillDateAndCountry(tester);
      await pickBirthTime(tester, const TimeOfDay(hour: 9, minute: 5));

      expect(
        tester.widget<Text>(find.byKey(const Key('birth_time_value'))).data,
        isNot(stringsFor(AppLocale.english).selectBirthTime),
      );
      await completeProfileStep(tester);

      final saved = await rig.profileRepository.load();
      expect(saved!.birthTime, '09:05');
    });

    testWidgets('turning it off continues with an unknown birth time', (
      tester,
    ) async {
      final rig = ReadingTestRig();
      await openProfileStep(tester, rig: rig);
      await fillDateAndCountry(tester);

      await tester.ensureVisible(find.byKey(const Key('knows_birth_time')));
      await tester.tap(find.byKey(const Key('knows_birth_time')));
      await tester.pumpAndSettle();

      // The picker goes away, and so does the prompt to answer it.
      expect(find.byKey(const Key('birth_time_picker')), findsNothing);
      expect(
        find.text(stringsFor(AppLocale.english).birthTimeUnknownDetail),
        findsOneWidget,
      );

      await completeProfileStep(tester);
      final saved = await rig.profileRepository.load();
      // Null is what puts the reading on the unknown-birth-hour path.
      expect(saved!.birthTime, isNull);
      expect(saved.toBirthProfile().birthTime, isNull);
      expect(saved.toBirthProfile().toJson().containsKey('birthTime'), isFalse);
    });

    testWidgets('turning it back on asks again rather than restoring', (
      tester,
    ) async {
      final rig = ReadingTestRig();
      await openProfileStep(tester, rig: rig);
      await fillDateAndCountry(tester);
      await pickBirthTime(tester, const TimeOfDay(hour: 9, minute: 5));

      final control = find.byKey(const Key('knows_birth_time'));
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();

      // Back on, and back to an unanswered question — not the earlier time,
      // and not an invented one.
      expect(
        tester.widget<Text>(find.byKey(const Key('birth_time_value'))).data,
        stringsFor(AppLocale.english).selectBirthTime,
      );
      await tester.ensureVisible(find.byKey(const Key('complete_profile')));
      await tester.tap(find.byKey(const Key('complete_profile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('birth_time_required')), findsOneWidget);
      expect(await rig.profileRepository.load(), isNull);
    });

    testWidgets('an existing profile that knew its time reopens knowing it', (
      tester,
    ) async {
      await openProfileStep(
        tester,
        initialProfile: profileWith(userName: 'Linh', birthTime: '09:05'),
      );

      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('knows_birth_time')))
            .value,
        isTrue,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('birth_time_value'))).data,
        isNot(stringsFor(AppLocale.english).selectBirthTime),
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('name_field')))
            .controller
            ?.text,
        'Linh',
      );
    });

    testWidgets('an existing profile that did not know its time stays off', (
      tester,
    ) async {
      await openProfileStep(
        tester,
        initialProfile: profileWith(birthTime: null),
      );

      // Not reset to on: that would either block the reader on a screen they
      // have already answered, or invite them to invent an hour.
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('knows_birth_time')))
            .value,
        isFalse,
      );
      expect(find.byKey(const Key('birth_time_picker')), findsNothing);
    });

    testWidgets('a stored time that cannot be read is treated as unknown', (
      tester,
    ) async {
      await openProfileStep(
        tester,
        initialProfile: profileWith(birthTime: 'half past nine'),
      );

      // The control is on, because the record says the time was known, but
      // nothing unreadable is repaired into a plausible hour.
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('knows_birth_time')))
            .value,
        isTrue,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('birth_time_value'))).data,
        stringsFor(AppLocale.english).selectBirthTime,
      );
    });
  });
}
