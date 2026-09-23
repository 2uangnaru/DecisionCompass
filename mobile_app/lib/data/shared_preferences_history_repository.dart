import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'history_entry.dart';
import 'history_repository.dart';

/// Persists reading snapshots on-device via `shared_preferences`.
///
/// Entries are stored as one JSON-encoded list, capped at [_maxEntries] so
/// history cannot grow without bound on a device that is never reinstalled.
/// A real free/premium retention window (see the UX spec's History section)
/// is a separate product decision, not implemented here.
class SharedPreferencesHistoryRepository implements HistoryRepository {
  const SharedPreferencesHistoryRepository();

  static const _key = 'history_entries_v1';
  static const _maxEntries = 200;

  @override
  Future<void> save(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _read(prefs);
    entries.insert(0, entry);
    if (entries.length > _maxEntries) {
      entries.removeRange(_maxEntries, entries.length);
    }
    await prefs.setString(_key, _encode(entries));
  }

  @override
  Future<List<HistoryEntry>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _read(prefs);
    entries.sort((a, b) => b.savedAtUtc.compareTo(a.savedAtUtc));
    return List.unmodifiable(entries);
  }

  Future<List<HistoryEntry>> _read(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _encode(List<HistoryEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());
}
