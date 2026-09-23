import 'package:flutter/material.dart';

import 'app.dart';
import 'data/current_context_provider.dart';
import 'data/engine_daily_brief_provider.dart';
import 'data/shared_preferences_history_repository.dart';
import 'data/shared_preferences_profile_repository.dart';
import 'local_engine/local_reading_repository.dart';
import 'reading_dependencies.dart';

/// Decision Compass calculates entirely on the device.
///
/// There is no API base URL, no HTTP client and no server to reach: the
/// reading engine is bundled in the app (`lib/local_engine/`) and runs on a
/// background isolate. A build needs no `--dart-define`, and an installed APK
/// produces readings in airplane mode.
///
/// The app may still use the network later for ads, analytics or store
/// services. The symbolic calculation never does.
void main() {
  // Shared with `EngineDailyBriefProvider` below, so Home's ambient preview
  // and a real reveal both go through the one on-device engine and context
  // resolver rather than standing up a second instance of either.
  const repository = LocalReadingRepository();
  const contextProvider = DeviceCurrentContextProvider();
  runApp(
    const DecisionCompassApp(
      dependencies: ReadingDependencies(
        repository: repository,
        contextProvider: contextProvider,
        historyRepository: SharedPreferencesHistoryRepository(),
        profileRepository: SharedPreferencesProfileRepository(),
        dailyBriefProvider: EngineDailyBriefProvider(
          repository: repository,
          contextProvider: contextProvider,
        ),
      ),
    ),
  );
}
