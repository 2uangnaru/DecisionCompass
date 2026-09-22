import 'birth_data_status.dart';
import 'daily_brief.dart';
import 'decision_mode.dart';
import 'engine_warning.dart';
import 'json_types.dart';
import 'lucky_window.dart';
import 'reading_category.dart';
import 'reading_input_snapshot.dart';
import 'reading_percentages.dart';
import 'reading_status.dart';
import 'resolved_context.dart';
import 'time_period.dart';
import 'window_status.dart';

/// The two fusion-axis scores and the score actually used for the requested
/// mode. Mirrors the `axisScores` object on `ReadingResult` in
/// `calculation-engine/src/index.d.ts`.
class AxisScores {
  const AxisScores({
    required this.action,
    required this.change,
    required this.selected,
  });

  final double action;
  final double change;
  final double selected;

  factory AxisScores.fromJson(JsonMap json, {String context = 'AxisScores'}) {
    return AxisScores(
      action: requireDouble(json, 'action', context),
      change: requireDouble(json, 'change', context),
      selected: requireDouble(json, 'selected', context),
    );
  }

  JsonMap toJson() => {
    'action': action,
    'change': change,
    'selected': selected,
  };
}

/// Full engine reading result. Mirrors `ReadingResult` in
/// `calculation-engine/src/index.d.ts`.
///
/// Field nullability intentionally matches the contract: [percentages] and
/// [winner] are always present but may be null (`insufficient_data` /
/// `balanced`); [dataCoverage], [readingKey], [axisScores], [modeScore],
/// [modeBasis], [evaluatedAtUtc], [windowStatus], [dailyBrief],
/// [consumeUnlock] and [monetizationHandledByApp] may be entirely absent
/// (e.g. `period_elapsed` omits most of them).
///
/// `segments` (per-module diagnostics, only present when the request set
/// `diagnostics: true`) is intentionally not modeled — the UI does not need
/// per-module technical detail, and it must never reach analytics.
class ReadingResponse {
  ReadingResponse({
    required this.engineVersion,
    required this.rulesetVersion,
    required Map<String, String> providers,
    required this.status,
    required this.percentages,
    required this.winner,
    this.dataCoverage,
    this.readingKey,
    this.axisScores,
    this.modeScore,
    this.modeBasis,
    required this.period,
    required this.mode,
    required this.category,
    required this.context,
    required this.birthData,
    required List<EngineWarning> warnings,
    required this.inputSnapshot,
    this.evaluatedAtUtc,
    required List<LuckyWindow> luckyWindows,
    this.windowStatus,
    this.dailyBrief,
    this.consumeUnlock,
    this.monetizationHandledByApp,
  }) : providers = Map.unmodifiable(providers),
       warnings = List.unmodifiable(warnings),
       luckyWindows = List.unmodifiable(luckyWindows);

  final String engineVersion;
  final String rulesetVersion;
  final Map<String, String> providers;
  final ReadingStatus status;

  /// Null for `insufficient_data` and `period_elapsed`.
  final ReadingPercentages? percentages;

  /// Null for `insufficient_data`, `balanced` and `period_elapsed`.
  final String? winner;

  final double? dataCoverage;
  final String? readingKey;
  final AxisScores? axisScores;
  final double? modeScore;

  /// Engine-defined basis string, e.g. "overall_acceptance",
  /// "symbolic_polarity". Kept as a raw string so a new mode's basis value
  /// does not break parsing.
  final String? modeBasis;

  final TimePeriod period;
  final DecisionMode mode;

  /// The category the engine actually evaluated, echoed back.
  ///
  /// Any of the seven wire categories may appear here; an unrecognised value is
  /// a contract violation and fails parsing. Read the category from *this*
  /// field rather than from what the UI last selected —
  /// [ReadingCategory.other] deliberately reuses the general formula but stays
  /// its own category with its own reading snapshot.
  final ReadingCategory category;

  final ResolvedContext context;
  final BirthDataStatus birthData;
  final List<EngineWarning> warnings;
  final ReadingInputSnapshot inputSnapshot;
  final String? evaluatedAtUtc;

  /// Empty for NOW and for `insufficient_data`/`period_elapsed`; up to two
  /// entries otherwise.
  final List<LuckyWindow> luckyWindows;

  final WindowStatus? windowStatus;
  final DailyBrief? dailyBrief;

  /// Only ever `false` in practice (set on the elapsed-period state); entitlement
  /// policy itself belongs to the app, not the engine.
  final bool? consumeUnlock;
  final bool? monetizationHandledByApp;

  factory ReadingResponse.fromJson(JsonMap json) {
    const ctx = 'ReadingResponse';

    final rawProviders = requireField<JsonMap>(json, 'providers', ctx);
    final providers = rawProviders.map((key, value) {
      if (value is! String) {
        throw ReadingDtoException(
          'Field "providers.$key" in $ctx expected a String but got ${value.runtimeType}',
        );
      }
      return MapEntry(key, value);
    });

    final rawPercentages = requireNullableField<JsonMap>(
      json,
      'percentages',
      ctx,
    );
    final rawAxisScores = optionalField<JsonMap>(json, 'axisScores', ctx);
    final rawWindowStatus = optionalField<String>(json, 'windowStatus', ctx);
    final rawDailyBrief = optionalField<JsonMap>(json, 'dailyBrief', ctx);
    final rawWarnings = requireField<List<dynamic>>(json, 'warnings', ctx);
    final rawLuckyWindows = requireField<List<dynamic>>(
      json,
      'luckyWindows',
      ctx,
    );

    return ReadingResponse(
      engineVersion: requireField<String>(json, 'engineVersion', ctx),
      rulesetVersion: requireField<String>(json, 'rulesetVersion', ctx),
      providers: providers,
      status: ReadingStatus.fromWire(
        requireField<String>(json, 'status', ctx),
        context: ctx,
      ),
      percentages: rawPercentages == null
          ? null
          : ReadingPercentages.fromJson(rawPercentages, context: ctx),
      winner: requireNullableField<String>(json, 'winner', ctx),
      dataCoverage: optionalDouble(json, 'dataCoverage', ctx),
      readingKey: optionalField<String>(json, 'readingKey', ctx),
      axisScores: rawAxisScores == null
          ? null
          : AxisScores.fromJson(rawAxisScores, context: ctx),
      modeScore: optionalDouble(json, 'modeScore', ctx),
      modeBasis: optionalField<String>(json, 'modeBasis', ctx),
      period: TimePeriod.fromWire(
        requireField<String>(json, 'period', ctx),
        context: ctx,
      ),
      mode: DecisionMode.fromWire(
        requireField<String>(json, 'mode', ctx),
        context: ctx,
      ),
      category: ReadingCategory.fromWire(
        requireField<String>(json, 'category', ctx),
        context: ctx,
      ),
      context: ResolvedContext.fromJson(
        requireField<JsonMap>(json, 'context', ctx),
      ),
      birthData: BirthDataStatus.fromJson(
        requireField<JsonMap>(json, 'birthData', ctx),
      ),
      warnings: List.unmodifiable(
        rawWarnings.map((w) => EngineWarning.fromJson(w, context: ctx)),
      ),
      inputSnapshot: ReadingInputSnapshot.fromJson(
        requireField<JsonMap>(json, 'inputSnapshot', ctx),
      ),
      evaluatedAtUtc: optionalField<String>(json, 'evaluatedAtUtc', ctx),
      luckyWindows: List.unmodifiable(
        rawLuckyWindows.map((w) {
          if (w is! JsonMap) {
            throw ReadingDtoException(
              'Entry in "luckyWindows" in $ctx expected an object but got ${w.runtimeType}',
            );
          }
          return LuckyWindow.fromJson(w);
        }),
      ),
      windowStatus: rawWindowStatus == null
          ? null
          : WindowStatus.fromWire(rawWindowStatus, context: ctx),
      dailyBrief: rawDailyBrief == null
          ? null
          : DailyBrief.fromJson(rawDailyBrief),
      consumeUnlock: optionalField<bool>(json, 'consumeUnlock', ctx),
      monetizationHandledByApp: optionalField<bool>(
        json,
        'monetizationHandledByApp',
        ctx,
      ),
    );
  }

  JsonMap toJson() => {
    'engineVersion': engineVersion,
    'rulesetVersion': rulesetVersion,
    'providers': providers,
    'status': status.toJson(),
    'percentages': percentages?.toJson(),
    'winner': winner,
    if (dataCoverage != null) 'dataCoverage': dataCoverage,
    if (readingKey != null) 'readingKey': readingKey,
    if (axisScores != null) 'axisScores': axisScores!.toJson(),
    if (modeScore != null) 'modeScore': modeScore,
    if (modeBasis != null) 'modeBasis': modeBasis,
    'period': period.toJson(),
    'mode': mode.toJson(),
    'category': category.toJson(),
    'context': context.toJson(),
    'birthData': birthData.toJson(),
    'warnings': warnings.map((w) => w.toJson()).toList(),
    'inputSnapshot': inputSnapshot.toJson(),
    if (evaluatedAtUtc != null) 'evaluatedAtUtc': evaluatedAtUtc,
    'luckyWindows': luckyWindows.map((w) => w.toJson()).toList(),
    if (windowStatus != null) 'windowStatus': windowStatus!.toJson(),
    if (dailyBrief != null) 'dailyBrief': dailyBrief!.toJson(),
    if (consumeUnlock != null) 'consumeUnlock': consumeUnlock,
    if (monetizationHandledByApp != null)
      'monetizationHandledByApp': monetizationHandledByApp,
  };
}
