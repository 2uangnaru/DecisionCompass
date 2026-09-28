import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show
        LicenseEntryWithLineBreaks,
        LicenseRegistry,
        TargetPlatform,
        defaultTargetPlatform;
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;

import 'app.dart';
import 'data/current_context_provider.dart';
import 'data/daily_energy_insight_deck.dart';
import 'data/engine_daily_brief_provider.dart';
import 'data/home_description_deck.dart';
import 'data/locale_controller.dart';
import 'data/locale_store.dart';
import 'data/shared_preferences_daily_energy_insight_store.dart';
import 'data/shared_preferences_history_repository.dart';
import 'data/shared_preferences_home_description_store.dart';
import 'data/shared_preferences_profile_repository.dart';
import 'local_engine/local_reading_repository.dart';
import 'reading_dependencies.dart';

/// AstraCue calculates entirely on the device.
///
/// There is no API base URL, no HTTP client and no server to reach: the
/// reading engine is bundled in the app (`lib/local_engine/`) and runs on a
/// background isolate. A build needs no `--dart-define`, and an installed APK
/// produces readings in airplane mode. The seven languages are compiled in
/// too — nothing is translated over the network at runtime.
///
/// The app may still use the network later for ads, analytics or store
/// services. The symbolic calculation never does.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();

  // Shared with `EngineDailyBriefProvider` below, so Home's ambient preview
  // and a real reveal both go through the one on-device engine and context
  // resolver rather than standing up a second instance of either.
  const repository = LocalReadingRepository();
  const contextProvider = DeviceCurrentContextProvider();
  // A ChangeNotifier, so Home and a Result opened from it stay in step.
  final dailyEnergyInsights = DailyEnergyInsightController(
    store: const SharedPreferencesDailyEnergyInsightStore(),
  );
  final localeController = LocaleController(
    store: const SharedPreferencesLocaleStore(),
  );
  // Load while the first Flutter frame animates. The app keeps the language-
  // neutral startup view until both tasks finish, so saved languages never
  // flash through English content.
  final startupPreparation = Future.wait<void>([
    initializeDateFormatting(),
    localeController.ensureLoaded(),
  ]);

  runApp(
    DecisionCompassApp(
      minimumStartupDuration: const Duration(milliseconds: 1800),
      startupPreparation: startupPreparation,
      onContentReady: () {
        if (defaultTargetPlatform == TargetPlatform.android) {
          unawaited(
            const MethodChannel('astracue/startup')
                .invokeMethod<void>('contentReady'),
          );
        }
      },
      dependencies: ReadingDependencies(
        repository: repository,
        contextProvider: contextProvider,
        historyRepository: const SharedPreferencesHistoryRepository(),
        profileRepository: const SharedPreferencesProfileRepository(),
        dailyBriefProvider: const EngineDailyBriefProvider(
          repository: repository,
          contextProvider: contextProvider,
        ),
        homeDescriptionDeck: const HomeDescriptionDeck(
          store: SharedPreferencesHomeDescriptionStore(),
        ),
        dailyEnergyInsights: dailyEnergyInsights,
        localeController: localeController,
      ),
    ),
  );
}

/// The SIL Open Font License for the bundled Noto families, so it appears in
/// the standard Flutter licence list rather than only sitting in the assets.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in const {
      'Noto Sans': 'assets/fonts/OFL-NotoSans.txt',
      'Noto Sans CJK': 'assets/fonts/OFL-NotoSansCJK.txt',
    }.entries) {
      yield LicenseEntryWithLineBreaks([
        entry.key,
      ], await rootBundle.loadString(entry.value));
    }
  });
}
