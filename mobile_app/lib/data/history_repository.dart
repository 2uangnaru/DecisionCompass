import 'history_entry.dart';

/// Abstraction over reading-history persistence.
///
/// UI pages must never touch a storage plugin directly — they depend on this
/// interface instead, wired in via `ReadingDependencies.historyRepository`.
/// See [InMemoryHistoryRepository] in `in_memory_history_repository.dart` for
/// the test/preview double.
abstract interface class HistoryRepository {
  /// Appends [entry]. Saved snapshots are immutable and never rerolled.
  Future<void> save(HistoryEntry entry);

  /// All saved entries, newest first.
  Future<List<HistoryEntry>> list();
}
