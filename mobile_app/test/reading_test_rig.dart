import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:decision_compass/local_engine/time/local_time.dart';
import 'package:decision_compass/app.dart';
import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/current_context_provider.dart';
import 'package:decision_compass/data/locale_controller.dart';
import 'package:decision_compass/data/locale_store.dart';
import 'package:decision_compass/data/fake_reading_repository.dart';
import 'package:decision_compass/data/daily_energy_insight_deck.dart';
import 'package:decision_compass/data/fixed_daily_brief_provider.dart';
import 'package:decision_compass/data/in_memory_daily_energy_insight_store.dart';
import 'package:decision_compass/data/home_description_deck.dart';
import 'package:decision_compass/data/in_memory_home_description_store.dart';
import 'package:decision_compass/data/history_entry.dart';
import 'package:decision_compass/data/in_memory_history_repository.dart';
import 'package:decision_compass/data/in_memory_profile_repository.dart';
import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/reading_dependencies.dart';
import 'package:decision_compass/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'bundled_fonts.dart';
import 'data/fixture_loader.dart';

/// Injected fakes for the reading flow. No network, GPS or platform channel is
/// touched: the repository, the context provider and the clock are all
/// in-memory.
class ReadingTestRig {
  ReadingTestRig({
    ReadingResponse? response,
    Object? error,
    Duration apiDelay = Duration.zero,
    DateTime? now,
    DateTime? localNow,
    this.liveLocalClock,
    String deviceTimezone = 'Asia/Ho_Chi_Minh',
    Duration? timezoneDelay,
    int timezoneFailures = 0,
    CurrentLocation? location,
    this.safetyAcknowledged = true,
    InMemoryHomeDescriptionStore? descriptionStore,
    Random? descriptionRandom,
    InMemoryDailyEnergyInsightStore? insightStore,
    Random? insightRandom,
    AppLocale? locale,
    InMemoryLocaleStore? localeStore,
  }) : localeStore = localeStore ?? InMemoryLocaleStore(),
       startingLocale = locale,
       descriptionStore = descriptionStore ?? InMemoryHomeDescriptionStore(),
       insightStore = insightStore ?? InMemoryDailyEnergyInsightStore.ordered(),
       insightRandom = insightRandom,
       descriptionRandom = descriptionRandom,
       localClock = localNow ?? _beforeEveryPeriod,
       repository = FakeReadingRepository(
         response: response,
         error: error,
         delay: apiDelay,
       ),
       contextProvider = FixedCurrentContextProvider(
         deviceTimezone: deviceTimezone,
         timezoneDelay: timezoneDelay,
         timezoneFailures: timezoneFailures,
         location: location,
       ),
       revealInstant =
           now ?? utcForLocal(localNow ?? _beforeEveryPeriod, deviceTimezone);

  /// Early enough that no period has closed, so a test that does not care
  /// about the clock can still reach every one of them.
  ///
  /// 08:30 rather than 05:30 so that the UTC instant it converts to still
  /// falls on 2026-09-18 in the default zone: the reading's own date is what
  /// the daily brief and the rotating copy are dealt from, and dragging it
  /// back to the 17th would change them for every test that never asked about
  /// the clock at all.
  static final _beforeEveryPeriod = DateTime(2026, 9, 18, 8, 30);


  final FakeReadingRepository repository;
  final FixedCurrentContextProvider contextProvider;
  final InMemoryHistoryRepository historyRepository =
      InMemoryHistoryRepository();
  final InMemoryProfileRepository profileRepository =
      InMemoryProfileRepository();
  final FixedDailyBriefProvider dailyBriefProvider = FixedDailyBriefProvider();

  /// Survives a rig swap when a test passes its own, so a "restart" keeps the
  /// deck exactly where the previous run left it.
  final InMemoryHomeDescriptionStore descriptionStore;
  final DateTime revealInstant;
  final bool safetyAcknowledged;
  final DateTime Function()? liveLocalClock;

  /// Seeded by tests that need a reproducible deal.
  final Random? descriptionRandom;

  /// Daily Energy insights. Defaults to decks in pool order, so a test that
  /// is about something else still sees each tone's original sentence.
  final InMemoryDailyEnergyInsightStore insightStore;
  final Random? insightRandom;

  /// The language the app starts in. Null means "whatever the store holds",
  /// which for a fresh store is the English default.
  final AppLocale? startingLocale;

  /// Survives a rig swap when a test passes its own, so a "restart" comes
  /// back in the language the previous run chose.
  final InMemoryLocaleStore localeStore;

  /// Device wall clock the ritual reads to mute periods that are over.
  DateTime localClock;

  /// How many times the flow asked for "now".
  /// How many times anything asked for the current instant.
  ///
  /// No longer one per reading: the ritual screen reads the clock on every
  /// build to decide which periods are still offerable. That a *reading* takes
  /// its moment once is asserted through [FixedCurrentContextProvider.captures]
  /// instead, which counts context captures rather than clock reads.
  var clockReads = 0;

  late final ReadingDependencies dependencies = ReadingDependencies(
    repository: repository,
    contextProvider: contextProvider,
    historyRepository: historyRepository,
    profileRepository: profileRepository,
    dailyBriefProvider: dailyBriefProvider,
    homeDescriptionDeck: HomeDescriptionDeck(
      store: descriptionStore,
      random: descriptionRandom,
    ),
    dailyEnergyInsights: dailyEnergyInsights,
    localeController: localeController,
    nowUtc: () {
      clockReads++;
      // A test that advances a live local clock is advancing the reader's own
      // clock, so the UTC instant has to move with it — the ritual screen now
      // decides period availability from `nowUtc` read in the resolved zone.
      final live = liveLocalClock;
      return live == null
          ? revealInstant
          : utcForLocal(live(), contextProvider.deviceTimezone);
    },
    nowLocal: () => liveLocalClock?.call() ?? localClock,
  );

  late final DailyEnergyInsightController dailyEnergyInsights =
      DailyEnergyInsightController(store: insightStore, random: insightRandom);

  /// Loaded synchronously when a test names a language, so the very first
  /// frame is already in it — the same guarantee `main` gives a real reader.
  late final LocaleController localeController = LocaleController(
    store: localeStore,
    initial: startingLocale,
  );

  /// The strings the app is currently rendering.
  AppLocalizations get strings =>
      stringsFor(startingLocale ?? AppLocale.english);

  late final Widget app = DecisionCompassApp(
    dependencies: dependencies,
    initialSafetyAcknowledged: safetyAcknowledged,
  );

  /// The single request the flow sent, or null when it sent none.
  ReadingRequest? get sentRequest =>
      repository.requests.isEmpty ? null : repository.requests.single;
}

/// A `MaterialApp` carrying the app's own localizations and theme, for tests
/// that mount one page instead of the whole app.
/// Takes the same named arguments a bare `MaterialApp` would, so a call site
/// only has to change the constructor name.
Widget localizedApp({
  required Widget home,
  ThemeData? theme,
  AppLocale locale = AppLocale.english,
}) => MaterialApp(
  theme: theme ?? buildCompassTheme(locale),
  locale: locale.locale,
  localizationsDelegates: compassLocalizationsDelegates,
  supportedLocales: compassSupportedLocales,
  home: home,
);

/// Lays the app out on a phone-sized screen at a given text scale.
///
/// Through `tester.view`, not `binding.setSurfaceSize`: the latter resizes the
/// surface without changing `MediaQuery.sizeOf`, so a test that used it was
/// measuring the default 800x600 desktop window while claiming to measure a
/// 360dp phone.
void useScreen(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  double textScale = 1.0,
}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

/// Registers the app's bundled fonts with the test engine.
///
/// Without this, `flutter test` measures every glyph with its placeholder
/// font, which is about one em wide whatever the character is — far wider
/// than real Latin text and a different shape from real Thai or Han. Any test
/// that asserts something fits has to use the fonts the app actually ships.
Future<void> loadBundledFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final entry in bundledFontFamilies().entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(File(path).readAsBytesSync()),
        ),
      );
    }
    await loader.load();
  }
}

/// The strings a locale actually renders, without pumping a widget.
///
/// `lookupAppLocalizations` is the function the delegate itself calls, so a
/// test reading a key through this sees exactly what a screen would.
AppLocalizations stringsFor(AppLocale locale) =>
    lookupAppLocalizations(locale.locale);

/// Taps the globe and chooses [locale] from the bottom sheet, the way a reader
/// would. Returns once the whole app has re-rendered.
Future<void> switchLanguage(WidgetTester tester, AppLocale locale) async {
  await openLanguageSheet(tester);
  await tester.tap(find.byKey(Key('language_option_${locale.tag}')));
  // Fixed steps rather than a settle: the welcome screen's orbit and the
  // ritual's reveal pulse both animate forever, so nothing on those screens
  // ever reaches a quiet frame.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  allowCountryNameGap(tester);
}

/// Consumes the framework's debug warning that `CountryLocalizations` does
/// not cover every supported locale.
///
/// It is true, and deliberate: `country_picker` has no Vietnamese or Thai
/// list, and answers Hindi with its Nepali one, so those three are left to
/// fall back to English country names rather than shown something wrong. The
/// gap is recorded in `handoff/localization/MISSING_KEYS.md`. Anything else
/// thrown here still fails the test.
void allowCountryNameGap(WidgetTester tester) {
  final thrown = tester.takeException();
  if (thrown == null) return;
  expect(
    '$thrown',
    contains('is not supported by all of its localization delegates'),
  );
}

/// Opens the language bottom sheet and lets it finish sliding in.
Future<void> openLanguageSheet(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('language_button')).first);
  await tester.tap(find.byKey(const Key('language_button')).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

ReadingResponse fixtureResponse(String name) =>
    ReadingResponse.fromJson(readFixture(name));

/// Picks a birth time the way a reader does: hour, minute, then AM or PM.
///
/// Every part of the dial is a real button, so this taps them rather than
/// aiming at painted numbers. The minute ring offers multiples of five;
/// [pickBirthTimeByTyping] covers the rest.
Future<void> pickBirthTime(WidgetTester tester, TimeOfDay time) async {
  await tester.ensureVisible(find.byKey(const Key('birth_time_picker')));
  await tester.tap(find.byKey(const Key('birth_time_picker')));
  await tester.pumpAndSettle();
  await chooseTimeInDialog(tester, time);
  await tester.tap(find.byKey(const Key('birth_time_confirm')));
  await tester.pumpAndSettle();
}

/// The same, typed into the hour and minute fields instead of tapped.
Future<void> pickBirthTimeByTyping(WidgetTester tester, TimeOfDay time) async {
  await tester.ensureVisible(find.byKey(const Key('birth_time_picker')));
  await tester.tap(find.byKey(const Key('birth_time_picker')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('birth_time_entry_mode')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('birth_time_hour_field')),
    '${time.hourOfPeriod}',
  );
  await tester.enterText(
    find.byKey(const Key('birth_time_minute_field')),
    time.minute.toString().padLeft(2, '0'),
  );
  await tester.pumpAndSettle();
  await tapDayPeriod(tester, time.period);
  await tester.tap(find.byKey(const Key('birth_time_confirm')));
  await tester.pumpAndSettle();
}

/// Chooses [time] in an already-open dialog, without confirming it.
Future<void> chooseTimeInDialog(WidgetTester tester, TimeOfDay time) async {
  await tester.tap(find.byKey(Key('birth_time_hour_${time.hourOfPeriod}')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('birth_time_minute_${time.minute}')));
  await tester.pumpAndSettle();
  await tapDayPeriod(tester, time.period);
}

/// Taps AM or PM.
Future<void> tapDayPeriod(WidgetTester tester, DayPeriod period) async {
  await tester.tap(
    find.byKey(Key(period == DayPeriod.am ? 'birth_time_am' : 'birth_time_pm')),
  );
  await tester.pumpAndSettle();
}

/// Walks the explainer and profile steps to Home.
///
/// [birthTime] null is the "I do not know my birth time" answer, which is what
/// most of these tests want: it turns the control off and sends null to the
/// engine. Passing a time turns the control on and picks it.
Future<void> fillOnboardingProfile(
  WidgetTester tester, {
  TimeOfDay? birthTime,
}) async {
  // The app's startup gate reads the saved profile before choosing between
  // Onboarding and Home; this lets that (already-resolved, in-memory) future
  // settle before the first interaction.
  await tester.pump();
  await tester.tap(find.byKey(const Key('continue_to_profile')));
  await tester.pumpAndSettle();

  await fillDateAndCountry(tester);
  await answerBirthTime(tester, birthTime);
}

/// The birth date and country, on whatever screen is already showing the
/// profile step. Split out so a test can mount that step directly and answer
/// the birth-time control itself.
Future<void> fillDateAndCountry(WidgetTester tester) async {
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
  // Searching by ISO code rather than by name: the picker matches the code in
  // every language, and the row's own text is localized.
  await tester.enterText(find.byType(TextField).last, 'US');
  await tester.pumpAndSettle();
  // The flag is the one cell of that row that reads the same in every
  // language, so the tap does not depend on the country's localized name.
  await tester.tap(find.text('\u{1F1FA}\u{1F1F8}').last);
  await tester.pumpAndSettle();
}

/// Answers the birth-time control.
///
/// It is on for a new profile, so a test that does not care about the birth
/// time still has to answer it one way or the other; nothing is filled in on
/// the reader's behalf. Null is the "I do not know" answer, which turns the
/// control off and sends null to the engine.
Future<void> answerBirthTime(WidgetTester tester, TimeOfDay? time) async {
  if (time == null) {
    await tester.ensureVisible(find.byKey(const Key('knows_birth_time')));
    await tester.tap(find.byKey(const Key('knows_birth_time')));
    await tester.pumpAndSettle();
  } else {
    await pickBirthTime(tester, time);
  }
}

/// Submits the profile step and waits for Home.
Future<void> completeProfileStep(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('complete_profile')));
  await tester.tap(find.byKey(const Key('complete_profile')));
  await tester.pumpAndSettle();
}

Future<void> completeOnboarding(
  WidgetTester tester, {
  bool settleHome = true,
  TimeOfDay? birthTime,
}) async {
  await fillOnboardingProfile(tester, birthTime: birthTime);
  await tester.ensureVisible(find.byKey(const Key('complete_profile')));
  await tester.tap(find.byKey(const Key('complete_profile')));
  if (settleHome) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// From Home, selects an optional category/mode, enters the ritual, picks an
/// optional period there, then reveals. Stops as soon as loading begins.
Future<void> revealReading(
  WidgetTester tester, {
  String? modeLabel,
  String? periodName,
  ReadingCategory? category,
}) async {
  if (category != null) {
    // Keys mirror the wire value for stability; the value itself is never shown.
    final key = Key('category_${category.wireValue}');
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pump();
  }
  if (modeLabel != null) {
    await tester.ensureVisible(find.text(modeLabel).first);
    await tester.tap(find.text(modeLabel).first);
    await tester.pump();
  }

  await tester.ensureVisible(find.byKey(const Key('find_direction')));
  await tester.tap(find.byKey(const Key('find_direction')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));

  // The period now lives on the ritual screen, beside the Reveal tap.
  if (periodName != null) {
    await tester.tap(find.byKey(Key('ritual_period_$periodName')));
    await tester.pump();
  }

  await tester.tap(find.byKey(const Key('reveal_button')));
  await tester.pump(const Duration(milliseconds: 380));
  await tester.pump();

  // If the first-time safety boundaries sheet appears, agree to proceed.
  final safetyAgreeButton = find.byKey(const Key('agree_safety_boundaries'));
  if (safetyAgreeButton.evaluate().isNotEmpty) {
    await tester.tap(safetyAgreeButton);
    await tester.pump(const Duration(milliseconds: 380));
    await tester.pump();
  }
}

/// A saved entry for [reading], keyed the way `ResultPage` keys one.
HistoryEntry historyEntryFor(ReadingResponse reading) => HistoryEntry(
  id: reading.readingKey ?? reading.context.instantUtc,
  reading: reading,
  savedAtUtc: DateTime.parse(reading.context.instantUtc),
);

/// A valid [DailyColors] pair for tests that only need the brief to exist.
/// Two different element families, as the engine always produces.
engine.DailyColors testDailyColors({
  String leadName = 'Ocean Blue',
  String leadHex = '#66A9D2',
  String supportingName = 'Cedar',
  String supportingHex = '#4EAE83',
}) => engine.DailyColors(
  lead: engine.DailyColor(
    key: leadName.toLowerCase().replaceAll(' ', '_'),
    name: leadName,
    hex: leadHex,
    element: 'water',
    stem: 8,
  ),
  supporting: engine.DailyColor(
    key: supportingName.toLowerCase().replaceAll(' ', '_'),
    name: supportingName,
    hex: supportingHex,
    element: 'wood',
    stem: 0,
  ),
);

/// The UTC instant at which [local]'s wall time occurs in [zone].
///
/// The ritual screen decides which periods are still offerable from the
/// instant of the tap read in the reader's own resolved zone, so a test that
/// pins an hour of the day has to pin it in both clocks or the two disagree
/// — which is what they quietly did before this existed.
DateTime utcForLocal(DateTime local, String zone) {
  final date =
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final clock =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  final candidates = localCandidates(date, clock, zone);
  if (candidates.isEmpty) {
    throw ArgumentError('$date $clock does not exist in $zone');
  }
  // `localCandidates` resolves whole minutes, so the seconds a test pinned
  // are added back afterwards. Dropping them silently moved a clock set to
  // 10:29:59 back to 10:29:00, which is a whole minute of slack in any test
  // that watches for a boundary.
  return DateTime.fromMillisecondsSinceEpoch(
    candidates.first.round(),
    isUtc: true,
  ).add(Duration(seconds: local.second, milliseconds: local.millisecond));
}
