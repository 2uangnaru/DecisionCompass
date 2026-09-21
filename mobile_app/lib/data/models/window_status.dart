import 'json_types.dart';

/// How many favorable time windows the requested (non-NOW) period yielded.
/// Wire values match the `windowStatus` union in
/// `calculation-engine/src/index.d.ts`.
///
/// - [notApplicable]: NOW was requested; NOW never has lucky windows.
/// - [twoAvailable]: two ranked windows remain in the period.
/// - [oneRemaining]: only one qualifying window remains.
/// - [no15MinuteWindow]: the period has remaining time but no window meets
///   the 15-minute minimum; the engine does not fabricate one.
enum WindowStatus {
  notApplicable('not_applicable'),
  twoAvailable('two_available'),
  oneRemaining('one_remaining'),
  no15MinuteWindow('no_15_minute_window');

  const WindowStatus(this.wireValue);

  final String wireValue;

  static WindowStatus fromWire(
    String value, {
    String context = 'WindowStatus',
  }) {
    for (final status in WindowStatus.values) {
      if (status.wireValue == value) return status;
    }
    throw ReadingDtoException('Unknown $context value "$value"');
  }

  String toJson() => wireValue;
}
