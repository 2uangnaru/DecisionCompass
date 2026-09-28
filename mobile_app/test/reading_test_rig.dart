import 'dart:math';

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
import 'package:flutter_test/flutter_test.dart';

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
         location: location,
       ),
       revealInstant = now ?? DateTime.utc(2026, 9, 18, 8, 30);

  /// Early enough that no period has elapsed, so a test that does not care
  /// about the clock can still reach every one of them.
  static final _beforeEveryPeriod = DateTime(2026, 9, 18, 5, 30);

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
      return revealInstant;
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

/// Walks the explainer and profile steps to Home.
Future<void> fillOnboardingProfile(WidgetTester tester) async {
  // The app's startup gate reads the saved profile before choosing between
  // Onboarding and Home; this lets that (already-resolved, in-memory) future
  // settle before the first interaction.
  await tester.pump();
  await tester.tap(find.byKey(const Key('continue_to_profile')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('birth_date_value')));
  await tester.tap(find.byKey(const Key('birth_date_value')));
  await tester.pumpAndSettle();
  // The dialog writes its years, days and buttons the way this language
  // writes them — Japanese and Chinese label the year "2000年", not "2000" —
  // so every label here is read back from the same localizations the dialog
  // used rather than assumed to be English.
  final dialog = MaterialLocalizations.of(
    tester.element(find.byType(DatePickerDialog)),
  );
  await tester.tap(find.text(dialog.formatYear(DateTime(2000))).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(dialog.formatDecimal(1)).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(dialog.okButtonLabel));
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

Future<void> completeOnboarding(
  WidgetTester tester, {
  bool settleHome = true,
}) async {
  await fillOnboardingProfile(tester);
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
