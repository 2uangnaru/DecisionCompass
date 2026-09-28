import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_locale.dart';
import 'app_profile.dart';
import 'l10n/app_localizations.dart';
import 'pages/home_page.dart';
import 'pages/onboarding_page.dart';
import 'reading_dependencies.dart';
import 'theme.dart';
import 'widgets/startup_loading_view.dart';

/// Every localization delegate the app installs.
///
/// Exposed so a test that mounts a single page renders with exactly the same
/// localizations the app does, rather than a bare `MaterialApp` that would
/// leave `AppLocalizations` missing.
const compassLocalizationsDelegates = <LocalizationsDelegate<Object?>>[
  AppLocalizations.delegate,
  _VerifiedCountryNames(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// The seven languages the app offers, and nothing else.
final compassSupportedLocales = AppLocale.values
    .map((locale) => locale.locale)
    .toList(growable: false);

class DecisionCompassApp extends StatefulWidget {
  const DecisionCompassApp({
    super.key,
    required this.dependencies,
    this.initialSafetyAcknowledged = false,
    this.onDetached,
    this.minimumStartupDuration = Duration.zero,
    this.startupPreparation,
    this.onContentReady,
  });

  final ReadingDependencies dependencies;
  final bool initialSafetyAcknowledged;

  /// Called when the app detaches, so a caller that owns a releasable
  /// resource can close it. Null in production — the bundled offline engine
  /// holds nothing to release — and null in tests.
  final VoidCallback? onDetached;
  final Duration minimumStartupDuration;
  final Future<void>? startupPreparation;
  final VoidCallback? onContentReady;

  @override
  State<DecisionCompassApp> createState() => _DecisionCompassAppState();
}

class _DecisionCompassAppState extends State<DecisionCompassApp> {
  AppLifecycleListener? _lifecycle;
  final Completer<void> _startupAnimationShown = Completer<void>();
  bool _startupTimerStarted = false;
  bool _contentReadyNotified = false;

  /// Read once at startup, so a saved profile skips onboarding entirely —
  /// restarting the app must return to Home, not lose everything.
  late final Future<AppProfile?> _savedProfile = _loadSavedProfile();

  Future<AppProfile?> _loadSavedProfile() {
    final profile = widget.dependencies.profileRepository.load();
    if (widget.minimumStartupDuration == Duration.zero &&
        widget.startupPreparation == null) {
      return profile;
    }
    return _finishStartup(profile);
  }

  Future<AppProfile?> _finishStartup(Future<AppProfile?> profile) async {
    final savedProfile = await profile;
    final preparation = widget.startupPreparation;
    if (preparation != null) await preparation;
    if (widget.minimumStartupDuration > Duration.zero) {
      await _startupAnimationShown.future;
    }
    return savedProfile;
  }

  void _onStartupFirstFrame() {
    if (_startupTimerStarted) return;
    _startupTimerStarted = true;
    Future<void>.delayed(widget.minimumStartupDuration, () {
      if (!_startupAnimationShown.isCompleted) {
        _startupAnimationShown.complete();
      }
    });
  }

  void _notifyContentReady() {
    if (_contentReadyNotified || widget.onContentReady == null) return;
    _contentReadyNotified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onContentReady?.call();
    });
  }

  @override
  void initState() {
    super.initState();
    final onDetached = widget.onDetached;
    if (onDetached != null) {
      _lifecycle = AppLifecycleListener(onDetach: onDetached);
    }
    // Held before the first frame in `main`, but a test may hand over a
    // controller that has not read its store yet.
    widget.dependencies.localeController.ensureLoaded();
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The whole app, including the date and time pickers and the safety sheet,
    // rebuilds from this one listener when the language changes.
    return ListenableBuilder(
      listenable: widget.dependencies.localeController,
      builder: (context, _) {
        final locale = widget.dependencies.localeController.locale;
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          theme: buildCompassTheme(locale),
          locale: locale.locale,
          // The reader's choice is the only input. A device locale, country or
          // timezone never selects a language here — those decide a reading.
          localeListResolutionCallback: (_, _) => locale.locale,
          localizationsDelegates: compassLocalizationsDelegates,
          supportedLocales: compassSupportedLocales,
          home: FutureBuilder<AppProfile?>(
            future: _savedProfile,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return StartupLoadingView(
                  onFirstFrame: widget.minimumStartupDuration == Duration.zero
                      ? null
                      : _onStartupFirstFrame,
                );
              }
              _notifyContentReady();
              final profile = snapshot.data;
              return profile == null
                  ? OnboardingPage(
                      dependencies: widget.dependencies,
                      initialSafetyAcknowledged:
                          widget.initialSafetyAcknowledged,
                    )
                  : HomePage(
                      profile: profile,
                      dependencies: widget.dependencies,
                    );
            },
          ),
        );
      },
    );
  }
}

/// Country names from `country_picker`, but only for the languages it really
/// carries.
///
/// The package answers `hi` with its Nepali list, and has nothing at all for
/// Vietnamese or Thai. Rather than present Nepali as Hindi, those three fall
/// through to the package's English names — a visible gap, recorded in
/// `handoff/localization/MISSING_KEYS.md`, instead of a quiet wrong answer.
class _VerifiedCountryNames
    extends LocalizationsDelegate<CountryLocalizations> {
  const _VerifiedCountryNames();

  static const _verified = {'en', 'es', 'ja', 'zh'};

  @override
  bool isSupported(Locale locale) => _verified.contains(locale.languageCode);

  /// Synchronous on purpose. The package's own delegate answers with a plain
  /// `Future`, which makes `Localizations` resolve over a frame and shows the
  /// app an empty screen before its first real paint. There is nothing to
  /// wait for here — the country tables are compiled in.
  @override
  Future<CountryLocalizations> load(Locale locale) =>
      SynchronousFuture(CountryLocalizations(locale));

  @override
  bool shouldReload(LocalizationsDelegate<CountryLocalizations> old) => false;
}
