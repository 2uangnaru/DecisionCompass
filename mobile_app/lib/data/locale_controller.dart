import 'package:flutter/foundation.dart';

import '../app_locale.dart';
import 'locale_store.dart';

/// Holds the language the whole app renders in.
///
/// A [ChangeNotifier] because every screen has to follow the same choice at
/// once: switching on the welcome screen must re-render onboarding, the date
/// and time pickers, the safety sheet and Home together, with no screen left
/// in the previous language.
///
/// The choice is stored before a profile exists, so a reader who picks their
/// language and then closes the app comes back to it.
class LocaleController extends ChangeNotifier {
  LocaleController({required this.store, AppLocale? initial})
    : _locale = initial ?? AppLocale.english,
      _loaded = initial != null;

  final LocaleStore store;

  AppLocale _locale;
  Future<void>? _loading;
  bool _loaded;

  AppLocale get locale => _locale;

  /// Whether the saved choice has been read. The app holds the first frame
  /// until it has, so a reader never sees English flash past before their own
  /// language arrives.
  bool get isLoaded => _loaded;

  /// Reads the stored choice once. Repeat callers share the same future.
  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final stored = await store.load();
    _loaded = true;
    _loading = null;
    if (stored != null && stored != _locale) {
      _locale = stored;
    }
    notifyListeners();
    return;
  }

  /// Switches language and persists it. Selecting the current language does
  /// nothing at all, so the screen does not rebuild for a no-op tap.
  Future<void> select(AppLocale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    _loaded = true;
    notifyListeners();
    // Persisted after the notify so the new language paints immediately; a
    // slow write can never hold up the switch the reader just asked for.
    await store.save(locale);
  }
}
