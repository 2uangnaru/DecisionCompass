import 'dart:async';

import 'package:decision_compass/services/ad_policy.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_test_fakes.dart';

class _ThrowingFormBackend extends FakeAdsBackend {
  bool failForm = true;
  @override
  Future<ConsentFormOutcome> showConsentFormIfRequired() async {
    formCount++;
    if (failForm) throw StateError('transient_form_failure');
    return formOutcome;
  }
}

class _Rig {
  _Rig({FakeAdsBackend? backend}) : backend = backend ?? FakeAdsBackend();
  final FakeAdsBackend backend;
  DateTime clock = DateTime.utc(2026, 10, 26, 12);
  late final ads = ManagedAdService(
    backend: backend,
    policy: AdPolicy(store: MemoryAdPolicyStore()),
    nowUtc: () => clock,
    nowLocal: () => clock,
  );
  Future<void> advance(WidgetTester tester, Duration duration) async {
    clock = clock.add(duration);
    await tester.pump(duration);
  }

  Future<void> resume(WidgetTester tester) async {
    ads.setForeground(false);
    ads.setForeground(true);
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    ads.dispose();
    await tester.pump();
  }
}

void main() {
  test(
    'production form bridge maps FormError to failed, not completed',
    () async {
      final result = await GoogleAdsBackend.presentForm((dismissed) async {
        dismissed(FormError(errorCode: 2, message: 'untrusted SDK error'));
      });
      expect(result, ConsentFormOutcome.failed);
    },
  );

  test(
    'production form bridge maps null error to completed, not permission',
    () async {
      final result = await GoogleAdsBackend.presentForm((dismissed) async {
        dismissed(null);
      });
      expect(result, ConsentFormOutcome.completed);
    },
  );

  test(
    'production form bridge does not invent success without a callback',
    () async {
      final result = await GoogleAdsBackend.presentForm((_) async {});
      expect(result, ConsentFormOutcome.failed);
    },
  );

  testWidgets(
    'production form bridge waits for real completion, not elapsed time',
    (tester) async {
      final nativeClosed = Completer<void>();
      late OnConsentFormDismissedListener dismissed;
      var completed = false;
      final operation =
          GoogleAdsBackend.presentForm((callback) {
            dismissed = callback;
            return nativeClosed.future;
          }).then((outcome) {
            completed = true;
            return outcome;
          });
      await tester.pump(const Duration(hours: 1));
      expect(completed, false);
      dismissed(null);
      nativeClosed.complete();
      expect(await operation, ConsentFormOutcome.completed);
    },
  );

  testWidgets(
    'form load failure without prior permission retries on a later resume',
    (tester) async {
      final rig = _Rig();
      try {
        rig.backend
          ..consent = false
          ..formOutcome = ConsentFormOutcome.failed;
        await rig.ads.initialize();
        expect(rig.backend.formCount, 1);
        expect(rig.backend.loads, isEmpty);
        expect(rig.backend.initializeCount, 0);

        await rig.advance(tester, const Duration(seconds: 30));
        await rig.resume(tester);
        expect(rig.backend.updateCount, 1);

        rig.backend
          ..consent = true
          ..formOutcome = ConsentFormOutcome.completed;
        await rig.advance(tester, const Duration(seconds: 30));
        for (var i = 0; i < 10; i++) {
          await rig.resume(tester);
        }
        await tester.pump();
        expect(rig.backend.updateCount, 2);
        expect(rig.backend.formCount, 2);
        expect(rig.backend.initializeCount, 1);
        expect(rig.backend.loads, hasLength(2));
        expect(rig.backend.ready(AdFormat.interstitial).showCount, 0);
        expect(rig.backend.ready(AdFormat.rewarded).showCount, 0);
      } finally {
        await rig.close(tester);
      }
    },
  );

  testWidgets(
    'a failed form cannot bypass SDK permission on repeated attempts',
    (tester) async {
      final rig = _Rig();
      try {
        rig.backend
          ..consent = false
          ..formOutcome = ConsentFormOutcome.failed;
        await rig.ads.initialize();
        await rig.advance(tester, const Duration(minutes: 2));
        await rig.resume(tester);
        await tester.pump();
        expect(rig.backend.formCount, 2);
        expect(rig.backend.loads, isEmpty);
        var grants = 0;
        expect(
          await rig.ads.showRewarded(
            onEarnedReward: () async {
              grants++;
            },
          ),
          AdOutcome.skipped,
        );
        expect(grants, 0);
      } finally {
        await rig.close(tester);
      }
    },
  );

  testWidgets('form failure with prior SDK permission still permits preload', (
    tester,
  ) async {
    final rig = _Rig();
    try {
      rig.backend.formOutcome = ConsentFormOutcome.failed;
      await rig.ads.initialize();
      expect(rig.backend.canRequestCount, 1);
      expect(rig.backend.loads, hasLength(2));
      await rig.advance(tester, const Duration(minutes: 2));
      await rig.resume(tester);
      expect(rig.backend.updateCount, 1);
    } finally {
      await rig.close(tester);
    }
  });

  testWidgets(
    'a thrown form failure also recovers, not only returned FormError',
    (tester) async {
      final backend = _ThrowingFormBackend()..consent = false;
      final rig = _Rig(backend: backend);
      try {
        await rig.ads.initialize();
        expect(backend.loads, isEmpty);
        backend
          ..failForm = false
          ..consent = true;
        await rig.advance(tester, const Duration(minutes: 2));
        await rig.resume(tester);
        await tester.pump();
        expect(backend.updateCount, 2);
        expect(backend.formCount, 2);
        expect(backend.loads, hasLength(2));
      } finally {
        await rig.close(tester);
      }
    },
  );

  testWidgets(
    'privacy form failure clears cache and uses the same guarded retry',
    (tester) async {
      final rig = _Rig();
      try {
        await rig.ads.initialize();
        final cached = rig.backend.ready(AdFormat.interstitial);
        await rig.advance(tester, const Duration(minutes: 2));
        rig.backend
          ..consent = false
          ..privacyFormOutcome = ConsentFormOutcome.failed;
        await rig.ads.showPrivacyOptions();
        expect(cached.disposeCount, 1);
        expect(cached.showCount, 0);
        await rig.advance(tester, const Duration(seconds: 30));
        await rig.resume(tester);
        expect(rig.backend.updateCount, 1);
        rig.backend.consent = true;
        await rig.advance(tester, const Duration(seconds: 30));
        await rig.resume(tester);
        await tester.pump();
        expect(rig.backend.updateCount, 2);
        expect(rig.backend.requests(AdFormat.interstitial), hasLength(2));
      } finally {
        await rig.close(tester);
      }
    },
  );

  testWidgets(
    'pending form never releases lock; a late failure can subsequently recover',
    (tester) async {
      final rig = _Rig();
      try {
        final pending = rig.backend.form = Completer<ConsentFormOutcome>();
        rig.backend.consent = false;
        final initialized = rig.ads.initialize();
        await tester.pump();
        await rig.advance(tester, const Duration(minutes: 2));
        await rig.resume(tester);
        await rig.ads.showPrivacyOptions();
        expect(rig.backend.updateCount, 1);
        expect(rig.backend.privacyFormCount, 0);
        expect(rig.backend.loads, isEmpty);
        pending.complete(ConsentFormOutcome.failed);
        await initialized;
        rig.backend
          ..form = null
          ..consent = true;
        await rig.resume(tester);
        await tester.pump();
        expect(rig.backend.updateCount, 2);
        expect(rig.backend.loads, hasLength(2));
      } finally {
        await rig.close(tester);
      }
    },
  );

  testWidgets(
    'completed collection with no SDK permission is not re-prompted',
    (tester) async {
      final rig = _Rig();
      try {
        rig.backend.consent = false;
        await rig.ads.initialize();
        await rig.advance(tester, const Duration(minutes: 2));
        await rig.resume(tester);
        expect(rig.backend.updateCount, 1);
        expect(rig.backend.formCount, 1);
        expect(rig.backend.loads, isEmpty);
      } finally {
        await rig.close(tester);
      }
    },
  );
}
