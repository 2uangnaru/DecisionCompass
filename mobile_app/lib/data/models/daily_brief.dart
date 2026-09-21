import 'json_types.dart';

/// Small daily-signal card content. Mirrors the `dailyBrief` object on
/// `ReadingResult` in `calculation-engine/src/index.d.ts`.
class DailyBrief {
  const DailyBrief({required this.luckyNumber, required this.colorInspiration});

  final int luckyNumber;
  final String colorInspiration;

  factory DailyBrief.fromJson(JsonMap json) {
    const context = 'DailyBrief';
    return DailyBrief(
      luckyNumber: requireInt(json, 'luckyNumber', context),
      colorInspiration: requireField<String>(json, 'colorInspiration', context),
    );
  }

  JsonMap toJson() => {
    'luckyNumber': luckyNumber,
    'colorInspiration': colorInspiration,
  };
}
