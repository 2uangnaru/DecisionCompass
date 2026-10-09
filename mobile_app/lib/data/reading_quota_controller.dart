import 'dart:async';
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
  Future<void> consumeReading(DateTime now);
  Future<void> ensureLoaded();
}

/// Persistent implementation backed by [SharedPreferences].
class SharedPreferencesReadingQuotaController extends ChangeNotifier
    implements ReadingQuotaController {
  SharedPreferencesReadingQuotaController({
    this.maxDailyFreeReadings = 3,
    this.cooldownDuration = const Duration(hours: 2, minutes: 15, seconds: 34),
  });

  @override
  final int maxDailyFreeReadings;
  final Duration cooldownDuration;

  static const _keyLastReadingEpochMs = 'reading_quota_last_epoch_ms';
  static const _keyDateString = 'reading_quota_date_string';
  static const _keyUsedToday = 'reading_quota_used_today';
  static const _keyBonusReadings = 'reading_quota_bonus_readings';

  DateTime? _lastReadingTime;
  String? _storedDateString;
  int _usedToday = 0;
  int _bonusReadings = 0;
  bool _loaded = false;

  @override
  int get bonusReadings => _bonusReadings;

  @override
  int dailyFreeReadingsUsed(DateTime now) {
    _normalizeDay(now);
    return _usedToday;
  }

  void _normalizeDay(DateTime now) {
    final todayKey = _dateKey(now);
    if (_storedDateString != todayKey) {
      _storedDateString = todayKey;
      _usedToday = 0;
    }
  }

  static String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  bool isAvailable(DateTime now) {
    if (_bonusReadings > 0) return true;
    _normalizeDay(now);
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
    _normalizeDay(now);
    if (_usedToday >= maxDailyFreeReadings) {
      final midnight = DateTime(now.year, now.month, now.day + 1);
      final diff = midnight.difference(now);
      return diff > Duration.zero ? diff : Duration.zero;
    }
    if (_lastReadingTime != null) {
      final elapsed = now.difference(_lastReadingTime!);
      if (elapsed < cooldownDuration) {
        return cooldownDuration - elapsed;
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
  Future<void> earnBonusReading() async {
    await ensureLoaded();
    _bonusReadings++;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBonusReadings, _bonusReadings);
  }

  @override
  Future<void> consumeReading(DateTime now) async {
    await ensureLoaded();
    _normalizeDay(now);
    if (_bonusReadings > 0) {
      _bonusReadings--;
    } else {
      _usedToday++;
      _lastReadingTime = now;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBonusReadings, _bonusReadings);
    await prefs.setInt(_keyUsedToday, _usedToday);
    await prefs.setString(_keyDateString, _storedDateString ?? _dateKey(now));
    if (_lastReadingTime != null) {
      await prefs.setInt(
        _keyLastReadingEpochMs,
        _lastReadingTime!.millisecondsSinceEpoch,
      );
    }
  }

  @override
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final epochMs = prefs.getInt(_keyLastReadingEpochMs);
    if (epochMs != null) {
      _lastReadingTime = DateTime.fromMillisecondsSinceEpoch(epochMs);
    }
    _storedDateString = prefs.getString(_keyDateString);
    _usedToday = prefs.getInt(_keyUsedToday) ?? 0;
    _bonusReadings = prefs.getInt(_keyBonusReadings) ?? 0;
    _loaded = true;
  }
}

/// Fallback / mock controller for testing and previews.
class NoopReadingQuotaController implements ReadingQuotaController {
  const NoopReadingQuotaController({
    this.defaultCooldown = false,
    this.defaultTimeString = '02:15:34',
  });

  final bool defaultCooldown;
  final String defaultTimeString;

  @override
  bool isAvailable(DateTime now) => !defaultCooldown;

  @override
  bool isCooldown(DateTime now) => defaultCooldown;

  @override
  Duration remainingCooldown(DateTime now) => defaultCooldown
      ? const Duration(hours: 2, minutes: 15, seconds: 34)
      : Duration.zero;

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
    Duration initialRemaining = const Duration(hours: 2, minutes: 15, seconds: 34),
    int initialBonus = 0,
  })  : _isCooldown = initialCooldown,
        _remaining = initialRemaining,
        _bonus = initialBonus;

  bool _isCooldown;
  Duration _remaining;
  int _bonus;

  void setCooldown(bool cooldown, {Duration? remaining}) {
    _isCooldown = cooldown;
    if (remaining != null) _remaining = remaining;
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
  int dailyFreeReadingsUsed(DateTime now) => 0;

  @override
  int get maxDailyFreeReadings => 3;

  @override
  Future<void> earnBonusReading() async {
    _bonus++;
    notifyListeners();
  }

  @override
  Future<void> consumeReading(DateTime now) async {
    if (_bonus > 0) {
      _bonus--;
    } else {
      _isCooldown = true;
    }
    notifyListeners();
  }

  @override
  Future<void> ensureLoaded() async {}
}
