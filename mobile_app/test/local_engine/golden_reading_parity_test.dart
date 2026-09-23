import 'dart:convert';
import 'dart:io';

import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/local_engine/local_reading_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden parity: the offline Dart engine against every real Node-generated
/// fixture in `test/fixtures/`.
///
/// These files are byte-for-byte engine output (see `test/fixtures/README.md`),
/// so anything the local engine emits differently is a port defect — including
/// the `readingKey`, which is a SHA-256 over the profile, the ruleset, the
/// provider versions and the evaluated segments. Matching it means the whole
/// evaluation agreed, not just the headline number.
void main() {
  /// Fixtures that the generator wrote from the engine itself. The two
  /// `synthetic_*` files are hand-maintained parser fixtures and are
  /// deliberately excluded — they are not engine output and cannot be
  /// reproduced by running the engine.
  const engineFixtures = <String>[
    'ready_yes_no_now.json',
    'ready_forward_backward_two_windows.json',
    'ready_left_right.json',
    'ready_advance_retreat.json',
    'ready_act_wait_midday.json',
    'one_remaining.json',
    'no_15_minute_window.json',
    'period_elapsed.json',
    'unknown_birth_time_warnings.json',
    'location_fallback_device_timezone.json',
    'ready_love_evening.json',
    'ready_career_now.json',
    'ready_money_afternoon.json',
    'ready_study_morning.json',
    'ready_friends_midday.json',
    'ready_other_now.json',
  ];

  Map<String, dynamic> loadFixture(String name) =>
      jsonDecode(File('test/fixtures/$name').readAsStringSync())
          as Map<String, dynamic>;

  /// The position fixes the generator sent. `inputSnapshot` deliberately does
  /// not record coordinates — that is a privacy guarantee, not an omission —
  /// so the one scenario that supplies a fix restates it here, copied from
  /// `calculation-engine/scripts/mobile-fixtures.mjs`.
  const locationFixes = <String, Map<String, Object?>>{
    'location_fallback_device_timezone.json': <String, Object?>{
      'latitude': 48.8566,
      'longitude': 2.3522,
      'accuracyMeters': 120,
      'capturedAtUtc': '2026-09-17T10:00:00Z',
    },
  };

  /// Rebuilds the request the generator used, from the fixture's own
  /// `inputSnapshot`. Nothing is guessed: the snapshot records the exact
  /// profile, instant, timezone, period, mode and category.
  Map<String, Object?> requestFrom(Map<String, dynamic> fixture, String name) {
    final snapshot = fixture['inputSnapshot'] as Map<String, dynamic>;
    final profile = Map<String, Object?>.from(
      snapshot['profile'] as Map<String, dynamic>,
    );
    final context = snapshot['context'] as Map<String, dynamic>;
    return <String, Object?>{
      'profile': profile,
      'context': <String, Object?>{
        'instantUtc': context['instantUtc'],
        'deviceTimezone': context['timezone'],
        if (locationFixes.containsKey(name)) 'location': locationFixes[name],
      },
      'period': snapshot['period'],
      'mode': snapshot['mode'],
      'category': snapshot['category'],
    };
  }

  Map<String, Object?> runLocal(Map<String, dynamic> fixture, String name) {
    final request = requestFrom(fixture, name);
    return calculateReading(
      profile: request['profile']! as Map<String, Object?>,
      context: request['context']! as Map<String, Object?>,
      period: request['period']! as String,
      mode: request['mode']! as String,
      category: request['category']! as String,
    );
  }

  /// Deep structural comparison that reports the first differing JSON path.
  void expectDeepEqual(Object? actual, Object? expected, String path) {
    if (expected is Map) {
      expect(actual, isA<Map<dynamic, dynamic>>(), reason: 'at $path');
      final actualMap = actual! as Map<dynamic, dynamic>;
      expect(
        actualMap.keys.map((k) => k.toString()).toSet(),
        expected.keys.map((k) => k.toString()).toSet(),
        reason: 'keys at $path',
      );
      for (final key in expected.keys) {
        expectDeepEqual(actualMap[key], expected[key], '$path.$key');
      }
      return;
    }
    if (expected is List) {
      expect(actual, isA<List<dynamic>>(), reason: 'at $path');
      final actualList = actual! as List<dynamic>;
      expect(actualList.length, expected.length, reason: 'length at $path');
      for (var i = 0; i < expected.length; i++) {
        expectDeepEqual(actualList[i], expected[i], '$path[$i]');
      }
      return;
    }
    if (expected is num && actual is num) {
      // Integers must match exactly; the ten-decimal rounded values the engine
      // emits are compared with a tolerance far below that rounding step.
      if (expected is int) {
        expect(actual, expected, reason: 'at $path');
      } else {
        expect(
          actual.toDouble(),
          closeTo(expected.toDouble(), 1e-12),
          reason: 'at $path',
        );
      }
      return;
    }
    expect(actual, expected, reason: 'at $path');
  }

  for (final name in engineFixtures) {
    test('local engine reproduces $name exactly', () {
      final fixture = loadFixture(name);
      final actual = runLocal(fixture, name);

      // Compared as decoded JSON so numeric typing is judged the way the DTO
      // and any saved snapshot would see it.
      final actualJson = jsonDecode(jsonEncode(actual)) as Map<String, dynamic>;
      expectDeepEqual(actualJson, fixture, name);
    });
  }

  test('every engine fixture also parses through the existing DTO', () {
    for (final name in engineFixtures) {
      final fixture = loadFixture(name);
      final actual = runLocal(fixture, name);
      final parsed = ReadingResponse.fromJson(
        jsonDecode(jsonEncode(actual)) as Map<String, dynamic>,
      );
      final expected = ReadingResponse.fromJson(fixture);

      expect(parsed.status, expected.status, reason: '$name status');
      expect(parsed.winner, expected.winner, reason: '$name winner');
      expect(parsed.mode, expected.mode, reason: '$name mode');
      expect(parsed.period, expected.period, reason: '$name period');
      expect(parsed.category, expected.category, reason: '$name category');
      expect(
        parsed.readingKey,
        expected.readingKey,
        reason: '$name readingKey',
      );
      expect(
        parsed.windowStatus,
        expected.windowStatus,
        reason: '$name windowStatus',
      );
      expect(
        parsed.luckyWindows.length,
        expected.luckyWindows.length,
        reason: '$name window count',
      );
      expect(
        parsed.warnings.map((w) => w.code).toList(),
        expected.warnings.map((w) => w.code).toList(),
        reason: '$name warnings',
      );
      expect(
        parsed.engineVersion,
        expected.engineVersion,
        reason: '$name engine version',
      );
      expect(
        parsed.rulesetVersion,
        expected.rulesetVersion,
        reason: '$name ruleset version',
      );
      expect(parsed.providers, expected.providers, reason: '$name providers');
    }
  });

  test('the same request twice returns an identical reading and key', () {
    final fixture = loadFixture('ready_yes_no_now.json');
    final first = runLocal(fixture, 'ready_yes_no_now.json');
    final second = runLocal(fixture, 'ready_yes_no_now.json');
    expect(jsonEncode(second), jsonEncode(first));
  });

  test('FORWARD/BACKWARD and LEFT/RIGHT are not aliases of YES/NO', () {
    final fixture = loadFixture('ready_yes_no_now.json');
    final request = requestFrom(fixture, 'ready_yes_no_now.json');
    final profile = request['profile']! as Map<String, Object?>;
    final context = request['context']! as Map<String, Object?>;

    Map<String, Object?> forMode(String mode) => calculateReading(
      profile: profile,
      context: context,
      period: 'now',
      mode: mode,
      category: 'general',
    );

    final yesNo = forMode('yes_no');
    final forwardBackward = forMode('forward_backward');
    final leftRight = forMode('left_right');

    // Same axes, three different projections: the selected score must differ,
    // and the winners must come from each mode's own label pair.
    final yesNoScore = (yesNo['modeScore']! as num).toDouble();
    final forwardScore = (forwardBackward['modeScore']! as num).toDouble();
    final leftScore = (leftRight['modeScore']! as num).toDouble();

    expect(forwardScore, isNot(closeTo(yesNoScore, 1e-9)));
    expect(leftScore, isNot(closeTo(yesNoScore, 1e-9)));
    expect(leftScore, isNot(closeTo(forwardScore, 1e-9)));

    expect(<String>['YES', 'NO'], contains(yesNo['winner']));
    expect(<String>[
      'FORWARD',
      'BACKWARD',
    ], contains(forwardBackward['winner']));
    expect(<String>['LEFT', 'RIGHT'], contains(leftRight['winner']));

    expect(yesNo['modeBasis'], 'overall_acceptance');
    expect(forwardBackward['modeBasis'], 'temporal_momentum');
    expect(leftRight['modeBasis'], 'symbolic_polarity');
  });
}
