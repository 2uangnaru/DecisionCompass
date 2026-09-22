/// Why a reading request failed, at the level the UI needs to make a decision
/// (retry, fix input, show offline state, tell the user to try later).
enum ReadingApiFailureKind {
  /// The build has no usable API base URL. Not retryable.
  configuration,

  /// The request exceeded the client timeout.
  timeout,

  /// The server could not be reached at all (DNS, refused, dropped socket).
  network,

  /// A reply arrived but did not match the API contract. Retrying is pointless.
  invalidResponse,

  /// The server understood the request and refused it (400/413/415/422).
  rejectedRequest,

  /// The server failed while handling a valid request (5xx).
  server,
}

/// A transport/contract failure from the calculation API.
///
/// Deliberately carries no request or response payload. [safeCode] and
/// [safeMessage] are constants owned by this app, selected from the HTTP
/// status; **nothing** the server sends is copied into them, not even fields
/// the API documents as generic. A reverse proxy, a future server version or a
/// compromised host could place birth data, a timezone, coordinates, a
/// `readingKey`, an `inputSnapshot` or a stack trace in any response field, so
/// none of them are trusted. That is what makes [toString] safe to log or
/// display verbatim.
class ReadingApiException implements Exception {
  const ReadingApiException({
    required this.kind,
    required this.safeCode,
    required this.safeMessage,
    this.statusCode,
  });

  final ReadingApiFailureKind kind;

  /// HTTP status when one was received, else null.
  final int? statusCode;

  /// Stable machine-readable code, always chosen by this client from the HTTP
  /// status or the transport failure. Never taken from the response.
  final String safeCode;

  /// Short generic sentence owned by this client, safe to surface or log
  /// as-is. Never taken from the response.
  final String safeMessage;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' status=$statusCode';
    return 'ReadingApiException(${kind.name}$status code=$safeCode): $safeMessage';
  }
}
