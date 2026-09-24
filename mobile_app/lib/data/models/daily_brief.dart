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

/// One of the engine's twenty palette entries. Editorial symbolism, not a
/// Yong Shen claim.
class DailyColor {
  const DailyColor({
    required this.key,
    required this.name,
    required this.hex,
    required this.element,
    required this.stem,
  });

  final String key;
  final String name;

  /// `#RRGGBB`, straight from the engine, so the app never invents a shade.
  final String hex;

  /// One of wood, fire, earth, metal, water.
  final String element;

  /// The Heavenly Stem this colour belongs to, 0–9.
  final int stem;

  /// The hex as an `0xAARRGGBB` value for Flutter's `Color`.
  int get argb => 0xFF000000 | int.parse(hex.substring(1), radix: 16);

  factory DailyColor.fromJson(JsonMap json, String context) {
    final hex = requireField<String>(json, 'hex', context);
    final element = requireField<String>(json, 'element', context);
    final stem = requireInt(json, 'stem', context);
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex) ||
        !const {'wood', 'fire', 'earth', 'metal', 'water'}.contains(element) ||
        stem < 0 ||
        stem > 9) {
      throw const ReadingDtoException('Invalid daily colour');
    }
    return DailyColor(
      key: requireField<String>(json, 'key', context),
      name: requireField<String>(json, 'name', context),
      hex: hex,
      element: element,
      stem: stem,
    );
  }

  JsonMap toJson() => {
    'key': key,
    'name': name,
    'hex': hex,
    'element': element,
    'stem': stem,
  };
}

/// The day's colour pairing: the lead from the day stem's own family, the
/// supporting from the family that element generates. Always two different
/// families, so the swatches are visually distinct.
class DailyColors {
  const DailyColors({
    required this.lead,
    required this.supporting,
    this.meaning = 'symbolic_colour_pairing_not_yong_shen',
  });

  final DailyColor lead;
  final DailyColor supporting;

  /// The engine's own disclaimer, carried rather than restated by the app.
  final String meaning;

  factory DailyColors.fromJson(JsonMap json) {
    const context = 'DailyColors';
    final colors = DailyColors(
      lead: DailyColor.fromJson(
        requireField<JsonMap>(json, 'lead', context),
        '$context.lead',
      ),
      supporting: DailyColor.fromJson(
        requireField<JsonMap>(json, 'supporting', context),
        '$context.supporting',
      ),
      meaning:
          optionalField<String>(json, 'meaning', context) ??
          'symbolic_colour_pairing_not_yong_shen',
    );
    if (colors.lead.element == colors.supporting.element ||
        colors.lead.hex.toUpperCase() == colors.supporting.hex.toUpperCase()) {
      throw const ReadingDtoException('Daily colours must be distinct');
    }
    return colors;
  }

  JsonMap toJson() => {
    'lead': lead.toJson(),
    'supporting': supporting.toJson(),
    'meaning': meaning,
  };
}

/// Small daily-signal card content. Mirrors the `dailyBrief` object on
/// `ReadingResult` in `calculation-engine/src/index.d.ts`.
class DailyBrief {
  const DailyBrief({
    required this.luckyNumber,
    this.colors,
    this.legacyColorInspiration,
    this.energy,
  }) : assert(colors != null || legacyColorInspiration != null);

  final int luckyNumber;

  /// New readings have a pair. Older saved snapshots retain their single
  /// colour instead of being silently recalculated with today's rules.
  final DailyColors? colors;
  final String? legacyColorInspiration;

  /// Optional so previously saved reading snapshots remain readable.
  final DailyEnergy? energy;

  factory DailyBrief.fromJson(JsonMap json) {
    const context = 'DailyBrief';
    final rawColors = optionalField<JsonMap>(json, 'colors', context);
    final legacyColor = rawColors == null
        ? requireField<String>(json, 'colorInspiration', context)
        : null;
    if (legacyColor != null && legacyColor.isEmpty) {
      throw const ReadingDtoException('Invalid legacy daily colour');
    }
    return DailyBrief(
      luckyNumber: requireInt(json, 'luckyNumber', context),
      colors: rawColors == null ? null : DailyColors.fromJson(rawColors),
      legacyColorInspiration: legacyColor,
      energy: switch (optionalField<JsonMap>(json, 'energy', context)) {
        final JsonMap value => DailyEnergy.fromJson(value),
        null => null,
      },
    );
  }

  JsonMap toJson() => {
    'luckyNumber': luckyNumber,
    if (colors != null) 'colors': colors!.toJson(),
    if (legacyColorInspiration != null)
      'colorInspiration': legacyColorInspiration,
    if (energy != null) 'energy': energy!.toJson(),
  };
}
