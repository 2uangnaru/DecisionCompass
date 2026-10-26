import '../app_locale.dart';
import '../data/models/models.dart' as engine;
import 'analytics_event.dart';
import 'analytics_service.dart';

/// A deliberate reward CTA and successful saved grant, not an ad impression.
/// Analytics deduplication does not change reward or quota business rules.
class RewardAnalyticsAttempt {
  RewardAnalyticsAttempt({
    required this.analytics,
    required this.mode,
    required this.category,
    required this.period,
    required this.language,
    required this.placement,
    this.grantSource = RewardGrantSource.prototype,
  }) : _version = analytics.consentVersion {
    _started = analytics.record(
      AnalyticsEvent.rewardCtaTapped(
        mode: mode,
        category: category,
        period: period,
        language: language,
        placement: placement,
        grantSource: grantSource,
      ),
    );
  }

  final AnalyticsService analytics;
  final engine.DecisionMode mode;
  final engine.ReadingCategory category;
  final engine.TimePeriod period;
  final AppLocale language;
  final RewardPlacement placement;
  final RewardGrantSource grantSource;
  final int _version;
  bool _started = false;
  bool _granted = false;

  /// Call only after the credit save or the option unlock succeeded.
  void granted() {
    if (_granted) return;
    _granted = true;
    if (!_started || _version != analytics.consentVersion) return;
    analytics.record(
      AnalyticsEvent.rewardGranted(
        mode: mode,
        category: category,
        period: period,
        language: language,
        placement: placement,
        grantSource: grantSource,
      ),
    );
  }
}
