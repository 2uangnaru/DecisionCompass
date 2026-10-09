import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/theme.dart';
import 'package:decision_compass/widgets/ad_banner_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  final profile = AppProfile(
    userName: 'Minh Quang',
    birthDate: DateTime(1998, 6, 21),
    birthCountryCode: 'VN',
    zodiacSign: ZodiacSign.capricorn,
    useCurrentLocation: false,
    safetyAcknowledged: true,
  );

  Future<void> pumpRitualOption1(
    WidgetTester tester, {
    bool isCooldown = true,
    bool? isQuotaExhausted,
    AppLocale locale = AppLocale.vietnamese,
  }) async {
    useScreen(tester, size: const Size(393, 873));
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
      quotaManager: FakeReadingQuotaController(initialCooldown: isCooldown),
    );
    await tester.pumpWidget(
      localizedApp(
        theme: buildCompassTheme(),
        locale: locale,
        home: RitualPage(
          mode: DecisionMode.yesNo,
          period: TimePeriod.now,
          category: engine.ReadingCategory.general,
          profile: profile,
          dependencies: rig.dependencies,
          isCooldown: isCooldown,
          isQuotaExhausted: isQuotaExhausted,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
    'RitualPage shows AdBannerSlot and Option 1 cooldown UI when isCooldown is true',
    (tester) async {
      await pumpRitualOption1(tester, isCooldown: true);

      // 1. Fixed bottom Ad banner is present
      expect(find.byType(AdBannerSlot), findsOneWidget);

      // 2. Cooldown elements are present (orb remains PHÂN TÍCH with amber/dark theme)
      expect(find.text('PHÂN TÍCH'), findsOneWidget);
      expect(find.byKey(const Key('ritual_watch_ad_button')), findsOneWidget);
      expect(find.text('Xem quảng cáo'), findsOneWidget);
      expect(find.text('Năng lượng cần hồi phục (03:00:00)'), findsOneWidget);
      expect(
        find.text('Bạn có thể xem video quảng cáo để tiếp tục'),
        findsOneWidget,
      );

      // Verify title 'Năng lượng cần hồi phục' is positioned ABOVE watch ad button
      final titleRect = tester.getRect(
        find.text('Năng lượng cần hồi phục (03:00:00)'),
      );
      final adBtnRect = tester.getRect(
        find.byKey(const Key('ritual_watch_ad_button')),
      );
      expect(titleRect.bottom, lessThan(adBtnRect.top));

      // 3. Tapping the locked analysis orb notifies user with floating notice and does not reveal
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump();
      expect(find.byKey(const Key('ritual_locked_notice')), findsOneWidget);
      expect(find.text('Năng lượng đang được tích tụ'), findsOneWidget);
      expect(find.text('PHÂN TÍCH'), findsOneWidget);
      expect(find.byKey(const Key('ritual_watch_ad_button')), findsOneWidget);

      // Spam tapping the locked orb holds the notice without re-queueing or flickering
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump();
      expect(find.byKey(const Key('ritual_locked_notice')), findsOneWidget);
      expect(find.text('Năng lượng đang được tích tụ'), findsOneWidget);

      // 4. Tapping the watch ad button directly unlocks the reading on the spot without opening a bottom sheet
      await tester.tap(find.byKey(const Key('ritual_watch_ad_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Cooldown is lifted directly without any modal sheet
      expect(find.text('Năng Lượng Đang Lắng Đọng'), findsNothing);
      expect(
        find.text('Đã xem quảng cáo & mở khóa 1 lượt phân tích ngay!'),
        findsOneWidget,
      );
      expect(find.text('PHÂN TÍCH'), findsOneWidget);
      expect(find.byKey(const Key('ritual_watch_ad_button')), findsNothing);
    },
  );

  testWidgets('RitualPage shows red theme when daily free quota is exhausted', (
    tester,
  ) async {
    await pumpRitualOption1(tester, isCooldown: true, isQuotaExhausted: true);

    expect(find.text('PHÂN TÍCH'), findsOneWidget);
    expect(find.byKey(const Key('ritual_watch_ad_button')), findsOneWidget);
    expect(find.text('Xem quảng cáo'), findsOneWidget);
    expect(find.text('Đã dùng hết 3 lượt hôm nay (03:00:00)'), findsOneWidget);
    expect(
      find.text('Bạn có thể xem video quảng cáo để tiếp tục'),
      findsOneWidget,
    );

    // Tapping locked orb shows quota exhausted notification at the top
    await tester.tap(find.byKey(const Key('reveal_button')));
    await tester.pump();
    expect(find.byKey(const Key('ritual_locked_notice')), findsOneWidget);
    expect(find.text('Đã dùng hết lượt miễn phí hôm nay'), findsOneWidget);

    // Tapping ad unlocks directly
    await tester.tap(find.byKey(const Key('ritual_watch_ad_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PHÂN TÍCH'), findsOneWidget);
    expect(find.byKey(const Key('ritual_watch_ad_button')), findsNothing);
  });

  testWidgets('Category badge and long press cannot change the lock state', (
    tester,
  ) async {
    await pumpRitualOption1(tester, isCooldown: true, isQuotaExhausted: false);

    // Initial: Cooldown (amber)
    expect(find.text('Năng lượng cần hồi phục (03:00:00)'), findsOneWidget);
    expect(find.byKey(const Key('ritual_watch_ad_button')), findsOneWidget);

    // Decorative category badge must not be a production preview switch.
    await tester.tap(find.byKey(const Key('ritual_category_badge')));
    await tester.pump();

    expect(find.text('Năng lượng cần hồi phục (03:00:00)'), findsOneWidget);
    expect(find.byKey(const Key('ritual_watch_ad_button')), findsOneWidget);

    await tester.longPress(find.byKey(const Key('reveal_button')));
    await tester.pump();

    expect(find.byKey(const Key('ritual_watch_ad_button')), findsOneWidget);
    expect(find.text('PHÂN TÍCH'), findsOneWidget);

    // Timer remains on its original schedule; neither action unlocks it.
    expect(find.textContaining('Năng lượng cần hồi phục'), findsOneWidget);
  });

  testWidgets('RitualPage renders localized monetization strings in English', (
    tester,
  ) async {
    await pumpRitualOption1(
      tester,
      isCooldown: true,
      locale: AppLocale.english,
    );

    expect(find.text('ANALYZE'), findsOneWidget);
    expect(find.text('Energy replenishing (03:00:00)'), findsOneWidget);
    expect(find.text('You can watch a video ad to continue'), findsOneWidget);
    expect(find.text('Watch ad'), findsOneWidget);

    // Tapping locked orb shows English notice
    await tester.tap(find.byKey(const Key('reveal_button')));
    await tester.pump();
    expect(find.byKey(const Key('ritual_locked_notice')), findsOneWidget);
    expect(find.text('Energy is gathering'), findsOneWidget);

    // Tapping ad unlocks with English reward notice
    await tester.tap(find.byKey(const Key('ritual_watch_ad_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Ad watched! 1 instant reading unlocked'),
      findsOneWidget,
    );
  });

  test('ReadingQuotaController tracks cooldown, consumes quota, and unlocks with bonus', () async {
    final quota = FakeReadingQuotaController(
      initialCooldown: false,
      initialRemaining: const Duration(hours: 2, minutes: 15, seconds: 34),
    );
    final now = DateTime(2026, 10, 9, 11, 0);

    // 1. Initially available
    expect(quota.isAvailable(now), isTrue);
    expect(quota.isCooldown(now), isFalse);

    // 2. Consume reading triggers cooldown
    await quota.consumeReading(now);
    expect(quota.isCooldown(now), isTrue);
    expect(quota.remainingTimeString(now), '02:15:34');

    // 3. Earn bonus reading unlocks immediately
    await quota.earnBonusReading();
    expect(quota.bonusReadings, 1);
    expect(quota.isAvailable(now), isTrue);
    expect(quota.isCooldown(now), isFalse);

    // 4. Consuming bonus reading leaves user in cooldown if timer not expired
    await quota.consumeReading(now);
    expect(quota.bonusReadings, 0);
    expect(quota.isCooldown(now), isTrue);
  });
}
