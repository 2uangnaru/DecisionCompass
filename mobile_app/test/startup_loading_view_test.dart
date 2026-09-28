import 'dart:async';

import 'package:decision_compass/app.dart';
import 'package:decision_compass/theme.dart';
import 'package:decision_compass/widgets/startup_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  testWidgets('the three dots orbit below the app name', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartupLoadingView()));

    expect(find.text('AstraCue'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      CompassColors.deep,
    );
    final dots = List.generate(3, (i) => find.byKey(Key('startup_dot_$i')));
    final start = dots.map(tester.getCenter).toList();
    await tester.pump(const Duration(milliseconds: 600));
    final quarterTurn = dots.map(tester.getCenter).toList();
    expect(quarterTurn[0].dx, closeTo(start[0].dx - 15, 1));
    expect(quarterTurn[0].dy, closeTo(start[0].dy + 15, 1));
    for (var i = 0; i < 3; i++) {
      expect(quarterTurn[i], isNot(start[i]));
    }
    await tester.pump(const Duration(milliseconds: 1800));
    for (var i = 0; i < 3; i++) {
      expect(tester.getCenter(dots[i]).dx, closeTo(start[i].dx, 1));
      expect(tester.getCenter(dots[i]).dy, closeTo(start[i].dy, 1));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows still orbit dots and settles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: StartupLoadingView(),
        ),
      ),
    );

    final dots = List.generate(3, (i) => find.byKey(Key('startup_dot_$i')));
    final baseline = dots.map(tester.getCenter).toList();
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      expect(tester.getCenter(dots[i]), baseline[i]);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup animation remains visible before the app opens', (
    tester,
  ) async {
    final rig = ReadingTestRig();
    var contentReadySignals = 0;
    await tester.pumpWidget(
      DecisionCompassApp(
        dependencies: rig.dependencies,
        minimumStartupDuration: const Duration(milliseconds: 1800),
        onContentReady: () => contentReadySignals++,
      ),
    );

    expect(find.byType(StartupLoadingView), findsOneWidget);
    expect(contentReadySignals, 0);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byType(StartupLoadingView), findsOneWidget);
    expect(contentReadySignals, 0);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.byType(StartupLoadingView), findsNothing);
    expect(find.text('Read the moment where you are.'), findsOneWidget);
    expect(contentReadySignals, 1);
    await tester.pump();
    expect(contentReadySignals, 1);
  });

  testWidgets('startup prepares data behind the animated screen', (
    tester,
  ) async {
    final preparation = Completer<void>();
    final rig = ReadingTestRig();
    await tester.pumpWidget(
      DecisionCompassApp(
        dependencies: rig.dependencies,
        startupPreparation: preparation.future,
      ),
    );
    await tester.pump();
    expect(find.byType(StartupLoadingView), findsOneWidget);

    preparation.complete();
    await tester.pump();
    expect(find.text('Read the moment where you are.'), findsOneWidget);
  });
}
