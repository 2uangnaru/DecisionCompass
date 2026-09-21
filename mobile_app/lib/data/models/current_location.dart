import 'json_types.dart';

/// A one-shot foreground location fix, used only to resolve the *current*
/// timezone/region. Mirrors the nested `location` object on `CurrentContext`
/// in `calculation-engine/src/index.d.ts`.
///
/// Never treat this as birth location — do not log its coordinates.
class CurrentLocation {
  const CurrentLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAtUtc,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String capturedAtUtc;

  factory CurrentLocation.fromJson(JsonMap json) {
    const context = 'CurrentLocation';
    return CurrentLocation(
      latitude: requireDouble(json, 'latitude', context),
      longitude: requireDouble(json, 'longitude', context),
      accuracyMeters: requireDouble(json, 'accuracyMeters', context),
      capturedAtUtc: requireField<String>(json, 'capturedAtUtc', context),
    );
  }

  JsonMap toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracyMeters,
    'capturedAtUtc': capturedAtUtc,
  };
}
