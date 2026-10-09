import 'package:flutter/foundation.dart';

import '../app_locale.dart';
import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import 'birth_country_language.dart';
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
  LocaleController({
    required this.store,
    AppLocale? initial,
    this.analytics = const NoopAnalyticsService(),
  }) : _locale = initial ?? AppLocale.english,
       _loaded = initial != null;

  final LocaleStore store;
  final AnalyticsService analytics;

  AppLocale _locale;
  Future<void>? _loading;
  bool _loaded;
  var _provenance = LocaleProvenance.unset;

  AppLocale get locale => _locale;

  /// Why [locale] is what it is. The country rule reads this, and only acts
  /// on [LocaleProvenance.unset].
  LocaleProvenance get provenance => _provenance;

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
    _provenance = stored.provenance;
    final saved = stored.locale;
    if (saved != null && saved != _locale) {
      _locale = saved;
    }
    notifyListeners();
    return;
  }

  /// Switches language at the reader's explicit request, and persists both the
  /// language and the fact that they chose it.
  ///
  /// Tapping the language already showing is still a choice. It changes
  /// nothing on screen, so nothing is repainted, but it is the reader saying
  /// "this one" — and from then on the country rule must leave them alone. An
  /// early return on `locale == _locale` would have quietly discarded that.
  Future<void> select(AppLocale locale) async {
    final previous = _locale;
    final changed = locale != _locale;
    _locale = locale;
    _loaded = true;
    _provenance = LocaleProvenance.manual;
    // Persisted after the notify so the new language paints immediately; a
    // slow write can never hold up the switch the reader just asked for.
    if (changed) notifyListeners();
    await store.save(locale, LocaleProvenance.manual);
    if (changed)
      analytics.record(AnalyticsEvent.languageChanged(previous, locale));
  }

  /// Chooses a language from the reader's country of birth, once.
  ///
  /// Returns which language is now on screen when the visible one changed, and
  /// whether the choice reached storage. A null `changedTo` means nothing
  /// visible happened — either somebody had already chosen, or the country
  /// maps to the language already showing.
  ///
  /// [provenance] is re-read here rather than trusted from before the profile
  /// save: that save is asynchronous, and a reader can open the language sheet
  /// and choose while it runs. The check has to happen at the moment of acting.
  Future<({AppLocale? changedTo, bool saved})> applyBirthCountryDefault(
    String birthCountryCode,
  ) async {
    if (_provenance != LocaleProvenance.unset) {
      return (changedTo: null, saved: true);
    }
    final chosen = languageForBirthCountry(birthCountryCode);
    final changed = chosen != _locale;
    _locale = chosen;
    _loaded = true;
    // Set even when `chosen` is English and nothing moved. The rule has run;
    // recording anything else would let it run again on the next profile.
    _provenance = LocaleProvenance.automatic;
    if (changed) notifyListeners();
    try {
      await store.save(chosen, LocaleProvenance.automatic);
    } catch (_) {
      // The language is applied for this session either way — undoing it now
      // would be a second surprise on top of the first. It simply will not be
      // remembered, and the caller says so rather than claiming otherwise.
      return (changedTo: changed ? chosen : null, saved: false);
    }
    return (changedTo: changed ? chosen : null, saved: true);
  }
}
