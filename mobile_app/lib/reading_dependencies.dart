import 'analytics/analytics_service.dart';
import 'data/current_context_provider.dart';
import 'data/daily_brief_provider.dart';
import 'data/daily_energy_insight_deck.dart';
import 'data/home_description_deck.dart';
import 'data/history_repository.dart';
import 'data/locale_controller.dart';
import 'data/profile_repository.dart';
import 'data/reading_repository.dart';

/// Everything the reading flow needs from outside the widget tree, passed down
/// by constructor so no page ever builds an HTTP client or touches a plugin
/// directly.
class ReadingDependencies {
  const ReadingDependencies({
    required this.repository,
    required this.contextProvider,
    required this.historyRepository,
    required this.profileRepository,
    required this.dailyBriefProvider,
    required this.homeDescriptionDeck,
    required this.dailyEnergyInsights,
    required this.localeController,
    this.analytics = const NoopAnalyticsService(),
    this.nowUtc = _systemNowUtc,
    this.nowLocal = _systemNowLocal,
  });

  final ReadingRepository repository;
  final CurrentContextProvider contextProvider;
  final HistoryRepository historyRepository;
  final ProfileRepository profileRepository;
  final DailyBriefProvider dailyBriefProvider;

  /// Deals Home's rotating description, one per local calendar day.
  final HomeDescriptionDeck homeDescriptionDeck;

  /// Deals the Daily Energy insight for a date and tone, and remembers
  /// which have been read. Shared by Home and Result so opening one clears
  /// the unread mark on the other.
  final DailyEnergyInsightController dailyEnergyInsights;

  /// The language every screen renders in. A [ChangeNotifier] so a switch on
  /// the welcome screen re-renders the whole flow at once, with no screen left
  /// behind in the previous language.
  final LocaleController localeController;
  final AnalyticsService analytics;

  /// Injected so tests can pin the instant a Reveal tap records.
  final DateTime Function() nowUtc;

  /// The device's wall clock, used only to mute time periods that are already
  /// over. It is separate from [nowUtc] so tests can pin an hour of the day
  /// without depending on the host machine's timezone.
  final DateTime Function() nowLocal;

  static DateTime _systemNowUtc() => DateTime.now().toUtc();

  static DateTime _systemNowLocal() => DateTime.now();
}
