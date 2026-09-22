import 'dart:convert';
import 'dart:io';

import 'package:decision_compass/data/models/models.dart';

/// Fixture files under `test/fixtures/`.
///
/// See `test/fixtures/README.md` for provenance: `synthetic_*` files are
/// parser-only fixtures for states the engine cannot be asked to emit, the rest
/// are scenarios `calculation-engine/scripts/mobile-fixtures.mjs` reproduces
/// from the real engine.
const fixtureFiles = <String>[
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
  'synthetic_balanced.json',
  'synthetic_insufficient_data.json',
];

JsonMap readFixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as JsonMap;

Map<String, JsonMap> readAllFixtures() => {
  for (final name in fixtureFiles) name: readFixture(name),
};
