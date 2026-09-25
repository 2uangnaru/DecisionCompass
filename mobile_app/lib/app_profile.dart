import 'data/models/models.dart' as engine;
import 'models.dart';

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
    this.safetyAcknowledged = false,
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

  /// Whether the user has accepted the Responsible Use & Safety boundaries.
  /// Required before the first reading is revealed.
  final bool safetyAcknowledged;

  AppProfile copyWith({
    String? userName,
    DateTime? birthDate,
    String? birthTime,
    String? birthCountryCode,
    engine.TraditionalProfile? traditionalProfile,
    ZodiacSign? zodiacSign,
    bool? useCurrentLocation,
    bool? safetyAcknowledged,
  }) {
    return AppProfile(
      userName: userName ?? this.userName,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      birthCountryCode: birthCountryCode ?? this.birthCountryCode,
      traditionalProfile: traditionalProfile ?? this.traditionalProfile,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      useCurrentLocation: useCurrentLocation ?? this.useCurrentLocation,
      safetyAcknowledged: safetyAcknowledged ?? this.safetyAcknowledged,
    );
  }

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

  /// For local persistence only (see `ProfileRepository`) — never sent to the
  /// engine or to analytics. [zodiacSign] is not stored: it is re-derived from
  /// [birthDate] on load, so the two can never disagree.
  Map<String, dynamic> toJson() => {
    'userName': userName,
    'birthDate': formattedBirthDate,
    if (birthTime != null) 'birthTime': birthTime,
    'birthCountryCode': birthCountryCode,
    if (traditionalProfile != null)
      'traditionalProfile': traditionalProfile!.wireValue,
    'useCurrentLocation': useCurrentLocation,
    'safetyAcknowledged': safetyAcknowledged,
  };

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    final birthDate = DateTime.parse(json['birthDate'] as String);
    final rawTraditionalProfile = json['traditionalProfile'] as String?;
    return AppProfile(
      userName: json['userName'] as String,
      birthDate: birthDate,
      birthTime: json['birthTime'] as String?,
      birthCountryCode: json['birthCountryCode'] as String,
      traditionalProfile: rawTraditionalProfile == null
          ? null
          : engine.TraditionalProfile.fromWire(rawTraditionalProfile),
      zodiacSign: zodiacForDate(birthDate),
      useCurrentLocation: json['useCurrentLocation'] as bool,
      safetyAcknowledged: json['safetyAcknowledged'] as bool? ?? false,
    );
  }
}
