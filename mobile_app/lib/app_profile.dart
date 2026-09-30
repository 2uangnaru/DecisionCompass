import 'data/models/models.dart' as engine;
import 'models.dart';

/// The profile collected in onboarding, carried for the whole session.
///
/// Immutable, and intentionally without a value-bearing `toString`: these
/// fields must never reach a log line.
class AppProfile {
  const AppProfile({
    this.userName,
    required this.birthDate,
    required this.birthCountryCode,
    required this.zodiacSign,
    required this.useCurrentLocation,
    this.birthTime,
    this.traditionalProfile,
    this.safetyAcknowledged = false,
    this.createdAt,
  });

  /// The timestamp when the user created their profile, used for journey tenure progression.
  final DateTime? createdAt;

  /// The name the reader typed, or null when they left it blank.
  ///
  /// Null is a *state*, not a word: it means "no name given", and the greeting
  /// resolves it to `Explorer` — or that word's translation — at display time,
  /// through `profileDisplayName`. Storing the translated word instead would
  /// freeze whichever language happened to be active when the profile was
  /// created, so a reader who signed up in Thai and later switched to English
  /// would keep being greeted in Thai.
  ///
  /// Display only; never sent to the engine.
  final String? userName;

  /// Whether the greeting will use the default name.
  bool get hasDefaultName => userName == null;

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

  /// [userName] cannot be *cleared* through this, only replaced: a null
  /// argument means "leave it alone", which is the usual `copyWith`
  /// convention. Nothing needs to clear a name, and a `copyWith` that could
  /// would make it easy to erase one by accident.
  AppProfile copyWith({
    String? userName,
    DateTime? birthDate,
    String? birthTime,
    String? birthCountryCode,
    engine.TraditionalProfile? traditionalProfile,
    ZodiacSign? zodiacSign,
    bool? useCurrentLocation,
    bool? safetyAcknowledged,
    DateTime? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
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
    // Omitted entirely when the reader gave no name, so the stored record
    // says "default" rather than naming a language's word for it.
    if (userName != null) 'userName': userName,
    'birthDate': formattedBirthDate,
    if (birthTime != null) 'birthTime': birthTime,
    'birthCountryCode': birthCountryCode,
    if (traditionalProfile != null)
      'traditionalProfile': traditionalProfile!.wireValue,
    'useCurrentLocation': useCurrentLocation,
    'safetyAcknowledged': safetyAcknowledged,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    final birthDate = DateTime.parse(json['birthDate'] as String);
    final rawTraditionalProfile = json['traditionalProfile'] as String?;
    final rawCreatedAt = json['createdAt'] as String?;
    // A record written before the default-name state existed always has this
    // key, so it is read as a name the reader chose — including the literal
    // string `Explorer`, which such a reader may well have typed. Guessing
    // that a stored `Explorer` was really a default would silently rename
    // anyone who had entered it on purpose.
    return AppProfile(
      userName: json['userName'] as String?,
      birthDate: birthDate,
      birthTime: json['birthTime'] as String?,
      birthCountryCode: json['birthCountryCode'] as String,
      traditionalProfile: rawTraditionalProfile == null
          ? null
          : engine.TraditionalProfile.fromWire(rawTraditionalProfile),
      zodiacSign: zodiacForDate(birthDate),
      useCurrentLocation: json['useCurrentLocation'] as bool,
      safetyAcknowledged: json['safetyAcknowledged'] as bool? ?? false,
      createdAt: rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt) : null,
    );
  }
}
