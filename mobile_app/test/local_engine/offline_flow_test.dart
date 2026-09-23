import 'package:decision_compass/app.dart';
import 'package:decision_compass/data/current_context_provider.dart';
import 'package:decision_compass/data/fixed_daily_brief_provider.dart';
import 'package:decision_compass/data/in_memory_history_repository.dart';
import 'package:decision_compass/data/in_memory_profile_repository.dart';
import 'package:decision_compass/local_engine/local_reading_repository.dart';
import 'package:decision_compass/reading_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../reading_test_rig.dart';

/// End-to-end through the real UI with the real on-device engine wired in —
/// no fake repository, no fixture response, no server.
///
/// The only doubles here are the ones a test cannot avoid: the clock (so the
/// reveal instant is fixed) and the context provider (so no platform channel
/// is touched). The reading itself is calculated by `lib/local_engine/`.
void main() {
  /// The ritual floor is 4.2–5.2s, so this clears any draw of the jitter.
  Future<void> pumpPastRitual(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 5400));
    await tester.pumpAndSettle();
  }

  Widget buildApp({
    String deviceTimezone = 'Asia/Ho_Chi_Minh',
    bool initialSafetyAcknowledged = true,
  }) {
    return DecisionCompassApp(
      initialSafetyAcknowledged: initialSafetyAcknowledged,
      dependencies: ReadingDependencies(
        // `runInline` keeps the calculation on the test isolate so the widget
        // tester's fake clock still governs the flow. The isolate dispatcher
        // itself is covered by `offline_guarantees_test.dart`.
        repository: const LocalReadingRepository(runner: runInline),
        contextProvider: FixedCurrentContextProvider(
          deviceTimezone: deviceTimezone,
        ),
        historyRepository: InMemoryHistoryRepository(),
        profileRepository: InMemoryProfileRepository(),
        dailyBriefProvider: FixedDailyBriefProvider(),
        nowUtc: () => DateTime.utc(2026, 9, 18, 8, 30),
      ),
    );
  }

  testWidgets('a NOW reading reaches the result page with no server', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await completeOnboarding(tester);
    await revealReading(tester);
    await pumpPastRitual(tester);

    expect(find.byKey(const Key('reading_error')), findsNothing);
    expect(find.byKey(const Key('result_ready')), findsOneWidget);
    expect(find.text('YES'), findsWidgets);
    // NOW never offers a window, and the daily brief comes from the engine.
    expect(find.byKey(const Key('result_lucky_windows')), findsNothing);
    expect(find.byKey(const Key('result_daily_brief')), findsOneWidget);
  });

  testWidgets('a future period reaches the result page with real windows', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await completeOnboarding(tester);
    await revealReading(tester, modeLabel: 'FORWARD', periodName: 'evening');
    await pumpPastRitual(tester);

    expect(find.byKey(const Key('reading_error')), findsNothing);
    expect(find.byKey(const Key('result_ready')), findsOneWidget);
    expect(find.text('FORWARD'), findsWidgets);
    // A future period really does carry engine-calculated windows.
    expect(find.byKey(const Key('result_lucky_windows')), findsOneWidget);
  });

  testWidgets('declining location still produces a reading', (tester) async {
    await tester.pumpWidget(buildApp());
    await completeOnboarding(tester, allowLocation: false);
    await revealReading(tester);
    await pumpPastRitual(tester);

    expect(find.byKey(const Key('reading_error')), findsNothing);
    expect(find.byKey(const Key('result_ready')), findsOneWidget);
  });

  testWidgets('a device timezone the engine does not know fails safely', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(deviceTimezone: 'Not/AZone'));
    await completeOnboarding(tester);
    await revealReading(tester);
    await pumpPastRitual(tester);

    // Surfaced as an app-owned message, with nothing from the input in it.
    final errorView = find.byKey(const Key('reading_error'));
    expect(errorView, findsOneWidget);
    expect(find.textContaining('Not/AZone'), findsNothing);
  });
}
