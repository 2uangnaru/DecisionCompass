import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/loading_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/services/ad_policy.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:decision_compass/services/banner_ad.dart';
import 'package:decision_compass/widgets/ad_banner_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ads_test_fakes.dart';
import 'banner_test_fakes.dart';
import 'reading_test_rig.dart';

void main() {
  setUpAll(loadBundledFonts);
  late FakeBannerBackend backend;
  late ManagedAdService ads;
  void slotTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      backend = FakeBannerBackend();
      ads = ManagedAdService(
        backend: backend,
        policy: AdPolicy(store: MemoryAdPolicyStore()),
      );
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        ads.dispose();
        await tester.pump();
      }
    });
  }

  Widget slot({BannerPlacement placement = BannerPlacement.home}) => Scaffold(
    body: Column(
      children: [
        const Expanded(child: Center(child: Text('App content'))),
        AdBannerSlot(ads: ads, placement: placement),
      ],
    ),
  );
  final native = find.byWidgetPredicate(
    (widget) =>
        widget.key is ValueKey<String> &&
        (widget.key as ValueKey<String>).value.startsWith(
          'fake_native_banner_',
        ),
  );

  slotTest(
    'no placeholder or native ad before permission; geometry stable at load',
    (tester) async {
      useScreen(tester);
      await tester.pumpWidget(MaterialApp(home: slot()));
      await tester.pump();
      expect(backend.banners, isEmpty);
      expect(find.textContaining('Astra Store'), findsNothing);
      expect(native, findsNothing);
      final before = tester.getRect(
        find.byKey(const Key('banner_layout_slot')),
      );
      await ads.initialize();
      await tester.pump();
      backend.banners.single.callbacks.loaded();
      await tester.pump();
      expect(native, findsOneWidget);
      expect(
        tester.getRect(find.byKey(const Key('banner_layout_slot'))),
        before,
      );
      expect(tester.getSize(native), const Size(360, 50));
    },
  );

  slotTest(
    'covered route removes native view; pop reuses without new request',
    (tester) async {
      await ads.initialize();
      await tester.pumpWidget(MaterialApp(home: slot()));
      await tester.pump();
      backend.banners.single.callbacks.loaded();
      await tester.pump();
      final context = tester.element(find.text('App content'));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Profile')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const Key('fake_native_banner_0'), skipOffstage: false),
        findsNothing,
      );
      expect(backend.banners.single.disposals, 0);
      Navigator.of(tester.element(find.text('Profile'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(native, findsOneWidget);
      expect(backend.banners, hasLength(1));
    },
  );

  slotTest(
    'modal sheet hides banner even though underlying content remains visible',
    (tester) async {
      await ads.initialize();
      await tester.pumpWidget(MaterialApp(home: slot()));
      await tester.pump();
      backend.banners.single.callbacks.loaded();
      await tester.pump();
      showModalBottomSheet<void>(
        context: tester.element(find.text('App content')),
        builder: (_) =>
            const SizedBox(height: 100, child: Text('Privacy controls')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(native, findsNothing);
      Navigator.of(tester.element(find.text('Privacy controls'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(native, findsOneWidget);
      expect(backend.banners, hasLength(1));
    },
  );

  slotTest('background and fullscreen remove AdWidget from current route', (
    tester,
  ) async {
    await ads.initialize();
    await tester.pumpWidget(MaterialApp(home: slot()));
    await tester.pump();
    backend.banners.single.callbacks.loaded();
    await tester.pump();
    ads.setForeground(false);
    await tester.pump();
    expect(native, findsNothing);
    ads.setForeground(true);
    await tester.pump();
    expect(native, findsOneWidget);
    final reward = backend.ready(AdFormat.rewarded);
    final show = ads.showRewarded(onEarnedReward: () async {});
    await tester.pump();
    expect(native, findsNothing);
    reward.close();
    await show;
    await tester.pump();
    expect(native, findsOneWidget);
    expect(backend.banners, hasLength(1));
  });

  slotTest('width changes request correct size and reject old native view', (
    tester,
  ) async {
    useScreen(tester);
    await ads.initialize();
    await tester.pumpWidget(MaterialApp(home: slot()));
    await tester.pump();
    backend.banners.single.callbacks.loaded();
    await tester.pump();
    tester.view.physicalSize = const Size(412, 915);
    await tester.pump();
    await tester.pump();
    expect(backend.banners, hasLength(2));
    expect(backend.banners.first.disposals, 1);
    expect(backend.banners.last.size.width, 412);
    expect(native, findsNothing);
    backend.banners.last.callbacks.loaded();
    await tester.pump();
    expect(tester.getSize(native), const Size(412, 50));
    expect(tester.takeException(), isNull);
  });

  slotTest('NoOp has no reserved space, native plugin or fake advertisement', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdBannerSlot(
            ads: NoOpAdService(),
            placement: BannerPlacement.home,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('banner_layout_slot')), findsNothing);
    expect(native, findsNothing);
  });

  final profile = AppProfile(
    userName: 'Alex',
    birthDate: DateTime(2001, 2, 12),
    birthCountryCode: 'VN',
    zodiacSign: ZodiacSign.aquarius,
    useCurrentLocation: false,
    safetyAcknowledged: true,
  );

  slotTest(
    'actual Home → Reveal → Loading/Result → Home: only current slot renders',
    (tester) async {
      useScreen(tester);
      await ads.initialize();
      final rig = ReadingTestRig(
        adService: ads,
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await rig.profileRepository.save(profile);
      await tester.pumpWidget(rig.app);
      await tester.pump();
      await tester.pump();
      backend.banners.single.callbacks.loaded();
      await tester.pump();
      expect(native, findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('find_direction')));
      await tester.tap(find.byKey(const Key('find_direction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(find.byType(RitualPage), findsOneWidget);
      expect(backend.banners, hasLength(2));
      backend.banners.last.callbacks.loaded();
      await tester.pump();
      expect(native, findsOneWidget);
      expect(
        find.byKey(const Key('fake_native_banner_0'), skipOffstage: false),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LoadingPage), findsOneWidget);
      expect(native, findsNothing);
      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byType(ResultPage), findsOneWidget);
      expect(native, findsNothing);
      Navigator.of(tester.element(find.byType(ResultPage)))
          .popUntil((route) => route.isFirst);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byKey(const Key('fake_native_banner_0')), findsOneWidget);
      expect(backend.banners, hasLength(2));
      expect(backend.banners.last.disposals, 1);
    },
  );

  for (final locale in AppLocale.values) {
    slotTest(
      'Reveal banner separated from CTA and safe-area at 360dp ${locale.name}',
      (tester) async {
        useScreen(tester);
        tester.view.padding = const FakeViewPadding(bottom: 24);
        tester.view.viewPadding = const FakeViewPadding(bottom: 24);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        await ads.initialize();
        final rig = ReadingTestRig(adService: ads);
        await tester.pumpWidget(
          localizedApp(
            locale: locale,
            home: RitualPage(
              mode: DecisionMode.yesNo,
              period: TimePeriod.now,
              category: engine.ReadingCategory.general,
              profile: profile,
              dependencies: rig.dependencies,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        backend.banners.single.callbacks.loaded();
        await tester.pump();
        final bannerRect = tester.getRect(native);
        final buttonRect = tester.getRect(
          find.byKey(const Key('reveal_button')),
        );
        expect(bannerRect.top, greaterThanOrEqualTo(buttonRect.bottom + 8));
        expect(bannerRect.bottom, lessThanOrEqualTo(640 - 24));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
