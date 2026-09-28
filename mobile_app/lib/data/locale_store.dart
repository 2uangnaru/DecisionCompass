import 'package:shared_preferences/shared_preferences.dart';

import '../app_locale.dart';

/// Where the reader's chosen language lives between runs.
abstract interface class LocaleStore {
  /// The saved language, or null when nothing usable is stored.
  Future<AppLocale?> load();

  Future<void> save(AppLocale locale);
}

/// Persists the language through `shared_preferences`, the store the profile,
/// history and both rotations already use — no new package.
///
/// It has its own key: a language must survive a profile being cleared, and a
/// damaged reading record must not be able to take the UI language with it.
class SharedPreferencesLocaleStore implements LocaleStore {
  const SharedPreferencesLocaleStore();

  static const _key = 'app_locale_v1';

  @override
  Future<AppLocale?> load() async {
    final prefs = await SharedPreferences.getInstance();
    // An unknown tag — a language a later build offered, or a hand-edited
    // value — reads as "nothing saved" rather than crashing the first frame.
    return AppLocale.fromTag(prefs.getString(_key));
  }

  @override
  Future<void> save(AppLocale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.tag);
  }
}

/// In-memory [LocaleStore] for tests and previews. Round-trips the stored tag
/// rather than the enum, so a test exercises the same validation the on-device
/// store does.
class InMemoryLocaleStore implements LocaleStore {
  InMemoryLocaleStore({this.tag, this.delay = Duration.zero});

  final Duration delay;

  String? tag;
  var saves = 0;

  @override
  Future<AppLocale?> load() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return AppLocale.fromTag(tag);
  }

  @override
  Future<void> save(AppLocale locale) async {
    saves++;
    tag = locale.tag;
  }
}
