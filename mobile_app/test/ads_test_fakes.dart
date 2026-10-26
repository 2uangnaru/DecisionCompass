import 'dart:async';

import 'package:decision_compass/services/ad_policy.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:flutter/foundation.dart';

class MemoryAdPolicyStore implements AdPolicyStore {
  String? day;
  int? dismissed;
  bool fail = false;
  @override
  Future<({String? viewedDay, int? dismissedMs})> load() async {
    if (fail) throw StateError('disk');
    return (viewedDay: day, dismissedMs: dismissed);
  }

  @override
  Future<void> save(String? viewedDay, int? dismissedMs) async {
    if (fail) throw StateError('disk');
    day = viewedDay;
    dismissed = dismissedMs;
  }
}

class FakeFullscreenAd implements FullscreenAd {
  /// [native] lets two wrappers stand for one native ad, the way the Google
  /// adapter delivers a duplicate load callback.
  FakeFullscreenAd({Object? native}) : _native = native;
  final Object? _native;
  @override
  Object get identity => _native ?? this;
  int showCount = 0, disposeCount = 0;
  bool throwsOnShow = false;
  VoidCallback close = () {},
      fail = () {},
      reward = () {},
      impression = () {},
      click = () {};
  void Function(double, String, String) paid = (_, _, _) {};
  @override
  Future<void> show({
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
    required VoidCallback onImpression,
    required VoidCallback onClick,
    required void Function(double, String, String) onPaid,
    required VoidCallback onReward,
  }) async {
    showCount++;
    close = onDismissed;
    fail = onFailed;
    reward = onReward;
    impression = onImpression;
    click = onClick;
    paid = onPaid;
    if (throwsOnShow) throw StateError('sdk');
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

class FakeAdLoad {
  FakeAdLoad(this.format, this.loaded, this.failed);
  final AdFormat format;
  final void Function(FullscreenAd) loaded;
  final VoidCallback failed;
}

/// Each UMP step answers at once unless a test installs a completer, which
/// then stands for a native call that has not answered yet.
class FakeAdsBackend implements AdsBackend {
  /// What `canRequestAds` reports.
  bool consent = true;
  bool updateSucceeds = true, privacyRequired = false, sdkFails = false;
  Completer<bool>? update;
  Completer<void>? form, privacyForm;
  int updateCount = 0, formCount = 0, privacyFormCount = 0;
  int canRequestCount = 0, initializeCount = 0;
  final loads = <FakeAdLoad>[];

  @override
  Future<bool> updateConsentInfo() {
    updateCount++;
    return update?.future ?? Future.value(updateSucceeds);
  }

  @override
  Future<void> showConsentFormIfRequired() {
    formCount++;
    return form?.future ?? Future.value();
  }

  @override
  Future<void> showPrivacyOptionsForm() {
    privacyFormCount++;
    return privacyForm?.future ?? Future.value();
  }

  @override
  Future<bool> canRequestAds() async {
    canRequestCount++;
    return consent;
  }

  @override
  Future<bool> privacyOptionsRequired() async => privacyRequired;

  @override
  Future<void> initializeSdk() async {
    initializeCount++;
    if (sdkFails) throw StateError('sdk');
  }

  @override
  Future<void> load(
    AdFormat format,
    void Function(FullscreenAd) loaded,
    VoidCallback failed,
  ) async {
    loads.add(FakeAdLoad(format, loaded, failed));
  }

  List<FakeAdLoad> requests(AdFormat format) =>
      loads.where((r) => r.format == format).toList();
  FakeFullscreenAd ready(AdFormat format) {
    final ad = FakeFullscreenAd();
    requests(format).last.loaded(ad);
    return ad;
  }
}
