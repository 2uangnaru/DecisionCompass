import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/auspicious_hour.dart';
import 'package:decision_compass/local_engine/calendar/calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The engine's own almanac verdict for the hour god in force at [local]
  /// (Asia/Ho_Chi_Minh, UTC+7 with no DST).
  bool engineSaysHuangDao(DateTime local) {
    final ms = DateTime.utc(
      local.year,
      local.month,
      local.day,
      local.hour,
    ).subtract(const Duration(hours: 7)).millisecondsSinceEpoch.toDouble();
    final god = almanac(calendarAt(ms, 'Asia/Ho_Chi_Minh'))
        .diagnostics['hourGod'];
    return (god! as Map)['auspicious'] == true;
  }

  int natalBranch(DateTime birth) => civilCalendar(
    '${birth.year}-${birth.month.toString().padLeft(2, '0')}-'
    '${birth.day.toString().padLeft(2, '0')}',
  ).day.branch;

  final births = [
    DateTime(2001, 2, 12),
    DateTime(1990, 7, 3),
    DateTime(1985, 11, 30),
  ];

  test('always a waking Hoàng Đạo hour that never clashes with the natal '
      'day, as the engine almanac reads it', () {
    for (var day = 0; day < 60; day++) {
      for (final birth in births) {
        for (final hour in [0, 8, 14, 22]) {
          final now = DateTime(2026, 10, 1 + day, hour, 30);
          final branch = bestAuspiciousHourBranch(
            nowLocal: now,
            birthDate: birth,
          );
          expect(branch, inInclusiveRange(3, 10), reason: '05:00–21:00');
          expect(branch, isNot((natalBranch(birth) + 6) % 12));
          expect(
            engineSaysHuangDao(
              DateTime(now.year, now.month, now.day, 2 * branch),
            ),
            isTrue,
            reason: '$now / $birth -> $branch',
          );
        }
      }
    }
  });

  test('a window still ahead today wins over one already past; never '
      'tomorrow', () {
    for (var day = 0; day < 30; day++) {
      for (final birth in births) {
        for (var hour = 0; hour < 24; hour++) {
          final now = DateTime(2026, 10, 1 + day, hour, 10);
          final branch = bestAuspiciousHourBranch(
            nowLocal: now,
            birthDate: birth,
          );
          final anyAhead = [
            for (var b = 3; b <= 10; b++)
              if (now.hour < 2 * b + 1 &&
                  b != (natalBranch(birth) + 6) % 12 &&
                  engineSaysHuangDao(
                    DateTime(now.year, now.month, now.day, 2 * b),
                  ))
                b,
          ].isNotEmpty;
          if (anyAhead) {
            expect(now.hour < 2 * branch + 1, isTrue, reason: '$now');
          }
        }
      }
    }
  });

  test('deterministic, and personal to the birth date', () {
    final now = DateTime(2026, 10, 29, 9);
    expect(
      bestAuspiciousHourBranch(nowLocal: now, birthDate: births[0]),
      bestAuspiciousHourBranch(nowLocal: now, birthDate: births[0]),
    );
    var differs = false;
    for (var day = 0; day < 30 && !differs; day++) {
      final at = DateTime(2026, 10, 1 + day, 6);
      differs =
          bestAuspiciousHourBranch(nowLocal: at, birthDate: births[0]) !=
          bestAuspiciousHourBranch(nowLocal: at, birthDate: births[1]);
    }
    expect(differs, isTrue);
  });

  test('the day master separates readers who share a natal day branch', () {
    // Twelve days apart: the same day branch, a different day stem.
    final a = DateTime(2001, 2, 12);
    final b = a.add(const Duration(days: 12));
    expect(natalBranch(a), natalBranch(b));
    var differs = false;
    for (var day = 0; day < 60 && !differs; day++) {
      final at = DateTime(2026, 10, 1 + day, 6);
      differs =
          bestAuspiciousHourBranch(nowLocal: at, birthDate: a) !=
          bestAuspiciousHourBranch(nowLocal: at, birthDate: b);
    }
    expect(differs, isTrue);
  });

  test('the window no longer repeats every six days', () {
    for (final birth in births) {
      final seq = [
        for (var day = 0; day < 60; day++)
          bestAuspiciousHourBranch(
            nowLocal: DateTime(2026, 10, 1 + day, 6),
            birthDate: birth,
          ),
      ];
      final repeatsEverySix = [
        for (var i = 6; i < 60; i++) seq[i] == seq[i - 6],
      ].every((same) => same);
      expect(repeatsEverySix, isFalse, reason: '$birth');
    }
  });

  test('formats the window with the hour name where the locale has one', () {
    expect(
      formatAuspiciousHour(7, AppLocale.vietnamese),
      '13:00 — 15:00 (Mùi)',
    );
    expect(formatAuspiciousHour(7, AppLocale.english), '13:00 — 15:00');
    expect(
      formatAuspiciousHour(7, AppLocale.simplifiedChinese),
      '13:00 — 15:00 (未时)',
    );
    expect(formatAuspiciousHour(7, AppLocale.japanese), '13:00 — 15:00 (未の刻)');
    expect(formatAuspiciousHour(7, AppLocale.korean), '13:00 — 15:00 (미시)');
    expect(formatAuspiciousHour(3, AppLocale.thai), '05:00 — 07:00');
    expect(
      formatAuspiciousHour(10, AppLocale.vietnamese),
      '19:00 — 21:00 (Tuất)',
    );
  });
}
