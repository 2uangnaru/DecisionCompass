import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';

import 'country_names_data.dart';

/// Country names for the birth-country picker, in the reader's language.
///
/// `country_picker` carries its own lists, but not for every language this app
/// offers: it has **no Vietnamese and no Thai list at all**, and it answers a
/// Hindi locale with its **Nepali** one — `फ्रान्स` for France where Hindi
/// writes `फ़्रांस`. Those three are served from bundled CLDR instead, which
/// is the same data ICU, Android and iOS use, so a country reads here the way
/// it reads everywhere else on the reader's phone. The four the package does
/// carry correctly (`en`, `es`, `ja`, `zh`) keep using it.
///
/// Nothing is fetched or translated at runtime: `country_names_data.dart` is
/// generated source, and the Unicode licence ships beside it.
///
/// This changes only what is *displayed*. The value a reading is calculated
/// from is the ISO 3166-1 alpha-2 code, which never passes through here.
class CompassCountryLocalizations extends CountryLocalizations {
  CompassCountryLocalizations(super.locale);

  /// The languages served from bundled CLDR rather than from the package.
  static const _cldr = <String, Map<String, String>>{
    'vi': countryNamesVI,
    'th': countryNamesTH,
    'hi': countryNamesHI,
  };

  /// Whether this build can name countries in [locale] at all. Every language
  /// the app offers is covered — four by the package, three by CLDR — so a
  /// birth-country screen is never half-translated.
  static bool covers(Locale locale) =>
      _cldr.containsKey(locale.languageCode) ||
      const {'en', 'es', 'ja', 'zh', 'ko'}.contains(locale.languageCode);

  @override
  String? countryName({required String countryCode}) {
    if (countryCode == 'KR' &&
        (locale.languageCode == 'en' || locale.languageCode.isEmpty)) {
      return 'Korea';
    }
    final bundled = _cldr[locale.languageCode];
    if (bundled != null) return bundled[countryCode];
    final defaultName = super.countryName(countryCode: countryCode);
    if (countryCode == 'KR' && defaultName == 'South Korea') {
      return 'Korea';
    }
    return defaultName;
  }
}

/// Installs [CompassCountryLocalizations] for every language the app offers.
class CompassCountryNamesDelegate
    extends LocalizationsDelegate<CountryLocalizations> {
  const CompassCountryNamesDelegate();

  @override
  bool isSupported(Locale locale) => CompassCountryLocalizations.covers(locale);

  /// Synchronous on purpose. The package's own delegate answers with a plain
  /// `Future`, which makes `Localizations` resolve over a frame and shows the
  /// app an empty screen before its first real paint. There is nothing to wait
  /// for — every table here is compiled in.
  @override
  Future<CountryLocalizations> load(Locale locale) =>
      SynchronousFuture(CompassCountryLocalizations(locale));

  @override
  bool shouldReload(LocalizationsDelegate<CountryLocalizations> old) => false;
}
