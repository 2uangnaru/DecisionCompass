import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'first free reading is immediate and starts exactly three hours',
    () async {
      final q = SharedPreferencesReadingQuotaController();
      await q.ensureLoaded();
      final now = DateTime(2026, 10, 9, 9);
      expect(q.isAvailable(now), isTrue);
      await q.consumeReading(now);
      expect(q.dailyFreeReadingsUsed(now), 1);
      expect(q.remainingCooldown(now), const Duration(hours: 3));
      expect(q.isAvailable(now.add(const Duration(hours: 3))), isTrue);
      expect(
        q.isAvailable(
          now.add(const Duration(hours: 3) - const Duration(milliseconds: 1)),
        ),
        isFalse,
      );
    },
  );

  test('a call during cooldown cannot spend another reading', () async {
    final q = SharedPreferencesReadingQuotaController();
    final now = DateTime(2026, 10, 9, 9);
    await q.consumeReading(now);
    await expectLater(
      q.consumeReading(now),
      throwsA(isA<ReadingQuotaUnavailableException>()),
    );
    expect(q.dailyFreeReadingsUsed(now), 1);
  });

  test('fourth free reading is refused by the controller itself', () async {
    final q = SharedPreferencesReadingQuotaController();
    for (final hour in [9, 12, 15]) {
      await q.consumeReading(DateTime(2026, 10, 9, hour));
    }
    await expectLater(
      q.consumeReading(DateTime(2026, 10, 9, 18)),
      throwsA(isA<ReadingQuotaUnavailableException>()),
    );
    expect(q.dailyFreeReadingsUsed(DateTime(2026, 10, 9, 18)), 3);
  });

  test(
    'UTC arguments are normalized to the device local calendar day',
    () async {
      final q = SharedPreferencesReadingQuotaController();
      final local = DateTime(2026, 10, 10, 1);
      await q.consumeReading(local.toUtc());
      expect(q.dailyFreeReadingsUsed(local), 1);
      expect(q.remainingCooldown(local), const Duration(hours: 3));
    },
  );

  test('midnight resets both free count and an unfinished cooldown', () async {
    final q = SharedPreferencesReadingQuotaController();
    await q.consumeReading(DateTime(2026, 10, 9, 23, 30));
    final midnight = DateTime(2026, 10, 10);
    expect(
      q.remainingCooldown(DateTime(2026, 10, 9, 23, 36)),
      const Duration(minutes: 24),
    );
    expect(q.isAvailable(midnight), isTrue);
    expect(q.dailyFreeReadingsUsed(midnight), 0);
    expect(q.remainingCooldown(midnight), Duration.zero);
    await q.consumeReading(midnight);
    expect(q.dailyFreeReadingsUsed(midnight), 1);
    expect(q.remainingCooldown(midnight), const Duration(hours: 3));
  });

  test(
    'exhausted countdown ends at local midnight and opens three new free uses',
    () async {
      final q = SharedPreferencesReadingQuotaController();
      for (final hour in [12, 15, 23]) {
        await q.consumeReading(DateTime(2026, 10, 9, hour));
      }
      expect(q.isAvailable(DateTime(2026, 10, 9, 23, 59, 59)), isFalse);
      expect(q.remainingTimeString(DateTime(2026, 10, 9, 23, 36)), '00:24:00');
      expect(q.dailyFreeReadingsUsed(DateTime(2026, 10, 10)), 0);
      expect(q.isAvailable(DateTime(2026, 10, 10)), isTrue);
    },
  );

  test('bonus survives midnight and never changes the free cooldown', () async {
    final q = SharedPreferencesReadingQuotaController();
    final now = DateTime(2026, 10, 9, 9);
    await q.consumeReading(now);
    await q.earnBonusReading();
    await q.consumeReading(now.add(const Duration(hours: 1)));
    expect(q.bonusReadings, 0);
    expect(q.dailyFreeReadingsUsed(now), 1);
    expect(
      q.remainingCooldown(now.add(const Duration(hours: 1))),
      const Duration(hours: 2),
    );
    await q.earnBonusReading();
    expect(q.dailyFreeReadingsUsed(DateTime(2026, 10, 10)), 0);
    expect(q.bonusReadings, 1);
  });

  test('concurrent free commits serialize and only one succeeds', () async {
    final q = SharedPreferencesReadingQuotaController();
    final now = DateTime(2026, 10, 9, 9);
    Future<bool> attempt() async {
      try {
        await q.consumeReading(now);
        return true;
      } on ReadingQuotaUnavailableException {
        return false;
      }
    }

    expect(await Future.wait([attempt(), attempt(), attempt()]), [
      true,
      false,
      false,
    ]);
    expect(q.dailyFreeReadingsUsed(now), 1);
  });

  test('concurrent rewards and restored state retain every credit', () async {
    final q = SharedPreferencesReadingQuotaController();
    await Future.wait([
      q.earnBonusReading(),
      q.earnBonusReading(),
      q.earnBonusReading(),
    ]);
    final restored = SharedPreferencesReadingQuotaController();
    await restored.ensureLoaded();
    expect(restored.bonusReadings, 3);
  });

  test('free cooldown and daily usage survive restart', () async {
    final now = DateTime(2026, 10, 9, 9);
    final q = SharedPreferencesReadingQuotaController();
    await q.consumeReading(now);
    final restored = SharedPreferencesReadingQuotaController();
    await restored.ensureLoaded();
    expect(restored.dailyFreeReadingsUsed(now), 1);
    expect(
      restored.remainingCooldown(now.add(const Duration(hours: 1))),
      const Duration(hours: 2),
    );
  });

  test(
    'existing four-key records are migrated without discarding quota or bonus',
    () async {
      final now = DateTime(2026, 10, 9, 9);
      SharedPreferences.setMockInitialValues({
        'reading_quota_date_string': '2026-10-09',
        'reading_quota_used_today': 2,
        'reading_quota_bonus_readings': 1,
        'reading_quota_last_epoch_ms': now.millisecondsSinceEpoch,
      });
      final q = SharedPreferencesReadingQuotaController();
      await q.ensureLoaded();
      expect(q.dailyFreeReadingsUsed(now), 2);
      await q.consumeReading(now.add(const Duration(minutes: 10)));
      final restored = SharedPreferencesReadingQuotaController();
      await restored.ensureLoaded();
      expect(restored.dailyFreeReadingsUsed(now), 2);
      expect(restored.bonusReadings, 0);
      expect(
        restored.remainingCooldown(now.add(const Duration(hours: 1))),
        const Duration(hours: 2),
      );
    },
  );
}
