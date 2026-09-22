import 'birth_profile.dart';
import 'current_context.dart';
import 'decision_mode.dart';
import 'json_types.dart';
import 'reading_category.dart';
import 'time_period.dart';

/// Request payload sent to the calculation engine. Mirrors `ReadingInput` in
/// `calculation-engine/src/index.d.ts`.
class ReadingRequest {
  const ReadingRequest({
    required this.profile,
    required this.context,
    this.period,
    this.mode,
    this.category = ReadingCategory.general,
    this.diagnostics,
  });

  final BirthProfile profile;
  final CurrentContext context;
  final TimePeriod? period;
  final DecisionMode? mode;

  /// Which area of life the reading is about, defaulting to
  /// [ReadingCategory.general] when the caller does not choose.
  ///
  /// All seven wire categories are supported; the engine rejects anything else
  /// with `INVALID_CATEGORY`. The category changes how module evidence is
  /// weighted and fused before the decision-mode projection, so it is part of
  /// the reading's identity — see the category rules in
  /// `calculation-engine/VERIFICATION.md`.
  final ReadingCategory category;

  /// Never sent from the app in production; diagnostics carry technical
  /// module internals that must not reach analytics.
  final bool? diagnostics;

  factory ReadingRequest.fromJson(JsonMap json) {
    const ctx = 'ReadingRequest';
    final rawPeriod = optionalField<String>(json, 'period', ctx);
    final rawMode = optionalField<String>(json, 'mode', ctx);
    final rawCategory = optionalField<String>(json, 'category', ctx);
    return ReadingRequest(
      profile: BirthProfile.fromJson(
        requireField<JsonMap>(json, 'profile', ctx),
      ),
      context: CurrentContext.fromJson(
        requireField<JsonMap>(json, 'context', ctx),
      ),
      period: rawPeriod == null
          ? null
          : TimePeriod.fromWire(rawPeriod, context: ctx),
      mode: rawMode == null
          ? null
          : DecisionMode.fromWire(rawMode, context: ctx),
      category: rawCategory == null
          ? ReadingCategory.general
          : ReadingCategory.fromWire(rawCategory, context: ctx),
      diagnostics: optionalField<bool>(json, 'diagnostics', ctx),
    );
  }

  JsonMap toJson() => {
    'profile': profile.toJson(),
    'context': context.toJson(),
    if (period != null) 'period': period!.toJson(),
    if (mode != null) 'mode': mode!.toJson(),
    'category': category.toJson(),
    if (diagnostics != null) 'diagnostics': diagnostics,
  };
}
