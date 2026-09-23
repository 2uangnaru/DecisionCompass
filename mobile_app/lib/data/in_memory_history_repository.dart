import 'history_entry.dart';
import 'history_repository.dart';

/// In-memory [HistoryRepository] for tests and widget previews.
///
/// Never touches a platform plugin, so it is safe in any widget test without
/// mocking `shared_preferences`.
class InMemoryHistoryRepository implements HistoryRepository {
  final List<HistoryEntry> _entries = [];

  /// Every entry saved so far, in save order (most recent last).
  List<HistoryEntry> get saved => List.unmodifiable(_entries);

  @override
  Future<void> save(HistoryEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<HistoryEntry>> list() async {
    final ordered = List<HistoryEntry>.of(_entries)
      ..sort((a, b) => b.savedAtUtc.compareTo(a.savedAtUtc));
    return List.unmodifiable(ordered);
  }
}
