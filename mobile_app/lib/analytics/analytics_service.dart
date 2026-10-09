import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_event.dart';

abstract interface class AnalyticsSink {
  Future<void> setEnabled(bool enabled);
  Future<void> send(AnalyticsEvent event);
}

class NoopAnalyticsSink implements AnalyticsSink {
  const NoopAnalyticsSink();
  @override
  Future<void> setEnabled(bool enabled) async {}
  @override
  Future<void> send(AnalyticsEvent event) async {}
}

abstract interface class AnalyticsConsentStore {
  Future<bool> load();
  Future<void> save(bool enabled);
}

class SharedPreferencesAnalyticsConsentStore implements AnalyticsConsentStore {
  const SharedPreferencesAnalyticsConsentStore();
  static const key = 'usage_analytics_consent_v1';
  @override
  Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(key)) {
      return true;
    }
    return prefs.get(key) == true;
  }

  @override
  Future<void> save(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(key, enabled)) {
      throw StateError('analytics_consent_not_saved');
    }
  }
}

abstract interface class AnalyticsService implements Listenable {
  bool get enabled;
  bool get busy;
  int get consentVersion;
  Future<void> ensureLoaded();
  Future<bool> setEnabled(bool enabled);
  bool record(AnalyticsEvent event);
}

/// Default for previews and existing tests: no plugins or consent UI.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();
  @override
  bool get enabled => false;
  @override
  bool get busy => false;
  @override
  int get consentVersion => 0;
  @override
  Future<void> ensureLoaded() async {}
  @override
  Future<bool> setEnabled(bool enabled) async => false;
  @override
  bool record(AnalyticsEvent event) => false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

/// Collection is opt-in. Events are dropped, never buffered, before consent.
/// A consent generation also invalidates queued events on withdrawal.
class ProductAnalytics extends ChangeNotifier implements AnalyticsService {
  ProductAnalytics({required this.store, required this.sink});
  final AnalyticsConsentStore store;
  final AnalyticsSink sink;
  bool _enabled = false;
  bool _ready = false;
  bool _busy = false;
  bool _loaded = false;
  int _version = 0;
  Future<void>? _loading;
  Future<void> _tail = Future.value();
  @override
  bool get enabled => _enabled;
  @override
  bool get busy => _busy || !_loaded;
  @override
  int get consentVersion => _version;

  @override
  Future<void> ensureLoaded() => _loading ??= _load();
  Future<void> _load() async {
    try {
      _enabled = await store.load();
      await sink.setEnabled(_enabled).timeout(const Duration(seconds: 3));
      _ready = true;
    } catch (_) {
      _enabled = false;
      _ready = false;
      try {
        await sink.setEnabled(false).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  @override
  Future<bool> setEnabled(bool value) async {
    if (_busy) return false;
    _busy = true;
    // Withdrawal gates Dart immediately, even if storage/native work is slow.
    if (!value) {
      _enabled = false;
      _ready = false;
      _version++;
    }
    notifyListeners();
    try {
      await ensureLoaded();
      _ready = false;
      _enabled = false;
      _version++;
      // Stop SDK collection before persisting a withdrawal. If the write
      // fails, this session stays off and the UI reports it was not saved.
      if (!value) await _enqueue(() => sink.setEnabled(false));
      await store.save(value);
      if (value) await _enqueue(() => sink.setEnabled(true));
      _enabled = value;
      _ready = true;
      return true;
    } catch (_) {
      _enabled = false;
      _ready = false;
      // If the preference wrote but SDK activation failed, do not leave a
      // hidden opt-in that could activate on the next launch.
      try {
        await store.save(false);
      } catch (_) {}
      try {
        await _enqueue(() => sink.setEnabled(false));
      } catch (_) {}
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _tail.then(
      (_) => action().timeout(const Duration(seconds: 3)),
    );
    // Consent calls may inspect failure; the chain always recovers. Events
    // attach their own handler and never leak errors or exception text.
    _tail = next.catchError((Object _) {});
    return next;
  }

  @override
  bool record(AnalyticsEvent event) {
    if (!_ready || !_enabled || _busy) return false;
    final generation = _version;
    _enqueue(() async {
      if (!_enabled || !_ready || generation != _version) return;
      await sink.send(event);
    }).catchError((Object _) {});
    return true;
  }

  @visibleForTesting
  Future<void> flush() => _tail;
}
