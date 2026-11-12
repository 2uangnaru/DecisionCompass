import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/ritual_tut_store.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

void main() {
  setUpAll(loadBundledFonts);

  final unacknowledgedProfile = AppProfile(
    userName: 'Minh Quang',
    birthDate: DateTime(1998, 6, 21),
    birthCountryCode: 'VN',
    zodiacSign: ZodiacSign.capricorn,
    useCurrentLocation: false,
    safetyAcknowledged: false,
  );

  final acknowledgedProfile = unacknowledgedProfile.copyWith(
    safetyAcknowledged: true,
  );

  final handTut = find.byKey(const Key('ritual_reveal_hand_tut'));
  final revealOrb = find.byKey(const Key('reveal_button'));
  final safetySheet = find.byKey(const Key('responsible_use_sheet'));
  final cuePill = find.byKey(const Key('safety_scroll_cue_pill'));

  group('RitualPage first-time hand tap TUT', () {
    testWidgets('appears only on RitualPage (not HomePage), renders hand + ripples only, '
        'dismisses on Reveal tap, and persists across launches', (tester) async {
      final store = InMemoryRitualTutStore();
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        safetyAcknowledged: false,
        ritualTutStore: store,
      );

      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      // HomePage must NOT display the Ritual hand TUT or any Home tap TUT.
      expect(handTut, findsNothing);

      await tester.ensureVisible(find.byKey(const Key('find_direction')));
      await tester.tap(find.byKey(const Key('find_direction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // First visit to RitualPage shows the Celestial Gold hand + ripples only.
      expect(revealOrb, findsOneWidget);
      expect(handTut, findsOneWidget);
      expect(
        find.descendant(of: handTut, matching: find.byType(Text)),
        findsNothing,
        reason: 'Hand TUT must not display text or coach bubble',
      );

      // Anchored at lower-right rim of the Reveal orb without leaving orb bounds.
      final orbRect = tester.getRect(revealOrb);
      final handRect = tester.getRect(handTut);
      expect(handRect.right, lessThanOrEqualTo(orbRect.right + 4));
      expect(handRect.left, greaterThan(orbRect.center.dx - 8));
      expect(handRect.top, greaterThan(orbRect.center.dy - 8));

      // Tapping Reveal dismisses the hand TUT immediately & persists dismissal.
      await tester.tap(revealOrb);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(handTut, findsNothing);
      expect(store.seen, isTrue);
      expect(safetySheet, findsOneWidget);
      expect(cuePill, findsOneWidget);

      // Even if the user dismisses the safety sheet without agreeing, the
      // hand TUT stays dismissed when returning to RitualPage.
      await tester.tapAt(const Offset(400, 8));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(safetySheet, findsNothing);
      expect(handTut, findsNothing);

      // Next app launch sharing the persisted store never shows the hand TUT.
      final relaunchRig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        safetyAcknowledged: false,
        ritualTutStore: store,
      );
      await tester.pumpWidget(
        localizedApp(
          locale: AppLocale.vietnamese,
          home: RitualPage(
            mode: DecisionMode.yesNo,
            period: TimePeriod.now,
            category: engine.ReadingCategory.general,
            profile: unacknowledgedProfile,
            dependencies: relaunchRig.dependencies,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(handTut, findsNothing);
    });

    testWidgets(
      'never appears for returning users who already acknowledged safety',
      (tester) async {
        final store = InMemoryRitualTutStore(initialSeen: false);
        final rig = ReadingTestRig(ritualTutStore: store);

        await tester.pumpWidget(
          localizedApp(
            home: RitualPage(
              mode: DecisionMode.yesNo,
              period: TimePeriod.now,
              category: engine.ReadingCategory.general,
              profile: acknowledgedProfile,
              dependencies: rig.dependencies,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(handTut, findsNothing);
      },
    );

    testWidgets(
      'does not appear when Reveal is in cooldown or daily quota exhausted',
      (tester) async {
        final store = InMemoryRitualTutStore(initialSeen: false);
        final rig = ReadingTestRig(ritualTutStore: store);

        await tester.pumpWidget(
          localizedApp(
            home: RitualPage(
              mode: DecisionMode.yesNo,
              period: TimePeriod.now,
              category: engine.ReadingCategory.general,
              profile: unacknowledgedProfile,
              dependencies: rig.dependencies,
              isCooldown: true,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(handTut, findsNothing);

        await tester.pumpWidget(
          localizedApp(
            home: RitualPage(
              mode: DecisionMode.yesNo,
              period: TimePeriod.now,
              category: engine.ReadingCategory.general,
              profile: unacknowledgedProfile,
              dependencies: rig.dependencies,
              isQuotaExhausted: true,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(handTut, findsNothing);
      },
    );

    testWidgets(
      'fits compact 320dp screen at 1.5x text scale without overflow (incl. reduced motion)',
      (tester) async {
        useScreen(tester, size: const Size(320, 640), textScale: 1.5);
        for (final disableAnimations in const [false, true]) {
          final store = InMemoryRitualTutStore();
          final rig = ReadingTestRig(
            ritualTutStore: store,
            locale: AppLocale.vietnamese,
          );
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 640),
                textScaler: const TextScaler.linear(1.5),
                disableAnimations: disableAnimations,
              ),
              child: localizedApp(
                locale: AppLocale.vietnamese,
                home: RitualPage(
                  mode: DecisionMode.yesNo,
                  period: TimePeriod.now,
                  category: engine.ReadingCategory.general,
                  profile: unacknowledgedProfile,
                  dependencies: rig.dependencies,
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(
            tester.takeException(),
            isNull,
            reason:
                'compact overflow with disableAnimations=$disableAnimations',
          );
          expect(handTut, findsOneWidget);
          final handRect = tester.getRect(handTut);
          expect(handRect.left, greaterThanOrEqualTo(0));
          expect(handRect.right, lessThanOrEqualTo(320));
          expect(handRect.bottom, lessThanOrEqualTo(640));
        }
      },
    );
  });

  group('SharedPreferencesRitualTutStore', () {
    test('defaults to false and persists seen across reads', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const store = SharedPreferencesRitualTutStore();

      expect(await store.isSeen(), isFalse);
      await store.markSeen();
      expect(await store.isSeen(), isTrue);
    });
  });
}
