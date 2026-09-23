import 'models/models.dart';

/// A saved snapshot of a completed reading, immutable once created.
///
/// History never rerolls: whatever [reading] the user actually saw is what
/// gets replayed later, even if the ruleset, timezone rules or formulas
/// change afterwards.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.reading,
    required this.savedAtUtc,
  });

  /// Unique per save. Prefer the engine's `readingKey`; some statuses (e.g.
  /// `period_elapsed`) omit it, so callers fall back to a value derived from
  /// the reading itself.
  final String id;
  final ReadingResponse reading;
  final DateTime savedAtUtc;

  factory HistoryEntry.fromJson(JsonMap json) {
    const context = 'HistoryEntry';
    return HistoryEntry(
      id: requireField<String>(json, 'id', context),
      reading: ReadingResponse.fromJson(
        requireField<JsonMap>(json, 'reading', context),
      ),
      savedAtUtc: DateTime.parse(
        requireField<String>(json, 'savedAtUtc', context),
      ),
    );
  }

  JsonMap toJson() => {
    'id': id,
    'reading': reading.toJson(),
    'savedAtUtc': savedAtUtc.toIso8601String(),
  };
}
