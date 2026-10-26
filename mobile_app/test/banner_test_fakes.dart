import 'dart:async';

import 'package:decision_compass/services/banner_ad.dart';
import 'package:flutter/material.dart';

import 'ads_test_fakes.dart';

class FakeBannerHandle implements BannerHandle {
  FakeBannerHandle(this.size, this.callbacks, this.index);
  @override
  final BannerSize size;
  final BannerCallbacks callbacks;
  final int index;
  int loads = 0, disposals = 0;
  bool throwOnLoad = false;
  @override
  Future<void> load() async {
    loads++;
    if (throwOnLoad) throw StateError('sdk-private-payload');
  }

  @override
  Widget buildView() =>
      ColoredBox(key: Key('fake_native_banner_$index'), color: Colors.blue);
  @override
  Future<void> dispose() async => disposals++;
}

class FakeBannerBackend extends FakeAdsBackend implements BannerBackend {
  final banners = <FakeBannerHandle>[];
  Completer<BannerHandle?>? pendingCreation;
  bool throwOnCreate = false, throwOnBannerLoad = false, noSize = false;
  int bannerHeight = 50;
  @override
  Future<BannerHandle?> createBanner({
    required int width,
    required BannerCallbacks callbacks,
  }) async {
    if (throwOnCreate) throw StateError('sdk-private-payload');
    if (noSize) return null;
    final ad = FakeBannerHandle(
      BannerSize(width, bannerHeight),
      callbacks,
      banners.length,
    )..throwOnLoad = throwOnBannerLoad;
    banners.add(ad);
    return pendingCreation?.future ?? ad;
  }
}
