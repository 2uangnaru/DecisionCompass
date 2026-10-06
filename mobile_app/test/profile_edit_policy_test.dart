import 'dart:convert';

import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/profile_edit_policy.dart';
import 'package:decision_compass/localized_presentation.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/data/shared_preferences_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

/// The cooldown arithmetic, the profile record that carries it, and the way
/// the remaining wait is spelled — none of which needs a widget tree.
void main() {
  final changed = DateTime.utc(2026, 9, 18, 10, 0);

  Duration waitAt(DateTime now, {Duration window = birthTimeEditCooldown}) =>
      remainingEditCooldown(changedAtUtc: changed, window: window, nowUtc: now);

  group('cooldown arithmetic', () {
    test('a field that was never changed is open', () {
      expect(
        remainingEditCooldown(
          changedAtUtc: null,
          window: birthTimeEditCooldown,
          nowUtc: changed,
        ),
        Duration.zero,
      );
      expect(
        canEditNow(
          changedAtUtc: null,
          window: birthCountryEditCooldown,
          nowUtc: changed,
        ),
        isTrue,
      );
    });

    test('a change just made holds the whole window', () {
      expect(waitAt(changed), birthTimeEditCooldown);
    });

    test('the wait counts down', () {
      expect(
        waitAt(changed.add(const Duration(minutes: 35))),
        const Duration(hours: 1, minutes: 25),
      );
    });

    test('one second short of the window is still shut', () {
      final almost = changed.add(
        birthTimeEditCooldown - const Duration(seconds: 1),
      );
      expect(waitAt(almost), const Duration(seconds: 1));
      expect(
        canEditNow(
          changedAtUtc: changed,
          window: birthTimeEditCooldown,
          nowUtc: almost,
        ),
        isFalse,
      );
    });

    test('exactly at the window it is open, not one tick short', () {
      final boundary = changed.add(birthTimeEditCooldown);
      expect(waitAt(boundary), Duration.zero);
      expect(
        canEditNow(
          changedAtUtc: changed,
          window: birthTimeEditCooldown,
          nowUtc: boundary,
        ),
        isTrue,
        reason:
            'a reader told "2 hours" who comes back at 2 hours must find it '
            'open',
      );
    });

    test('the country window is its own, shorter one', () {
      final hour = changed.add(const Duration(hours: 1));
      expect(waitAt(hour, window: birthCountryEditCooldown), Duration.zero);
      expect(
        waitAt(hour),
        const Duration(hours: 1),
        reason: 'the birth-time window must not inherit the country one',
      );
    });

    test('a clock moved backwards locks for one window, never forever', () {
      // The device's own clock is now *before* the stamp — a time-zone change
      // the OS applied retroactively, a manual correction, or a record copied
      // from another device. Measured naively this is a negative elapsed time
      // and a wait of days.
      final rewound = changed.subtract(const Duration(days: 400));
      expect(waitAt(rewound), birthTimeEditCooldown);
    });

    test('a local-time "now" is compared in UTC', () {
      // The same instant, expressed in a +07:00 wall clock. Comparing the
      // wall clocks rather than the instants would make this read as seven
      // hours later and unlock the field.
      final local = DateTime.utc(2026, 9, 18, 17, 0).toLocal();
      expect(
        remainingEditCooldown(
          changedAtUtc: changed,
          window: birthTimeEditCooldown,
          nowUtc: local,
        ),
        Duration.zero,
      );
    });
  });

  group('the profile record', () {
    AppProfile base({
      String? userName = 'Alex',
      String? birthTime = '14:30',
      DateTime? birthTimeChangedAtUtc,
      DateTime? birthCountryChangedAtUtc,
    }) => AppProfile(
      userName: userName,
      birthDate: DateTime(1998, 6, 21),
      birthTime: birthTime,
      birthCountryCode: 'VN',
      zodiacSign: zodiacForDate(DateTime(1998, 6, 21)),
      useCurrentLocation: false,
      birthTimeChangedAtUtc: birthTimeChangedAtUtc,
      birthCountryChangedAtUtc: birthCountryChangedAtUtc,
    );

    test('edited() clears a name, which copyWith cannot', () {
      final profile = base();

      expect(
        profile.copyWith(userName: null).userName,
        'Alex',
        reason:
            'copyWith keeps its "null means leave it alone" rule, so no '
            'existing caller can erase a name by omitting an argument',
      );

      final cleared = profile.edited(
        userName: null,
        birthDate: profile.birthDate,
        birthTime: profile.birthTime,
        birthCountryCode: profile.birthCountryCode,
        birthTimeChangedAtUtc: null,
        birthCountryChangedAtUtc: null,
        birthDateChangedAtUtc: null,
      );
      expect(cleared.userName, isNull);
      expect(cleared.hasDefaultName, isTrue);
      // And the stored record omits the key entirely rather than writing a
      // language's word for the default.
      expect(cleared.toJson().containsKey('userName'), isFalse);
    });

    test('edited() can mark a known birth time unknown', () {
      final unknown = base().edited(
        userName: 'Alex',
        birthDate: base().birthDate,
        birthTime: null,
        birthCountryCode: 'VN',
        birthTimeChangedAtUtc: changed,
        birthCountryChangedAtUtc: null,
        birthDateChangedAtUtc: null,
      );
      expect(unknown.birthTime, isNull);
      expect(unknown.toBirthProfile().birthTime, isNull);
    });

    test('edited() leaves everything it was not given alone', () {
      final profile = base();
      final next = profile.edited(
        userName: 'Bo',
        birthDate: profile.birthDate,
        birthTime: '09:15',
        birthCountryCode: 'JP',
        birthTimeChangedAtUtc: changed,
        birthCountryChangedAtUtc: changed,
        birthDateChangedAtUtc: null,
      );
      expect(next.birthDate, profile.birthDate);
      expect(next.zodiacSign, profile.zodiacSign);
      expect(next.useCurrentLocation, profile.useCurrentLocation);
      expect(next.safetyAcknowledged, profile.safetyAcknowledged);
      expect(next.createdAt, profile.createdAt);
    });

    test('the stamps round-trip, normalised to UTC', () {
      // Written in local time on purpose: the record must not keep an offset
      // that a later launch would read in a different zone.
      final local = DateTime.utc(2026, 9, 18, 10, 0).toLocal();
      final restored = AppProfile.fromJson(
        base(
          birthTimeChangedAtUtc: local,
          birthCountryChangedAtUtc: local,
        ).toJson(),
      );
      expect(restored.birthTimeChangedAtUtc, changed);
      expect(restored.birthTimeChangedAtUtc!.isUtc, isTrue);
      expect(restored.birthCountryChangedAtUtc, changed);
    });

    test('a profile saved before cooldowns existed reads as never changed', () {
      final legacy = base().toJson()
        ..remove('birthTimeChangedAtUtc')
        ..remove('birthCountryChangedAtUtc');
      final restored = AppProfile.fromJson(legacy);
      expect(restored.birthTimeChangedAtUtc, isNull);
      expect(restored.birthCountryChangedAtUtc, isNull);
    });

    test('a changed date brings its own sign, and keeps createdAt', () {
      final made = DateTime.utc(2026, 9, 1, 8, 0);
      final profile = base().copyWith(createdAt: made);
      expect(profile.zodiacSign, zodiacForDate(DateTime(1998, 6, 21)));

      final moved = profile.edited(
        userName: profile.userName,
        birthDate: DateTime(1998, 3, 10),
        birthTime: profile.birthTime,
        birthCountryCode: profile.birthCountryCode,
        birthTimeChangedAtUtc: null,
        birthCountryChangedAtUtc: null,
        birthDateChangedAtUtc: changed,
      );

      expect(moved.birthDate, DateTime(1998, 3, 10));
      expect(
        moved.zodiacSign,
        zodiacForDate(DateTime(1998, 3, 10)),
        reason: 'the avatar would have kept the old sign',
      );
      expect(moved.zodiacSign, isNot(profile.zodiacSign));
      expect(moved.toBirthProfile().birthDate, '1998-03-10');
      expect(
        moved.createdAt,
        made,
        reason: 'editing a profile does not re-make it',
      );
      expect(moved.birthDateChangedAtUtc, changed);
    });

    test('the birth-date stamp round-trips in UTC, and survives a reload', () {
      final local = DateTime.utc(2026, 9, 18, 10, 0).toLocal();
      final restored = AppProfile.fromJson(
        base().copyWith(birthDateChangedAtUtc: local).toJson(),
      );
      expect(restored.birthDateChangedAtUtc, changed);
      expect(restored.birthDateChangedAtUtc!.isUtc, isTrue);
    });

    test(
      'a record written before birth-date editing reads as never changed',
      () {
        final legacy = base().toJson()..remove('birthDateChangedAtUtc');
        expect(AppProfile.fromJson(legacy).birthDateChangedAtUtc, isNull);
      },
    );

    test('a damaged birth-date stamp reads as absent, not as just-changed', () {
      for (final broken in <Object>[42, 'yesterday', '', false]) {
        final json = base().toJson()..['birthDateChangedAtUtc'] = broken;
        expect(
          AppProfile.fromJson(json).birthDateChangedAtUtc,
          isNull,
          reason: 'a stamp of $broken should read as absent',
        );
      }
    });

    test('createdAt survives every shape a damaged record can hold', () {
      // `as String?` threw on all of these, and it threw on the first frame —
      // before the legacy rule below could decide anything, and before the
      // repository's own try/catch could do more than drop the whole profile
      // and send the reader back through onboarding.
      final shapes = <String, Object?>{
        'a number': 42,
        'a float': 1.5,
        'a boolean': true,
        'a list': ['2026-09-18T08:00:00Z'],
        'a map': {'at': '2026-09-18T08:00:00Z'},
        'an empty string': '',
        'a sentence': 'last Tuesday',
        'a half-written date': '2026-09-',
      };

      for (final entry in shapes.entries) {
        final json = base().toJson()..['createdAt'] = entry.value;
        late final AppProfile restored;
        expect(
          () => restored = AppProfile.fromJson(json),
          returnsNormally,
          reason: 'a createdAt of ${entry.key} stopped the profile loading',
        );
        // Every other field is still the profile the reader had.
        expect(restored.createdAt, isNull, reason: entry.key);
        expect(restored.birthDate, DateTime(1998, 6, 21), reason: entry.key);
        expect(restored.birthCountryCode, 'VN', reason: entry.key);
        expect(restored.userName, 'Alex', reason: entry.key);
        // And the legacy rule applies: the first birth-date edit is free.
        expect(
          remainingBirthDateWait(
            createdAt: restored.createdAt,
            changedAtUtc: restored.birthDateChangedAtUtc,
            nowUtc: changed,
          ),
          Duration.zero,
          reason: '${entry.key} left the birth date locked',
        );
      }
    });

    test('a createdAt that is missing or explicitly null reads as absent', () {
      final missing = base().toJson()..remove('createdAt');
      expect(AppProfile.fromJson(missing).createdAt, isNull);

      final explicit = base().toJson()..['createdAt'] = null;
      expect(AppProfile.fromJson(explicit).createdAt, isNull);
    });

    test('a valid createdAt is read exactly as it was written', () {
      // Unchanged behaviour, and the reason the fix is a type check rather
      // than a conversion: this value is not normalised to UTC, and the
      // two-hour gate is measured from it.
      final made = DateTime.utc(2026, 9, 18, 8, 0);
      final restored = AppProfile.fromJson(
        base().copyWith(createdAt: made).toJson(),
      );
      expect(restored.createdAt, made);
      expect(
        remainingBirthDateWait(
          createdAt: restored.createdAt,
          changedAtUtc: null,
          nowUtc: made.add(const Duration(minutes: 30)),
        ),
        const Duration(hours: 1, minutes: 30),
        reason: 'the two-hour first-edit gate moved',
      );

      // A local timestamp, which is what this build actually writes, comes
      // back as the same wall time rather than being shifted.
      final local = DateTime(2026, 9, 18, 8, 0);
      final fromLocal = AppProfile.fromJson(
        base().copyWith(createdAt: local).toJson(),
      );
      expect(fromLocal.createdAt, local);
      expect(fromLocal.createdAt!.isUtc, isFalse);
    });

    test('a damaged stamp unlocks the field rather than throwing', () {
      // The other way round would lock a reader out of their own profile over
      // a corrupt string, with nothing they could do about it.
      for (final broken in <Object>[123, 'not a date', '', true]) {
        final json = base().toJson()..['birthTimeChangedAtUtc'] = broken;
        expect(
          AppProfile.fromJson(json).birthTimeChangedAtUtc,
          isNull,
          reason: 'a stamp of $broken should read as absent',
        );
      }
    });
  });

  group('the birth date, which has two clocks', () {
    final created = DateTime.utc(2026, 9, 18, 8, 0);

    Duration waitFor({
      DateTime? createdAt,
      DateTime? changedAtUtc,
      required DateTime now,
    }) => remainingBirthDateWait(
      createdAt: createdAt,
      changedAtUtc: changedAtUtc,
      nowUtc: now,
    );

    test('a profile that knows neither is open, so a legacy reader is not '
        'locked out forever', () {
      expect(
        waitFor(createdAt: null, changedAtUtc: null, now: created),
        Duration.zero,
      );
    });

    test('a new profile waits two hours from when it was made', () {
      expect(
        waitFor(createdAt: created, changedAtUtc: null, now: created),
        birthDateFirstEditDelay,
      );
      expect(
        waitFor(
          createdAt: created,
          changedAtUtc: null,
          now: created.add(const Duration(minutes: 75)),
        ),
        const Duration(minutes: 45),
      );
    });

    test('one second short of two hours is still shut', () {
      expect(
        waitFor(
          createdAt: created,
          changedAtUtc: null,
          now: created.add(
            birthDateFirstEditDelay - const Duration(seconds: 1),
          ),
        ),
        const Duration(seconds: 1),
      );
    });

    test('exactly two hours after creation it opens', () {
      expect(
        waitFor(
          createdAt: created,
          changedAtUtc: null,
          now: created.add(birthDateFirstEditDelay),
        ),
        Duration.zero,
      );
    });

    test('once changed, the four-hour wait replaces the creation gate', () {
      // An ancient profile whose date was changed a minute ago is shut, which
      // is the whole point: the gate is about the last edit, not the birth of
      // the profile.
      final ancient = DateTime.utc(2020, 1, 1);
      final changedAt = created.add(const Duration(minutes: 1));
      expect(
        waitFor(createdAt: ancient, changedAtUtc: changedAt, now: changedAt),
        birthDateEditCooldown,
      );
      expect(
        waitFor(
          createdAt: ancient,
          changedAtUtc: changedAt,
          now: changedAt.add(const Duration(hours: 1, minutes: 30)),
        ),
        const Duration(hours: 2, minutes: 30),
      );
    });

    test('exactly four hours after a change it opens again', () {
      expect(
        waitFor(
          createdAt: created,
          changedAtUtc: created,
          now: created.add(birthDateEditCooldown),
        ),
        Duration.zero,
      );
      expect(
        waitFor(
          createdAt: created,
          changedAtUtc: created,
          now: created.add(birthDateEditCooldown - const Duration(seconds: 1)),
        ),
        const Duration(seconds: 1),
      );
    });

    test('a second change restarts the whole four hours', () {
      final first = created;
      final second = created.add(const Duration(hours: 3, minutes: 59));
      // A minute before the second change the reader was nearly free.
      expect(
        waitFor(
          createdAt: created,
          changedAtUtc: first,
          now: second.subtract(const Duration(minutes: 1)),
        ),
        const Duration(minutes: 2),
      );
      // Changing it again puts the full window back.
      expect(
        waitFor(createdAt: created, changedAtUtc: second, now: second),
        birthDateEditCooldown,
      );
    });

    test('the three waits do not borrow from each other', () {
      final now = created.add(const Duration(hours: 1));
      // Only the date was changed, an hour ago.
      expect(
        waitFor(createdAt: created, changedAtUtc: created, now: now),
        const Duration(hours: 3),
      );
      expect(
        remainingEditCooldown(
          changedAtUtc: null,
          window: birthTimeEditCooldown,
          nowUtc: now,
        ),
        Duration.zero,
      );
      expect(
        remainingEditCooldown(
          changedAtUtc: null,
          window: birthCountryEditCooldown,
          nowUtc: now,
        ),
        Duration.zero,
      );
    });
  });

  group('two dates name the same day, or they do not', () {
    test('the clock and the zone on them are not part of the answer', () {
      // What the picker hands back is a local midnight; what came out of
      // storage may be the same day read in another zone. Comparing the
      // instants would call that an edit and start four hours of waiting for
      // a date nobody touched.
      expect(
        isSameBirthDate(DateTime(1998, 6, 21), DateTime(1998, 6, 21, 23, 59)),
        isTrue,
      );
      expect(
        isSameBirthDate(DateTime(1998, 6, 21), DateTime.utc(1998, 6, 21, 17)),
        isTrue,
      );
    });

    test('one day apart is a different birthday', () {
      expect(
        isSameBirthDate(DateTime(1998, 6, 21), DateTime(1998, 6, 22)),
        isFalse,
      );
      expect(
        isSameBirthDate(DateTime(1998, 6, 21), DateTime(1999, 6, 21)),
        isFalse,
      );
      expect(
        isSameBirthDate(DateTime(1998, 6, 21), DateTime(1998, 7, 21)),
        isFalse,
      );
    });
  });

  group('loading a profile off the device', () {
    setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

    /// What the store actually holds: a JSON string under one key.
    Future<AppProfile?> loadWith(Object? createdAt) async {
      final record = {
        'userName': 'Alex',
        'birthDate': '1998-06-21',
        'birthTime': '14:30',
        'birthCountryCode': 'VN',
        'useCurrentLocation': false,
        'safetyAcknowledged': true,
        'createdAt': createdAt,
      };
      SharedPreferences.setMockInitialValues({
        'app_profile_v1': jsonEncode(record),
      });
      return const SharedPreferencesProfileRepository().load();
    }

    test(
      'a damaged createdAt does not cost the reader their profile',
      () async {
        // The repository degrades a record it cannot read to "no profile", and
        // the app sends a reader with no profile back through onboarding. A
        // throw in `fromJson` therefore does not merely lose a timestamp — it
        // loses the birth date, the hour and the country the reader entered.
        for (final broken in <Object>[
          7,
          true,
          <String>[],
          <String, String>{},
          'whenever',
        ]) {
          final profile = await loadWith(broken);
          expect(
            profile,
            isNotNull,
            reason: 'a createdAt of $broken sent the reader back to onboarding',
          );
          expect(profile!.birthDate, DateTime(1998, 6, 21));
          expect(profile.birthCountryCode, 'VN');
          expect(profile.createdAt, isNull);
        }
      },
    );

    test('a profile with a usable createdAt still carries it', () async {
      final profile = await loadWith('2026-09-18T08:00:00.000Z');
      expect(profile!.createdAt, DateTime.utc(2026, 9, 18, 8));
    });
  });

  group('the wait, spelled out', () {
    final en = stringsFor(AppLocale.english);

    test('under an hour reads in minutes alone', () {
      expect(formatEditWait(en, 'en', const Duration(minutes: 24)), '24 min');
    });

    test('a part-minute rounds up, so a locked field never says 0 min', () {
      expect(formatEditWait(en, 'en', const Duration(seconds: 12)), '1 min');
      expect(
        formatEditWait(en, 'en', const Duration(minutes: 3, seconds: 1)),
        '4 min',
      );
    });

    test('an hour or more reads in both', () {
      expect(formatEditWait(en, 'en', birthTimeEditCooldown), '2 hr 0 min');
      expect(
        formatEditWait(en, 'en', const Duration(hours: 1, minutes: 24)),
        '1 hr 24 min',
      );
      // 59:30 is an hour once rounded up, and must not read as "0 hr 60 min".
      expect(
        formatEditWait(en, 'en', const Duration(minutes: 59, seconds: 30)),
        '1 hr 0 min',
      );
    });

    test('it is spelled in the reader\'s own language', () {
      final vi = stringsFor(AppLocale.vietnamese);
      expect(
        formatEditWait(vi, 'vi', const Duration(hours: 1, minutes: 24)),
        '1 giờ 24 phút',
      );
      final ja = stringsFor(AppLocale.japanese);
      expect(formatEditWait(ja, 'ja', const Duration(minutes: 24)), '24分');
    });
  });
}
