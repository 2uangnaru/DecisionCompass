import 'package:decision_compass/widgets/celestial_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'the preview inside the popup updates the instant AM/PM is tapped, '
    'before OK is pressed',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCompassTimePicker(
                  context,
                  initial: const TimeOfDay(hour: 1, minute: 30),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('1:30 AM'), findsOneWidget);

      await tester.tap(find.text('PM'));
      await tester.pump();

      // Still inside the popup — OK has not been tapped yet.
      expect(find.text('1:30 PM'), findsOneWidget);
      expect(find.text('1:30 AM'), findsNothing);
      expect(find.byKey(const Key('birth_time_confirm')), findsOneWidget);
    },
  );

  testWidgets(
    'toggling AM/PM combines with the already-picked hour immediately — no '
    'reopen needed to see the change take effect',
    (tester) async {
      TimeOfDay? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showCompassTimePicker(
                    context,
                    initial: const TimeOfDay(hour: 1, minute: 30),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Reported bug: pick 1:30, then switch to PM — the confirmed value
      // must already read 13:30 the instant OK is tapped.
      await tester.tap(find.text('PM'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('birth_time_confirm')));
      await tester.pumpAndSettle();

      expect(result, const TimeOfDay(hour: 13, minute: 30));
    },
  );

  testWidgets('switching back to AM combines correctly too', (tester) async {
    TimeOfDay? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showCompassTimePicker(
                  context,
                  initial: const TimeOfDay(hour: 13, minute: 30),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AM'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('birth_time_confirm')));
    await tester.pumpAndSettle();

    expect(result, const TimeOfDay(hour: 1, minute: 30));
  });

  testWidgets('cancel returns null and never reports a picked value', (
    tester,
  ) async {
    TimeOfDay? result = const TimeOfDay(hour: 9, minute: 0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showCompassTimePicker(
                  context,
                  initial: const TimeOfDay(hour: 9, minute: 0),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
