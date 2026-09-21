import 'json_types.dart';

/// The two-label percentage split for a reading, e.g. `{"YES": 62, "NO":
/// 38}`. Mirrors `percentages` (`Record<string, number> | null`) on
/// `ReadingResult` in `calculation-engine/src/index.d.ts`.
///
/// Keys are the mode's own labels (see `DecisionMode`), not fixed across
/// modes — read them by label, not by position. For a `ready` or `balanced`
/// status the two values always sum to 100; this class does not enforce
/// that, it only carries what the engine sent.
class ReadingPercentages {
  ReadingPercentages(Map<String, int> values)
    : values = Map.unmodifiable(values);

  final Map<String, int> values;

  int? operator [](String label) => values[label];

  factory ReadingPercentages.fromJson(
    JsonMap json, {
    String context = 'ReadingPercentages',
  }) {
    final out = <String, int>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is! num) {
        throw ReadingDtoException(
          'Field "${entry.key}" in $context.percentages expected a number but '
          'got ${value.runtimeType}',
        );
      }
      out[entry.key] = value.toInt();
    }
    return ReadingPercentages(out);
  }

  JsonMap toJson() => Map<String, dynamic>.unmodifiable(values);
}
