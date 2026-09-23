import '../app_profile.dart';
import 'daily_brief_provider.dart';
import 'models/models.dart' as engine;

/// Deterministic [DailyBriefProvider] for tests and widget previews. Returns
/// [response] (defaulting to null, i.e. Home's placeholder look) without
/// touching any platform channel or the reveal flow's own fakes.
class FixedDailyBriefProvider implements DailyBriefProvider {
  FixedDailyBriefProvider({this.response});

  engine.DailyBrief? response;
  int previewCalls = 0;

  @override
  Future<engine.DailyBrief?> preview(AppProfile profile) async {
    previewCalls++;
    return response;
  }
}
