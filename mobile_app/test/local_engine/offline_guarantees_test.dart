import 'dart:io';

import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/data/reading_api_config.dart';
import 'package:decision_compass/data/reading_api_exception.dart';
import 'package:decision_compass/local_engine/local_reading_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proves the properties that make the app work with no server: that nothing
/// in the production dependency graph reaches the network, and that a reading
/// succeeds with no `DECISION_API_BASE_URL` in the build.
void main() {
  /// Walks the `package:decision_compass/...` imports reachable from a file.
  Set<String> reachableLibraries(String entry) {
    final visited = <String>{};
    final queue = <String>[entry];

    while (queue.isNotEmpty) {
      final path = queue.removeLast();
      if (!visited.add(path)) continue;
      final file = File(path);
      if (!file.existsSync()) continue;

      final directory = file.parent.path.replaceAll('\\', '/');
      for (final match in RegExp(
        '''^\\s*(?:import|export)\\s+['"]([^'"]+)['"]''',
        multiLine: true,
      ).allMatches(file.readAsStringSync())) {
        final target = match.group(1)!;
        if (target.startsWith('dart:')) continue;
        if (target.startsWith('package:decision_compass/')) {
          queue.add(
            'lib/${target.substring('package:decision_compass/'.length)}',
          );
          continue;
        }
        if (target.startsWith('package:')) {
          visited.add(target); // third-party package, recorded as a leaf
          continue;
        }
        queue.add(_normalize('$directory/$target'));
      }
    }
    return visited;
  }

  final productionGraph = reachableLibraries('lib/main.dart');

  test('the production graph contains no HTTP repository or API config', () {
    expect(
      productionGraph,
      isNot(contains('lib/data/http_reading_repository.dart')),
      reason: 'main.dart must not reach the development HTTP repository',
    );
    expect(
      productionGraph,
      isNot(contains('lib/data/reading_api_config.dart')),
      reason: 'main.dart must not reach the DECISION_API_BASE_URL config',
    );
    expect(
      productionGraph,
      isNot(contains('lib/data/misconfigured_reading_repository.dart')),
      reason: 'a missing API base URL is no longer a reachable state',
    );
    expect(
      productionGraph,
      contains('lib/local_engine/local_reading_repository.dart'),
      reason: 'main.dart must wire the on-device engine',
    );
  });

  test('the production graph pulls in no HTTP package', () {
    expect(productionGraph, isNot(contains('package:http/http.dart')));
    expect(
      productionGraph.where((entry) => entry.startsWith('package:')).toSet(),
      everyElement(isNot(contains('http'))),
      reason:
          'third-party packages reachable from main.dart: '
          '${productionGraph.where((e) => e.startsWith('package:')).toList()}',
    );
  });

  test('the local engine itself imports nothing that can reach a network', () {
    final engineGraph = reachableLibraries(
      'lib/local_engine/local_reading_repository.dart',
    );
    for (final entry in engineGraph) {
      expect(
        entry,
        isNot(contains('http')),
        reason: 'engine graph entry $entry',
      );
      expect(
        entry,
        isNot(contains('socket')),
        reason: 'engine graph entry $entry',
      );
    }
    // `dart:io` is never imported by engine sources either, so the engine
    // cannot open a socket or read a file even by accident.
    for (final path in engineGraph.where((e) => e.startsWith('lib/'))) {
      final file = File(path);
      if (!file.existsSync()) continue;
      expect(
        file.readAsStringSync(),
        isNot(contains("import 'dart:io'")),
        reason: '$path must not import dart:io',
      );
    }
  });

  test('no DECISION_API_BASE_URL is defined in this build', () {
    const define = String.fromEnvironment(ReadingApiConfig.defineKey);
    expect(define, isEmpty);
  });

  test('a reading succeeds with no API base URL and no network', () async {
    const repository = LocalReadingRepository(runner: runInline);
    final response = await repository.calculate(
      const ReadingRequest(
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
        period: TimePeriod.now,
        mode: DecisionMode.yesNo,
        category: ReadingCategory.general,
      ),
    );

    expect(response.status, ReadingStatus.ready);
    expect(response.winner, 'YES');
    expect(response.readingKey, isNotNull);
    expect(response.providers['tzdb'], isNotEmpty);
  });

  test(
    'the default dispatcher runs the engine on a background isolate',
    () async {
      const repository = LocalReadingRepository();
      final response = await repository.calculate(
        const ReadingRequest(
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
          period: TimePeriod.evening,
          mode: DecisionMode.forwardBackward,
        ),
      );

      expect(response.status, ReadingStatus.ready);
      expect(response.mode, DecisionMode.forwardBackward);
      expect(response.luckyWindows, isNotEmpty);
    },
  );

  test('a refusal survives the isolate boundary as a safe failure', () async {
    // The default dispatcher throws across an isolate, so the exception has to
    // be copyable and still carry nothing about the input.
    const repository = LocalReadingRepository();
    try {
      await repository.calculate(
        const ReadingRequest(
          profile: BirthProfile(birthDate: '1998-06-21', birthCountry: 'VN'),
          context: CurrentContext(
            instantUtc: '2026-09-18T08:30:00.000Z',
            deviceTimezone: 'Not/AZone',
          ),
        ),
      );
      fail('expected the reading to be refused');
    } on ReadingApiException catch (failure) {
      expect(failure.kind, ReadingApiFailureKind.rejectedRequest);
      expect(failure.toString(), isNot(contains('Not/AZone')));
      expect(failure.toString(), isNot(contains('1998')));
    }
  });

  test('a rejected input becomes a safe, non-retryable failure', () async {
    const repository = LocalReadingRepository(runner: runInline);

    Future<ReadingApiException> failureFor(ReadingRequest request) async {
      try {
        await repository.calculate(request);
      } on ReadingApiException catch (failure) {
        return failure;
      }
      fail('expected the reading to be refused');
    }

    final futureBirth = await failureFor(
      const ReadingRequest(
        profile: BirthProfile(birthDate: '2099-01-01', birthCountry: 'VN'),
        context: CurrentContext(
          instantUtc: '2026-09-18T08:30:00.000Z',
          deviceTimezone: 'Asia/Ho_Chi_Minh',
        ),
      ),
    );
    expect(futureBirth.kind, ReadingApiFailureKind.rejectedRequest);

    final badZone = await failureFor(
      const ReadingRequest(
        profile: BirthProfile(birthDate: '1998-06-21', birthCountry: 'VN'),
        context: CurrentContext(
          instantUtc: '2026-09-18T08:30:00.000Z',
          deviceTimezone: 'Not/AZone',
        ),
      ),
    );
    expect(badZone.kind, ReadingApiFailureKind.rejectedRequest);

    // Whatever the failure, nothing about the input may appear in it.
    for (final failure in <ReadingApiException>[futureBirth, badZone]) {
      final text = failure.toString();
      expect(text, isNot(contains('1998')));
      expect(text, isNot(contains('2099')));
      expect(text, isNot(contains('Ho_Chi_Minh')));
      expect(text, isNot(contains('Not/AZone')));
      expect(text, isNot(contains('VN')));
    }
  });
}

String _normalize(String path) {
  final parts = <String>[];
  for (final segment in path.split('/')) {
    if (segment == '.' || segment.isEmpty) continue;
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(segment);
  }
  return parts.join('/');
}
