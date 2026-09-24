import 'json_types.dart';

/// The two-label percentage split for a reading, e.g. `{"YES": 56.1, "NO":
/// 43.9}`. Mirrors `percentages` (`Record<string, number> | null`) on
/// `ReadingResult` in `calculation-engine/src/index.d.ts`.
///
/// Held as integer tenths of a percent, the same representation the engine
/// builds them from, so the two sides always add to exactly 100.0 and no
/// floating-point sum can drift. A percentage is symbolic alignment — never a
/// probability or a chance of success.
///
/// Keys are the mode's own labels (see `DecisionMode`), not fixed across
/// modes — read them by label, not by position.
class ReadingPercentages {
  ReadingPercentages(Map<String, int> tenths)
    : tenths = Map.unmodifiable(tenths);

  /// Tenths of a percent: 561 means 56.1%.
  final Map<String, int> tenths;

  /// The same values as percentages with one decimal.
  Map<String, double> get values => <String, double>{
    for (final entry in tenths.entries) entry.key: entry.value / 10,
  };

  double? operator [](String label) {
    final value = tenths[label];
    return value == null ? null : value / 10;
  }

  /// One decimal, always — "56.0", never "56".
  ///
  /// The decimal separator is not localised yet: the app ships English only,
  /// and adding a formatting package for one number was not worth it. A
  /// locale that writes "56,0" will need `intl` here.
  String? display(String label) => this[label]?.toStringAsFixed(1);

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
      out[entry.key] = (value * 10).round();
    }
    return ReadingPercentages(out);
  }

  JsonMap toJson() => <String, dynamic>{
    for (final entry in tenths.entries) entry.key: entry.value / 10,
  };
}
