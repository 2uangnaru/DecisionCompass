import '../daily_energy_messages.dart';
import 'daily_energy_insight_deck.dart';

/// In-memory [DailyEnergyInsightStore] for tests and widget previews.
///
/// It round-trips through the real JSON encoding rather than holding the
/// object, so a test that survives a "restart" exercises the same validation
/// the on-device store does.
class InMemoryDailyEnergyInsightStore implements DailyEnergyInsightStore {
  InMemoryDailyEnergyInsightStore({this.raw, this.delay = Duration.zero});

  /// Every tone's deck in pool order, so the first insight opened for a level
  /// is the one that shipped before the rotation. Tests that are about
  /// something else stay readable this way; the shuffling has its own tests.
  /// [coachMarkShown] defaults to true so a test about something else is not
  /// interrupted by the first-run coach mark; the coach mark has its own
  /// tests, which pass false.
  factory InMemoryDailyEnergyInsightStore.ordered({
    bool coachMarkShown = true,
  }) {
    return InMemoryDailyEnergyInsightStore(
      raw: DailyEnergyInsightState(
        decks: {
          for (final level in dailyEnergyMessagePools.keys)
            level: List<int>.generate(dailyEnergyPoolSize, (i) => i),
        },
        recent: const {},
        entries: const {},
        coachMarkShown: coachMarkShown,
      ).toJson(),
    );
  }

  /// The stored record, in the shape the on-device store would hold. Tests
  /// seed this directly to simulate damaged or foreign data.
  Object? raw;

  /// Held back by this long, so a test can watch the frames before the record
  /// has answered.
  final Duration delay;

  var saves = 0;

  @override
  Future<void> save(DailyEnergyInsightState state) async {
    saves++;
    raw = state.toJson();
  }

  @override
  Future<DailyEnergyInsightState?> load() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return raw == null ? null : DailyEnergyInsightState.fromJson(raw);
  }
}
