import '../app_profile.dart';
import 'models/models.dart' as engine;

/// A read-only preview of today's ambient `DailyBrief` — the color/lucky
/// number shown on Home before the user has revealed anything — independent
/// of any decision mode/period/category.
///
/// Deliberately its own interface rather than reusing `ReadingRepository`
/// directly from `HomePage`: the ambient preview and an actual reveal are
/// different actions (see [EngineDailyBriefProvider]'s doc comment), and
/// keeping them separate means a background preview never shows up in a
/// reveal flow's own request/instant tracking.
abstract interface class DailyBriefProvider {
  Future<engine.DailyBrief?> preview(AppProfile profile);
}
