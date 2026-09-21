import 'json_types.dart';

/// A single favorable time window for a future (non-NOW) period. Mirrors
/// `LuckyWindow` in `calculation-engine/src/index.d.ts`.
///
/// [score] is a symbolic timing alignment, not a real-world probability —
/// see [meaning].
class LuckyWindow {
  const LuckyWindow({
    required this.startUtc,
    required this.endUtc,
    required this.startLocal,
    required this.endLocal,
    required this.score,
    required this.dataCoverage,
    required this.hourBranch,
    required this.meaning,
  });

  final String startUtc;
  final String endUtc;
  final String startLocal;
  final String endLocal;
  final double score;
  final double dataCoverage;
  final int hourBranch;

  /// Always the literal "symbolic_timing_score_not_probability" today; kept
  /// as a plain string (not an enum) so an engine change here cannot crash
  /// parsing.
  final String meaning;

  factory LuckyWindow.fromJson(JsonMap json) {
    const context = 'LuckyWindow';
    return LuckyWindow(
      startUtc: requireField<String>(json, 'startUtc', context),
      endUtc: requireField<String>(json, 'endUtc', context),
      startLocal: requireField<String>(json, 'startLocal', context),
      endLocal: requireField<String>(json, 'endLocal', context),
      score: requireDouble(json, 'score', context),
      dataCoverage: requireDouble(json, 'dataCoverage', context),
      hourBranch: requireInt(json, 'hourBranch', context),
      meaning: requireField<String>(json, 'meaning', context),
    );
  }

  JsonMap toJson() => {
    'startUtc': startUtc,
    'endUtc': endUtc,
    'startLocal': startLocal,
    'endLocal': endLocal,
    'score': score,
    'dataCoverage': dataCoverage,
    'hourBranch': hourBranch,
    'meaning': meaning,
  };
}
