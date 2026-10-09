import '../app_locale.dart';
import '../data/models/models.dart' as engine;
import '../data/reading_api_exception.dart';
import 'analytics_event.dart';
import 'analytics_service.dart';

/// One logical attempt; a retry gets a new instance. No identifier is sent.
class ReadingAnalyticsAttempt {
  ReadingAnalyticsAttempt({
    required this.analytics,
    required this.mode,
    required this.category,
    required this.period,
    required this.language,
    required this.elapsed,
  }) : _version = analytics.consentVersion {
    _started = analytics.record(
      AnalyticsEvent.readingStarted(
        mode: mode,
        category: category,
        period: period,
        language: language,
      ),
    );
  }
  final AnalyticsService analytics;
  final engine.DecisionMode mode;
  final engine.ReadingCategory category;
  final engine.TimePeriod period;
  final AppLocale language;
  final Stopwatch elapsed;
  final int _version;
  bool _started = false;
  bool _settled = false;

  void completed() {
    if (_settled) return;
    _settled = true;
    elapsed.stop();
    if (!_started || _version != analytics.consentVersion) return;
    analytics.record(
      AnalyticsEvent.readingCompleted(
        mode: mode,
        category: category,
        period: period,
        language: language,
        elapsedMs: elapsed.elapsedMilliseconds,
      ),
    );
  }

  void failed(ReadingApiFailureKind kind) {
    if (_settled) return;
    _settled = true;
    elapsed.stop();
    if (!_started || _version != analytics.consentVersion) return;
    analytics.record(
      AnalyticsEvent.readingFailed(
        mode: mode,
        category: category,
        period: period,
        kind: kind,
      ),
    );
  }
}
