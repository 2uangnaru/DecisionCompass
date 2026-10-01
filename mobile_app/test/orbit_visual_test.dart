import 'package:decision_compass/widgets/celestial_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double orbitProgress(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find
        .descendant(
          of: find.byType(OrbitVisual),
          matching: find.byType(CustomPaint),
        )
        .first,
  );
  return (paint.painter as dynamic).progress as double;
}

void main() {
  testWidgets('orbit phase continues through the old 14-second loop seam', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OrbitVisual(labels: ['BaZi', 'ZiWei'])),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 13990));
    final before = orbitProgress(tester);

    await tester.pump(const Duration(milliseconds: 20));
    final after = orbitProgress(tester);

    expect(before, closeTo(13990 / 14000, 0.001));
    expect(after, greaterThan(1));
    expect(after - before, closeTo(20 / 14000, 0.0001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion keeps the orbit still', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: OrbitVisual(labels: ['BaZi'])),
        ),
      ),
    );
    expect(orbitProgress(tester), 0.1);
    await tester.pump(const Duration(seconds: 15));
    expect(orbitProgress(tester), 0.1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('orbit painter inherits display font family', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Montserrat'),
        home: const Scaffold(body: OrbitVisual(labels: ['BaZi'])),
      ),
    );
    final paint = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byType(OrbitVisual),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    final painter = paint.painter as dynamic;
    expect(painter.textStyle?.fontFamily, 'Montserrat');
  });
}
