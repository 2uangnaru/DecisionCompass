import 'package:decision_compass/data/fake_reading_repository.dart';
import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/data/reading_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_loader.dart';

const _request = ReadingRequest(
  profile: BirthProfile(birthDate: '1998-06-21', birthCountry: 'VN'),
  context: CurrentContext(
    instantUtc: '2026-09-18T08:30:00.000Z',
    deviceTimezone: 'Asia/Ho_Chi_Minh',
  ),
  mode: DecisionMode.yesNo,
  period: TimePeriod.now,
);

ReadingResponse _fixtureResponse() =>
    ReadingResponse.fromJson(readFixture('ready_yes_no_now.json'));

void main() {
  test('FakeReadingRepository satisfies the ReadingRepository interface', () {
    expect(FakeReadingRepository(), isA<ReadingRepository>());
  });

  test('returns the configured response and records the request', () async {
    final repository = FakeReadingRepository(response: _fixtureResponse());

    final response = await repository.calculate(_request);

    expect(response.status, ReadingStatus.ready);
    expect(response.mode, DecisionMode.yesNo);
    expect(repository.requests, hasLength(1));
    expect(repository.requests.single.mode, DecisionMode.yesNo);
  });

  test('respondWith overrides later calls', () async {
    final repository = FakeReadingRepository();
    repository.respondWith(_fixtureResponse());

    expect((await repository.calculate(_request)).winner, 'YES');
  });

  test('surfaces a configured error instead of inventing a reading', () async {
    final repository = FakeReadingRepository(
      error: const ReadingDtoException('offline'),
    );

    expect(
      () => repository.calculate(_request),
      throwsA(isA<ReadingDtoException>()),
    );
  });

  test(
    'throws when no response is configured rather than returning a default',
    () async {
      final repository = FakeReadingRepository();

      expect(() => repository.calculate(_request), throwsA(isA<StateError>()));
    },
  );
}
