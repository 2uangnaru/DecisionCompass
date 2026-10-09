import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

import 'analytics_event.dart';
import 'analytics_service.dart';

/// Remains dormant until a genuinely configured Android build explicitly
/// opts in using --dart-define=FIREBASE_ANALYTICS_ENABLED=true.
class FirebaseAnalyticsSink implements AnalyticsSink {
  FirebaseAnalytics? _analytics;
  Future<FirebaseAnalytics>? _initializing;
  bool _desiredEnabled = false;
  Future<void> _nativeTail = Future.value();

  Future<FirebaseAnalytics> _instance() async {
    if (_analytics != null) return _analytics!;
    return _initializing ??= _initialize();
  }

  Future<FirebaseAnalytics> _initialize() async {
    try {
      await Firebase.initializeApp();
      return _analytics = FirebaseAnalytics.instance;
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) {
    _desiredEnabled = enabled;
    final operation = _nativeTail.then((_) async {
      final analytics = await _instance();
      // A timed-out older activation cannot turn collection back on after
      // a newer withdrawal; serialize native state changes and recheck intent.
      if (enabled && !_desiredEnabled) return;
      await analytics.setAnalyticsCollectionEnabled(false);
      await analytics.setConsent(
        analyticsStorageConsentGranted: enabled && _desiredEnabled,
        adStorageConsentGranted: false,
        adUserDataConsentGranted: false,
        adPersonalizationSignalsConsentGranted: false,
      );
      if (enabled && _desiredEnabled) {
        await analytics.setAnalyticsCollectionEnabled(true);
      }
      if (!_desiredEnabled)
        await analytics.setAnalyticsCollectionEnabled(false);
    });
    _nativeTail = operation.catchError((Object _) {});
    return operation;
  }

  @override
  Future<void> send(AnalyticsEvent event) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logEvent(name: event.name, parameters: event.parameters);
  }
}
