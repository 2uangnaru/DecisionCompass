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
import 'package:decision_compass/widgets/celestial_ui.dart';
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
    bool reducedMotion = false,
  }) async {
    // A test that opens Profile twice has to leave the first one first:
    // `pumpWidget` reuses a structurally identical tree, so a Profile route
    // still on the navigator would hide the button this taps.
    if (find.byKey(const Key('profile_cancel')).evaluate().isNotEmpty) {
      await tester.ensureVisible(find.byKey(const Key('profile_cancel')));
      await tester.tap(find.byKey(const Key('profile_cancel')));
      await tester.pumpAndSettle();
    }
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
                      // Wrapped around the page rather than around `home`: a
                      // pushed route is built under the Navigator, which is
                      // itself under `home`, so an override up there never
                      // reaches it.
                      builder: (_) => MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(disableAnimations: reducedMotion),
                        child: ProfilePage(
                          profile: profile,
                          dependencies: dependencies,
                        ),
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

  Future<void> pickDate(
    WidgetTester tester, {
    required String day,
    required String month,
    required String year,
  }) async {
    await tester.ensureVisible(find.byKey(const Key('profile_birth_date')));
    await tester.tap(find.byKey(const Key('profile_birth_date')));
    await tester.pumpAndSettle();
    // Typed rather than spun: the wheels' resting position is the picker's
    // business, and these tests are about what the date does afterwards.
    await tester.tap(find.byKey(const Key('birth_date_type_tab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('birth_date_day')), day);
    await tester.enterText(find.byKey(const Key('birth_date_month')), month);
    await tester.enterText(find.byKey(const Key('birth_date_year')), year);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
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
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_time_value')))
            .data,
        formatClock('en', 14, 30),
      );
      expect(find.text('Vietnam'), findsOneWidget);

      // Every one of the three is a control, including the birth date — it
      // used to be the one row with nothing to tap.
      for (final key in const [
        'profile_birth_date',
        'profile_birth_time',
        'profile_birth_country',
      ]) {
        expect(
          tester
              .getSemantics(find.byKey(Key(key)))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$key cannot be opened',
        );
      }
      // This profile has no stamps and no createdAt, so nothing is held.
      expect(find.byKey(const Key('profile_birth_date_wait')), findsNothing);
      expect(l10n.profileTitle, isNotEmpty);
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
          [l10n.profileBirthDateLocked('x'), en.profileBirthDateLocked('x')],
          [l10n.profileConfirmBirthDate, en.profileConfirmBirthDate],
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

  // ---------------------------------------------------------- birth date --

  group('the birth date', () {
    /// A legacy profile: no `createdAt`, never edited, so the first change is
    /// allowed straight away.
    AppProfile legacy() => profileWith().copyWith(createdAt: null);

    testWidgets('a legacy profile may fix it immediately', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: legacy(),
        dependencies: rig.dependencies,
      );

      expect(find.byKey(const Key('profile_birth_date_wait')), findsNothing);
      await pickDate(tester, day: '10', month: '03', year: '1998');
      await save(tester);

      final saved = result['saved']!;
      expect(saved.birthDate.year, 1998);
      expect(saved.birthDate.month, 3);
      expect(saved.birthDate.day, 10);
      expect(saved.birthDateChangedAtUtc, nowUtc());
      // The other two are untouched, which is what independent means.
      expect(saved.birthTimeChangedAtUtc, isNull);
      expect(saved.birthCountryChangedAtUtc, isNull);
    });

    testWidgets('the avatar follows the picker before the reader commits', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: legacy(),
        dependencies: rig.dependencies,
      );
      final l10n = stringsFor(AppLocale.english);
      final before = zodiacForDate(DateTime(1998, 6, 21));
      expect(find.text(zodiacLabel(l10n, before)), findsOneWidget);

      await pickDate(tester, day: '10', month: '03', year: '1998');

      final after = zodiacForDate(DateTime(1998, 3, 10));
      expect(after, isNot(before));
      expect(find.text(zodiacLabel(l10n, after)), findsOneWidget);
      expect(find.text(zodiacLabel(l10n, before)), findsNothing);
      expect(
        tester.widget<ZodiacAvatar>(find.byType(ZodiacAvatar).first).sign,
        after,
      );
      // Still only a preview: nothing is written until Save.
      expect(rig.profileRepository.saves, 0);
    });

    testWidgets('a new profile waits two hours, then opens', (tester) async {
      final rig = makeRig();
      final created = nowUtc().subtract(const Duration(minutes: 97));
      await openProfile(
        tester,
        profile: profileWith().copyWith(createdAt: created),
        dependencies: rig.dependencies,
      );
      final l10n = stringsFor(AppLocale.english);

      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_date_wait')))
            .data,
        l10n.profileBirthDateLocked('23 min'),
      );
      await tester.ensureVisible(find.byKey(const Key('profile_birth_date')));
      await tester.tap(find.byKey(const Key('profile_birth_date')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('birth_date_sheet')),
        findsNothing,
        reason: 'the picker must not open while the date is held',
      );
      expect(find.byKey(const Key('profile_locked_notice')), findsOneWidget);

      // Exactly at the two hours, from a profile created that long ago.
      await openProfile(
        tester,
        profile: profileWith().copyWith(
          createdAt: nowUtc().subtract(birthDateFirstEditDelay),
        ),
        dependencies: rig.dependencies,
      );
      expect(find.byKey(const Key('profile_birth_date_wait')), findsNothing);
      await pickDate(tester, day: '10', month: '03', year: '1998');
      await save(tester);
      expect(result['saved']!.birthDate.month, 3);
    });

    testWidgets('a second change waits four hours from that change', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: legacy().copyWith(
          birthDateChangedAtUtc: nowUtc().subtract(
            const Duration(hours: 1, minutes: 12),
          ),
        ),
        dependencies: rig.dependencies,
      );

      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_date_wait')))
            .data,
        stringsFor(AppLocale.english).profileBirthDateLocked('2 hr 48 min'),
      );
      // The other two fields are untouched by it.
      expect(find.byKey(const Key('profile_birth_time_wait')), findsNothing);
      expect(find.byKey(const Key('profile_birth_country_wait')), findsNothing);

      // And exactly four hours after that change it is open again.
      await openProfile(
        tester,
        profile: legacy().copyWith(
          birthDateChangedAtUtc: nowUtc().subtract(birthDateEditCooldown),
        ),
        dependencies: rig.dependencies,
      );
      expect(find.byKey(const Key('profile_birth_date_wait')), findsNothing);
    });

    testWidgets('editing it again restarts the whole four hours', (
      tester,
    ) async {
      final rig = makeRig();
      // Four hours and a minute since the last change: open, but only just.
      await openProfile(
        tester,
        profile: legacy().copyWith(
          birthDateChangedAtUtc: nowUtc().subtract(
            birthDateEditCooldown + const Duration(minutes: 1),
          ),
        ),
        dependencies: rig.dependencies,
      );
      await pickDate(tester, day: '10', month: '03', year: '1998');
      await save(tester);

      final saved = result['saved']!;
      expect(saved.birthDateChangedAtUtc, nowUtc());
      // Re-opened with what was written, the full window is back.
      await openProfile(tester, profile: saved, dependencies: rig.dependencies);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_date_wait')))
            .data,
        stringsFor(AppLocale.english).profileBirthDateLocked('4 hr 0 min'),
      );
    });

    testWidgets('the wait runs out while the reader watches', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: profileWith().copyWith(
          createdAt: nowUtc().subtract(
            birthDateFirstEditDelay - const Duration(minutes: 2),
          ),
        ),
        dependencies: rig.dependencies,
      );
      expect(find.byKey(const Key('profile_birth_date_wait')), findsOneWidget);

      clock = clock.add(const Duration(minutes: 3));
      await tester.pump(const Duration(minutes: 3));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile_birth_date_wait')), findsNothing);
    });

    testWidgets('re-picking the same day is not a change', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: legacy(),
        dependencies: rig.dependencies,
      );

      await pickDate(tester, day: '21', month: '06', year: '1998');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile_save')))
            .onPressed,
        isNull,
        reason:
            'saving the same birthday would start four hours of waiting for '
            'nothing',
      );
    });

    testWidgets('a dismissed picker, a declined confirmation and a refused '
        'write all leave it alone', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: legacy(),
        dependencies: rig.dependencies,
      );

      // Dismissed.
      await tester.ensureVisible(find.byKey(const Key('profile_birth_date')));
      await tester.tap(find.byKey(const Key('profile_birth_date')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('birth_date_type_tab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('birth_date_day')), '10');
      await tester.enterText(find.byKey(const Key('birth_date_month')), '03');
      await tester.enterText(find.byKey(const Key('birth_date_year')), '1998');
      await tester.tap(find.byKey(const Key('birth_date_cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Jun 21, 1998'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile_save')))
            .onPressed,
        isNull,
      );

      // Declined at the confirmation.
      await pickDate(tester, day: '10', month: '03', year: '1998');
      await save(tester, confirm: false);
      expect(rig.profileRepository.saves, 0);
      expect(closed, 0);

      // Refused by the store.
      rig.profileRepository.failSaves = true;
      await save(tester);
      expect(find.byKey(const Key('profile_save_failed')), findsOneWidget);
      expect(rig.profileRepository.saves, 0);
      expect(await rig.profileRepository.load(), isNull);
      expect(closed, 0);
    });

    testWidgets('the lock survives a restart', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: legacy(),
        dependencies: rig.dependencies,
      );
      await pickDate(tester, day: '10', month: '03', year: '1998');
      await save(tester);

      clock = clock.add(const Duration(minutes: 30));
      final reloaded = await rig.profileRepository.load();
      expect(reloaded!.birthDateChangedAtUtc, isNotNull);

      final restarted = makeRig();
      await openProfile(
        tester,
        profile: AppProfile.fromJson(reloaded.toJson()),
        dependencies: restarted.dependencies,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('profile_birth_date_wait')))
            .data,
        stringsFor(AppLocale.english).profileBirthDateLocked('3 hr 30 min'),
      );
    });

    testWidgets('all three at once each start their own wait, and the '
        'confirmation names each one', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: legacy(),
        dependencies: rig.dependencies,
      );
      final l10n = stringsFor(AppLocale.english);

      await pickDate(tester, day: '10', month: '03', year: '1998');
      await pickTime(tester, const TimeOfDay(hour: 9, minute: 15));
      await pickCountry(tester, 'JP', japan);

      await tester.ensureVisible(find.byKey(const Key('profile_save')));
      await tester.tap(find.byKey(const Key('profile_save')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.profileConfirmBirthDate), findsOneWidget);
      expect(find.text(l10n.profileConfirmBirthTime), findsOneWidget);
      expect(find.text(l10n.profileConfirmBirthCountry), findsOneWidget);
      // The row is still a row, with three lines above it.
      final cancel = tester.getRect(
        find.byKey(const Key('profile_confirm_cancel')),
      );
      final confirmSave = tester.getRect(
        find.byKey(const Key('profile_confirm_save')),
      );
      expect(
        cancel.center.dy,
        moreOrLessEquals(confirmSave.center.dy, epsilon: 0.5),
      );
      expect(cancel.right, lessThanOrEqualTo(confirmSave.left));

      await tester.tap(find.byKey(const Key('profile_confirm_save')));
      await tester.pumpAndSettle();

      final saved = result['saved']!;
      expect(saved.birthDateChangedAtUtc, nowUtc());
      expect(saved.birthTimeChangedAtUtc, nowUtc());
      expect(saved.birthCountryChangedAtUtc, nowUtc());
    });

    testWidgets('a name-only save moves no stamp, including the date one', (
      tester,
    ) async {
      final rig = makeRig();
      final seeded = legacy().copyWith(
        birthDateChangedAtUtc: nowUtc().subtract(const Duration(hours: 9)),
      );
      await openProfile(
        tester,
        profile: seeded,
        dependencies: rig.dependencies,
      );

      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Bo');
      await tester.pumpAndSettle();
      await save(tester);

      expect(find.byKey(const Key('profile_confirm_dialog')), findsNothing);
      expect(
        result['saved']!.birthDateChangedAtUtc,
        seeded.birthDateChangedAtUtc,
      );
    });
  });

  // ---------------------------------------------- a new date, seen from Home --

  group('a new birth date, back on Home', () {
    testWidgets('changes the avatar, the signals and the next reading, and '
        'leaves History alone', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        liveLocalClock: () => clock,
      );
      rig.dailyBriefProvider.responseFor = (profile) => engine.DailyBrief(
        colors: testDailyColors(),
        luckyNumber: profile.birthDate.month == 3 ? 7 : 3,
        energy: null,
      );
      final entry = historyEntryFor(fixtureResponse('ready_yes_no_now.json'));
      await rig.historyRepository.save(entry);
      final historyBefore = rig.historyRepository.saved.single;

      await rig.profileRepository.save(profileWith().copyWith(createdAt: null));
      await tester.pumpWidget(rig.app);
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
      final before = zodiacForDate(DateTime(1998, 6, 21));

      await tester.tap(find.byKey(const Key('home_open_profile')));
      await tester.pumpAndSettle();
      await pickDate(tester, day: '10', month: '03', year: '1998');
      await save(tester);

      // The header avatar is the new sign, without a restart.
      final after = zodiacForDate(DateTime(1998, 3, 10));
      expect(after, isNot(before));
      expect(
        tester.widget<ZodiacAvatar>(find.byType(ZodiacAvatar).first).sign,
        after,
      );
      // Today's signals were redealt from the saved profile.
      expect(rig.dailyBriefProvider.profiles.last.birthDate.month, 3);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsNothing);

      // And the next reading is calculated from the new date.
      await revealReading(tester);
      await tester.pumpAndSettle();
      expect(rig.sentRequest!.profile.birthDate, '1998-03-10');

      // The reading already in History is the reading it always was.
      expect(rig.historyRepository.saved, hasLength(2));
      final historyAfter = rig.historyRepository.saved.first;
      expect(identical(historyAfter, historyBefore), isTrue);
      expect(
        historyAfter.reading.inputSnapshot.raw,
        historyBefore.reading.inputSnapshot.raw,
      );
    });
  });

  // ------------------------------------------------- the locked-field notice --

  group('the locked-field notice', () {
    /// Both the date and the time held, so there are two different sentences
    /// to tell apart.
    AppProfile heldProfile() =>
        profileWith(
          birthTimeChangedAtUtc: nowUtc().subtract(const Duration(minutes: 36)),
        ).copyWith(
          createdAt: null,
          birthDateChangedAtUtc: nowUtc().subtract(const Duration(minutes: 12)),
        );

    Finder notice() => find.byKey(const Key('profile_locked_notice'));

    Future<void> tapLocked(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
    }

    testWidgets('ten rapid taps make one notice, and nothing arrives later', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: heldProfile(),
        dependencies: rig.dependencies,
      );

      for (var i = 0; i < 10; i++) {
        await tapLocked(tester, 'profile_birth_date');
      }
      await tester.pumpAndSettle();

      expect(notice(), findsOneWidget, reason: 'ten taps, ten notices');
      // Not the messenger's queue, which is where the ten came from.
      expect(find.byType(SnackBar), findsNothing);

      // It goes by itself...
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(notice(), findsNothing);

      // ...and nothing follows it out of a queue, however long the reader
      // waits. This is the half the old behaviour failed: the notices kept
      // coming up over Cancel and Save long after the tapping stopped.
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      expect(notice(), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a different held field replaces the sentence at once', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: heldProfile(),
        dependencies: rig.dependencies,
      );
      final l10n = stringsFor(AppLocale.english);
      final dateMessage = l10n.profileBirthDateLocked('3 hr 48 min');
      final timeMessage = l10n.profileBirthTimeLocked('1 hr 24 min');

      await tapLocked(tester, 'profile_birth_date');
      await tester.pumpAndSettle();
      expect(tester.getSemantics(notice()).label, dateMessage);

      // Straight to the other one, with no wait in between.
      await tapLocked(tester, 'profile_birth_time');
      await tester.pumpAndSettle();
      expect(notice(), findsOneWidget, reason: 'the first one was queued');
      expect(tester.getSemantics(notice()).label, timeMessage);
      // Scoped to the banner: the same sentence is also the standing label
      // under the date row, and that one is supposed to stay.
      expect(
        find.descendant(of: notice(), matching: find.text(dateMessage)),
        findsNothing,
      );
      expect(
        find.descendant(of: notice(), matching: find.text(timeMessage)),
        findsOneWidget,
      );

      // And the replacement does not leave the first one waiting to return.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(notice(), findsNothing);
    });

    testWidgets('a tap after it has gone brings a new one', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: heldProfile(),
        dependencies: rig.dependencies,
      );

      await tapLocked(tester, 'profile_birth_date');
      await tester.pumpAndSettle();
      expect(notice(), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(notice(), findsNothing);

      await tapLocked(tester, 'profile_birth_date');
      await tester.pumpAndSettle();
      expect(
        notice(),
        findsOneWidget,
        reason: 'the field is still held, so asking again must still answer',
      );
    });

    testWidgets('it covers neither the Back control nor Cancel and Save', (
      tester,
    ) async {
      useScreen(tester, size: const Size(360, 640));
      final rig = makeRig();
      await openProfile(
        tester,
        profile: heldProfile(),
        dependencies: rig.dependencies,
      );

      await tapLocked(tester, 'profile_birth_date');
      await tester.pumpAndSettle();

      final box = tester.getRect(notice());
      expect(box.top, greaterThanOrEqualTo(0), reason: 'off the top edge');
      expect(
        box.top,
        lessThan(640 / 2),
        reason: 'the notice is meant to be near the top',
      );

      // Below the Back row, which is pinned above the scrolling area — so
      // this holds at every scroll offset, not just this one.
      final back = tester.getRect(find.byKey(const Key('profile_back')));
      expect(
        box.top,
        greaterThanOrEqualTo(back.bottom),
        reason: 'the notice sits over the Back control',
      );
      // And close under it rather than somewhere down the page.
      expect(box.top - back.bottom, lessThan(24));

      // Scrolled to the bottom, where Cancel and Save are, it still does not
      // reach them.
      await tester.ensureVisible(find.byKey(const Key('profile_save')));
      await tester.pumpAndSettle();
      for (final key in const ['profile_cancel', 'profile_save']) {
        final button = tester.getRect(find.byKey(Key(key)));
        expect(
          tester.getRect(notice()).overlaps(button),
          isFalse,
          reason: 'the notice covers $key once the page is scrolled down',
        );
      }
      // The notice has not moved while the page scrolled underneath it.
      expect(tester.getRect(notice()), box);
    });

    testWidgets('nothing on the page moves when it comes or goes', (
      tester,
    ) async {
      useScreen(tester, size: const Size(360, 640));
      final rig = makeRig();
      await openProfile(
        tester,
        profile: heldProfile(),
        dependencies: rig.dependencies,
      );

      // Scrolled away from the top, so a real scroll offset is in play —
      // and settled *before* anything is measured, because `ensureVisible`
      // moves the page itself and that is not what this test is about.
      await tester.ensureVisible(find.byKey(const Key('profile_birth_date')));
      await tester.pumpAndSettle();

      Rect rectOf(Finder finder) => tester.getRect(finder);
      double scrollOffset() => tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;

      final watched = <String, Finder>{
        'the Back row': find.byKey(const Key('profile_back')),
        'the avatar': find.byType(ZodiacAvatar).first,
        'the name field': find.byKey(const Key('profile_name_field')),
        'the birth-date row': find.byKey(const Key('profile_birth_date')),
        'Save': find.byKey(const Key('profile_save')),
      };
      final before = {
        for (final entry in watched.entries) entry.key: rectOf(entry.value),
      };
      final offsetBefore = scrollOffset();

      // Tapped where it already is: no `ensureVisible`, so any movement
      // measured below is the notice's doing and nobody else's.
      await tester.tap(find.byKey(const Key('profile_birth_date')));
      await tester.pumpAndSettle();
      expect(notice(), findsOneWidget);

      before.forEach((name, rect) {
        expect(
          rectOf(watched[name]!),
          rect,
          reason: '$name moved when the notice arrived',
        );
      });
      expect(scrollOffset(), offsetBefore, reason: 'the page scrolled itself');

      // ...and nothing moves back when it leaves, either.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(notice(), findsNothing);
      before.forEach((name, rect) {
        expect(
          rectOf(watched[name]!),
          rect,
          reason: '$name moved when the notice left',
        );
      });
      expect(scrollOffset(), offsetBefore);
    });

    testWidgets('it slides in from the left as it fades up, and fades out '
        'where it is', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: heldProfile(),
        dependencies: rig.dependencies,
      );

      double opacity() => tester
          .widget<FadeTransition>(
            find
                .ancestor(of: notice(), matching: find.byType(FadeTransition))
                .first,
          )
          .opacity
          .value;

      await tapLocked(tester, 'profile_birth_date');
      await tester.pump(const Duration(milliseconds: 80));
      final arriving = tester.getRect(notice());
      final arrivingOpacity = opacity();
      expect(arrivingOpacity, greaterThan(0));
      expect(arrivingOpacity, lessThan(1), reason: 'it appeared at full');

      await tester.pumpAndSettle();
      final settled = tester.getRect(notice());
      expect(opacity(), 1);
      expect(
        arriving.left,
        lessThan(settled.left),
        reason: 'it did not travel in from the left',
      );
      expect(
        arriving.top,
        settled.top,
        reason: 'it moved vertically; this is meant to be a horizontal slide',
      );

      // On the way out it fades where it is rather than retreating left.
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 120));
      expect(opacity(), lessThan(1));
      expect(opacity(), greaterThan(0));
      expect(
        tester.getRect(notice()).left,
        settled.left,
        reason: 'it slid back out instead of fading',
      );

      await tester.pumpAndSettle();
      expect(notice(), findsNothing);
    });

    testWidgets('with animations off it simply appears and disappears', (
      tester,
    ) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: heldProfile(),
        dependencies: rig.dependencies,
        reducedMotion: true,
      );

      await tapLocked(tester, 'profile_birth_date');
      // One frame, no settling: it is already all the way there.
      final box = tester.getRect(notice());
      expect(
        tester
            .widget<FadeTransition>(
              find
                  .ancestor(of: notice(), matching: find.byType(FadeTransition))
                  .first,
            )
            .opacity
            .value,
        1,
        reason: 'a reader who asked for no animation got a fade anyway',
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getRect(notice()), box, reason: 'it was still sliding');

      await tester.pump(const Duration(seconds: 4));
      expect(notice(), findsNothing);
    });

    testWidgets('a screen reader is told, once', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: heldProfile(),
        dependencies: rig.dependencies,
      );

      await tapLocked(tester, 'profile_birth_date');
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(notice());
      expect(
        semantics.label,
        stringsFor(AppLocale.english).profileBirthDateLocked('3 hr 48 min'),
      );
      expect(
        semantics.getSemanticsData().flagsCollection.isLiveRegion,
        isTrue,
        reason: 'TalkBack would not announce it without being asked to look',
      );
    });

    testWidgets('it wraps rather than clips on a narrow phone at a large '
        'text scale', (tester) async {
      useScreen(tester, size: const Size(320, 640), textScale: 1.5);
      final rig = makeRig();
      await openProfile(
        tester,
        profile: heldProfile(),
        dependencies: rig.dependencies,
        locale: AppLocale.spanish,
      );

      await tapLocked(tester, 'profile_birth_date');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'the notice overflowed');
      final box = tester.getRect(notice());
      expect(box.left, greaterThanOrEqualTo(0));
      expect(box.right, lessThanOrEqualTo(320));
      final text = tester.widget<Text>(
        find.descendant(of: notice(), matching: find.byType(Text)),
      );
      expect(
        text.overflow,
        isNot(TextOverflow.ellipsis),
        reason: 'the remaining time is the point; it must not be cut off',
      );
    });

    testWidgets('leaving Profile takes it with them', (tester) async {
      final rig = makeRig();
      await openProfile(
        tester,
        profile: heldProfile(),
        dependencies: rig.dependencies,
      );

      await tapLocked(tester, 'profile_birth_date');
      await tester.pumpAndSettle();
      expect(notice(), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('profile_cancel')));
      await tester.tap(find.byKey(const Key('profile_cancel')));
      await tester.pumpAndSettle();

      expect(closed, 1);
      expect(notice(), findsNothing);
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: 'a messenger notice would have followed the reader to Home',
      );
      // Its timer went with the page: were it still running, the test
      // framework would report it pending at teardown.
      await tester.pump(const Duration(seconds: 10));
      expect(notice(), findsNothing);
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
