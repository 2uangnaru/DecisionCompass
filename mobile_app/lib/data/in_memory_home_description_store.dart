import 'home_description_deck.dart';

/// In-memory [HomeDescriptionStore] for tests and widget previews.
///
/// It round-trips through the real JSON encoding rather than holding the
/// object, so a test that survives a "restart" is exercising the same
/// validation the on-device store does.
class InMemoryHomeDescriptionStore implements HomeDescriptionStore {
  InMemoryHomeDescriptionStore({this.raw, this.delay = Duration.zero});

  /// Held back by this long, so a test can watch the frame before the record
  /// has answered.
  final Duration delay;

  /// The stored record, in the shape the on-device store would hold. Tests
  /// seed this directly to simulate damaged or foreign data.
  Object? raw;

  var saves = 0;

  @override
  Future<void> save(HomeDescriptionDeckState state) async {
    saves++;
    raw = state.toJson();
  }

  @override
  Future<HomeDescriptionDeckState?> load() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return raw == null ? null : HomeDescriptionDeckState.fromJson(raw);
  }
}
