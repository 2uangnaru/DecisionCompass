import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contract for managing user reading energy, daily quota, and rewarded unlocks.
abstract interface class ReadingQuotaController implements Listenable {
  bool isAvailable(DateTime now);
  bool isCooldown(DateTime now);
  Duration remainingCooldown(DateTime now);
  String remainingTimeString(DateTime now);
  int get bonusReadings;
  int dailyFreeReadingsUsed(DateTime now);
  int get maxDailyFreeReadings;
  Future<void> earnBonusReading();

  /// Commit one successful reading using the device LOCAL completion time.
  /// Throws when no entitlement remains; never call before calculation succeeds.
  Future<void> consumeReading(DateTime now);
  Future<void> ensureLoaded();
}

class ReadingQuotaUnavailableException implements Exception {
  const ReadingQuotaUnavailableException({required this.exhausted});
  final bool exhausted;
}

/// Persistent implementation backed by [SharedPreferences].
class SharedPreferencesReadingQuotaController extends ChangeNotifier
    implements ReadingQuotaController {
  SharedPreferencesReadingQuotaController({
    this.maxDailyFreeReadings = 3,
    this.cooldownDuration = const Duration(hours: 3),
  });

  @override
  final int maxDailyFreeReadings;
  final Duration cooldownDuration;

  static const _keyLastReadingEpochMs = 'reading_quota_last_epoch_ms';
  static const _keyDateString = 'reading_quota_date_string';
  static const _keyUsedToday = 'reading_quota_used_today';
  static const _keyBonusReadings = 'reading_quota_bonus_readings';
  // One write prevents partial commits across counters, date and cooldown.
  // Legacy keys remain readable for existing installs.
  static const _keyState = 'reading_quota_state_v1';

  DateTime? _lastReadingTime;
  String? _storedDateString;
  int _usedToday = 0;
  int _bonusReadings = 0;
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _pending = Future<void>.value();

  Future<void> _serialize(Future<void> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  @override
  int get bonusReadings => _bonusReadings;

  @override
  int dailyFreeReadingsUsed(DateTime now) {
    return _storedDateString == _dateKey(now.toLocal()) ? _usedToday : 0;
  }

  void _normalizeDay(DateTime now) {
    final todayKey = _dateKey(now.toLocal());
    if (_storedDateString != todayKey) {
      _storedDateString = todayKey;
      _usedToday = 0;
      // Product rule: local midnight resets BOTH free quota and cooldown.
      // Bonus credits are independent and survive the reset.
      _lastReadingTime = null;
    }
  }

  static String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  bool isAvailable(DateTime now) {
    if (_bonusReadings > 0) return true;
    if (_storedDateString != _dateKey(now.toLocal())) return true;
    if (_usedToday >= maxDailyFreeReadings) return false;
    if (_lastReadingTime != null) {
      final elapsed = now.difference(_lastReadingTime!);
      if (elapsed < cooldownDuration) return false;
    }
    return true;
  }

  @override
  bool isCooldown(DateTime now) => !isAvailable(now);

  @override
  Duration remainingCooldown(DateTime now) {
    if (_bonusReadings > 0) return Duration.zero;
    if (_storedDateString != _dateKey(now.toLocal())) return Duration.zero;
    final local = now.toLocal();
    final midnight = DateTime(local.year, local.month, local.day + 1);
    final untilMidnight = midnight.difference(local);
    if (_usedToday >= maxDailyFreeReadings) return untilMidnight;
    if (_lastReadingTime != null) {
      final elapsed = now.difference(_lastReadingTime!);
      if (elapsed < cooldownDuration) {
        final wait = cooldownDuration - elapsed;
        return wait < untilMidnight ? wait : untilMidnight;
      }
    }
    return Duration.zero;
  }

  @override
  String remainingTimeString(DateTime now) {
    final remaining = remainingCooldown(now);
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Future<void> earnBonusReading() => _serialize(() async {
    await ensureLoaded();
    final nextBonus = _bonusReadings + 1;
    await _persist(used: _usedToday, bonus: nextBonus, last: _lastReadingTime);
    _bonusReadings = nextBonus;
    notifyListeners();
  });

  @override
  Future<void> consumeReading(DateTime now) => _serialize(() async {
    await ensureLoaded();
    final local = now.toLocal();
    _normalizeDay(local);
    if (!isAvailable(local)) {
      throw ReadingQuotaUnavailableException(
        exhausted: _usedToday >= maxDailyFreeReadings,
      );
    }
    final useBonus = _bonusReadings > 0;
    final nextBonus = useBonus ? _bonusReadings - 1 : _bonusReadings;
    final nextUsed = useBonus ? _usedToday : _usedToday + 1;
    final nextLast = useBonus ? _lastReadingTime : local;
    await _persist(used: nextUsed, bonus: nextBonus, last: nextLast);
    _bonusReadings = nextBonus;
    _usedToday = nextUsed;
    _lastReadingTime = nextLast;
    notifyListeners();
  });

  Future<void> _persist({
    required int used,
    required int bonus,
    required DateTime? last,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _keyState,
      jsonEncode({
        'date': _storedDateString,
        'used': used,
        'bonus': bonus,
        'lastEpochMs': last?.millisecondsSinceEpoch,
      }),
    );
    if (!saved) throw StateError('reading_quota_save_failed');
  }

  @override
  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_keyState);
      final state = stored == null
          ? null
          : jsonDecode(stored) as Map<String, dynamic>;
      final epochMs = state == null
          ? prefs.getInt(_keyLastReadingEpochMs)
          : state['lastEpochMs'] as int?;
      if (epochMs != null) {
        _lastReadingTime = DateTime.fromMillisecondsSinceEpoch(epochMs);
      }
      _storedDateString = state == null
          ? prefs.getString(_keyDateString)
          : state['date'] as String?;
      _usedToday = state == null
          ? (prefs.getInt(_keyUsedToday) ?? 0)
          : state['used'] as int;
      _bonusReadings = state == null
          ? (prefs.getInt(_keyBonusReadings) ?? 0)
          : state['bonus'] as int;
      _loaded = true;
    } finally {
      _loading = null;
    }
  }
}

/// Fallback / mock controller for testing and previews.
class NoopReadingQuotaController implements ReadingQuotaController {
  const NoopReadingQuotaController({
    this.defaultCooldown = false,
    this.defaultTimeString = '03:00:00',
  });

  final bool defaultCooldown;
  final String defaultTimeString;

  @override
  bool isAvailable(DateTime now) => !defaultCooldown;

  @override
  bool isCooldown(DateTime now) => defaultCooldown;

  @override
  Duration remainingCooldown(DateTime now) =>
      defaultCooldown ? const Duration(hours: 3) : Duration.zero;

  @override
  String remainingTimeString(DateTime now) => defaultTimeString;

  @override
  int get bonusReadings => 0;

  @override
  int dailyFreeReadingsUsed(DateTime now) => 0;

  @override
  int get maxDailyFreeReadings => 3;

  @override
  Future<void> earnBonusReading() async {}

  @override
  Future<void> consumeReading(DateTime now) async {}

  @override
  Future<void> ensureLoaded() async {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// Fake controller for widget and flow tests.
class FakeReadingQuotaController extends ChangeNotifier
    implements ReadingQuotaController {
  FakeReadingQuotaController({
    bool initialCooldown = false,
    Duration initialRemaining = const Duration(hours: 3),
    int initialBonus = 0,
    int initialUsed = 0,
  }) : _isCooldown = initialCooldown,
       _remaining = initialRemaining,
       _bonus = initialBonus,
       _usedToday = initialUsed;

  bool _isCooldown;
  Duration _remaining;
  int _bonus;
  int _usedToday;

  void setCooldown(bool cooldown, {Duration? remaining}) {
    _isCooldown = cooldown;
    if (remaining != null) _remaining = remaining;
    notifyListeners();
  }

  void setUsedToday(int used) {
    _usedToday = used;
    notifyListeners();
  }

  @override
  bool isAvailable(DateTime now) => !_isCooldown || _bonus > 0;

  @override
  bool isCooldown(DateTime now) => !isAvailable(now);

  @override
  Duration remainingCooldown(DateTime now) =>
      _bonus > 0 ? Duration.zero : (_isCooldown ? _remaining : Duration.zero);

  @override
  String remainingTimeString(DateTime now) {
    final rem = remainingCooldown(now);
    final hours = rem.inHours.toString().padLeft(2, '0');
    final minutes = (rem.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  int get bonusReadings => _bonus;

  @override
  int dailyFreeReadingsUsed(DateTime now) => _usedToday;

  @override
  int get maxDailyFreeReadings => 3;

  @override
  Future<void> earnBonusReading() async {
    _bonus++;
    notifyListeners();
  }

  @override
  Future<void> consumeReading(DateTime now) async {
    if (!isAvailable(now)) {
      throw const ReadingQuotaUnavailableException(exhausted: false);
    }
    if (_bonus > 0) {
      _bonus--;
    } else {
      _usedToday++;
      _isCooldown = true;
    }
    notifyListeners();
  }

  @override
  Future<void> ensureLoaded() async {}
}
