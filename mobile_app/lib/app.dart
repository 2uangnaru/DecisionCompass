import 'package:flutter/material.dart';

import 'app_profile.dart';
import 'pages/home_page.dart';
import 'pages/onboarding_page.dart';
import 'reading_dependencies.dart';
import 'theme.dart';
import 'widgets/celestial_ui.dart';

class DecisionCompassApp extends StatefulWidget {
  const DecisionCompassApp({
    super.key,
    required this.dependencies,
    this.initialSafetyAcknowledged = false,
    this.onDetached,
  });

  final ReadingDependencies dependencies;
  final bool initialSafetyAcknowledged;

  /// Called when the app detaches, so a caller that owns a releasable
  /// resource can close it. Null in production — the bundled offline engine
  /// holds nothing to release — and null in tests.
  final VoidCallback? onDetached;

  @override
  State<DecisionCompassApp> createState() => _DecisionCompassAppState();
}

class _DecisionCompassAppState extends State<DecisionCompassApp> {
  AppLifecycleListener? _lifecycle;

  /// Read once at startup, so a saved profile skips onboarding entirely —
  /// restarting the app must return to Home, not lose everything.
  late final Future<AppProfile?> _savedProfile =
      widget.dependencies.profileRepository.load();

  @override
  void initState() {
    super.initState();
    final onDetached = widget.onDetached;
    if (onDetached != null) {
      _lifecycle = AppLifecycleListener(onDetach: onDetached);
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstraCue: Cosmic Decisions',
      debugShowCheckedModeBanner: false,
      theme: buildCompassTheme(),
      home: FutureBuilder<AppProfile?>(
        future: _savedProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CelestialScaffold(
              child: Center(
                child: CircularProgressIndicator(color: CompassColors.gold),
              ),
            );
          }
          final profile = snapshot.data;
          return profile == null
              ? OnboardingPage(
                  dependencies: widget.dependencies,
                  initialSafetyAcknowledged: widget.initialSafetyAcknowledged,
                )
              : HomePage(profile: profile, dependencies: widget.dependencies);
        },
      ),
    );
  }
}
