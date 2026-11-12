import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the first-time Reveal orb hand tutorial on `RitualPage`
/// has already been dismissed by tapping the Reveal button.
abstract interface class RitualTutStore {
  Future<bool> isSeen();

  Future<void> markSeen();
}

/// In-memory [RitualTutStore] for tests and widget previews.
class InMemoryRitualTutStore implements RitualTutStore {
  InMemoryRitualTutStore({bool initialSeen = false}) : _seen = initialSeen;

  bool _seen;

  bool get seen => _seen;

  @override
  Future<bool> isSeen() async => _seen;

  @override
  Future<void> markSeen() async {
    _seen = true;
  }
}

/// Persists the Ritual orb hand tutorial dismissal on-device via
/// `shared_preferences`.
class SharedPreferencesRitualTutStore implements RitualTutStore {
  const SharedPreferencesRitualTutStore();

  static const _key = 'ritual_reveal_hand_tut_seen_v1';

  @override
  Future<bool> isSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
