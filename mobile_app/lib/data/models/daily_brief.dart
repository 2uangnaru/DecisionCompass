import 'json_types.dart';

/// Duration-weighted symbolic tone of the whole local day. The index is an
/// internal 10–90 scale, not a probability or a physical energy measurement.
class DailyEnergy {
  const DailyEnergy({
    required this.level,
    required this.index,
    required this.dataCoverage,
  });

  final String level;
  final int? index;
  final double dataCoverage;

  String get displayLabel => switch (level) {
    'quiet' => 'QUIET',
    'soft' => 'SOFT',
    'steady' => 'STEADY',
    'lively' => 'LIVELY',
    'bright' => 'BRIGHT',
    'radiant' => 'RADIANT',
    'focused' => 'FOCUSED',
    'flowing' => 'FLOWING',
    _ => '—',
  };

  factory DailyEnergy.fromJson(JsonMap json) {
    const context = 'DailyEnergy';
    final level = requireField<String>(json, 'level', context);
    if (!const {
      'quiet',
      'soft',
      'steady',
      'lively',
      'bright',
      'radiant',
      'focused',
      'flowing',
      'unavailable',
    }.contains(level)) {
      throw const ReadingDtoException('Invalid daily energy level');
    }
    final index = requireNullableField<int>(json, 'index', context);
    final coverage = requireDouble(json, 'dataCoverage', context);
    if ((index != null && (index < 10 || index > 90)) ||
        coverage < 0 ||
        coverage > 1 ||
        (level == 'unavailable') != (index == null)) {
      throw const ReadingDtoException('Invalid daily energy values');
    }
    return DailyEnergy(level: level, index: index, dataCoverage: coverage);
  }

  JsonMap toJson() => {
    'level': level,
    'index': index,
    'dataCoverage': dataCoverage,
  };
}

/// Small daily-signal card content. Mirrors the `dailyBrief` object on
/// `ReadingResult` in `calculation-engine/src/index.d.ts`.
class DailyBrief {
  const DailyBrief({
    required this.luckyNumber,
    required this.colorInspiration,
    this.energy,
  });

  final int luckyNumber;
  final String colorInspiration;

  /// Optional so previously saved reading snapshots remain readable.
  final DailyEnergy? energy;

  factory DailyBrief.fromJson(JsonMap json) {
    const context = 'DailyBrief';
    return DailyBrief(
      luckyNumber: requireInt(json, 'luckyNumber', context),
      colorInspiration: requireField<String>(json, 'colorInspiration', context),
      energy: switch (optionalField<JsonMap>(json, 'energy', context)) {
        final JsonMap value => DailyEnergy.fromJson(value),
        null => null,
      },
    );
  }

  JsonMap toJson() => {
    'luckyNumber': luckyNumber,
    'colorInspiration': colorInspiration,
    if (energy != null) 'energy': energy!.toJson(),
  };
}
