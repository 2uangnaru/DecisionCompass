import 'dart:async';

import 'package:decision_compass/analytics/analytics_event.dart';
import 'package:decision_compass/analytics/analytics_service.dart';
import 'package:decision_compass/analytics/reading_analytics_attempt.dart';
import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/locale_controller.dart';
import 'package:decision_compass/data/locale_store.dart';
import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/data/reading_api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryConsent implements AnalyticsConsentStore {
  bool value = false;
  bool fail = false;
  @override
  Future<bool> load() async => value;
  @override
  Future<void> save(bool enabled) async {
    if (fail) throw StateError('private data must not escape');
    value = enabled;
  }
}

class RecordingSink implements AnalyticsSink {
  final events = <AnalyticsEvent>[];
  final enabledValues = <bool>[];
  bool fail = false;
  Completer<void>? block;
  @override
  Future<void> setEnabled(bool enabled) async {
    enabledValues.add(enabled);
    if (fail) throw StateError('sensitive configuration');
  }

  @override
  Future<void> send(AnalyticsEvent event) async {
    if (fail) throw StateError('sensitive payload');
    events.add(event);
    await block?.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryConsent store;
  late RecordingSink sink;
  late ProductAnalytics analytics;
  setUp(() {
    store = MemoryConsent();
    sink = RecordingSink();
    analytics = ProductAnalytics(store: store, sink: sink);
  });
  tearDown(() => analytics.dispose());

  test('default off; no pre-consent queue or replay', () async {
    expect(analytics.record(AnalyticsEvent.onboardingStarted()), false);
    await analytics.ensureLoaded();
    expect(analytics.enabled, false);
    expect(analytics.record(AnalyticsEvent.onboardingStarted()), false);
    expect(await analytics.setEnabled(true), true);
    await analytics.flush();
    expect(sink.events, isEmpty);
    expect(analytics.record(AnalyticsEvent.historyOpened()), true);
    await analytics.flush();
    expect(sink.events.single.name, 'history_opened');
  });

  test(
    'consent persists and restores; malformed storage fails closed',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesAnalyticsConsentStore.key: 'true',
      });
      const prefs = SharedPreferencesAnalyticsConsentStore();
      expect(await prefs.load(), false);
      await prefs.save(true);
      expect(await prefs.load(), true);
      store.value = true;
      await analytics.ensureLoaded();
      expect(analytics.enabled, true);
      expect(sink.enabledValues, [true]);
    },
  );

  test('withdrawal drops queued and future events immediately', () async {
    await analytics.ensureLoaded();
    await analytics.setEnabled(true);
    sink.block = Completer<void>();
    analytics.record(AnalyticsEvent.historyOpened());
    await Future<void>.delayed(Duration.zero);
    analytics.record(AnalyticsEvent.shareRequested(fromHistory: true));
    final disabling = analytics.setEnabled(false);
    expect(analytics.enabled, false);
    expect(analytics.record(AnalyticsEvent.historyOpened()), false);
    sink.block!.complete();
    await disabling;
    await analytics.flush();
    expect(sink.events.map((e) => e.name), ['history_opened']);
    expect(store.value, false);
  });

  test('consent write failures stay off and do not escape', () async {
    await analytics.ensureLoaded();
    store.fail = true;
    expect(await analytics.setEnabled(true), false);
    expect(analytics.enabled, false);
    expect(analytics.record(AnalyticsEvent.historyOpened()), false);
  });

  test('sink failures are contained, including enabling', () async {
    await analytics.ensureLoaded();
    sink.fail = true;
    expect(await analytics.setEnabled(true), false);
    expect(analytics.enabled, false);
    sink.fail = false;
    await analytics.setEnabled(true);
    sink.fail = true;
    analytics.record(AnalyticsEvent.historyOpened());
    await analytics.flush();
    expect(sink.events, isEmpty);
  });

  ReadingAnalyticsAttempt attempt() => ReadingAnalyticsAttempt(
    analytics: analytics,
    mode: DecisionMode.commitWithdraw,
    category: ReadingCategory.love,
    period: TimePeriod.evening,
    language: AppLocale.vietnamese,
    elapsed: Stopwatch()..start(),
  );

  test(
    'exact reading payloads; completion deduplicates; retries distinct',
    () async {
      await analytics.ensureLoaded();
      await analytics.setEnabled(true);
      final first = attempt();
      first.failed(ReadingApiFailureKind.network);
      first.failed(ReadingApiFailureKind.server);
      final retry = attempt();
      retry.completed();
      retry.completed();
      await analytics.flush();
      expect(sink.events.map((e) => e.name), [
        'reading_started',
        'reading_failed',
        'reading_started',
        'reading_completed',
      ]);
      expect(sink.events.first.parameters, {
        'decision_mode': 'commit_withdraw',
        'category': 'love',
        'time_period': 'evening',
        'ui_language': 'vi',
      });
      expect(sink.events[1].parameters, {
        'decision_mode': 'commit_withdraw',
        'category': 'love',
        'time_period': 'evening',
        'error_kind': 'network',
      });
      expect(sink.events.last.parameters.keys.toSet(), {
        'decision_mode',
        'category',
        'time_period',
        'ui_language',
        'elapsed_ms',
      });
      expect(sink.events.last.parameters['elapsed_ms'], isA<int>());
    },
  );

  test('attempts begun without consent do not later emit completion', () async {
    await analytics.ensureLoaded();
    final first = attempt();
    await analytics.setEnabled(true);
    first.completed();
    await analytics.flush();
    expect(sink.events, isEmpty);
  });

  test('withdraw/re-enable does not resurrect a pending attempt', () async {
    await analytics.ensureLoaded();
    await analytics.setEnabled(true);
    final first = attempt();
    await analytics.flush();
    await analytics.setEnabled(false);
    await analytics.setEnabled(true);
    first.completed();
    await analytics.flush();
    expect(sink.events.map((e) => e.name), ['reading_started']);
  });

  test(
    'language tracking only after successful, actual manual changes',
    () async {
      await analytics.ensureLoaded();
      await analytics.setEnabled(true);
      final locales = InMemoryLocaleStore();
      final controller = LocaleController(
        store: locales,
        initial: AppLocale.english,
        analytics: analytics,
      );
      addTearDown(controller.dispose);
      await controller.select(AppLocale.english);
      await controller.select(AppLocale.thai);
      locales.failSaves = true;
      await expectLater(
        controller.select(AppLocale.japanese),
        throwsStateError,
      );
      await analytics.flush();
      expect(sink.events.length, 1);
      expect(sink.events.single.parameters, {
        'previous_language': 'en',
        'new_language': 'th',
      });
    },
  );

  test('all non-reading payloads are fixed and immutable', () {
    expect(AnalyticsEvent.onboardingStarted().parameters, isEmpty);
    expect(AnalyticsEvent.onboardingCompleted().parameters, isEmpty);
    expect(AnalyticsEvent.historyOpened().parameters, isEmpty);
    final share = AnalyticsEvent.shareRequested(fromHistory: false);
    expect(share.name, 'share_requested');
    expect(share.parameters, {'source': 'generated'});
    expect(
      () => share.parameters['birthDate'] = '2000-01-01',
      throwsUnsupportedError,
    );
  });
}
