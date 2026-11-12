import 'package:flutter/foundation.dart';

/// Temporary iOS free edition. Android keeps its existing monetization.
/// Re-enable iOS explicitly only after store/ad configuration and native QA.
class MonetizationPolicy {
  static bool enabledFor(
    TargetPlatform platform, {
    bool iosEnabled = const bool.fromEnvironment('IOS_MONETIZATION_ENABLED'),
  }) => platform != TargetPlatform.iOS || iosEnabled;
}
