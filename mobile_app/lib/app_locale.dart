/// The languages AstraCue offers, and how they are named to the reader.
///
/// The choice is the reader's alone. Nothing here looks at the device locale,
/// the current country, the birth country or the timezone: those decide a
/// *reading*, never a language. English is the first-launch default.
library;

import 'package:flutter/widgets.dart';

enum AppLocale {
  /// Each option is always written in its own script, so the list stays
  /// readable before any translation is active.
  english('en', 'English', Locale('en')),
  vietnamese('vi', 'Tiếng Việt', Locale('vi')),
  japanese('ja', '日本語', Locale('ja')),
  spanish('es', 'Español', Locale('es')),
  thai('th', 'ไทย', Locale('th')),
  hindi('hi-IN', 'हिन्दी', Locale('hi', 'IN')),
  simplifiedChinese(
    'zh-Hans-CN',
    '简体中文',
    Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
      countryCode: 'CN',
    ),
  );

  const AppLocale(this.tag, this.nativeName, this.locale);

  /// The stored value. A BCP 47 tag rather than an enum index, so a saved
  /// preference survives the list being reordered.
  final String tag;

  /// The option's own name in its own language. Never translated — a reader
  /// looking for their language has to recognise it on sight.
  final String nativeName;

  final Locale locale;

  /// The name `intl` wants for dates, times and numbers. It is derived from
  /// [locale] rather than stored separately so the two cannot drift.
  String get intlName => <String?>[
    locale.languageCode,
    locale.scriptCode,
    locale.countryCode,
  ].whereType<String>().join('_');

  /// The saved tag, or null when it names no language this build offers —
  /// callers then fall back to [AppLocale.english] rather than guessing.
  static AppLocale? fromTag(String? tag) {
    if (tag == null) return null;
    for (final value in AppLocale.values) {
      if (value.tag == tag) return value;
    }
    return null;
  }

  /// The language a [Locale] belongs to, matching most specific first so
  /// `hi-IN` is never mistaken for a different Hindi.
  static AppLocale? forLocale(Locale locale) {
    for (final value in AppLocale.values) {
      if (value.locale == locale) return value;
    }
    for (final value in AppLocale.values) {
      if (value.locale.languageCode == locale.languageCode) return value;
    }
    return null;
  }
}
