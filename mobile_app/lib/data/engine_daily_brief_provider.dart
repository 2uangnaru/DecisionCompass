import '../app_profile.dart';
import 'current_context_provider.dart';
import 'daily_brief_provider.dart';
import 'models/models.dart' as engine;
import 'reading_repository.dart';

/// Computes a real `DailyBrief` via one default-mode/period/category engine
/// reading, discarding everything else the response carries.
///
/// `calculation-engine/src/index.js`'s `dailyBrief` (`COLORS`/`briefNumber`)
/// depends only on the profile and today's calendar date — never on
/// `mode`/`period`/`category` — so there is no lighter-weight engine entry
/// point, but any default request produces the same brief a real reveal
/// would have.
///
/// Location is deliberately never used here: this ambient Home card is not
/// the explicit per-reading action the user gave location consent for, so it
/// always resolves from the device timezone alone.
class EngineDailyBriefProvider implements DailyBriefProvider {
  const EngineDailyBriefProvider({
    required this.repository,
    required this.contextProvider,
  });

  final ReadingRepository repository;
  final CurrentContextProvider contextProvider;

  @override
  Future<engine.DailyBrief?> preview(AppProfile profile) async {
    try {
      final context = await contextProvider.capture(
        instantUtc: DateTime.now().toUtc(),
        includeLocation: false,
      );
      final response = await repository.calculate(
        engine.ReadingRequest(
          profile: profile.toBirthProfile(),
          context: context,
          mode: engine.DecisionMode.yesNo,
          period: engine.TimePeriod.now,
          category: engine.ReadingCategory.general,
        ),
      );
      return response.dailyBrief;
    } catch (_) {
      // An ambient preview card is never worth surfacing an error state for;
      // it simply falls back to its placeholder look.
      return null;
    }
  }
}
