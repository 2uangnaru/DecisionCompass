import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AdPolicyStore {
  Future<({String? viewedDay, int? dismissedMs})> load();
  Future<void> save(String? viewedDay, int? dismissedMs);
}

class SharedPreferencesAdPolicyStore implements AdPolicyStore {
  static const key = 'ad_policy_v1';
  @override
  Future<({String? viewedDay, int? dismissedMs})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return (viewedDay: null, dismissedMs: null);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final day = json['viewedDay'];
    final ms = json['dismissedMs'];
    if ((day != null &&
            (day is! String ||
                !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day))) ||
        (ms != null && (ms is! int || ms < 0))) {
      throw const FormatException('invalid_ad_policy');
    }
    return (viewedDay: day as String?, dismissedMs: ms as int?);
  }

  @override
  Future<void> save(String? viewedDay, int? dismissedMs) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      key,
      jsonEncode({'viewedDay': viewedDay, 'dismissedMs': dismissedMs}),
    )) {
      throw StateError('ad_policy_not_saved');
    }
  }
}

/// A quota commit is not proof a result was viewed. No daily cap/reward gap.
class AdPolicy {
  AdPolicy({required this.store});
  final AdPolicyStore store;
  static const interstitialGap = Duration(seconds: 30);
  String? _viewedDay;
  int? _dismissedMs;
  bool _ready = false;
  Future<void>? _loading;
  Future<void>? _tail;
  static String dayKey(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  Future<void> initialize() => _loading ??= _load();
  Future<void> _load() async {
    try {
      final data = await store.load().timeout(const Duration(seconds: 3));
      _viewedDay = data.viewedDay;
      _dismissedMs = data.dismissedMs;
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  String? skipReason(DateTime local, DateTime utc) {
    if (!_ready) return 'policy_unavailable';
    if (_viewedDay != dayKey(local)) return 'first_daily_flow';
    if (_dismissedMs != null &&
        utc.millisecondsSinceEpoch - _dismissedMs! <
            interstitialGap.inMilliseconds)
      return 'interstitial_gap';
    return null;
  }

  Future<void> markViewed(DateTime local) => _serialize(() async {
    await initialize();
    if (!_ready) return;
    _viewedDay = dayKey(local);
    await _persist();
  });
  Future<void> markDismissed(DateTime utc) => _serialize(() async {
    await initialize();
    _dismissedMs = utc.millisecondsSinceEpoch;
    await _persist();
  });
  Future<void> _persist() async {
    try {
      await store
          .save(_viewedDay, _dismissedMs)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> _serialize(Future<void> Function() action) {
    final next = (_tail ?? Future<void>.value()).then((_) => action());
    _tail = next.catchError((Object _) {});
    return next;
  }
}
