import 'dart:async';

import 'package:decision_compass/analytics/analytics_event.dart';
import 'package:decision_compass/analytics/analytics_service.dart';
import 'package:decision_compass/app.dart';
import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/reading_api_exception.dart';
import 'package:decision_compass/pages/onboarding_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/theme.dart';
import 'package:decision_compass/widgets/analytics_consent_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../reading_test_rig.dart';

class RecordingAnalytics extends ChangeNotifier implements AnalyticsService {
  final events = <AnalyticsEvent>[];
  @override
  bool enabled = true;
  @override
  bool get busy => false;
  @override
  int consentVersion = 0;
  @override
  Future<void> ensureLoaded() async {}
  @override
  Future<bool> setEnabled(bool value) async {
    enabled = value;
    consentVersion++;
    notifyListeners();
    return true;
  }

  @override
  bool record(AnalyticsEvent event) {
    if (!enabled) return false;
    events.add(event);
    return true;
  }
}

void main() {
  setUpAll(loadBundledFonts);
  late RecordingAnalytics analytics;
  late RecordingAnalytics sink;
  setUp(() {
    analytics = RecordingAnalytics();
    sink = analytics;
  });

  Future<void> finishRitual(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 5400));
    await tester.pumpAndSettle();
    await tester.pump();
  }

  testWidgets('onboarding and reading events once despite taps/rebuilds', (
    tester,
  ) async {
    final rig = ReadingTestRig(
      analytics: analytics,
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await tester.pump();
    await completeOnboarding(tester);
    await tester.pump();
    expect(sink.events.map((e) => e.name), [
      'onboarding_started',
      'onboarding_completed',
    ]);
    await revealReading(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('loading_tap_surface')));
      await tester.pump(const Duration(milliseconds: 80));
    }
    await finishRitual(tester);
    await tester.pump();
    expect(sink.events.where((e) => e.name == 'reading_started'), hasLength(1));
    expect(
      sink.events.where((e) => e.name == 'reading_completed'),
      hasLength(1),
    );
    await tester.ensureVisible(find.byKey(const Key('result_history_action')));
    await tester.tap(find.byKey(const Key('result_history_action')));
    await tester.pumpAndSettle();
    await tester.pump();
    expect(sink.events.where((e) => e.name == 'history_opened'), hasLength(1));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: compassLocalizationsDelegates,
        supportedLocales: compassSupportedLocales,
        theme: buildCompassTheme(AppLocale.english),
        home: ResultPage(
          reading: fixtureResponse('ready_yes_no_now.json'),
          dependencies: rig.dependencies,
          autoSave: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      sink.events.where((e) => e.name == 'reading_completed'),
      hasLength(1),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    analytics.dispose();
  });

  testWidgets('failed onboarding is not counted as complete', (tester) async {
    final rig = ReadingTestRig(
      analytics: analytics,
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await fillOnboardingProfile(tester);
    rig.profileRepository.failSaves = true;
    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pumpAndSettle();
    await tester.pump();
    expect(sink.events.map((e) => e.name), ['onboarding_started']);
    expect(find.byType(OnboardingPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    analytics.dispose();
  });

  testWidgets(
    'each failed retry is separate, rapid retry taps not duplicated',
    (tester) async {
      final rig = ReadingTestRig(
        analytics: analytics,
        error: const ReadingApiException(
          kind: ReadingApiFailureKind.network,
          safeCode: 'fixed_network_error',
          safeMessage: 'Private text never sent',
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await finishRitual(tester);
      expect(
        sink.events.where((e) => e.name == 'reading_failed'),
        hasLength(1),
      );
      final retry = find.byKey(const Key('retry_reading'));
      await tester.tap(retry);
      await tester.tap(retry);
      await finishRitual(tester);
      expect(
        sink.events.where((e) => e.name == 'reading_started'),
        hasLength(2),
      );
      expect(
        sink.events.where((e) => e.name == 'reading_failed'),
        hasLength(2),
      );
      expect(sink.events.where((e) => e.name == 'reading_completed'), isEmpty);
      expect(
        sink.events.map((e) => e.parameters.toString()).join(),
        isNot(contains('Private text')),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      analytics.dispose();
    },
  );

  testWidgets('share requested deduplicates while platform sheet pending', (
    tester,
  ) async {
    final held = Completer<Object?>();
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) => held.future,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final rig = ReadingTestRig(analytics: analytics);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: compassLocalizationsDelegates,
        supportedLocales: compassSupportedLocales,
        theme: buildCompassTheme(AppLocale.english),
        home: ResultPage(
          reading: fixtureResponse('ready_yes_no_now.json'),
          dependencies: rig.dependencies,
          autoSave: false,
        ),
      ),
    );
    await tester.pump();
    final share = find.byKey(const Key('result_share'));
    await tester.tap(share);
    await tester.tap(share);
    await tester.pump();
    await tester.pump();
    expect(sink.events.map((e) => e.name), ['share_requested']);
    expect(sink.events.single.parameters, {'source': 'history'});
    held.complete('');
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    analytics.dispose();
  });

  for (final locale in AppLocale.values) {
    testWidgets('consent copy wraps at 360dp / 1.5x in ${locale.tag}', (
      tester,
    ) async {
      useScreen(tester, size: const Size(360, 640));
      await tester.pumpWidget(
        MaterialApp(
          locale: locale.locale,
          localizationsDelegates: compassLocalizationsDelegates,
          supportedLocales: compassSupportedLocales,
          theme: buildCompassTheme(locale),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AnalyticsConsentTile(analytics: analytics),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(stringsFor(locale).analyticsConsentTitle),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      analytics.dispose();
    });
  }
}
