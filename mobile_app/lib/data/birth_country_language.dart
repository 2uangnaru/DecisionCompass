import '../app_locale.dart';

/// Which bundled language a country of birth suggests, for the one automatic
/// choice the app makes on a reader's behalf.
///
/// Deliberately its own file, and deliberately not derived from anything the
/// engine knows. The engine reads a birth country to build a chart; this reads
/// it to guess which of seven translations a new reader is most likely to want
/// to read. They are different questions about the same two letters, and
/// letting one drift into the other would mean a change to a chart rule could
/// silently change somebody's UI language.
///
/// Nothing here consults GPS, IP address, SIM, device region, current location
/// or current timezone. The only input is the ISO code the reader themselves
/// chose on the profile form.
///
/// The list is short on purpose. A country only appears when the mapping is
/// unambiguous enough to be worth making without asking:
///
/// - **IN is absent.** India has more than twenty official languages and
///   English is widely used in exactly the kind of app this is. Picking Hindi
///   for every reader born there would be a guess about a person, not about a
///   country, so no country maps to Hindi at all — it stays a choice.
/// - **TW and HK are absent.** Both read traditional characters, which this
///   app does not bundle. Sending them Simplified would be worse than English.
/// - The Spanish list is Spain and the Spanish-speaking Americas. Brazil
///   (Portuguese) and Equatorial Guinea are not on it.
///
/// Whatever this returns is only ever a starting point: one tap in the
/// language sheet overrides it permanently.
const Set<String> _spanishSpeaking = <String>{
  'ES',
  'MX',
  'AR',
  'CO',
  'CL',
  'PE',
  'VE',
  'EC',
  'GT',
  'CU',
  'BO',
  'DO',
  'HN',
  'PY',
  'SV',
  'NI',
  'CR',
  'PA',
  'UY',
};

/// The language [countryCode] suggests, or [AppLocale.english] when it
/// suggests nothing in particular.
///
/// [countryCode] is an ISO 3166-1 alpha-2 code. Case and surrounding space are
/// tolerated because this reads a stored profile field, not a literal.
AppLocale languageForBirthCountry(String countryCode) {
  final code = countryCode.trim().toUpperCase();
  if (_spanishSpeaking.contains(code)) return AppLocale.spanish;
  return switch (code) {
    'VN' => AppLocale.vietnamese,
    'JP' => AppLocale.japanese,
    'KR' => AppLocale.korean,
    'TH' => AppLocale.thai,
    'CN' => AppLocale.simplifiedChinese,
    // Including the empty string, a three-letter code, or anything else a
    // future country picker might hand over: English is the honest answer to
    // "no idea", and it is what the app already shows.
    _ => AppLocale.english,
  };
}

/// Every country code this mapping treats as anything other than English.
///
/// Exposed so a test can assert the whole table at once rather than sampling
/// it, and so the absences above are checkable rather than only documented.
Map<String, AppLocale> get birthCountryLanguages => <String, AppLocale>{
  'VN': AppLocale.vietnamese,
  'JP': AppLocale.japanese,
  'KR': AppLocale.korean,
  'TH': AppLocale.thai,
  'CN': AppLocale.simplifiedChinese,
  for (final code in _spanishSpeaking) code: AppLocale.spanish,
};
