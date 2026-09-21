import 'package:flutter/material.dart';

import 'pages/onboarding_page.dart';
import 'theme.dart';

class DecisionCompassApp extends StatelessWidget {
  const DecisionCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Decision Compass',
      debugShowCheckedModeBanner: false,
      theme: buildCompassTheme(),
      home: const OnboardingPage(),
    );
  }
}
