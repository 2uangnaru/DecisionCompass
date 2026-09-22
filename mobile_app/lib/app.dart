import 'package:flutter/material.dart';

import 'pages/onboarding_page.dart';
import 'reading_dependencies.dart';
import 'theme.dart';

class DecisionCompassApp extends StatefulWidget {
  const DecisionCompassApp({
    super.key,
    required this.dependencies,
    this.onDetached,
  });

  final ReadingDependencies dependencies;

  /// Called when the engine detaches, so whoever owns the HTTP client can
  /// close it. Null in tests, which own nothing to release.
  final VoidCallback? onDetached;

  @override
  State<DecisionCompassApp> createState() => _DecisionCompassAppState();
}

class _DecisionCompassAppState extends State<DecisionCompassApp> {
  AppLifecycleListener? _lifecycle;

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
      title: 'Decision Compass',
      debugShowCheckedModeBanner: false,
      theme: buildCompassTheme(),
      home: OnboardingPage(dependencies: widget.dependencies),
    );
  }
}
