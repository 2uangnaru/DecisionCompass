import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_locale.dart';
import 'app_profile.dart';
import 'data/country_names.dart';
import 'l10n/app_localizations.dart';
import 'pages/home_page.dart';
import 'pages/onboarding_page.dart';
import 'reading_dependencies.dart';
import 'services/network_guard.dart';
import 'theme.dart';
import 'widgets/startup_loading_view.dart';

/// Every localization delegate the app installs.
///
/// Exposed so a test that mounts a single page renders with exactly the same
/// localizations the app does, rather than a bare `MaterialApp` that would
/// leave `AppLocalizations` missing.
const compassLocalizationsDelegates = <LocalizationsDelegate<Object?>>[
  AppLocalizations.delegate,
  CompassCountryNamesDelegate(),
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
    this.internetCheck,
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

  /// When set, the startup screen is held until this reports online, so the
  /// reader's day is never shown before the offline dialog; later losses of
  /// connection show the dialog over whatever is on screen. Null in tests,
  /// which have no network.
  final InternetCheck? internetCheck;

  @override
  State<DecisionCompassApp> createState() => _DecisionCompassAppState();
}

class _DecisionCompassAppState extends State<DecisionCompassApp> {
  AppLifecycleListener? _lifecycle;
  final Completer<void> _startupAnimationShown = Completer<void>();
  bool _startupTimerStarted = false;
  bool _contentReadyNotified = false;
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final NetworkGuard? _networkGuard = widget.internetCheck == null
      ? null
      : NetworkGuard(navigatorKey: _navigatorKey, check: widget.internetCheck!);

  /// Read once at startup, so a saved profile skips onboarding entirely —
  /// restarting the app must return to Home, not lose everything.
  late final Future<AppProfile?> _savedProfile = _loadSavedProfile();

  /// Started in [initState], alongside the startup animation.
  Future<bool>? _firstProbe;

  Future<AppProfile?> _loadSavedProfile() {
    final guard = _networkGuard;
    if (guard == null) return _loadProfile();
    return _loadProfile().then((profile) async {
      await guard.ensureOnline(first: _firstProbe);
      return profile;
    });
  }

  Future<AppProfile?> _loadProfile() {
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
    if (_contentReadyNotified) return;
    _contentReadyNotified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onContentReady?.call();
      _networkGuard?.start();
    });
  }

  @override
  void initState() {
    super.initState();
    _firstProbe = widget.internetCheck?.call();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        final resumed = state == AppLifecycleState.resumed;
        widget.dependencies.adService.setForeground(resumed);
        _networkGuard?.setForeground(resumed);
        if (resumed) widget.dependencies.plus?.appResumed();
      },
      onDetach: widget.onDetached,
    );
    // Held before the first frame in `main`, but a test may hand over a
    // controller that has not read its store yet.
    widget.dependencies.localeController.ensureLoaded();
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _networkGuard?.dispose();
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
          navigatorKey: _navigatorKey,
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
