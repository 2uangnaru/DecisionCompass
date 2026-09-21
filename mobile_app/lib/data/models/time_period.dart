import 'json_types.dart';

/// Reading period. Wire values match `Period` in
/// `calculation-engine/src/index.d.ts`.
///
/// [now] uses the instant at Reveal and never returns lucky windows. The
/// other periods are fixed local-time bands (see engine README); the engine
/// never silently rolls an elapsed period into tomorrow.
enum TimePeriod {
  now('now'),
  morning('morning'),
  midday('midday'),
  afternoon('afternoon'),
  evening('evening');

  const TimePeriod(this.wireValue);

  final String wireValue;

  static TimePeriod fromWire(String value, {String context = 'TimePeriod'}) {
    for (final period in TimePeriod.values) {
      if (period.wireValue == value) return period;
    }
    throw ReadingDtoException('Unknown $context value "$value"');
  }

  String toJson() => wireValue;
}
