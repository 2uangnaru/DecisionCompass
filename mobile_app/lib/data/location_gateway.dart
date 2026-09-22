import 'package:geolocator/geolocator.dart';

/// A single one-shot position reading, independent of the plugin's types.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestampUtc,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestampUtc;
}

/// Thin seam over the location plugin.
///
/// It exists so a test can prove the plugin is never touched once the user has
/// opted out: a recording double implements this interface and asserts that no
/// method was called at all.
abstract interface class LocationGateway {
  Future<void> requestPermission();
  Future<bool> hasPermission();
  Future<bool> isServiceEnabled();
  Future<LocationFix?> currentFix(Duration timeout);
}

/// Production gateway backed by `geolocator`.
class GeolocatorLocationGateway implements LocationGateway {
  const GeolocatorLocationGateway();

  @override
  Future<void> requestPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  @override
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationFix?> currentFix(Duration timeout) async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: timeout,
      ),
    );
    return LocationFix(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      timestampUtc: position.timestamp.toUtc(),
    );
  }
}
