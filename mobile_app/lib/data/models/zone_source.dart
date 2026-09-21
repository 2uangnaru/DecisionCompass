import 'json_types.dart';

/// Where the resolved current timezone came from. Wire values match
/// `ResolvedContext.zoneSource` in `calculation-engine/src/index.d.ts`.
///
/// [location] only ever describes the *current* timezone/region from a
/// one-shot foreground fix — never the birth location or timezone.
enum ZoneSource {
  device('device'),
  location('location');

  const ZoneSource(this.wireValue);

  final String wireValue;

  static ZoneSource fromWire(String value, {String context = 'ZoneSource'}) {
    for (final source in ZoneSource.values) {
      if (source.wireValue == value) return source;
    }
    throw ReadingDtoException('Unknown $context value "$value"');
  }

  String toJson() => wireValue;
}
