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
    this.birthTimeChangedAtUtc,
    this.birthCountryChangedAtUtc,
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

  /// When the birth time was last changed from Profile, in UTC — or null if
  /// it never has been.
  ///
  /// UTC because the reader can fly: a stamp written in local time would make
  /// the wait shrink or stretch by the offset difference on landing. Null is
  /// the first-edit state, which is always allowed; see
  /// `data/profile_edit_policy.dart` for the window itself.
  ///
  /// This is a UX cooldown and nothing more. It lives in the same local store
  /// as the rest of the profile, so anyone willing to edit that store can
  /// clear it — which is fine, because nothing downstream trusts it.
  final DateTime? birthTimeChangedAtUtc;

  /// The same, for the country of birth.
  final DateTime? birthCountryChangedAtUtc;

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
  /// convention, and a `copyWith` that could clear one would make it easy to
  /// erase a name by accident.
  ///
  /// Profile editing does need to clear both the name and the birth time, so
  /// it goes through [edited] instead, where null means null and every
  /// editable field is required. Loosening the rule here would have made
  /// every existing caller's omitted argument a potential erasure.
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
    DateTime? birthTimeChangedAtUtc,
    DateTime? birthCountryChangedAtUtc,
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
      birthTimeChangedAtUtc:
          birthTimeChangedAtUtc ?? this.birthTimeChangedAtUtc,
      birthCountryChangedAtUtc:
          birthCountryChangedAtUtc ?? this.birthCountryChangedAtUtc,
    );
  }

  /// Applies an edit made on the Profile screen.
  ///
  /// Every field the screen can touch is required, and null means null: an
  /// empty name clears [userName] back to the default-name state, and an
  /// unknown birth time clears [birthTime]. `copyWith` cannot express either,
  /// and making it able to would weaken it everywhere else.
  ///
  /// The birth date is not here on purpose. It is the one input the whole
  /// chart is built from, and the screen shows it read-only.
  AppProfile edited({
    required String? userName,
    required String? birthTime,
    required String birthCountryCode,
    required DateTime? birthTimeChangedAtUtc,
    required DateTime? birthCountryChangedAtUtc,
  }) => AppProfile(
    userName: userName,
    birthDate: birthDate,
    birthTime: birthTime,
    birthCountryCode: birthCountryCode,
    traditionalProfile: traditionalProfile,
    zodiacSign: zodiacSign,
    useCurrentLocation: useCurrentLocation,
    safetyAcknowledged: safetyAcknowledged,
    createdAt: createdAt,
    birthTimeChangedAtUtc: birthTimeChangedAtUtc,
    birthCountryChangedAtUtc: birthCountryChangedAtUtc,
  );

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
    // Always written as UTC, whatever the DateTime handed in was, so a record
    // can never be read back in the wrong clock.
    if (birthTimeChangedAtUtc != null)
      'birthTimeChangedAtUtc': birthTimeChangedAtUtc!.toUtc().toIso8601String(),
    if (birthCountryChangedAtUtc != null)
      'birthCountryChangedAtUtc': birthCountryChangedAtUtc!
          .toUtc()
          .toIso8601String(),
  };

  /// Reads a stored timestamp, in UTC, or null when it is absent, not a
  /// string, or not a date. The type is checked rather than cast: a record
  /// holding a number here must not throw on the first frame.
  static DateTime? _readUtc(Object? raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

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
      // An unparseable stamp reads as "never changed", which unlocks the
      // field. The alternative — treating it as "just changed" — would lock a
      // reader out of their own profile over a corrupt string.
      birthTimeChangedAtUtc: _readUtc(json['birthTimeChangedAtUtc']),
      birthCountryChangedAtUtc: _readUtc(json['birthCountryChangedAtUtc']),
    );
  }
}
