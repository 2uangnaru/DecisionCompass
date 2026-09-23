import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// The ritual floor is 4.2–5.2s, so this clears any draw of the jitter.
Future<void> pumpPastRitual(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pumpAndSettle();
}

final loadingSurface = find.byKey(const Key('loading_tap_surface'));
final errorView = find.byKey(const Key('reading_error'));
final retryButton = find.byKey(const Key('retry_reading'));

void main() {
  group('the request the Reveal tap builds', () {
    testWidgets('carries the profile collected in onboarding', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await tester.pump();

      final profile = rig.sentRequest!.profile;
      expect(profile.birthDate, '1998-06-21');
      // The ISO code, not the display name the dropdown showed.
      expect(profile.birthCountry, 'US');
      expect(profile.birthTimezone, isNull);
      expect(rig.sentRequest!.category, engine.ReadingCategory.general);
      expect(rig.sentRequest!.diagnostics, isNull);

      await pumpPastRitual(tester);
    });

    testWidgets('sends null when the birth time is unknown', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await tester.pump();

      expect(rig.sentRequest!.profile.birthTime, isNull);

      await pumpPastRitual(tester);
    });

    testWidgets('sends HH:mm once the birth time is known', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await tester.pump(); // let the startup profile-load future settle
      await tester.tap(find.byKey(const Key('allow_location')));
      await tester.pumpAndSettle();

      // Turning the switch off reveals the time picker card.
      expect(find.byKey(const Key('birth_time_picker')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('birth_time_unknown')));
      await tester.tap(find.byKey(const Key('birth_time_unknown')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('birth_time_picker')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('complete_profile')));
      await tester.tap(find.byKey(const Key('complete_profile')));
      await tester.pumpAndSettle();
      await revealReading(tester);
      await tester.pump();

      expect(rig.sentRequest!.profile.birthTime, '14:30');

      await pumpPastRitual(tester);
    });

    testWidgets('records the Reveal instant exactly once', (tester) async {
      final instant = DateTime.utc(2026, 9, 18, 8, 30);
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        now: instant,
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await tester.pump();

      expect(rig.clockReads, 1);
      expect(rig.contextProvider.captures.map((c) => c.instantUtc), [instant]);
      expect(rig.sentRequest!.context.instantUtc, instant.toIso8601String());
      expect(rig.sentRequest!.context.deviceTimezone, 'Asia/Ho_Chi_Minh');
      expect(rig.sentRequest!.context.location, isNull);

      await pumpPastRitual(tester);
    });

    testWidgets('asks the repository once despite rebuilds', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);

      // Force rebuilds of the loading page while the call is in flight.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await tester.pump();
      await tester.tap(loadingSurface);
      await tester.pump();

      expect(rig.repository.requests, hasLength(1));
      await pumpPastRitual(tester);
      expect(rig.repository.requests, hasLength(1));
    });

    testWidgets('every UI mode reaches the engine as its own mode', (
      tester,
    ) async {
      const cases = {
        'YES': engine.DecisionMode.yesNo,
        'ACT': engine.DecisionMode.actWait,
        'ADVANCE': engine.DecisionMode.advanceRetreat,
        'STAY': engine.DecisionMode.stayGo,
        'KEEP': engine.DecisionMode.keepLetGo,
        'FORWARD': engine.DecisionMode.forwardBackward,
        'LEFT': engine.DecisionMode.leftRight,
      };

      for (final entry in cases.entries) {
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
        );
        // Tear the previous tree down first: pumping another
        // DecisionCompassApp would reuse the live element tree, and its
        // Navigator would still be sitting on the last result.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(rig.app);
        await completeOnboarding(tester);
        await revealReading(tester, modeLabel: entry.key);
        await tester.pump();

        expect(
          rig.sentRequest!.mode,
          entry.value,
          reason: '${entry.key} must not be sent as another mode',
        );
        await pumpPastRitual(tester);
      }
    });

    testWidgets('every period reaches the engine as its own period', (
      tester,
    ) async {
      const cases = {
        'now': engine.TimePeriod.now,
        'morning': engine.TimePeriod.morning,
        'midday': engine.TimePeriod.midday,
        'afternoon': engine.TimePeriod.afternoon,
        'evening': engine.TimePeriod.evening,
      };

      for (final entry in cases.entries) {
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(rig.app);
        await completeOnboarding(tester);
        await revealReading(tester, periodName: entry.key);
        await tester.pump();

        expect(rig.sentRequest!.period, entry.value);
        await pumpPastRitual(tester);
      }
    });
  });

  group('loading orchestration', () {
    testWidgets('an instant API still waits for the ritual floor', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);

      await tester.pump(const Duration(milliseconds: 4100));
      expect(
        loadingSurface,
        findsOneWidget,
        reason: 'the ritual must not end before 4.2s',
      );
      expect(find.text('YOUR DIRECTION'), findsNothing);

      await pumpPastRitual(tester);
      expect(find.text('YOUR DIRECTION'), findsOneWidget);
    });

    testWidgets('a slow API keeps the ritual on screen until it answers', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        apiDelay: const Duration(seconds: 8),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);

      await tester.pump(const Duration(milliseconds: 5400));
      expect(
        loadingSurface,
        findsOneWidget,
        reason: 'the ritual must continue while the API is pending',
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('YOUR DIRECTION'), findsOneWidget);
    });
  });

  group('result rendering', () {
    testWidgets('a ready YES/NO reading shows the engine percentages', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await pumpPastRitual(tester);

      expect(find.byKey(const Key('result_ready')), findsOneWidget);
      expect(find.text('YES'), findsOneWidget);
      expect(find.text('56%'), findsOneWidget);
      expect(find.text('NO  44%'), findsOneWidget);
      // NOW never shows windows.
      expect(find.byKey(const Key('result_lucky_windows')), findsNothing);
      expect(find.byKey(const Key('result_daily_brief')), findsOneWidget);
    });

    testWidgets('FORWARD/BACKWARD keeps its own percentages and windows', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_forward_backward_two_windows.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester, modeLabel: 'FORWARD', periodName: 'evening');
      await pumpPastRitual(tester);

      expect(find.text('FORWARD'), findsWidgets);
      // Scoped to the direction block: the window scores are also 57%.
      expect(
        find.descendant(
          of: find.byKey(const Key('result_ready')),
          matching: find.text('57%'),
        ),
        findsOneWidget,
      );
      expect(find.text('BACKWARD  43%'), findsOneWidget);
      final windowCard = find.byKey(const Key('result_lucky_windows'));
      expect(windowCard, findsOneWidget);
      // The engine's own local wall clock (18:00–19:00 and 19:00–21:00 in
      // +07:00), rendered without a second timezone conversion.
      expect(find.text('6:00 PM – 7:00 PM'), findsOneWidget);
      expect(find.text('7:00 PM – 9:00 PM'), findsOneWidget);
      // Scores read as percentages; both windows scored 57 in this fixture.
      expect(
        find.descendant(of: windowCard, matching: find.text('57%')),
        findsNWidgets(2),
      );
      expect(find.text('Your Luckiest Times This Evening'), findsOneWidget);
      expect(find.textContaining('not a chance of success'), findsOneWidget);
      expect(find.textContaining('do not add up to 100%'), findsOneWidget);
      expect(find.textContaining('symbolic timing alignment'), findsOneWidget);
    });

    testWidgets('LEFT/RIGHT keeps its own percentages', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_left_right.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester, modeLabel: 'LEFT', periodName: 'afternoon');
      await pumpPastRitual(tester);

      // The engine gave RIGHT the lead here, which YES/NO would not have.
      expect(find.text('RIGHT'), findsWidgets);
      expect(find.text('52%'), findsOneWidget);
      expect(find.text('LEFT  48%'), findsOneWidget);
    });

    testWidgets('a balanced reading shows both sides and no winner', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('synthetic_balanced.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await pumpPastRitual(tester);

      expect(find.byKey(const Key('result_balanced')), findsOneWidget);
      expect(find.text('BALANCED'), findsOneWidget);
      expect(find.text('ACT  50%'), findsOneWidget);
      expect(find.text('WAIT  50%'), findsOneWidget);
      expect(find.text('YOUR DIRECTION'), findsNothing);
    });

    testWidgets(
      'insufficient data explains itself without inventing a winner',
      (tester) async {
        final rig = ReadingTestRig(
          response: fixtureResponse('synthetic_insufficient_data.json'),
        );
        await tester.pumpWidget(rig.app);
        await completeOnboarding(tester);
        await revealReading(tester);
        await pumpPastRitual(tester);

        expect(
          find.byKey(const Key('result_insufficient_data')),
          findsOneWidget,
        );
        expect(find.text('NOT ENOUGH TO READ'), findsOneWidget);
        expect(find.text('YOUR DIRECTION'), findsNothing);
        expect(find.text('BALANCED'), findsNothing);
      },
    );

    testWidgets('an elapsed period says so and does not use another period', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('period_elapsed.json'),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await pumpPastRitual(tester);

      expect(find.byKey(const Key('result_period_elapsed')), findsOneWidget);
      expect(find.text('THAT PERIOD HAS PASSED'), findsOneWidget);
      // Names the period from the response and refuses to roll it forward.
      expect(find.textContaining('Morning'), findsWidgets);
      expect(find.textContaining('not rolled into tomorrow'), findsOneWidget);
      expect(find.byKey(const Key('result_lucky_windows')), findsNothing);
      expect(find.text('YOUR DIRECTION'), findsNothing);
    });
  });

  group('error states', () {
    const network = ReadingApiException(
      kind: ReadingApiFailureKind.network,
      safeCode: 'reading_service_unreachable',
      safeMessage: 'The reading service could not be reached.',
    );

    testWidgets('a network failure offers an explicit retry that succeeds', (
      tester,
    ) async {
      final rig = ReadingTestRig(error: network);
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);

      // The error waits for the ritual floor rather than flashing instantly.
      await tester.pump(const Duration(milliseconds: 4100));
      expect(errorView, findsNothing);

      await pumpPastRitual(tester);
      expect(errorView, findsOneWidget);
      expect(
        find.text('The connection slipped out of alignment.'),
        findsOneWidget,
      );
      expect(retryButton, findsOneWidget);
      expect(find.byKey(const Key('back_from_error')), findsOneWidget);
      expect(rig.repository.requests, hasLength(1));

      // No retry happens until the user asks for one.
      await tester.pump(const Duration(seconds: 20));
      expect(rig.repository.requests, hasLength(1));

      rig.repository
        ..error = null
        ..respondWith(fixtureResponse('ready_yes_no_now.json'));
      await tester.tap(retryButton);
      await tester.pump();
      await pumpPastRitual(tester);

      expect(find.text('YOUR DIRECTION'), findsOneWidget);
      expect(rig.repository.requests, hasLength(2));
      // The retry replays the original Reveal moment.
      expect(
        rig.repository.requests.last.context.instantUtc,
        rig.repository.requests.first.context.instantUtc,
      );
      expect(rig.clockReads, 1);
    });

    testWidgets('a rejected request offers no retry', (tester) async {
      final rig = ReadingTestRig(
        error: const ReadingApiException(
          kind: ReadingApiFailureKind.rejectedRequest,
          statusCode: 422,
          safeCode: 'reading_request_rejected',
          safeMessage: 'The reading request was rejected.',
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await pumpPastRitual(tester);

      expect(find.text('Some profile details need attention.'), findsOneWidget);
      expect(retryButton, findsNothing);
      expect(find.byKey(const Key('back_from_error')), findsOneWidget);
      expect(rig.repository.requests, hasLength(1));
    });

    testWidgets('a server failure may be retried', (tester) async {
      final rig = ReadingTestRig(
        error: const ReadingApiException(
          kind: ReadingApiFailureKind.server,
          statusCode: 500,
          safeCode: 'reading_service_failed',
          safeMessage: 'The reading service could not complete the request.',
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await pumpPastRitual(tester);

      expect(
        find.text('The reading could not be completed right now.'),
        findsOneWidget,
      );
      expect(retryButton, findsOneWidget);
    });

    testWidgets(
      'a configuration failure names the missing define, not a retry',
      (tester) async {
        final rig = ReadingTestRig(
          error: const ReadingApiException(
            kind: ReadingApiFailureKind.configuration,
            safeCode: 'missing_api_base_url',
            safeMessage: 'No API base URL was provided.',
          ),
        );
        await tester.pumpWidget(rig.app);
        await completeOnboarding(tester);
        await revealReading(tester);
        await pumpPastRitual(tester);

        expect(
          find.text('This build has no reading service configured.'),
          findsOneWidget,
        );
        expect(find.textContaining('DECISION_API_BASE_URL'), findsOneWidget);
        expect(retryButton, findsNothing);
      },
    );

    testWidgets('an invalid response cannot be retried', (tester) async {
      final rig = ReadingTestRig(
        error: const ReadingApiException(
          kind: ReadingApiFailureKind.invalidResponse,
          statusCode: 200,
          safeCode: 'unexpected_reading_contract',
          safeMessage: 'The reading service returned unreadable data.',
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await pumpPastRitual(tester);

      expect(
        find.text('This app version could not read the result.'),
        findsOneWidget,
      );
      expect(retryButton, findsNothing);
    });

    testWidgets('error text never shows exception, birth or location data', (
      tester,
    ) async {
      // Poisoned deliberately: even if something upstream leaked into the
      // exception, the UI must not put it on screen.
      final rig = ReadingTestRig(
        error: const ReadingApiException(
          kind: ReadingApiFailureKind.network,
          statusCode: 500,
          safeCode: 'birthDate_1998-06-21',
          safeMessage:
              'readingKey deadbeef inputSnapshot 10.7769 Asia/Ho_Chi_Minh '
              'at Object.<anonymous> (/srv/engine/src/index.js:66:11)',
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await pumpPastRitual(tester);

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' | ');

      for (final needle in [
        '1998-06-21',
        'deadbeef',
        'inputSnapshot',
        '10.7769',
        'Asia/Ho_Chi_Minh',
        'index.js',
        'ReadingApiException',
        'birthDate',
        '14:30',
      ]) {
        expect(
          rendered.contains(needle),
          isFalse,
          reason: 'error screen leaked "$needle"',
        );
      }
    });
  });
}
