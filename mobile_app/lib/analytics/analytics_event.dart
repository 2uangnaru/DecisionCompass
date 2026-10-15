import '../app_locale.dart';
import '../data/models/models.dart' as engine;
import '../data/reading_api_exception.dart';
import '../data/reading_quota_controller.dart';

enum ReadingLockReason { cooldown, exhausted }

enum ReadingLockStage { ritual, loading, commit }

enum RewardPlacement { reading, mode, category, period }

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

  factory AnalyticsEvent.readingLocked({
    required engine.DecisionMode mode,
    required engine.ReadingCategory category,
    required engine.TimePeriod period,
    required AppLocale language,
    required ReadingLockReason reason,
    required ReadingLockStage stage,
  }) => AnalyticsEvent._('reading_locked', {
    ..._reading(mode, category, period, language),
    'lock_reason': reason.name,
    'lock_stage': stage.name,
  });

  factory AnalyticsEvent.optionLocked({
    required engine.DecisionMode mode,
    required engine.ReadingCategory category,
    required engine.TimePeriod period,
    required AppLocale language,
    required RewardPlacement placement,
  }) => AnalyticsEvent._('option_locked', {
    ..._reading(mode, category, period, language),
    'placement': placement.name,
  });

  factory AnalyticsEvent.rewardCtaTapped({
    required engine.DecisionMode mode,
    required engine.ReadingCategory category,
    required engine.TimePeriod period,
    required AppLocale language,
    required RewardPlacement placement,
  }) => AnalyticsEvent._('reward_cta_tapped', {
    ..._reading(mode, category, period, language),
    'placement': placement.name,
    'grant_source': 'prototype',
  });

  /// Only an app-owned prototype reward; never an ad impression or revenue.
  factory AnalyticsEvent.rewardGranted({
    required engine.DecisionMode mode,
    required engine.ReadingCategory category,
    required engine.TimePeriod period,
    required AppLocale language,
    required RewardPlacement placement,
  }) => AnalyticsEvent._('reward_granted', {
    ..._reading(mode, category, period, language),
    'placement': placement.name,
    'grant_source': 'prototype',
  });

  factory AnalyticsEvent.readingEntitlementUsed({
    required engine.DecisionMode mode,
    required engine.ReadingCategory category,
    required engine.TimePeriod period,
    required AppLocale language,
    required ReadingEntitlementSource source,
  }) => AnalyticsEvent._('reading_entitlement_used', {
    ..._reading(mode, category, period, language),
    'entitlement_source': source.name,
  });
}
