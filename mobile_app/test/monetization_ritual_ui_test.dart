import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
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
  }) async {
    useScreen(tester, size: const Size(393, 873));
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(
      localizedApp(
        theme: buildCompassTheme(),
        locale: AppLocale.vietnamese,
        home: RitualPage(
          mode: DecisionMode.yesNo,
          period: TimePeriod.now,
          category: engine.ReadingCategory.general,
          profile: profile,
          dependencies: rig.dependencies,
          isCooldown: isCooldown,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('RitualPage shows AdBannerSlot and Option 1 cooldown UI when isCooldown is true', (
    tester,
  ) async {
    await pumpRitualOption1(tester, isCooldown: true);

    // 1. Fixed bottom Ad banner is present
    expect(find.byType(AdBannerSlot), findsOneWidget);

    // 2. Cooldown elements are present
    expect(find.text('LẮNG ĐỌNG'), findsOneWidget);
    // Time is removed from the analysis / ritual screen
    expect(find.text('02:15:34'), findsNothing);
    expect(find.byKey(const Key('ritual_watch_ad_button')), findsOneWidget);
    expect(find.text('Xem quảng cáo'), findsOneWidget);
    expect(find.text('Năng lượng cần hồi phục'), findsOneWidget);

    // Verify title 'Năng lượng cần hồi phục' is positioned ABOVE watch ad button
    final titleRect = tester.getRect(find.text('Năng lượng cần hồi phục'));
    final adBtnRect = tester.getRect(
      find.byKey(const Key('ritual_watch_ad_button')),
    );
    expect(titleRect.bottom, lessThan(adBtnRect.top));

    // 3. Tapping the watch ad button opens the Unlock Bottom Sheet
    await tester.tap(find.byKey(const Key('ritual_watch_ad_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Năng Lượng Đang Lắng Đọng'), findsOneWidget);
    expect(find.text('PHÂN TÍCH NGAY BÂY GIỜ'), findsOneWidget);

    // 4. Tapping the watch ad option unlocks the reading
    await tester.tap(find.text('PHÂN TÍCH NGAY BÂY GIỜ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Bottom sheet is dismissed and cooldown is lifted
    expect(find.text('PHÂN TÍCH'), findsOneWidget);
    expect(find.byKey(const Key('ritual_watch_ad_button')), findsNothing);
  });

  testWidgets('Tapping category badge toggles cooldown state preview', (
    tester,
  ) async {
    await pumpRitualOption1(tester, isCooldown: true);

    expect(find.byKey(const Key('ritual_watch_ad_button')), findsOneWidget);

    // Tap badge to toggle to Ready state
    await tester.tap(find.byKey(const Key('ritual_category_badge')));
    await tester.pump();

    expect(find.byKey(const Key('ritual_watch_ad_button')), findsNothing);
    expect(find.text('PHÂN TÍCH'), findsOneWidget);

    // Tap badge again to toggle back to Cooldown state
    await tester.tap(find.byKey(const Key('ritual_category_badge')));
    await tester.pump();

    expect(find.byKey(const Key('ritual_watch_ad_button')), findsOneWidget);
    expect(find.text('LẮNG ĐỌNG'), findsOneWidget);
  });
}
