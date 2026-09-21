import 'json_types.dart';
import 'traditional_profile.dart';

/// Birth profile sent to the engine. Mirrors `Profile` in
/// `calculation-engine/src/index.d.ts`.
///
/// Do not log [birthDate], [birthTime], [birthCountry] or [birthTimezone].
class BirthProfile {
  const BirthProfile({
    required this.birthDate,
    this.birthTime,
    this.birthCountry,
    this.birthTimezone,
    this.traditionalProfile,
    this.revision,
  });

  /// ISO calendar date, e.g. "1998-06-21".
  final String birthDate;

  /// "HH:mm" local birth time, or null when the user marked it unknown.
  final String? birthTime;

  /// ISO country code, e.g. "VN". Never derived from current location.
  final String? birthCountry;

  /// Exact birth IANA zone, only when known independently of current
  /// location (e.g. from a birth-place lookup, not GPS at reveal time).
  final String? birthTimezone;

  final TraditionalProfile? traditionalProfile;

  /// Profile revision for cache invalidation; the engine defaults this to 1
  /// when omitted.
  final int? revision;

  factory BirthProfile.fromJson(JsonMap json) {
    const context = 'BirthProfile';
    final rawTraditionalProfile = optionalField<String>(
      json,
      'traditionalProfile',
      context,
    );
    return BirthProfile(
      birthDate: requireField<String>(json, 'birthDate', context),
      birthTime: optionalField<String>(json, 'birthTime', context),
      birthCountry: optionalField<String>(json, 'birthCountry', context),
      birthTimezone: optionalField<String>(json, 'birthTimezone', context),
      traditionalProfile: rawTraditionalProfile == null
          ? null
          : TraditionalProfile.fromWire(
              rawTraditionalProfile,
              context: context,
            ),
      revision: optionalInt(json, 'revision', context),
    );
  }

  JsonMap toJson() => {
    'birthDate': birthDate,
    if (birthTime != null) 'birthTime': birthTime,
    if (birthCountry != null) 'birthCountry': birthCountry,
    if (birthTimezone != null) 'birthTimezone': birthTimezone,
    if (traditionalProfile != null)
      'traditionalProfile': traditionalProfile!.toJson(),
    if (revision != null) 'revision': revision,
  };
}
