import 'package:decision_compass/analytics/analytics_event.dart';
import 'package:decision_compass/analytics/analytics_service.dart';
import 'package:decision_compass/analytics/reading_analytics_attempt.dart';
import 'package:decision_compass/analytics/reward_analytics_attempt.dart';
import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _Consent implements AnalyticsConsentStore {
  bool value = true;
  @override
  Future<bool> load() async => value;
  @override
  Future<void> save(bool enabled) async => value = enabled;
}

class _Sink implements AnalyticsSink {
  final events = <AnalyticsEvent>[];
  bool fail = false;
  @override
  Future<void> setEnabled(bool enabled) async {}
  @override
  Future<void> send(AnalyticsEvent event) async {
    if (fail) throw StateError('private sink error');
    events.add(event);
  }
}

void main() {
  late _Consent consent;
  late _Sink sink;
  late ProductAnalytics analytics;
  setUp(() async {
    consent = _Consent();
    sink = _Sink();
    analytics = ProductAnalytics(store: consent, sink: sink);
    await analytics.ensureLoaded();
  });
  tearDown(() => analytics.dispose());

  RewardAnalyticsAttempt reward(RewardPlacement placement) =>
      RewardAnalyticsAttempt(
        analytics: analytics,
        mode: DecisionMode.commitWithdraw,
        category: ReadingCategory.love,
        period: TimePeriod.evening,
        language: AppLocale.vietnamese,
        placement: placement,
      );
  ReadingAnalyticsAttempt reading() => ReadingAnalyticsAttempt(
    analytics: analytics,
    mode: DecisionMode.yesNo,
    category: ReadingCategory.study,
    period: TimePeriod.now,
    language: AppLocale.english,
    elapsed: Stopwatch()..start(),
  );

  for (final placement in RewardPlacement.values) {
    test(
      'exact prototype reward payload and once-only grant: ${placement.name}',
      () async {
        final attempt = reward(placement);
        attempt.granted();
        attempt.granted();
        await analytics.flush();
        expect(sink.events.map((e) => e.name), [
          'reward_cta_tapped',
          'reward_granted',
        ]);
        for (final event in sink.events) {
          expect(event.parameters, {
            'decision_mode': 'commit_withdraw',
            'category': 'love',
            'time_period': 'evening',
            'ui_language': 'vi',
            'placement': placement.name,
            'grant_source': 'prototype',
          });
          expect(
            () => event.parameters['birthDate'] = 'private',
            throwsUnsupportedError,
          );
        }
      },
    );
  }

  test('a reward CTA without a successful grant has no grant event', () async {
    reward(RewardPlacement.reading);
    await analytics.flush();
    expect(sink.events.map((e) => e.name), ['reward_cta_tapped']);
  });
  test(
    'no delayed reward after a no-consent start or withdrawal/re-enable',
    () async {
      await analytics.setEnabled(false);
      final withoutConsent = reward(RewardPlacement.reading);
      await analytics.setEnabled(true);
      withoutConsent.granted();
      await analytics.flush();
      expect(sink.events, isEmpty);
      final pending = reward(RewardPlacement.reading);
      await analytics.flush();
      await analytics.setEnabled(false);
      await analytics.setEnabled(true);
      pending.granted();
      await analytics.flush();
      expect(sink.events.map((e) => e.name), ['reward_cta_tapped']);
    },
  );

  for (final source in ReadingEntitlementSource.values) {
    test(
      'actual ${source.name} source is once-only and separate from completion',
      () async {
        final attempt = reading();
        attempt.entitlementUsed(source);
        attempt.entitlementUsed(source);
        attempt.completed();
        attempt.completed();
        await analytics.flush();
        expect(sink.events.map((e) => e.name), [
          'reading_started',
          'reading_entitlement_used',
          'reading_completed',
        ]);
        expect(sink.events[1].parameters, {
          'decision_mode': 'yes_no',
          'category': 'study',
          'time_period': 'now',
          'ui_language': 'en',
          'entitlement_source': source.name,
        });
      },
    );
  }
  test(
    'withdrawal does not resurrect consumption from a pending reading',
    () async {
      final attempt = reading();
      await analytics.flush();
      await analytics.setEnabled(false);
      await analytics.setEnabled(true);
      attempt.entitlementUsed(ReadingEntitlementSource.free);
      attempt.completed();
      await analytics.flush();
      expect(sink.events.map((e) => e.name), ['reading_started']);
    },
  );
  test(
    'fixed lock/option payloads and opt-out applies to every new event',
    () async {
      final events = [
        AnalyticsEvent.readingLocked(
          mode: DecisionMode.yesNo,
          category: ReadingCategory.general,
          period: TimePeriod.now,
          language: AppLocale.english,
          reason: ReadingLockReason.exhausted,
          stage: ReadingLockStage.loading,
        ),
        AnalyticsEvent.optionLocked(
          mode: DecisionMode.stayGo,
          category: ReadingCategory.friends,
          period: TimePeriod.afternoon,
          language: AppLocale.thai,
          placement: RewardPlacement.mode,
        ),
      ];
      expect(events[0].parameters, {
        'decision_mode': 'yes_no',
        'category': 'general',
        'time_period': 'now',
        'ui_language': 'en',
        'lock_reason': 'exhausted',
        'lock_stage': 'loading',
      });
      expect(events[1].parameters, {
        'decision_mode': 'stay_go',
        'category': 'friends',
        'time_period': 'afternoon',
        'ui_language': 'th',
        'placement': 'mode',
      });
      await analytics.setEnabled(false);
      for (final event in events) {
        expect(analytics.record(event), isFalse);
      }
      final attempt = reward(RewardPlacement.category);
      attempt.granted();
      final attemptReading = reading();
      attemptReading.entitlementUsed(ReadingEntitlementSource.bonus);
      attemptReading.completed();
      await analytics.flush();
      expect(sink.events, isEmpty);
    },
  );
  test('sink failure is contained and does not make tracking throw', () async {
    sink.fail = true;
    final attempt = reward(RewardPlacement.reading);
    attempt.granted();
    final attemptReading = reading();
    attemptReading.entitlementUsed(ReadingEntitlementSource.free);
    attemptReading.completed();
    await analytics.flush();
    expect(sink.events, isEmpty);
  });
}
