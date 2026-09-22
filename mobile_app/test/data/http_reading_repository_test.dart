import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decision_compass/data/http_reading_repository.dart';
import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/data/reading_api_config.dart';
import 'package:decision_compass/data/reading_api_exception.dart';
import 'package:decision_compass/data/reading_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fixture_loader.dart';

const _request = ReadingRequest(
  profile: BirthProfile(
    birthDate: '1998-06-21',
    birthTime: '14:30',
    birthCountry: 'VN',
    traditionalProfile: TraditionalProfile.male,
  ),
  context: CurrentContext(
    instantUtc: '2026-09-18T08:30:00.000Z',
    deviceTimezone: 'Asia/Ho_Chi_Minh',
  ),
  mode: DecisionMode.yesNo,
  period: TimePeriod.now,
);

final _config = ReadingApiConfig.parse('http://127.0.0.1:8787');

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

HttpReadingRepository repositoryReturning(
  http.Response Function(http.Request request) handler, {
  ReadingApiConfig? config,
  Duration? timeout,
}) => HttpReadingRepository(
  client: MockClient((request) async => handler(request)),
  config: config ?? _config,
  timeout: timeout ?? HttpReadingRepository.defaultTimeout,
);

http.Response jsonResponse(
  Object? body, {
  int status = 200,
  Map<String, String>? headers,
}) => http.Response(
  body is String ? body : jsonEncode(body),
  status,
  headers: headers ?? _jsonHeaders,
);

Future<ReadingApiException> captureFailure(
  Future<void> Function() action,
) async {
  try {
    await action();
  } on ReadingApiException catch (error) {
    return error;
  }
  fail('expected a ReadingApiException');
}

void main() {
  group('request shape', () {
    test(
      'POSTs to /v1/readings with the documented headers and exact DTO JSON',
      () async {
        http.Request? seen;
        final repository = repositoryReturning((request) {
          seen = request;
          return jsonResponse(readFixture('ready_yes_no_now.json'));
        });

        await repository.calculate(_request);

        assert(seen != null);
        expect(seen!.method, 'POST');
        expect(seen!.url, Uri.parse('http://127.0.0.1:8787/v1/readings'));
        expect(
          seen!.headers['content-type'],
          'application/json; charset=utf-8',
        );
        expect(seen!.headers['accept'], 'application/json');
        // Serialization goes through the DTO and nothing else.
        expect(jsonDecode(seen!.body), equals(_request.toJson()));
        expect(seen!.body, jsonEncode(_request.toJson()));
      },
    );

    test('honours an explicit port and a base path', () async {
      http.Request? seen;
      final repository = repositoryReturning((request) {
        seen = request;
        return jsonResponse(readFixture('ready_yes_no_now.json'));
      }, config: ReadingApiConfig.parse('http://127.0.0.1:19999/api/'));

      await repository.calculate(_request);
      expect(seen!.url, Uri.parse('http://127.0.0.1:19999/api/v1/readings'));
    });

    test('implements ReadingRepository', () {
      expect(
        repositoryReturning((_) => jsonResponse(null)),
        isA<ReadingRepository>(),
      );
    });
  });

  group('successful readings parse real engine output', () {
    for (final entry in {
      'ready_yes_no_now.json': ('yes_no', DecisionMode.yesNo),
      'ready_forward_backward_two_windows.json': (
        'forward_backward',
        DecisionMode.forwardBackward,
      ),
      'ready_left_right.json': ('left_right', DecisionMode.leftRight),
    }.entries) {
      test('${entry.key} round-trips through the transport', () async {
        final fixture = readFixture(entry.key);
        final repository = repositoryReturning((_) => jsonResponse(fixture));

        final reading = await repository.calculate(_request);

        expect(reading.mode, entry.value.$2);
        expect(reading.mode.wireValue, entry.value.$1);
        expect(reading.engineVersion, fixture['engineVersion']);
        expect(reading.readingKey, fixture['readingKey']);
        expect(reading.status, ReadingStatus.ready);
        final percentages = reading.percentages!.values.values;
        expect(percentages.fold<int>(0, (a, b) => a + b), 100);
      });
    }

    test('unknown response fields do not break parsing', () async {
      final fixture = JsonMap.from(readFixture('ready_yes_no_now.json'))
        ..['futureServerField'] = {'anything': 'goes'};
      final repository = repositoryReturning((_) => jsonResponse(fixture));

      final reading = await repository.calculate(_request);
      expect(reading.status, ReadingStatus.ready);
    });

    test('a bare application/json content type is accepted', () async {
      final repository = repositoryReturning(
        (_) => jsonResponse(
          readFixture('ready_yes_no_now.json'),
          headers: const {'content-type': 'application/json'},
        ),
      );
      expect(
        (await repository.calculate(_request)).status,
        ReadingStatus.ready,
      );
    });
  });

  group('HTTP status mapping', () {
    for (final status in [400, 413, 415, 422]) {
      test('$status maps to rejectedRequest', () async {
        final repository = repositoryReturning(
          (_) => jsonResponse({
            'error': {
              'code': 'invalid_reading_request',
              'message': 'The reading request could not be processed.',
            },
          }, status: status),
        );

        final failure = await captureFailure(
          () => repository.calculate(_request),
        );
        expect(failure.kind, ReadingApiFailureKind.rejectedRequest);
        expect(failure.statusCode, status);
        // The client's own constant, not the server's `invalid_reading_request`.
        expect(failure.safeCode, 'reading_request_rejected');
        expect(failure.safeMessage, 'The reading request was rejected.');
      });
    }

    for (final status in [404, 405]) {
      test('$status maps to invalidResponse', () async {
        final repository = repositoryReturning(
          (_) => jsonResponse({
            'error': {'code': 'not_found', 'message': 'nope'},
          }, status: status),
        );

        final failure = await captureFailure(
          () => repository.calculate(_request),
        );
        expect(failure.kind, ReadingApiFailureKind.invalidResponse);
        expect(failure.statusCode, status);
        expect(failure.safeCode, 'reading_endpoint_unavailable');
      });
    }

    for (final status in [500, 503, 599]) {
      test('$status maps to server', () async {
        final repository = repositoryReturning(
          (_) => jsonResponse({
            'error': {'code': 'internal_error', 'message': 'nope'},
          }, status: status),
        );

        final failure = await captureFailure(
          () => repository.calculate(_request),
        );
        expect(failure.kind, ReadingApiFailureKind.server);
        expect(failure.statusCode, status);
        expect(failure.safeCode, 'reading_service_failed');
      });
    }

    for (final status in [201, 204, 302, 418]) {
      test('unexpected status $status maps to invalidResponse', () async {
        final repository = repositoryReturning(
          (_) => jsonResponse({}, status: status),
        );

        final failure = await captureFailure(
          () => repository.calculate(_request),
        );
        expect(failure.kind, ReadingApiFailureKind.invalidResponse);
      });
    }

    test(
      'a rejection without a usable error body still yields a generic code',
      () async {
        final repository = repositoryReturning(
          (_) => http.Response(
            '<html>nope</html>',
            422,
            headers: const {'content-type': 'text/html'},
          ),
        );

        final failure = await captureFailure(
          () => repository.calculate(_request),
        );
        expect(failure.kind, ReadingApiFailureKind.rejectedRequest);
        expect(failure.safeCode, 'reading_request_rejected');
        expect(failure.toString(), isNot(contains('html')));
      },
    );
  });

  group('transport failures', () {
    test('a timeout maps to timeout', () async {
      final repository = HttpReadingRepository(
        client: MockClient((_) => Completer<http.Response>().future),
        config: _config,
        timeout: const Duration(milliseconds: 40),
      );

      final failure = await captureFailure(
        () => repository.calculate(_request),
      );
      expect(failure.kind, ReadingApiFailureKind.timeout);
      expect(failure.statusCode, isNull);
    });

    test('an http ClientException maps to network', () async {
      final repository = HttpReadingRepository(
        client: MockClient(
          (_) async => throw http.ClientException('connection closed'),
        ),
        config: _config,
      );

      final failure = await captureFailure(
        () => repository.calculate(_request),
      );
      expect(failure.kind, ReadingApiFailureKind.network);
    });

    test('a SocketException maps to network', () async {
      final repository = HttpReadingRepository(
        client: MockClient(
          (_) async => throw const SocketException('connection refused'),
        ),
        config: _config,
      );

      final failure = await captureFailure(
        () => repository.calculate(_request),
      );
      expect(failure.kind, ReadingApiFailureKind.network);
    });

    test('a failed POST is never retried', () async {
      var calls = 0;
      final repository = HttpReadingRepository(
        client: MockClient((_) async {
          calls++;
          return jsonResponse({
            'error': {'code': 'internal_error', 'message': 'x'},
          }, status: 500);
        }),
        config: _config,
      );

      await captureFailure(() => repository.calculate(_request));
      expect(calls, 1);

      calls = 0;
      final networkRepository = HttpReadingRepository(
        client: MockClient((_) async {
          calls++;
          throw http.ClientException('down');
        }),
        config: _config,
      );
      await captureFailure(() => networkRepository.calculate(_request));
      expect(calls, 1);
    });
  });

  group('response safety', () {
    test(
      'HTTP 200 with a non-JSON content type maps to invalidResponse',
      () async {
        final repository = repositoryReturning(
          (_) => http.Response(
            jsonEncode(readFixture('ready_yes_no_now.json')),
            200,
            headers: const {'content-type': 'text/html; charset=utf-8'},
          ),
        );

        final failure = await captureFailure(
          () => repository.calculate(_request),
        );
        expect(failure.kind, ReadingApiFailureKind.invalidResponse);
        expect(failure.safeCode, 'unexpected_response_content_type');
      },
    );

    test(
      'HTTP 200 with a missing content type maps to invalidResponse',
      () async {
        final repository = repositoryReturning(
          (_) => http.Response(
            jsonEncode(readFixture('ready_yes_no_now.json')),
            200,
          ),
        );

        final failure = await captureFailure(
          () => repository.calculate(_request),
        );
        expect(failure.kind, ReadingApiFailureKind.invalidResponse);
      },
    );

    test('malformed JSON maps to invalidResponse', () async {
      final repository = repositoryReturning(
        (_) => jsonResponse('{"status": '),
      );

      final failure = await captureFailure(
        () => repository.calculate(_request),
      );
      expect(failure.kind, ReadingApiFailureKind.invalidResponse);
      expect(failure.safeCode, 'unreadable_reading_response');
    });

    for (final body in ['[]', 'null', '42', '"text"', 'true']) {
      test('a JSON $body body maps to invalidResponse', () async {
        final repository = repositoryReturning((_) => jsonResponse(body));

        final failure = await captureFailure(
          () => repository.calculate(_request),
        );
        expect(failure.kind, ReadingApiFailureKind.invalidResponse);
      });
    }

    test('a malformed reading payload maps to invalidResponse', () async {
      final broken = JsonMap.from(readFixture('ready_yes_no_now.json'))
        ..remove('status');
      final repository = repositoryReturning((_) => jsonResponse(broken));

      final failure = await captureFailure(
        () => repository.calculate(_request),
      );
      expect(failure.kind, ReadingApiFailureKind.invalidResponse);
      expect(failure.safeCode, 'unexpected_reading_contract');
      // The DTO's field-level complaint must not reach the caller.
      expect(failure.toString(), isNot(contains('Missing required field')));
      expect(failure.toString(), isNot(contains('ReadingDtoException')));
    });
  });

  group('failures never carry sensitive data', () {
    // Sensitive values planted in BOTH error.code and error.message, plus the
    // surrounding body. A proxy or future server could do exactly this, so
    // none of it may reach a loggable exception.
    const planted = <String, String>{
      'birth date': '1998-06-21',
      'birth time': '14:30',
      'timezone': 'Asia/Ho_Chi_Minh',
      'latitude': '10.7769',
      'longitude': '106.7009',
      'readingKey':
          '4c046e6fcf3ea1b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef01234',
      'inputSnapshot': 'inputSnapshot',
      'stack frame': 'at Object.<anonymous> (/srv/engine/src/index.js:66:11)',
    };

    for (final status in [400, 404, 422, 500, 418]) {
      test(
        'status $status discards sensitive text from error.code and error.message',
        () async {
          final hostile = planted.values.join(' | ');
          final repository = repositoryReturning(
            (_) => jsonResponse({
              'error': {
                // Both fields are poisoned, not just the message.
                'code': 'birthDate_1998-06-21_readingKey_deadbeef',
                'message': hostile,
              },
              'echo': planted,
              'stack': planted['stack frame'],
            }, status: status),
          );

          final failure = await captureFailure(
            () => repository.calculate(_request),
          );

          for (final entry in planted.entries) {
            expect(
              failure.safeCode,
              isNot(contains(entry.value)),
              reason: 'safeCode leaked ${entry.key}',
            );
            expect(
              failure.safeMessage,
              isNot(contains(entry.value)),
              reason: 'safeMessage leaked ${entry.key}',
            );
            expect(
              failure.toString(),
              isNot(contains(entry.value)),
              reason: 'toString() leaked ${entry.key}',
            );
          }
          // Field *names* must not survive either.
          for (final needle in [
            'birthDate',
            'birthTime',
            'deadbeef',
            'index.js',
            'at Object.',
          ]) {
            expect(
              failure.toString(),
              isNot(contains(needle)),
              reason: 'leaked "$needle"',
            );
          }

          // What is left is exclusively client-owned.
          expect(failure.safeCode, matches(r'^[a-z_]+$'));
          expect(failure.statusCode, status);
          expect(
            failure.toString(),
            'ReadingApiException(${failure.kind.name} status=$status '
            'code=${failure.safeCode}): ${failure.safeMessage}',
          );
        },
      );
    }

    test(
      'an arbitrarily long server message cannot reach the exception',
      () async {
        final repository = repositoryReturning(
          (_) => jsonResponse({
            'error': {'code': 'x' * 5000, 'message': 'y' * 5000},
          }, status: 500),
        );

        final failure = await captureFailure(
          () => repository.calculate(_request),
        );
        // Not truncated — never copied in the first place.
        expect(failure.safeCode, 'reading_service_failed');
        expect(
          failure.safeMessage,
          'The reading service could not complete the request.',
        );
        expect(failure.toString(), isNot(contains('xxx')));
        expect(failure.toString(), isNot(contains('yyy')));
        expect(failure.toString().length, lessThan(160));
      },
    );

    test('no failure path echoes the response body', () async {
      final secret = 'birthDate-1998-06-21-inputSnapshot';
      final repositories = [
        repositoryReturning((_) => jsonResponse(secret)),
        repositoryReturning((_) => jsonResponse('"$secret"')),
        repositoryReturning(
          (_) => http.Response(
            secret,
            200,
            headers: const {'content-type': 'text/plain'},
          ),
        ),
        repositoryReturning(
          (_) => http.Response(
            secret,
            500,
            headers: const {'content-type': 'text/plain'},
          ),
        ),
      ];

      for (final repository in repositories) {
        final failure = await captureFailure(
          () => repository.calculate(_request),
        );
        expect(failure.toString(), isNot(contains('1998-06-21')));
        expect(failure.toString(), isNot(contains('inputSnapshot')));
      }
    });
  });

  group('ReadingApiConfig validation', () {
    test('accepts loopback, emulator and https URLs', () {
      expect(
        ReadingApiConfig.parse('http://127.0.0.1:8787').readingsEndpoint,
        Uri.parse('http://127.0.0.1:8787/v1/readings'),
      );
      expect(
        ReadingApiConfig.parse('http://10.0.2.2:8787').readingsEndpoint,
        Uri.parse('http://10.0.2.2:8787/v1/readings'),
      );
      expect(
        ReadingApiConfig.parse('https://readings.example.com').readingsEndpoint,
        Uri.parse('https://readings.example.com/v1/readings'),
      );
    });

    test('normalizes trailing slashes without losing the port', () {
      final config = ReadingApiConfig.parse('http://127.0.0.1:8787///');
      expect(config.baseUrl, Uri.parse('http://127.0.0.1:8787'));
      expect(
        config.readingsEndpoint,
        Uri.parse('http://127.0.0.1:8787/v1/readings'),
      );
      expect(config.baseUrl.port, 8787);
    });

    test('trims surrounding whitespace', () {
      expect(
        ReadingApiConfig.parse('  http://127.0.0.1:8787  ').baseUrl,
        Uri.parse('http://127.0.0.1:8787'),
      );
    });

    test('reports cleartext so callers can warn', () {
      expect(
        ReadingApiConfig.parse('http://127.0.0.1:8787').isCleartext,
        isTrue,
      );
      expect(
        ReadingApiConfig.parse('https://readings.example.com').isCleartext,
        isFalse,
      );
    });

    test('never rewrites http to https', () {
      expect(
        ReadingApiConfig.parse('http://127.0.0.1:8787').baseUrl.scheme,
        'http',
      );
    });

    for (final invalid in <(String, String)>[
      ('', 'missing_api_base_url'),
      ('   ', 'missing_api_base_url'),
      ('not a url', 'malformed_api_base_url'),
      // A bare host:port has no scheme at all — a digit cannot start one.
      ('127.0.0.1:8787', 'malformed_api_base_url'),
      ('/v1/readings', 'malformed_api_base_url'),
      ('ftp://127.0.0.1:8787', 'unsupported_api_scheme'),
      ('ws://127.0.0.1:8787', 'unsupported_api_scheme'),
      ('http://', 'malformed_api_base_url'),
      ('http://user:secret@127.0.0.1:8787', 'credentials_in_api_base_url'),
      ('http://127.0.0.1:8787?debug=1', 'query_in_api_base_url'),
      ('http://127.0.0.1:8787#frag', 'fragment_in_api_base_url'),
    ]) {
      test('rejects ${invalid.$1.isEmpty ? '<empty>' : invalid.$1}', () {
        final failure = () {
          try {
            ReadingApiConfig.parse(invalid.$1);
          } on ReadingApiException catch (error) {
            return error;
          }
          fail('expected ${invalid.$1} to be rejected');
        }();

        expect(failure.kind, ReadingApiFailureKind.configuration);
        expect(failure.safeCode, invalid.$2);
        // A rejected URL must not be echoed back — it can embed credentials.
        expect(failure.toString(), isNot(contains('secret')));
      });
    }

    test('fromEnvironment fails when the dart-define is absent', () {
      // No --dart-define is set under `flutter test`.
      final failure = () {
        try {
          ReadingApiConfig.fromEnvironment();
        } on ReadingApiException catch (error) {
          return error;
        }
        fail('expected a configuration failure');
      }();

      expect(failure.kind, ReadingApiFailureKind.configuration);
      expect(failure.safeCode, 'missing_api_base_url');
      expect(failure.safeMessage, contains('DECISION_API_BASE_URL'));
    });
  });
}
