import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// The approved Plus artwork animates continuously, which `pumpAndSettle`
/// can never outlast. Every test therefore starts with the platform's
/// reduced-motion setting, which those widgets already honour; production
/// animations are untouched. A test that needs motion still sets its own
/// `MediaQuery`, which wins over this default.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  await testMain();
}
