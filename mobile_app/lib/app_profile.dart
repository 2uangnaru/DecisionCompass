import 'data/models/models.dart' as engine;
import 'models.dart';

/// Birth-country choices offered in onboarding, mapped explicitly to
/// ISO-3166 alpha-2 codes. The engine expects the code; a display name would
/// be rejected.
const birthCountryChoices = <({String code, String label})>[
  (code: 'US', label: 'United States'),
  (code: 'GB', label: 'United Kingdom'),
  (code: 'DE', label: 'Germany'),
  (code: 'JP', label: 'Japan'),
  (code: 'VN', label: 'Vietnam'),
];

/// The profile collected in onboarding, carried for the whole session.
///
/// Immutable, and intentionally without a value-bearing `toString`: these
/// fields must never reach a log line.
class AppProfile {
  const AppProfile({
    required this.userName,
    required this.birthDate,
    required this.birthCountryCode,
    required this.zodiacSign,
    required this.useCurrentLocation,
    this.birthTime,
    this.traditionalProfile,
  });

  /// Display name only; never sent to the engine.
  final String userName;

  final DateTime birthDate;

  /// `HH:mm`, or null when the user marked the birth time unknown.
  final String? birthTime;

  /// ISO-3166 alpha-2, chosen explicitly by the user. Never derived from the
  /// current location.
  final String birthCountryCode;

  /// Not collected in this MVP; the engine reduces coverage rather than
  /// guessing, and it must never be inferred from name or country.
  final engine.TraditionalProfile? traditionalProfile;

  final ZodiacSign zodiacSign;

  /// The user's explicit answer on the explainer screen: true only after
  /// "Allow Current Location", false after "Use Device Time Zone Instead".
  ///
  /// This is what gates the location lookup — not the OS permission state, so
  /// a permission granted in an earlier session cannot resurrect location
  /// collection for someone who has since opted out.
  final bool useCurrentLocation;

  String get formattedBirthDate =>
      '${birthDate.year.toString().padLeft(4, '0')}-'
      '${birthDate.month.toString().padLeft(2, '0')}-'
      '${birthDate.day.toString().padLeft(2, '0')}';

  /// `birthTimezone` stays null for the MVP: the engine derives candidate
  /// zones from the country, and the current location must never stand in for
  /// the birthplace.
  engine.BirthProfile toBirthProfile() => engine.BirthProfile(
    birthDate: formattedBirthDate,
    birthTime: birthTime,
    birthCountry: birthCountryCode,
    traditionalProfile: traditionalProfile,
  );
}
