import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the device-wide reading count somewhere that outlives app storage.
abstract interface class DeviceCounterBackup {
  Future<int?> read();
  Future<void> write(int value);
}

/// Google Block Store, through `MainActivity`. Documented to survive an
/// uninstall/reinstall when the user has Google backup on; whether Android's
/// "Clear data" also clears it is NOT documented and needs a device check.
/// Without the channel (iOS, tests) every call fails and is ignored.
class BlockStoreCounterBackup implements DeviceCounterBackup {
  const BlockStoreCounterBackup();
  static const _channel = MethodChannel('astracue/block_store');

  @override
  Future<int?> read() => _channel.invokeMethod<int>('readGuidanceCount');

  @override
  Future<void> write(int value) =>
      _channel.invokeMethod<void>('writeGuidanceCount', value);
}

/// Action Guidance allowance: the first [freeReadings] new readings on this
/// device show it; every later one (free or bonus) stays blurred until a
/// rewarded ad opens that reading for good.
///
/// Only readings admitted past the allowance are ever locked, so History
/// snapshots saved before this rule stay readable.
class GuidanceLockStore {
  GuidanceLockStore({this.backup});

  final DeviceCounterBackup? backup;

  static const freeReadings = 3;
  static const countKey = 'guidance_reading_count_v1';
  static const lockedKey = 'guidance_locked_keys_v1';
  static const openKey = 'guidance_open_keys_v1';
  static const _backupDeadline = Duration(seconds: 3);

  Future<void> _tail = Future<void>.value();

  Future<T> _serialize<T>(Future<T> Function() body) {
    final run = _tail.then((_) => body());
    _tail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  /// Records a new usable reading; true when its guidance starts locked.
  /// Every reading counts; one whose exact guidance was already open (a
  /// repeat inside the same time segment) stays open.
  Future<bool> admit(String readingKey) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    final open = prefs.getStringList(openKey) ?? const <String>[];
    int? backedUp;
    try {
      backedUp = await backup?.read().timeout(_backupDeadline);
    } catch (_) {}
    final count = math.max(prefs.getInt(countKey) ?? 0, backedUp ?? 0);
    final locked = count >= freeReadings && !open.contains(readingKey);
    // ponytail: key lists grow with every reading; prune alongside History
    // if it ever gets a retention limit.
    if (locked) {
      final keys = prefs.getStringList(lockedKey) ?? const <String>[];
      if (!keys.contains(readingKey)) {
        await _write(prefs.setStringList(lockedKey, [...keys, readingKey]));
      }
    } else if (!open.contains(readingKey)) {
      await _write(prefs.setStringList(openKey, [...open, readingKey]));
    }
    await _write(prefs.setInt(countKey, count + 1));
    // Not awaited: the Result screen must not wait on Play services to save.
    unawaited(
      backup
          ?.write(count + 1)
          .timeout(_backupDeadline)
          .then<void>((_) {}, onError: (_) {}),
    );
    return locked;
  });

  /// For a saved snapshot: locked only if it was admitted locked and never
  /// opened by a reward.
  Future<bool> isLocked(String readingKey) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(lockedKey) ?? const []).contains(readingKey) &&
        !(prefs.getStringList(openKey) ?? const []).contains(readingKey);
  });

  /// Opens a reading permanently. Throws if the choice could not be saved,
  /// so the reward path reports it instead of pretending.
  Future<void> unlock(String readingKey) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    final open = prefs.getStringList(openKey) ?? const <String>[];
    if (!open.contains(readingKey)) {
      await _write(prefs.setStringList(openKey, [...open, readingKey]));
    }
    final locked = prefs.getStringList(lockedKey) ?? const <String>[];
    await _write(
      prefs.setStringList(lockedKey, [
        for (final key in locked)
          if (key != readingKey) key,
      ]),
    );
  });

  static Future<void> _write(Future<bool> saved) async {
    if (!await saved) throw StateError('guidance_lock_not_saved');
  }
}
