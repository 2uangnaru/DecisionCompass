import 'package:decision_compass/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  testWidgets(
    "the app applies the dark celestial theme, not Flutter's default light "
    'theme',
    (tester) async {
      final rig = ReadingTestRig();
      await tester.pumpWidget(rig.app);
      await tester.pump();

      final context = tester.element(find.byType(MaterialApp));
      final theme = Theme.of(context);

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, CompassColors.deep);
      // Regression test: `MaterialApp` once shipped without its `theme:`
      // argument, so every screen fell back to Flutter's default (near-black
      // on a light scheme) text colors — nearly invisible against this app's
      // dark backgrounds everywhere a widget didn't hardcode its own color.
      expect(theme.textTheme.headlineLarge?.color, CompassColors.text);
      expect(theme.textTheme.headlineMedium?.color, CompassColors.text);
      expect(theme.textTheme.displayLarge?.color, CompassColors.text);
      expect(theme.textTheme.bodyLarge?.color, CompassColors.text);
      expect(theme.textTheme.bodyMedium?.color, CompassColors.secondary);
    },
  );
}
