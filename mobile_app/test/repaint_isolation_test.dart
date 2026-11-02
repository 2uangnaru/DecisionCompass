import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

/// The Plus badge and gem box animate forever. Without their own repaint
/// boundary every frame re-recorded the whole Home scroll view (601 of ~700
/// render objects, 60 times a second, even with nobody touching the screen),
/// which is what made Home feel heavy after the Plus UI landed.
void main() {
  setUpAll(loadBundledFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Render objects re-painted when [node]'s nearest repaint boundary is.
  int frameCost(RenderObject node) {
    RenderObject? boundary = node;
    while (!boundary!.isRepaintBoundary) {
      boundary = boundary.parent;
    }
    var count = 0;
    void visit(RenderObject child) {
      count++;
      if (!child.isRepaintBoundary) child.visitChildren(visit);
    }

    boundary.visitChildren(visit);
    return count;
  }

  testWidgets('Home\'s looping Plus animations repaint only themselves', (
    tester,
  ) async {
    useScreen(tester, size: const Size(393, 852));
    // flutter_test_config switches animations off; a real phone runs them.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final rig = ReadingTestRig();
    await tester.pumpWidget(
      localizedApp(
        home: HomePage(
          profile: AppProfile(
            userName: 'Alex',
            birthDate: DateTime(2001, 2, 12),
            birthCountryCode: 'VN',
            zodiacSign: ZodiacSign.aquarius,
            useCurrentLocation: false,
            safetyAcknowledged: true,
          ),
          dependencies: rig.dependencies,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final looping = [
      find.byKey(const Key('home_plus_button')),
      find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_AnimatedPlusGemBox',
      ),
    ];
    var checked = 0;
    for (final finder in looping) {
      for (final element in finder.evaluate()) {
        checked++;
        expect(
          frameCost(element.renderObject!),
          lessThan(100),
          reason: '${element.widget.runtimeType} repaints far more than itself',
        );
      }
    }
    expect(checked, greaterThanOrEqualTo(2), reason: 'nothing was measured');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
