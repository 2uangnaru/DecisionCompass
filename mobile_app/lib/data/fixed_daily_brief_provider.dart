import '../app_profile.dart';
import 'daily_brief_provider.dart';
import 'models/models.dart' as engine;

/// Deterministic [DailyBriefProvider] for tests and widget previews. Returns
/// [response] (defaulting to null, i.e. Home's placeholder look) without
/// touching any platform channel or the reveal flow's own fakes.
class FixedDailyBriefProvider implements DailyBriefProvider {
  FixedDailyBriefProvider({this.response, this.responseFor});

  engine.DailyBrief? response;

  /// Answers from the profile instead of ignoring it, for the tests that have
  /// to tell a brief computed for one profile from a brief computed for
  /// another. Takes precedence over [response] when set.
  engine.DailyBrief? Function(AppProfile profile)? responseFor;

  int previewCalls = 0;

  /// Every profile a preview was asked for, in order.
  final profiles = <AppProfile>[];

  @override
  Future<engine.DailyBrief?> preview(AppProfile profile) async {
    previewCalls++;
    profiles.add(profile);
    return responseFor?.call(profile) ?? response;
  }
}
