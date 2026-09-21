import 'json_types.dart';

/// Traditional profile/convention used only where the calculation needs it
/// (e.g. Zi Wei gender convention). Wire values match
/// `Profile.traditionalProfile` in `calculation-engine/src/index.d.ts`.
///
/// Never inferred from name or country — [unspecified] is a real, valid
/// choice, not a missing-data error.
enum TraditionalProfile {
  male('male'),
  female('female'),
  maleConvention('male_convention'),
  femaleConvention('female_convention'),
  unspecified('unspecified');

  const TraditionalProfile(this.wireValue);

  final String wireValue;

  static TraditionalProfile fromWire(
    String value, {
    String context = 'TraditionalProfile',
  }) {
    for (final profile in TraditionalProfile.values) {
      if (profile.wireValue == value) return profile;
    }
    throw ReadingDtoException('Unknown $context value "$value"');
  }

  String toJson() => wireValue;
}
