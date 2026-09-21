import 'current_location.dart';
import 'json_types.dart';

/// Current UTC instant, device timezone, and optional one-shot location,
/// captured only when Reveal is tapped. Mirrors `CurrentContext` in
/// `calculation-engine/src/index.d.ts`.
class CurrentContext {
  const CurrentContext({
    required this.instantUtc,
    required this.deviceTimezone,
    this.location,
  });

  /// ISO-8601 UTC instant captured at Reveal.
  final String instantUtc;

  /// IANA device timezone captured at Reveal.
  final String deviceTimezone;

  /// One-shot foreground fix for current timezone/region only, or null when
  /// location was denied or not requested.
  final CurrentLocation? location;

  factory CurrentContext.fromJson(JsonMap json) {
    const context = 'CurrentContext';
    final rawLocation = optionalField<JsonMap>(json, 'location', context);
    return CurrentContext(
      instantUtc: requireField<String>(json, 'instantUtc', context),
      deviceTimezone: requireField<String>(json, 'deviceTimezone', context),
      location: rawLocation == null
          ? null
          : CurrentLocation.fromJson(rawLocation),
    );
  }

  JsonMap toJson() => {
    'instantUtc': instantUtc,
    'deviceTimezone': deviceTimezone,
    if (location != null) 'location': location!.toJson(),
  };
}
