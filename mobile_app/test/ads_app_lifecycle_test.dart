import 'package:decision_compass/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

class _LifecycleAds extends NoOpAdService {
  final states = <bool>[];
  int shows = 0;
  @override
  void setForeground(bool value) {
    states.add(value);
  }

  @override
  Future<void> showInterstitial({
    required VoidCallback onDismissed,
    InterstitialPlacement placement = InterstitialPlacement.afterAnalysis,
  }) async {
    shows++;
    onDismissed();
  }
}

void main() {
  testWidgets(
    'root forwards Android lifecycle to ads without automatic display',
    (tester) async {
      final ads = _LifecycleAds();
      final rig = ReadingTestRig(adService: ads);
      await tester.pumpWidget(rig.app);
      // Welcome has perpetual ambient animation; it never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(ads.states, [false, false, false, false, false, true]);
      expect(ads.shows, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
