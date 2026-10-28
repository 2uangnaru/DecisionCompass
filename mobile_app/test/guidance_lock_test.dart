import 'package:decision_compass/data/guidance_lock_store.dart';
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/services/ad_runtime.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

class _Backup implements DeviceCounterBackup {
  int? value;
  bool fail = false;
  @override
  Future<int?> read() async {
    if (fail) throw StateError('no play services');
    return value;
  }

  @override
  Future<void> write(int v) async {
    if (fail) throw StateError('no play services');
    value = v;
  }
}

class _UnearnedAdService extends NoOpAdService {
  const _UnearnedAdService();
  @override
  Future<AdOutcome> showRewarded({
    required Future<void> Function() onEarnedReward,
    String placement = 'reading',
  }) async => AdOutcome.dismissed;
}

class _RecordingRewardAdService extends NoOpAdService {
  final placements = <String>[];
  @override
  Future<AdOutcome> showRewarded({
    required Future<void> Function() onEarnedReward,
    String placement = 'reading',
  }) async {
    placements.add(placement);
    await onEarnedReward();
    return AdOutcome.rewarded;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('GuidanceLockStore', () {
    test('first three new readings are open, the fourth is locked', () async {
      final store = GuidanceLockStore();
      expect(await store.admit('a'), isFalse);
      expect(await store.admit('b'), isFalse);
      expect(await store.admit('c'), isFalse);
      expect(await store.admit('d'), isTrue);
      expect(await store.isLocked('d'), isTrue);
      expect(await store.isLocked('a'), isFalse);
    });

    test('a repeat counts but stays open; the next new one locks', () async {
      final store = GuidanceLockStore();
      await store.admit('a');
      await store.admit('a');
      await store.admit('b');
      expect(await store.admit('a'), isFalse);
      expect(await store.admit('c'), isTrue);
    });

    test('unlock opens that reading for good, including a repeat', () async {
      final store = GuidanceLockStore();
      for (final key in ['a', 'b', 'c']) {
        await store.admit(key);
      }
      expect(await store.admit('d'), isTrue);
      await store.unlock('d');
      expect(await store.isLocked('d'), isFalse);
      expect(await GuidanceLockStore().admit('d'), isFalse);
      expect(await store.admit('e'), isTrue);
    });

    test('snapshots never admitted stay readable', () async {
      expect(await GuidanceLockStore().isLocked('old'), isFalse);
    });

    test('backup count survives cleared app storage', () async {
      final backup = _Backup();
      final store = GuidanceLockStore(backup: backup);
      for (final key in ['a', 'b', 'c']) {
        await store.admit(key);
      }
      expect(backup.value, 3);
      SharedPreferences.setMockInitialValues({});
      expect(await GuidanceLockStore(backup: backup).admit('x'), isTrue);
    });

    test('a failing backup falls back to app storage', () async {
      final store = GuidanceLockStore(backup: _Backup()..fail = true);
      for (final key in ['a', 'b', 'c']) {
        expect(await store.admit(key), isFalse);
      }
      expect(await store.admit('d'), isTrue);
    });
  });

  group('Result page', () {
    setUpAll(loadBundledFonts);
    final reading = fixtureResponse('ready_yes_no_now.json');
    final key = '${reading.readingKey!}|${reading.mode.toJson()}';
    const button = Key('result_guidance_watch_ad_button');

    Future<GuidanceLockStore> spent(int readings) async {
      final store = GuidanceLockStore();
      for (var i = 0; i < readings; i++) {
        await store.admit('earlier_$i');
      }
      return store;
    }

    Future<void> pump(
      WidgetTester tester,
      ReadingTestRig rig, {
      bool fresh = true,
    }) async {
      useScreen(tester, size: const Size(412, 2400));
      await tester.pumpWidget(
        localizedApp(
          home: ResultPage(
            reading: reading,
            dependencies: rig.dependencies,
            autoSave: fresh,
            billableResult: fresh,
          ),
        ),
      );
      // The store answers through SharedPreferences, outside fake time.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    testWidgets('third reading of the device is open', (tester) async {
      final store = await tester.runAsync(() => spent(2));
      await pump(tester, ReadingTestRig(guidanceLocks: store));
      expect(find.byKey(button), findsNothing);
    });

    testWidgets('fourth reading is locked; earned reward opens it for good, '
        'with its own placement and no reading credit', (tester) async {
      final store = (await tester.runAsync(() => spent(3)))!;
      final ads = _RecordingRewardAdService();
      final quota = SharedPreferencesReadingQuotaController();
      final rig = ReadingTestRig(
        guidanceLocks: store,
        adService: ads,
        quotaManager: quota,
      );
      await pump(tester, rig);
      expect(find.byKey(button), findsOneWidget);
      await tester.tap(find.byKey(button));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.byKey(button), findsNothing);
      expect(ads.placements, ['guidance']);
      expect(quota.bonusReadings, 0);
      expect(await tester.runAsync(() => store.isLocked(key)), isFalse);
    });

    testWidgets('the lock is keyed per mode, since readingKey omits it', (
      tester,
    ) async {
      await pump(tester, ReadingTestRig(guidanceLocks: GuidanceLockStore()));
      final open = (await SharedPreferences.getInstance()).getStringList(
        GuidanceLockStore.openKey,
      );
      expect(open, [key]);
      expect(key, endsWith('|${reading.mode.toJson()}'));
    });

    testWidgets('an unearned ad leaves it locked', (tester) async {
      final store = (await tester.runAsync(() => spent(3)))!;
      await pump(
        tester,
        ReadingTestRig(
          guidanceLocks: store,
          adService: const _UnearnedAdService(),
        ),
      );
      await tester.tap(find.byKey(button));
      await tester.pump();
      expect(find.byKey(button), findsOneWidget);
      expect(await tester.runAsync(() => store.isLocked(key)), isTrue);
    });

    testWidgets('History reopens a locked snapshot locked, without spending', (
      tester,
    ) async {
      final store = (await tester.runAsync(() async {
        final s = await spent(3);
        await s.admit(key);
        return s;
      }))!;
      await pump(tester, ReadingTestRig(guidanceLocks: store), fresh: false);
      expect(find.byKey(button), findsOneWidget);
      // Reopening did not count as a new reading.
      expect(
        (await SharedPreferences.getInstance()).getInt(
          GuidanceLockStore.countKey,
        ),
        4,
      );
    });

    testWidgets('no store never locks', (tester) async {
      await pump(tester, ReadingTestRig());
      expect(find.byKey(button), findsNothing);
    });
  });
}
