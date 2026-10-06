import 'dart:async';

import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/daily_brief_provider.dart';
import 'package:decision_compass/data/locale_store.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/profile_edit_policy.dart';
import 'package:decision_compass/data/profile_repository.dart';
import 'package:decision_compass/localized_presentation.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:decision_compass/pages/profile_page.dart';
import 'package:decision_compass/reading_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// The Profile screen: what it shows, what it lets a reader correct, how long
/// it then holds those fields still, and what the rest of the app does with
/// the result.
void main() {
  const zone = 'Asia/Ho_Chi_Minh';

  /// The reader's wall clock. A `var` so a test can move it forward and watch
  /// a cooldown expire; the rig converts it to the UTC instant the page reads.
  late DateTime clock;

  setUp(() => clock = DateTime(2026, 9, 18, 8, 30));

  DateTime nowUtc() => utcForLocal(clock, zone);

  ReadingTestRig makeRig({
    bool failSaves = false,
    AppLocale? locale,
    InMemoryLocaleStore? localeStore,
  }) {
    final rig = ReadingTestRig(
      liveLocalClock: () => clock,
      locale: locale,
      localeStore: localeStore,
    );
    rig.profileRepository.failSaves = failSaves;
    return rig;
  }

  AppProfile profileWith({
    String? userName = 'Alex',
    String? birthTime = '14:30',
    String country = 'VN',
    DateTime? birthTimeChangedAtUtc,
    DateTime? birthCountryChangedAtUtc,
  }) => AppProfile(
    userName: userName,
    birthDate: DateTime(1998, 6, 21),
    birthTime: birthTime,
    birthCountryCode: country,
    zodiacSign: zodiacForDate(DateTime(1998, 6, 21)),
    useCurrentLocation: false,
    safetyAcknowledged: true,
    birthTimeChangedAtUtc: birthTimeChangedAtUtc,
    birthCountryChangedAtUtc: birthCountryChangedAtUtc,
  );

  /// What the Profile screen handed back when it closed.
  final result = <String, AppProfile?>{};
  var closed = 0;

  setUp(() {
    result.clear();
    closed = 0;
  });

  /// Pushes Profile onto a host route, so a pop has somewhere to go and its
  /// result can be read — which is how Home learns what was saved.
  Future<void> openProfile(
    WidgetTester tester, {
    required AppProfile profile,
    required ReadingDependencies dependencies,
    AppLocale locale = AppLocale.english,
  }) async {
    await tester.pumpWidget(
      localizedApp(
        locale: locale,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_profile'),
                onPressed: () async {
                  final saved = await Navigator.of(context).push<AppProfile>(
                    MaterialPageRoute<AppProfile>(
                      builder: (_) => ProfilePage(
                        profile: profile,
                        dependencies: dependencies,
                      ),
                    ),
                  );
                  closed++;
                  result['saved'] = saved;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_profile')));
    await tester.pumpAndSettle();
  }

  Future<void> pickTime(WidgetTester tester, TimeOfDay time) async {
    await tester.ensureVisible(find.byKey(const Key('profile_birth_time')));
    await tester.tap(find.byKey(const Key('profile_birth_time')));
    await tester.pumpAndSettle();
    await chooseTimeInDialog(tester, time);
    await tester.tap(find.byKey(const Key('birth_time_confirm')));
    await tester.pumpAndSettle();
  }

  Future<void> pickCountry(
    WidgetTester tester,
    String code,
    String flag,
  ) async {
    await tester.ensureVisible(find.byKey(const Key('profile_birth_country')));
    await tester.tap(find.byKey(const Key('profile_birth_country')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, code);
    await tester.pumpAndSettle();
    await tester.tap(find.text(flag).last);
    await tester.pumpAndSettle();
  }

  /// Taps Save and answers the confirmation when one appears.
  Future<void> save(WidgetTester tester, {bool confirm = true}) async {
    await tester.ensureVisible(find.byKey(const Key('profile_save')));
    await tester.tap(find.byKey(const Key('profile_save')));
    await tester.pumpAndSettle();
    if (find.byKey(const Key('profile_confirm_dialog')).evaluate().isNotEmpty) {
      await tester.tap(
        find.byKey(
          Key(confirm ? 'profile_confirm_save' : 'profile_confirm_cancel'),
        ),
      );
      await tester.pumpAndSettle();
    }
  }

  const japan = '\u{1F1EF}\u{1F1F5}';

  /// The rig's dependencies with one collaborator replaced, for the tests
  /// that need to hold a write or a brief open by hand.
  ReadingDependencies depsWith(
    ReadingTestRig rig, {
    ProfileRepository? profileRepository,
    DailyBriefProvider? dailyBriefProvider,
  }) => ReadingDependencies(
    repository: rig.repository,
    contextProvider: rig.contextProvider,
    historyRepository: rig.historyRepository,
    profileRepository: profileRepository ?? rig.profileRepository,
    dailyBriefProvider: dailyBriefProvider ?? rig.dailyBriefProvider,
    homeDescriptionDeck: rig.dependencies.homeDescriptionDeck,
    dailyEnergyInsights: rig.dependencies.dailyEnergyInsights,
    localeController: rig.localeController,
    nowUtc: rig.dependencies.nowUtc,
    nowLocal: rig.dependencies.nowLocal,
  );

  // -------------------------------------------------------------- display --

  group('what it shows', () {
    testWidgets('the saved profile, with the birth date read-only', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(),
        dependencies: rig.dependencies,
      );
      final l10n = stringsFor(AppLocale.english);

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('profile_name_field')))
            .controller!
            .text,
        'Alex',
      );
      expect(find.byKey(const Key('profile_birth_date_value')), findsOneWidget);
      expect(find.text('Jun 21, 1998'), findsOneWidget);
      expect(find.text(l10n.profileBirthDateFixed), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_time_value')))
            .data,
        formatClock('en', 14, 30),
      );
      expect(find.text('Vietnam'), findsOneWidget);

      // The birth date is the one row with nothing to tap.
      expect(
        tester.getSemantics(find.byKey(const Key('profile_birth_date_value'))),
        isNot(matchesSemantics(isButton: true)),
      );
    });

    testWidgets('an unknown birth time says Unknown, not an invented hour', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(birthTime: null),
        dependencies: rig.dependencies,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_time_value')))
            .data,
        stringsFor(AppLocale.english).profileBirthTimeUnknownValue,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('profile_knows_birth_time')),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('Save is dead until something actually differs', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(),
        dependencies: rig.dependencies,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile_save')))
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(const Key('profile_name_field')),
        'Alex Tran',
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile_save')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('every new string is translated, not an English fallback', (
      tester,
    ) async {
      for (final locale in AppLocale.values) {
        final l10n = stringsFor(locale);
        final en = stringsFor(AppLocale.english);
        if (locale == AppLocale.english) continue;
        for (final pair in <List<String>>[
          [l10n.profileTitle, en.profileTitle],
          [l10n.saveAction, en.saveAction],
          [l10n.cancelAction, en.cancelAction],
          [l10n.profileBirthDateFixed, en.profileBirthDateFixed],
          [l10n.profileSaved, en.profileSaved],
          [l10n.profileConfirmTitle, en.profileConfirmTitle],
          [l10n.profileConfirmBirthTime, en.profileConfirmBirthTime],
          [l10n.profileConfirmBirthCountry, en.profileConfirmBirthCountry],
          [l10n.profileBirthTimeUnknownValue, en.profileBirthTimeUnknownValue],
          [l10n.profileReadingsUnchanged, en.profileReadingsUnchanged],
          [l10n.openProfile, en.openProfile],
        ]) {
          expect(
            pair[0],
            isNot(pair[1]),
            reason: '${locale.tag} still shows the English string',
          );
        }
      }
    });
  });

  // ------------------------------------------------------------- the name --

  group('the name', () {
    testWidgets('changes without a confirmation and without a cooldown', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(),
        dependencies: rig.dependencies,
      );

      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Bo');
      await tester.pumpAndSettle();
      await save(tester);

      // No dialog: nothing is about to be held still.
      expect(find.byKey(const Key('profile_confirm_dialog')), findsNothing);
      expect(rig.profileRepository.saves, 1);
      final saved = result['saved']!;
      expect(saved.userName, 'Bo');
      expect(saved.birthTimeChangedAtUtc, isNull);
      expect(saved.birthCountryChangedAtUtc, isNull);
    });

    testWidgets('an empty name goes back to the default, not to its word', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(),
        dependencies: rig.dependencies,
      );

      await tester.enterText(
        find.byKey(const Key('profile_name_field')),
        '   ',
      );
      await tester.pumpAndSettle();
      await save(tester);

      final saved = result['saved']!;
      expect(saved.userName, isNull);
      expect(saved.hasDefaultName, isTrue);
      // Stored as an absence, so switching language later re-reads the
      // default rather than freezing one language's word for it.
      expect(saved.toJson().containsKey('userName'), isFalse);
    });
  });

  // -------------------------------------------------------- the birth time --

  group('the birth time', () {
    testWidgets('a reader who gave one may correct it straight away', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(birthTime: '14:30'),
        dependencies: rig.dependencies,
      );

      expect(find.byKey(const Key('profile_birth_time_wait')), findsNothing);
      await pickTime(tester, const TimeOfDay(hour: 9, minute: 15));
      await save(tester);

      final saved = result['saved']!;
      expect(saved.birthTime, '09:15');
      expect(saved.birthTimeChangedAtUtc, nowUtc());
      expect(saved.birthCountryChangedAtUtc, isNull);
    });

    testWidgets('a reader who said Unknown may add one straight away', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(birthTime: null),
        dependencies: rig.dependencies,
      );

      await tester.ensureVisible(
        find.byKey(const Key('profile_knows_birth_time')),
      );
      await tester.tap(find.byKey(const Key('profile_knows_birth_time')));
      await tester.pumpAndSettle();
      await pickTime(tester, const TimeOfDay(hour: 6, minute: 45));
      await save(tester);

      expect(result['saved']!.birthTime, '06:45');
      expect(result['saved']!.birthTimeChangedAtUtc, nowUtc());
    });

    testWidgets('a known time can be marked unknown again', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(birthTime: '14:30'),
        dependencies: rig.dependencies,
      );

      await tester.ensureVisible(
        find.byKey(const Key('profile_knows_birth_time')),
      );
      await tester.tap(find.byKey(const Key('profile_knows_birth_time')));
      await tester.pumpAndSettle();
      await save(tester);

      expect(result['saved']!.birthTime, isNull);
      expect(result['saved']!.birthTimeChangedAtUtc, nowUtc());
    });

    testWidgets('a second change is refused for two hours, and says for how '
        'long', (tester) async {
      final rig = makeRig();
      final changedAt = nowUtc().subtract(const Duration(minutes: 36));
      await openProfile(
        tester,
        profile: profileWith(birthTimeChangedAtUtc: changedAt),
        dependencies: rig.dependencies,
      );
      final l10n = stringsFor(AppLocale.english);

      // The remaining wait is on screen without having to tap anything.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_time_wait')))
            .data,
        l10n.profileBirthTimeLocked('1 hr 24 min'),
      );

      // Tapping the row explains itself rather than doing nothing.
      await tester.ensureVisible(find.byKey(const Key('profile_birth_time')));
      await tester.tap(find.byKey(const Key('profile_birth_time')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile_locked_notice')), findsOneWidget);
      expect(find.byKey(const Key('birth_time_confirm')), findsNothing);

      // So does the switch, which is the other way to change the answer.
      await tester.ensureVisible(
        find.byKey(const Key('profile_knows_birth_time')),
      );
      await tester.tap(find.byKey(const Key('profile_knows_birth_time')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('profile_knows_birth_time')),
            )
            .value,
        isTrue,
        reason: 'a locked switch must not flip',
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile_save')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('exactly two hours later it opens again', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(
          birthTimeChangedAtUtc: nowUtc().subtract(birthTimeEditCooldown),
        ),
        dependencies: rig.dependencies,
      );

      expect(find.byKey(const Key('profile_birth_time_wait')), findsNothing);
      await pickTime(tester, const TimeOfDay(hour: 7, minute: 5));
      await save(tester);
      expect(result['saved']!.birthTime, '07:05');
    });

    testWidgets('the wait runs out while the reader watches', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(
          birthTimeChangedAtUtc: nowUtc().subtract(
            birthTimeEditCooldown - const Duration(minutes: 2),
          ),
        ),
        dependencies: rig.dependencies,
      );
      expect(find.byKey(const Key('profile_birth_time_wait')), findsOneWidget);

      // The reader's own clock moves on; the screen's timer wakes it up.
      clock = clock.add(const Duration(minutes: 3));
      await tester.pump(const Duration(minutes: 3));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile_birth_time_wait')), findsNothing);
    });
  });

  // ----------------------------------------------------- the birth country --

  group('the country of birth', () {
    testWidgets('changes once immediately, then waits an hour', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(country: 'VN'),
        dependencies: rig.dependencies,
      );

      await pickCountry(tester, 'JP', japan);
      await save(tester);

      final saved = result['saved']!;
      expect(saved.birthCountryCode, 'JP');
      expect(saved.birthCountryChangedAtUtc, nowUtc());
      expect(saved.birthTimeChangedAtUtc, isNull);

      // And the write is what the next open would read.
      expect(
        (await rig.profileRepository.load())!.birthCountryChangedAtUtc,
        nowUtc(),
      );
    });

    testWidgets('a second change is refused for an hour, and says for how '
        'long', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(
          country: 'JP',
          birthCountryChangedAtUtc: nowUtc().subtract(
            const Duration(minutes: 18),
          ),
        ),
        dependencies: rig.dependencies,
      );

      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_country_wait')))
            .data,
        stringsFor(AppLocale.english).profileBirthCountryLocked('42 min'),
      );
      // Its own window, not the birth time's: that field is still open.
      expect(find.byKey(const Key('profile_birth_time_wait')), findsNothing);

      await tester.ensureVisible(
        find.byKey(const Key('profile_birth_country')),
      );
      await tester.tap(find.byKey(const Key('profile_birth_country')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile_locked_notice')), findsOneWidget);
      expect(find.text('Search countries'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile_save')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('changing it never changes the app language', (tester) async {
      // Vietnam maps to Vietnamese in the onboarding rule. Editing a profile
      // is not onboarding, and a reader reading in English stays in English.
      final store = InMemoryLocaleStore(tag: 'en', provenanceName: 'automatic');
      final rig = makeRig(locale: AppLocale.english, localeStore: store);
      await rig.localeController.ensureLoaded();
      final savesBefore = store.saves;
      final provenanceBefore = rig.localeController.provenance;

      await openProfile(
        tester,
        profile: profileWith(country: 'JP'),
        dependencies: rig.dependencies,
      );
      await pickCountry(tester, 'VN', '\u{1F1FB}\u{1F1F3}');
      await save(tester);

      expect(result['saved']!.birthCountryCode, 'VN');
      expect(rig.localeController.locale, AppLocale.english);
      expect(
        rig.localeController.provenance,
        provenanceBefore,
        reason: 'an edit must not re-decide how the language was chosen',
      );
      expect(store.tag, 'en');
      expect(store.saves, savesBefore);
    });
  });

  // --------------------------------------------------- cancelling and failing --

  group('nothing written, nothing started', () {
    testWidgets('cancelling a change leaves the profile and the clock alone', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(),
        dependencies: rig.dependencies,
      );

      await pickTime(tester, const TimeOfDay(hour: 9, minute: 15));
      await tester.tap(find.byKey(const Key('profile_cancel')));
      await tester.pumpAndSettle();

      expect(closed, 1);
      expect(result['saved'], isNull);
      expect(rig.profileRepository.saves, 0);
      expect(await rig.profileRepository.load(), isNull);
    });

    testWidgets('declining the confirmation saves nothing', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(),
        dependencies: rig.dependencies,
      );

      await pickCountry(tester, 'JP', japan);
      await save(tester, confirm: false);

      expect(rig.profileRepository.saves, 0);
      expect(closed, 0, reason: 'the screen stays open with the edit intact');
      expect(find.text('Japan'), findsOneWidget);
    });

    testWidgets('re-picking the time already stored is not a change', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(birthTime: '14:30'),
        dependencies: rig.dependencies,
      );

      await pickTime(tester, const TimeOfDay(hour: 14, minute: 30));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile_save')))
            .onPressed,
        isNull,
        reason: 'saving the same value would start a two-hour wait for nothing',
      );
    });

    testWidgets('a save that fails starts no cooldown and keeps the edit', (
      tester,
    ) async {
      final rig = makeRig(failSaves: true);
      await openProfile(
        tester,
        profile: profileWith(),
        dependencies: rig.dependencies,
      );

      await pickTime(tester, const TimeOfDay(hour: 9, minute: 15));
      await save(tester);

      expect(find.byKey(const Key('profile_save_failed')), findsOneWidget);
      expect(closed, 0);
      expect(rig.profileRepository.saves, 0);
      expect(await rig.profileRepository.load(), isNull);
      // The edit is still on screen, and so is a live Save to retry with.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_time_value')))
            .data,
        formatClock('en', 9, 15),
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile_save')))
            .onPressed,
        isNotNull,
      );

      // Retrying against a store that works writes it, with the cooldown
      // starting from the write and not from the first attempt.
      rig.profileRepository.failSaves = false;
      clock = clock.add(const Duration(minutes: 5));
      await save(tester);
      expect(result['saved']!.birthTimeChangedAtUtc, nowUtc());
    });
  });

  // ----------------------------------------------------------- persistence --

  testWidgets('a cooldown survives a restart', (tester) async {
    final rig = makeRig();
    await openProfile(
      tester,
      profile: profileWith(),
      dependencies: rig.dependencies,
    );
    await pickTime(tester, const TimeOfDay(hour: 9, minute: 15));
    await save(tester);

    // What a relaunch actually reads: the stored record, not the object that
    // was in memory.
    clock = clock.add(const Duration(minutes: 20));
    final reloaded = await rig.profileRepository.load();
    expect(reloaded, isNotNull);
    expect(reloaded!.birthTimeChangedAtUtc, isNotNull);

    final restarted = makeRig();
    await openProfile(
      tester,
      profile: AppProfile.fromJson(reloaded.toJson()),
      dependencies: restarted.dependencies,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('profile_birth_time_wait')))
          .data,
      stringsFor(AppLocale.english).profileBirthTimeLocked('1 hr 40 min'),
    );
  });

  // ------------------------------------------------------------------ Home --

  group('back on Home', () {
    Future<void> pumpHome(
      WidgetTester tester,
      ReadingTestRig rig,
      AppProfile profile,
    ) async {
      await tester.pumpWidget(
        localizedApp(
          home: HomePage(profile: profile, dependencies: rig.dependencies),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openFromHeader(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('home_open_profile')));
      await tester.pumpAndSettle();
    }

    testWidgets('the avatar and name open Profile', (tester) async {
      final rig = makeRig();
      await pumpHome(tester, rig, profileWith());

      final header = tester.getSemantics(
        find.byKey(const Key('home_open_profile')),
      );
      expect(header.label, stringsFor(AppLocale.english).openProfile);
      expect(
        header.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the header is reachable without a touch gesture',
      );

      await openFromHeader(tester);
      expect(find.byKey(const Key('profile_save')), findsOneWidget);
    });

    testWidgets('a rename reaches the greeting without a restart', (
      tester,
    ) async {
      final rig = makeRig();
      await pumpHome(tester, rig, profileWith(userName: 'Alex'));
      expect(find.text('Alex'), findsOneWidget);

      await openFromHeader(tester);
      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Bo');
      await tester.pumpAndSettle();
      await save(tester);

      // The header used to render the profile Home was constructed with, so
      // this is the assertion that catches that regression coming back.
      expect(find.text('Bo'), findsOneWidget);
      expect(find.text('Alex'), findsNothing);
    });

    testWidgets('a rename alone does not spend a calculation', (tester) async {
      final rig = makeRig();
      await pumpHome(tester, rig, profileWith());
      final before = rig.dailyBriefProvider.previewCalls;

      await openFromHeader(tester);
      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Bo');
      await tester.pumpAndSettle();
      await save(tester);

      expect(
        rig.dailyBriefProvider.previewCalls,
        before,
        reason: 'the engine reads nothing a rename touched',
      );
    });

    testWidgets('a new birth country redeals today\'s signals', (tester) async {
      final rig = makeRig();
      rig.dailyBriefProvider.responseFor = (profile) => engine.DailyBrief(
        colors: testDailyColors(),
        luckyNumber: profile.birthCountryCode == 'JP' ? 7 : 3,
        energy: null,
      );
      await pumpHome(tester, rig, profileWith(country: 'VN'));
      expect(find.text('3'), findsOneWidget);

      await openFromHeader(tester);
      await pickCountry(tester, 'JP', japan);
      await save(tester);

      expect(
        rig.dailyBriefProvider.profiles.last.birthCountryCode,
        'JP',
        reason: 'the preview was recomputed from the profile just saved',
      );
      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('a preview still in flight for the old profile is dropped', (
      tester,
    ) async {
      final scripted = _ScriptedBriefProvider();
      final rig = ReadingTestRig(liveLocalClock: () => clock);
      final dependencies = ReadingDependencies(
        repository: rig.repository,
        contextProvider: rig.contextProvider,
        historyRepository: rig.historyRepository,
        profileRepository: rig.profileRepository,
        dailyBriefProvider: scripted,
        homeDescriptionDeck: rig.dependencies.homeDescriptionDeck,
        dailyEnergyInsights: rig.dependencies.dailyEnergyInsights,
        localeController: rig.localeController,
        nowUtc: rig.dependencies.nowUtc,
        nowLocal: rig.dependencies.nowLocal,
      );

      await tester.pumpWidget(
        localizedApp(
          home: HomePage(
            profile: profileWith(country: 'VN'),
            dependencies: dependencies,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(scripted.pending, hasLength(1));

      await tester.tap(find.byKey(const Key('home_open_profile')));
      await tester.pumpAndSettle();
      await pickCountry(tester, 'JP', japan);
      await save(tester);
      expect(scripted.pending, hasLength(2));

      // The second preview lands first, then the first one finally answers —
      // with the number computed for the country the reader has just left.
      scripted.complete(1, 7);
      await tester.pumpAndSettle();
      scripted.complete(0, 3);
      await tester.pumpAndSettle();

      expect(
        find.text('7'),
        findsOneWidget,
        reason: 'a late answer for the old profile overwrote the new one',
      );
      expect(find.text('3'), findsNothing);
    });

    testWidgets('history is left exactly as it was', (tester) async {
      final rig = makeRig();
      final entry = historyEntryFor(fixtureResponse('ready_yes_no_now.json'));
      await rig.historyRepository.save(entry);
      final before = rig.historyRepository.saved.single;

      await pumpHome(tester, rig, profileWith(country: 'VN'));
      await openFromHeader(tester);
      await pickCountry(tester, 'JP', japan);
      await save(tester);

      expect(rig.historyRepository.saved, hasLength(1));
      final after = rig.historyRepository.saved.single;
      expect(identical(after, before), isTrue);
      // Not just the same object — the same values, read the way the History
      // screen reads them. A snapshot is the reading as it was answered, and
      // editing the profile it came from must not reach back into it.
      expect(after.reading.inputSnapshot.raw, before.reading.inputSnapshot.raw);
      expect(
        after.reading.percentages?.tenths,
        before.reading.percentages?.tenths,
      );
      expect(after.reading.winner, before.reading.winner);
    });
  });

  testWidgets('the next reading is calculated from the saved profile', (
    tester,
  ) async {
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
      liveLocalClock: () => clock,
    );
    await rig.profileRepository.save(profileWith(country: 'VN'));
    await tester.pumpWidget(rig.app);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_open_profile')));
    await tester.pumpAndSettle();
    await pickCountry(tester, 'JP', japan);
    await save(tester);

    await revealReading(tester);
    await tester.pumpAndSettle();

    expect(rig.sentRequest, isNotNull);
    expect(rig.sentRequest!.profile.birthCountry, 'JP');
    expect(
      rig.sentRequest!.profile.birthDate,
      '1998-06-21',
      reason: 'the birth date is not editable and must not have moved',
    );
  });

  // ------------------------------------------- adding a time from Unknown --

  group('from Unknown, through the row itself', () {
    testWidgets('confirming a time answers the switch as well', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(birthTime: null),
        dependencies: rig.dependencies,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('profile_knows_birth_time')),
            )
            .value,
        isFalse,
      );

      // Straight to the row, without touching the switch first. The row is
      // reachable in this state, so this is a path a reader will take.
      await pickTime(tester, const TimeOfDay(hour: 6, minute: 45));

      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('profile_knows_birth_time')),
            )
            .value,
        isTrue,
        reason: 'confirming an hour is the answer to "do you know it?"',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_time_value')))
            .data,
        formatClock('en', 6, 45),
      );

      await save(tester);
      expect(result['saved']!.birthTime, '06:45');
      expect(result['saved']!.birthTimeChangedAtUtc, nowUtc());
    });

    testWidgets('dismissing the picker leaves Unknown exactly as it was', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(birthTime: null),
        dependencies: rig.dependencies,
      );

      await tester.ensureVisible(find.byKey(const Key('profile_birth_time')));
      await tester.tap(find.byKey(const Key('profile_birth_time')));
      await tester.pumpAndSettle();
      // A choice made and then abandoned must not leak out of the sheet.
      await chooseTimeInDialog(tester, const TimeOfDay(hour: 6, minute: 45));
      await tester.tap(find.byKey(const Key('birth_time_cancel')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('profile_knows_birth_time')),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_time_value')))
            .data,
        stringsFor(AppLocale.english).profileBirthTimeUnknownValue,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile_save')))
            .onPressed,
        isNull,
        reason: 'a dismissal is not an edit, so there is nothing to save',
      );
      expect(rig.profileRepository.saves, 0);
    });

    testWidgets('while locked, neither the row nor the switch can add one', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(
          birthTime: null,
          birthTimeChangedAtUtc: nowUtc().subtract(const Duration(minutes: 36)),
        ),
        dependencies: rig.dependencies,
      );
      final l10n = stringsFor(AppLocale.english);

      await tester.ensureVisible(find.byKey(const Key('profile_birth_time')));
      await tester.tap(find.byKey(const Key('profile_birth_time')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('birth_time_sheet')),
        findsNothing,
        reason: 'the picker must not open at all while the field is held',
      );
      expect(find.byKey(const Key('profile_locked_notice')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_time_wait')))
            .data,
        l10n.profileBirthTimeLocked('1 hr 24 min'),
      );

      await tester.ensureVisible(
        find.byKey(const Key('profile_knows_birth_time')),
      );
      await tester.tap(find.byKey(const Key('profile_knows_birth_time')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('profile_knows_birth_time')),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_time_value')))
            .data,
        l10n.profileBirthTimeUnknownValue,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile_save')))
            .onPressed,
        isNull,
      );
    });
  });

  // ------------------------------------------------ Back during a save ----

  group('the Android Back button', () {
    testWidgets('leaves Profile before anything has been saved', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(),
        dependencies: rig.dependencies,
      );
      await pickTime(tester, const TimeOfDay(hour: 9, minute: 15));

      await simulateSystemBack();
      await tester.pumpAndSettle();

      expect(closed, 1);
      expect(result['saved'], isNull);
      expect(rig.profileRepository.saves, 0);
    });

    testWidgets('cannot pop the page out from under a save in flight', (
      tester,
    ) async {
      final repository = _PendingProfileRepository();
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(),
        dependencies: depsWith(rig, profileRepository: repository),
      );

      await pickTime(tester, const TimeOfDay(hour: 9, minute: 15));
      await save(tester);
      expect(repository.pending, hasLength(1));
      expect(closed, 0);

      // The race this guards: Back arrives while the write is still on its
      // way to storage. Popping here would leave the record written and Home
      // still holding the profile it was built with.
      await simulateSystemBack();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('profile_save')),
        findsOneWidget,
        reason: 'Profile was popped while its own save was still running',
      );
      expect(closed, 0);

      repository.finish();
      await tester.pumpAndSettle();

      expect(closed, 1, reason: 'the saved profile must arrive exactly once');
      expect(result['saved']!.birthTime, '09:15');
      expect(repository.written, hasLength(1));

      // And the back press that was refused is not replayed afterwards.
      await simulateSystemBack();
      await tester.pumpAndSettle();
      expect(closed, 1);
    });

    testWidgets('works again after a save that failed, with no cooldown '
        'started', (tester) async {
      final repository = _PendingProfileRepository();
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith(),
        dependencies: depsWith(rig, profileRepository: repository),
      );

      await pickTime(tester, const TimeOfDay(hour: 9, minute: 15));
      await save(tester);
      repository.refuse();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_save_failed')), findsOneWidget);
      expect(closed, 0);
      expect(repository.written, isEmpty);
      expect(await repository.load(), isNull);
      // The edit survives the failure.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_time_value')))
            .data,
        formatClock('en', 9, 15),
      );

      await simulateSystemBack();
      await tester.pumpAndSettle();
      expect(closed, 1);
      expect(
        result['saved'],
        isNull,
        reason: 'nothing was written, so Home has nothing to adopt',
      );
    });
  });

  // ----------------------------------------- Home while it recalculates ----

  group('Home while the new brief is still coming', () {
    testWidgets('does not show the old profile\'s signals under the new one', (
      tester,
    ) async {
      final scripted = _ScriptedBriefProvider();
      final rig = makeRig();
      await tester.pumpWidget(
        localizedApp(
          home: HomePage(
            profile: profileWith(country: 'VN'),
            dependencies: depsWith(rig, dailyBriefProvider: scripted),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The first brief has already landed, so these are real values on
      // screen — which is exactly the state that made the bug invisible.
      scripted.complete(0, 3);
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home_open_profile')));
      await tester.pumpAndSettle();
      await pickCountry(tester, 'JP', japan);
      await save(tester);

      expect(scripted.pending, hasLength(2));
      expect(
        find.text('3'),
        findsNothing,
        reason:
            "the previous profile's lucky number was still on screen under "
            'the new profile',
      );
      expect(find.text('—'), findsWidgets);

      scripted.complete(1, 7);
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('a rename leaves the signals showing and asks for nothing', (
      tester,
    ) async {
      final scripted = _ScriptedBriefProvider();
      final rig = makeRig();
      await tester.pumpWidget(
        localizedApp(
          home: HomePage(
            profile: profileWith(userName: 'Alex'),
            dependencies: depsWith(rig, dailyBriefProvider: scripted),
          ),
        ),
      );
      await tester.pumpAndSettle();
      scripted.complete(0, 3);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_open_profile')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Bo');
      await tester.pumpAndSettle();
      await save(tester);

      expect(scripted.pending, hasLength(1), reason: 'nothing was recomputed');
      expect(find.text('3'), findsOneWidget, reason: 'the signals blinked out');
      expect(find.text('Bo'), findsOneWidget);
    });
  });
}

/// A [DailyBriefProvider] whose answers are released by hand, so a test can
/// land them out of order.
class _ScriptedBriefProvider implements DailyBriefProvider {
  final pending = <Completer<engine.DailyBrief?>>[];

  @override
  Future<engine.DailyBrief?> preview(AppProfile profile) {
    final completer = Completer<engine.DailyBrief?>();
    pending.add(completer);
    return completer.future;
  }

  void complete(int index, int luckyNumber) {
    pending[index].complete(
      engine.DailyBrief(
        colors: testDailyColors(),
        luckyNumber: luckyNumber,
        energy: null,
      ),
    );
  }
}

/// A [ProfileRepository] whose writes finish only when a test says so.
///
/// The real one is a `shared_preferences` write that lands in microseconds,
/// which is fast enough to hide the window this is about rather than to prove
/// there is not one.
class _PendingProfileRepository implements ProfileRepository {
  final pending = <Completer<void>>[];

  /// Only the writes that actually completed.
  final written = <AppProfile>[];

  AppProfile? _stored;

  @override
  Future<void> save(AppProfile profile) {
    final completer = Completer<void>();
    pending.add(completer);
    return completer.future.then((_) {
      written.add(profile);
      _stored = profile;
    });
  }

  @override
  Future<AppProfile?> load() async => _stored;

  void finish([int index = 0]) => pending[index].complete();

  /// Fails the write the way a full or locked store would.
  void refuse([int index = 0]) => pending[index].completeError(
    StateError('the profile could not be written'),
  );
}
