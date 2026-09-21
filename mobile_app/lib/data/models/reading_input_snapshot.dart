import 'json_types.dart';

/// Opaque echo of the request the engine actually evaluated
/// (`inputSnapshot` in the contract). Kept as a raw, read-only map rather
/// than a typed model because `calculation-engine/src/index.d.ts` documents
/// its shape as `Record<string, unknown>` and the engine is free to extend
/// it.
///
/// Never log [raw] directly — it carries the normalized birth profile.
class ReadingInputSnapshot {
  ReadingInputSnapshot(JsonMap raw) : raw = deepUnmodifiableMap(raw);

  /// Deeply unmodifiable: nested maps and lists reject mutation too.
  final Map<String, dynamic> raw;

  factory ReadingInputSnapshot.fromJson(JsonMap json) =>
      ReadingInputSnapshot(json);

  JsonMap toJson() => raw;
}
