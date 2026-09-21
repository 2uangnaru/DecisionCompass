import 'json_types.dart';

/// Overall outcome state of a [ReadingResponse]. Wire values match the
/// `status` union in `calculation-engine/src/index.d.ts`.
///
/// - [ready]: a winning direction with a percentage split.
/// - [balanced]: the split landed exactly 50/50; there is no winner.
/// - [insufficientData]: too little birth/context data to produce a score.
/// - [periodElapsed]: the requested local period has already passed today;
///   the engine never substitutes tomorrow's window.
enum ReadingStatus {
  ready('ready'),
  balanced('balanced'),
  insufficientData('insufficient_data'),
  periodElapsed('period_elapsed');

  const ReadingStatus(this.wireValue);

  final String wireValue;

  static ReadingStatus fromWire(
    String value, {
    String context = 'ReadingStatus',
  }) {
    for (final status in ReadingStatus.values) {
      if (status.wireValue == value) return status;
    }
    throw ReadingDtoException('Unknown $context value "$value"');
  }

  String toJson() => wireValue;
}
