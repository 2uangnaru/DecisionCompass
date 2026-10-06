import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/profile_edit_policy.dart';
import 'package:decision_compass/localized_presentation.dart';
import 'package:decision_compass/models.dart';
import 'package:flutter_test/flutter_test.dart';

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
        birthTime: profile.birthTime,
        birthCountryCode: profile.birthCountryCode,
        birthTimeChangedAtUtc: null,
        birthCountryChangedAtUtc: null,
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
        birthTime: null,
        birthCountryCode: 'VN',
        birthTimeChangedAtUtc: changed,
        birthCountryChangedAtUtc: null,
      );
      expect(unknown.birthTime, isNull);
      expect(unknown.toBirthProfile().birthTime, isNull);
    });

    test('edited() leaves the birth date and everything else alone', () {
      final profile = base();
      final next = profile.edited(
        userName: 'Bo',
        birthTime: '09:15',
        birthCountryCode: 'JP',
        birthTimeChangedAtUtc: changed,
        birthCountryChangedAtUtc: changed,
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
