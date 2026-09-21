import 'models/models.dart';

/// Abstraction over the calculation engine.
///
/// UI pages must never construct HTTP calls or parse engine JSON directly —
/// they depend on this interface instead. A real implementation (HTTP
/// client, local Dart port, or native bridge) is wired in behind it later
/// without UI pages changing. See [FakeReadingRepository] in
/// `fake_reading_repository.dart` for the test/preview double.
abstract interface class ReadingRepository {
  Future<ReadingResponse> calculate(ReadingRequest request);
}
