/// The production [ReadingRepository]: the calculation engine, on the device.
///
/// No HTTP client, no base URL, no localhost, no `adb reverse`. A reading is
/// computed from the request alone, so it works in airplane mode and on a
/// physical device with nothing else installed.
///
/// The heavy work runs on a background isolate so the reveal animation never
/// stutters. Nothing platform-specific crosses that boundary: the request is
/// already a plain map of primitives by the time it is sent, and the isolate
/// touches no plugin, no file and no socket.
library;

import 'dart:async';
import 'dart:isolate';

import '../data/models/models.dart';
import '../data/reading_api_exception.dart';
import '../data/reading_repository.dart';
import 'core/core.dart';
import 'local_reading_engine.dart';
import 'time/local_time.dart' show EngineError;

/// Runs a reading with the bundled offline engine.
class LocalReadingRepository implements ReadingRepository {
  const LocalReadingRepository({this.runner = _runOnIsolate});

  /// How the calculation is dispatched.
  ///
  /// Defaults to a background isolate. Tests that want a deterministic stack
  /// trace, or a caller that is already off the UI thread, can pass
  /// [runInline] instead. Both paths run exactly the same engine.
  final Future<JsonMap> Function(JsonMap payload) runner;

  @override
  Future<ReadingResponse> calculate(ReadingRequest request) async {
    final payload = <String, Object?>{
      'profile': request.profile.toJson(),
      'context': request.context.toJson(),
      'period': (request.period ?? TimePeriod.now).toJson(),
      'mode': (request.mode ?? DecisionMode.yesNo).toJson(),
      'category': request.category.toJson(),
    };

    final JsonMap raw;
    try {
      raw = await runner(payload);
    } on ReadingApiException {
      rethrow;
    } catch (_) {
      // Deliberately swallows the object: an engine error can carry an input
      // value, and a stack trace can carry a file path. Neither may reach the
      // UI or a log.
      throw const ReadingApiException(
        kind: ReadingApiFailureKind.server,
        safeCode: 'local_engine_failed',
        safeMessage: 'The reading could not be completed on this device.',
      );
    }

    try {
      return ReadingResponse.fromJson(raw);
    } on ReadingDtoException {
      throw const ReadingApiException(
        kind: ReadingApiFailureKind.invalidResponse,
        safeCode: 'local_engine_contract_mismatch',
        safeMessage: 'The reading could not be read by this app version.',
      );
    }
  }
}

/// Engine error codes that mean "this input cannot produce a reading".
///
/// They are told apart from an unexpected internal failure so the UI can send
/// the person back to their birth details instead of offering a pointless
/// retry. Only the code is used — never the value that triggered it.
const Set<String> _inputRejectionCodes = <String>{
  'PROFILE_REQUIRED',
  'INVALID_BIRTH_DATE',
  'INVALID_BIRTH_TIME',
  'INVALID_BIRTH_COUNTRY',
  'INVALID_TRADITIONAL_PROFILE',
  'INVALID_PROFILE_REVISION',
  'INVALID_IANA_TIMEZONE',
  'INVALID_LOCAL_DATETIME',
  'INVALID_INSTANT',
  'UTC_OR_OFFSET_REQUIRED',
  'SUPPORTED_BIRTH_YEARS_1900_2099',
  'SUPPORTED_READING_YEARS_1900_2099',
  'BIRTH_DATE_IN_FUTURE',
  'BIRTH_INSTANT_IN_FUTURE',
  'CURRENT_TIMEZONE_UNAVAILABLE',
  'INVALID_DECISION_MODE',
  'INVALID_PERIOD',
  'INVALID_CATEGORY',
  'SPATIAL_FENG_SHUI_OUT_OF_SCOPE',
};

ReadingApiException _rejected(String code) => ReadingApiException(
  kind: ReadingApiFailureKind.rejectedRequest,
  safeCode: 'local_engine_${code.toLowerCase()}',
  safeMessage: 'Some of the details for this reading could not be used.',
);

/// Runs the engine and normalizes its failures, without crossing an isolate.
///
/// Used by [runInline] and by the isolate entry point, so both paths classify
/// failures identically.
JsonMap _calculate(JsonMap payload) {
  try {
    return calculateReading(
      profile: (payload['profile']! as Map).cast<String, Object?>(),
      context: (payload['context']! as Map).cast<String, Object?>(),
      period: payload['period']! as String,
      mode: payload['mode']! as String,
      category: payload['category']! as String,
    );
  } on EngineFailure catch (failure) {
    throw _classify(failure.code);
  } on EngineError catch (failure) {
    throw _classify(failure.code);
  }
}

ReadingApiException _classify(String code) {
  if (_inputRejectionCodes.contains(code)) return _rejected(code);
  return const ReadingApiException(
    kind: ReadingApiFailureKind.server,
    safeCode: 'local_engine_failed',
    safeMessage: 'The reading could not be completed on this device.',
  );
}

/// Default dispatcher: a short-lived background isolate.
///
/// Must stay a top-level function so it can be sent to an isolate.
Future<JsonMap> _runOnIsolate(JsonMap payload) =>
    Isolate.run(() => _calculate(payload));

/// Runs the engine on the calling isolate.
///
/// Intended for tests and for callers already off the UI thread; a Flutter app
/// should use the default isolate dispatcher instead.
Future<JsonMap> runInline(JsonMap payload) async => _calculate(payload);
