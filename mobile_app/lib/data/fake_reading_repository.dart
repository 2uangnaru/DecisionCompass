import 'models/models.dart';
import 'reading_repository.dart';

/// In-memory [ReadingRepository] for tests and widget previews.
///
/// Configure a response with [respondWith] (or the constructor), or set
/// [error] to have [calculate] throw instead. Every request received is
/// recorded in [requests] for assertions. This never calls the real engine
/// and carries no network/formula logic of its own.
class FakeReadingRepository implements ReadingRepository {
  FakeReadingRepository({
    ReadingResponse? response,
    this.error,
    this.delay = Duration.zero,
  }) : _response = response;

  ReadingResponse? _response;

  /// When set, [calculate] throws this instead of returning a response.
  Object? error;

  /// Simulated round-trip time, so tests can exercise an API that answers
  /// faster or slower than the loading ritual.
  Duration delay;

  /// Requests received so far, most recent last.
  final List<ReadingRequest> requests = [];

  /// Overrides the response returned by subsequent calls to [calculate].
  void respondWith(ReadingResponse response) => _response = response;

  @override
  Future<ReadingResponse> calculate(ReadingRequest request) async {
    requests.add(request);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final pendingError = error;
    if (pendingError != null) throw pendingError;
    final response = _response;
    if (response == null) {
      throw StateError('FakeReadingRepository has no response configured');
    }
    return response;
  }
}
