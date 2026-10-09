import '../app_locale.dart';
import '../data/models/models.dart' as engine;
import '../data/reading_api_exception.dart';

/// Closed, typed payloads: no profile, response, identifier or arbitrary text
/// can be supplied to an analytics event.
class AnalyticsEvent {
  AnalyticsEvent._(this.name, Map<String, Object> parameters)
    : parameters = Map.unmodifiable(parameters);

  final String name;
  final Map<String, Object> parameters;

  factory AnalyticsEvent.onboardingStarted() =>
      AnalyticsEvent._('onboarding_started', {});
  factory AnalyticsEvent.onboardingCompleted() =>
      AnalyticsEvent._('onboarding_completed', {});
  factory AnalyticsEvent.historyOpened() =>
      AnalyticsEvent._('history_opened', {});
  factory AnalyticsEvent.shareRequested({required bool fromHistory}) =>
      AnalyticsEvent._('share_requested', {
        'source': fromHistory ? 'history' : 'generated',
      });
  factory AnalyticsEvent.languageChanged(AppLocale previous, AppLocale next) =>
      AnalyticsEvent._('language_changed', {
        'previous_language': previous.tag,
        'new_language': next.tag,
      });

  static Map<String, Object> _reading(
    engine.DecisionMode mode,
    engine.ReadingCategory category,
    engine.TimePeriod period,
    AppLocale language,
  ) => {
    'decision_mode': mode.toJson(),
    'category': category.toJson(),
    'time_period': period.toJson(),
    'ui_language': language.tag,
  };

  factory AnalyticsEvent.readingStarted({
    required engine.DecisionMode mode,
    required engine.ReadingCategory category,
    required engine.TimePeriod period,
    required AppLocale language,
  }) => AnalyticsEvent._(
    'reading_started',
    _reading(mode, category, period, language),
  );

  factory AnalyticsEvent.readingCompleted({
    required engine.DecisionMode mode,
    required engine.ReadingCategory category,
    required engine.TimePeriod period,
    required AppLocale language,
    required int elapsedMs,
  }) => AnalyticsEvent._('reading_completed', {
    ..._reading(mode, category, period, language),
    'elapsed_ms': elapsedMs < 0 ? 0 : elapsedMs,
  });

  factory AnalyticsEvent.readingFailed({
    required engine.DecisionMode mode,
    required engine.ReadingCategory category,
    required engine.TimePeriod period,
    required ReadingApiFailureKind kind,
  }) => AnalyticsEvent._('reading_failed', {
    'decision_mode': mode.toJson(),
    'category': category.toJson(),
    'time_period': period.toJson(),
    'error_kind': kind.name,
  });
}
