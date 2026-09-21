/// Barrel export for the calculation-engine DTOs.
///
/// These enum/class names intentionally mirror
/// `calculation-engine/src/index.d.ts` (e.g. `DecisionMode`, `TimePeriod`).
/// [lib/models.dart](../../models.dart) already declares UI-only types with
/// the *same names* for the mock prototype flow. Do not import both
/// libraries unprefixed into the same file — import this one with a prefix
/// (e.g. `import 'data/models/models.dart' as engine;`) when the two need to
/// coexist, until the mock models are replaced.
library;

export 'birth_data_status.dart';
export 'birth_profile.dart';
export 'current_context.dart';
export 'current_location.dart';
export 'daily_brief.dart';
export 'decision_mode.dart';
export 'engine_warning.dart';
export 'json_types.dart';
export 'lucky_window.dart';
export 'reading_category.dart';
export 'reading_input_snapshot.dart';
export 'reading_percentages.dart';
export 'reading_request.dart';
export 'reading_response.dart';
export 'reading_status.dart';
export 'resolved_context.dart';
export 'time_period.dart';
export 'traditional_profile.dart';
export 'window_status.dart';
export 'zone_source.dart';
