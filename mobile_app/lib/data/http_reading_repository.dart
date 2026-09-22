import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models/models.dart';
import 'reading_api_config.dart';
import 'reading_api_exception.dart';
import 'reading_repository.dart';

/// [ReadingRepository] backed by the Node calculation API
/// (`POST /v1/readings`).
///
/// This class writes nothing to any log or analytics sink. Request and
/// response bodies carry birth data, timezone, coordinates, `readingKey` and
/// `inputSnapshot`, so none of it is ever printed. Failures surface as
/// [ReadingApiException], whose code and message are client-owned constants —
/// no server-supplied text is ever copied into them.
///
/// A failed POST is never retried here: a reading is not idempotent from the
/// user's point of view (it consumes entitlement and the engine pins the
/// instant), so retry policy belongs to the caller, not the transport.
///
/// There is no fallback to mock data. If the API cannot answer, this throws.
class HttpReadingRepository implements ReadingRepository {
  /// [client] is **owned by the caller**: this class never creates a client of
  /// its own and never closes the one it is given, so a single client can be
  /// shared and closed once at app shutdown.
  HttpReadingRepository({
    required http.Client client,
    required ReadingApiConfig config,
    Duration timeout = defaultTimeout,
  }) : _client = client,
       _config = config,
       _timeout = timeout;

  static const Duration defaultTimeout = Duration(seconds: 15);

  final http.Client _client;
  final ReadingApiConfig _config;
  final Duration _timeout;

  ReadingApiConfig get config => _config;

  @override
  Future<ReadingResponse> calculate(ReadingRequest request) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            _config.readingsEndpoint,
            headers: const {
              'content-type': 'application/json; charset=utf-8',
              'accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const ReadingApiException(
        kind: ReadingApiFailureKind.timeout,
        safeCode: 'reading_request_timeout',
        safeMessage: 'The reading service did not respond in time.',
      );
    } on http.ClientException {
      throw _networkFailure();
    } on SocketException {
      throw _networkFailure();
    } on HandshakeException {
      throw _networkFailure();
    }

    if (response.statusCode == 200) return _parseReading(response);
    // Only the status crosses into the failure: the body is never read.
    throw _failureForStatus(response.statusCode);
  }

  ReadingResponse _parseReading(http.Response response) {
    if (!_isJsonContentType(response.headers['content-type'])) {
      throw _invalidResponse(
        'unexpected_response_content_type',
        'The reading service returned an unexpected content type.',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw _invalidResponse(
        'unreadable_reading_response',
        'The reading service returned a malformed response.',
        statusCode: response.statusCode,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw _invalidResponse(
        'unexpected_reading_response_shape',
        'The reading service returned an unexpected response shape.',
        statusCode: response.statusCode,
      );
    }

    try {
      return ReadingResponse.fromJson(decoded);
    } on ReadingDtoException {
      // The DTO's own message names the offending field only, never a value,
      // but it is still not surfaced: the UI cannot act on it.
      throw _invalidResponse(
        'unexpected_reading_contract',
        'The reading service returned data this app version cannot read.',
        statusCode: response.statusCode,
      );
    }
  }

  /// Derives the failure from the HTTP status **alone**.
  ///
  /// Takes an `int`, not the response, so the body is not in scope and cannot
  /// be read even by accident. Nothing the server sends — including fields the
  /// API documents as generic, such as `error.code` and `error.message` — is
  /// copied out: a reverse proxy, a future server version or a compromised
  /// host could put birth data, a timezone, coordinates, a `readingKey`, an
  /// `inputSnapshot` or a stack trace into any of them, and
  /// [ReadingApiException] is meant to be safe to log verbatim.
  static ReadingApiException _failureForStatus(int status) {
    final (kind, code, message) = switch (status) {
      400 || 413 || 415 || 422 => (
        ReadingApiFailureKind.rejectedRequest,
        'reading_request_rejected',
        'The reading request was rejected.',
      ),
      404 || 405 => (
        ReadingApiFailureKind.invalidResponse,
        'reading_endpoint_unavailable',
        'The reading service endpoint is not available.',
      ),
      >= 500 && <= 599 => (
        ReadingApiFailureKind.server,
        'reading_service_failed',
        'The reading service could not complete the request.',
      ),
      _ => (
        ReadingApiFailureKind.invalidResponse,
        'unexpected_reading_status',
        'The reading service returned an unexpected status.',
      ),
    };

    return ReadingApiException(
      kind: kind,
      statusCode: status,
      safeCode: code,
      safeMessage: message,
    );
  }

  static bool _isJsonContentType(String? value) =>
      value != null &&
      value.split(';').first.trim().toLowerCase() == 'application/json';

  static ReadingApiException _networkFailure() => const ReadingApiException(
    kind: ReadingApiFailureKind.network,
    safeCode: 'reading_service_unreachable',
    safeMessage: 'The reading service could not be reached.',
  );

  static ReadingApiException _invalidResponse(
    String code,
    String message, {
    int? statusCode,
  }) => ReadingApiException(
    kind: ReadingApiFailureKind.invalidResponse,
    statusCode: statusCode,
    safeCode: code,
    safeMessage: message,
  );
}
