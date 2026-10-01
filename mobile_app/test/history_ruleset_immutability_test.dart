import 'dart:convert';

import 'package:decision_compass/data/history_entry.dart';
import 'package:decision_compass/data/shared_preferences_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

/// A saved reading is a record of what the app said, not a question it asks
/// again.
///
/// v9.4 changed two mode mixtures. For COMMIT / WITHDRAW the change is large
/// enough to reverse the direction on the very scenario below: under the v9.3
/// ruleset that profile and instant read COMMIT 69.6%, and under v9.4 the same
/// inputs read WITHDRAW 55.2%. A reader who saved the first one must still see
/// the first one — relabelling it would be the app claiming it had said
/// something it never said.
///
/// This is only true because nothing recalculates a stored snapshot. The
/// numbers below are therefore written in by hand, as a v9.3-era entry, and
/// the test asserts they survive the read path untouched.
void main() {
  /// The v9.3 COMMIT / WITHDRAW result for the profile and evening context in
  /// `calculation-engine/test/fixtures/mode-baseline.json`, captured before
  /// the mixture changed.
  const savedPercentages = {'COMMIT': 69.6, 'WITHDRAW': 30.4};
  const savedWinner = 'COMMIT';
  const savedRuleset =
      'civil-midnight-chinese-calendar-symbolic-v9.3-experimental';

  Map<String, dynamic> v93Snapshot() {
    final reading = fixtureResponse('ready_commit_withdraw_two_windows.json')
        .toJson();
    reading['engineVersion'] = '4.2.0-mvp';
    reading['rulesetVersion'] = savedRuleset;
    reading['readingKey'] =
        'dc93bb786f01973a00d34a920a9e9c3bb6934e0451487f6b03395b5d9fffe6a3';
    reading['winner'] = savedWinner;
    reading['percentages'] = savedPercentages;
    reading['modeScore'] = 0.2730263427;
    return reading;
  }

  test(
    'a v9.3 snapshot keeps its own direction under the v9.4 ruleset',
    () async {
      final saved = v93Snapshot();
      SharedPreferences.setMockInitialValues({
        'history_entries_v1': jsonEncode([
          {
            'id': 'saved-under-v93',
            'reading': saved,
            'savedAtUtc': '2026-09-30T10:00:00.000Z',
          },
        ]),
      });

      const repository = SharedPreferencesHistoryRepository();
      final entries = await repository.list();
      expect(entries, hasLength(1));
      final reading = entries.single.reading;

      // The direction the engine would now give these inputs is the opposite
      // one. Reading the entry must not consult the engine at all.
      expect(reading.winner, savedWinner);
      expect(reading.percentages!.display('COMMIT'), '69.6');
      expect(reading.percentages!.display('WITHDRAW'), '30.4');
      expect(reading.modeScore, 0.2730263427);

      // And it still says which ruleset produced it, so the snapshot can be
      // read for what it is rather than mistaken for a current reading.
      expect(reading.rulesetVersion, savedRuleset);
      expect(reading.engineVersion, '4.2.0-mvp');
    },
  );

  test('saving a new reading beside it rewrites neither', () async {
    SharedPreferences.setMockInitialValues({
      'history_entries_v1': jsonEncode([
        {
          'id': 'saved-under-v93',
          'reading': v93Snapshot(),
          'savedAtUtc': '2026-09-30T10:00:00.000Z',
        },
      ]),
    });

    const repository = SharedPreferencesHistoryRepository();
    await repository.save(
      HistoryEntry(
        id: 'saved-under-v94',
        reading: fixtureResponse('ready_commit_withdraw_two_windows.json'),
        savedAtUtc: DateTime.utc(2026, 10, 1, 10),
      ),
    );

    final entries = await repository.list();
    expect(entries, hasLength(2));

    final old = entries.singleWhere((e) => e.id == 'saved-under-v93');
    expect(old.reading.winner, savedWinner);
    expect(old.reading.percentages!.display('COMMIT'), '69.6');
    expect(old.reading.rulesetVersion, savedRuleset);

    // The new one is the current ruleset, and the two coexist with different
    // numbers for the same question. That is the point of a snapshot.
    final fresh = entries.singleWhere((e) => e.id == 'saved-under-v94');
    expect(
      fresh.reading.rulesetVersion,
      'civil-midnight-chinese-calendar-symbolic-v9.4-experimental',
    );
    expect(fresh.reading.readingKey, isNot(old.reading.readingKey));
  });
}
