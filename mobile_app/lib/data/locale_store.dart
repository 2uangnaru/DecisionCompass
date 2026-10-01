import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../app_locale.dart';

/// How the current language came to be the current language.
///
/// The app chooses a language for a new reader from their country of birth,
/// once. Knowing *why* a language is set is what stops that rule running twice,
/// and what stops it overruling somebody who has already said what they want.
enum LocaleProvenance {
  /// Nobody has chosen, and the country rule has not run. The only state in
  /// which the country rule may act.
  unset,

  /// The country rule chose it. Recorded even when the result was English and
  /// nothing on screen changed, because the rule has still been spent.
  automatic,

  /// The reader chose it, by tapping an option in the language sheet. Outranks
  /// everything and is never reconsidered.
  manual,
}

/// The language and the reason for it, as read back from storage.
class StoredLocale {
  const StoredLocale({this.locale, this.provenance = LocaleProvenance.unset});

  /// Null when nothing usable is stored.
  final AppLocale? locale;

  final LocaleProvenance provenance;
}

/// Where the reader's chosen language lives between runs.
abstract interface class LocaleStore {
  Future<StoredLocale> load();

  Future<void> save(AppLocale locale, LocaleProvenance provenance);
}

/// Persists the language through `shared_preferences`, the store the profile,
/// history and both rotations already use — no new package.
///
/// It has its own key: a language must survive a profile being cleared, and a
/// damaged reading record must not be able to take the UI language with it.
class SharedPreferencesLocaleStore implements LocaleStore {
  const SharedPreferencesLocaleStore();

  /// The language and the reason for it, as one JSON record.
  ///
  /// One key, not two. Written separately, a write that succeeded for the
  /// language and failed for the provenance would leave a reader with a
  /// language nobody can account for — and an absent provenance reads as
  /// "chosen by hand", so the mismatch would quietly become a permanent
  /// manual choice the reader never made, with the country rule switched off
  /// for good. A single record is either there or it is not.
  static const _recordKey = 'app_locale_v2';

  /// What builds before the record wrote: a bare BCP 47 tag.
  static const _legacyTagKey = 'app_locale_v1';

  @override
  Future<StoredLocale> load() async {
    final prefs = await SharedPreferences.getInstance();
    final record = prefs.getString(_recordKey);
    if (record != null) {
      final decoded = _decode(record);
      if (decoded != null) return decoded;
      // Unreadable: hand-edited, or written by a build this one does not
      // understand. Falling through to the legacy key is better than guessing.
    }
    // An unknown tag — a language a later build offered, or a hand-edited
    // value — reads as "nothing saved" rather than crashing the first frame.
    final legacy = AppLocale.fromTag(prefs.getString(_legacyTagKey));
    if (legacy == null) return const StoredLocale();
    // A language written before the record existed could only have been
    // chosen by hand: that was the only way to set one. Reading it as manual
    // is what stops the country rule switching an existing reader's language
    // out from under them on first launch after the update.
    return StoredLocale(locale: legacy, provenance: LocaleProvenance.manual);
  }

  static StoredLocale? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final locale = AppLocale.fromTag(decoded['tag'] as String?);
      if (locale == null) return null;
      final provenance = LocaleProvenance.values
          .asNameMap()[decoded['provenance']];
      // A record naming a provenance this build does not know is a record
      // whose meaning is unclear. Manual is the reading that changes nothing
      // on the reader's behalf.
      return StoredLocale(
        locale: locale,
        provenance: provenance ?? LocaleProvenance.manual,
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(AppLocale locale, LocaleProvenance provenance) async {
    final prefs = await SharedPreferences.getInstance();
    final written = await prefs.setString(
      _recordKey,
      jsonEncode({'tag': locale.tag, 'provenance': provenance.name}),
    );
    // `setString` reports failure by returning false rather than by throwing,
    // so an unchecked call is indistinguishable from a successful one. What
    // the reader is told is the caller's decision; what nobody may do is
    // assume it worked.
    if (!written) {
      throw StateError('the language record could not be written');
    }
  }
}

/// In-memory [LocaleStore] for tests and previews. Round-trips the stored tag
/// rather than the enum, so a test exercises the same validation the on-device
/// store does.
class InMemoryLocaleStore implements LocaleStore {
  InMemoryLocaleStore({
    this.tag,
    this.provenanceName,
    this.legacyOnly = false,
    this.delay = Duration.zero,
    this.failSaves = false,
  });

  /// Seeds the state an older build left behind: a language tag and nothing
  /// else.
  ///
  /// [provenanceName] is ignored while this is true, so a test cannot describe
  /// a legacy install that also knew its own provenance — which is the one
  /// thing a legacy install never did.
  final bool legacyOnly;

  final Duration delay;

  String? tag;

  /// Written as a raw name so a test can seed a value an older build wrote —
  /// including no value at all, which is the migration case.
  String? provenanceName;

  /// When true, [save] throws the way a full or locked store would.
  bool failSaves;

  var saves = 0;

  @override
  Future<StoredLocale> load() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final locale = AppLocale.fromTag(tag);
    if (locale == null) return const StoredLocale();
    if (legacyOnly) {
      return StoredLocale(locale: locale, provenance: LocaleProvenance.manual);
    }
    return StoredLocale(
      locale: locale,
      provenance:
          LocaleProvenance.values.asNameMap()[provenanceName] ??
          LocaleProvenance.manual,
    );
  }

  @override
  Future<void> save(AppLocale locale, LocaleProvenance provenance) async {
    if (failSaves) throw StateError('the language could not be written');
    saves++;
    tag = locale.tag;
    provenanceName = provenance.name;
  }
}
