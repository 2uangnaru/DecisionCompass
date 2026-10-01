import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/loading_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// Where the period cutoff is actually enforced.
///
/// The ritual screen greys a chip out and re-checks it at the tap, but a
/// greyed chip is a presentation detail: it is the request that must not be
/// built. [LoadingPage] is the one place in the app where a live reading
/// request comes into existence, so these tests go straight there and skip
/// the screen that would normally have stopped them.
///
/// The engine underneath is deliberately not involved. It is a pure function
/// of its inputs and will answer for any instant it is given — which is the
/// only reason a reading saved months ago can be replayed, and why the
/// fixtures and the parity suite work at all. The rule lives here instead.
Widget _host(ReadingTestRig rig, TimePeriod period, DateTime localTap) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: LoadingPage(
      mode: DecisionMode.yesNo,
      period: period,
      category: engine.ReadingCategory.study,
      profile: _profile,
      instantUtc: utcForLocal(localTap, rig.contextProvider.deviceTimezone),
      dependencies: rig.dependencies,
    ),
  );
}

/// A complete profile, so nothing is refused for a reason other than the one
/// under test.
final _profile = AppProfile(
  userName: 'Alex',
  birthDate: DateTime(1998, 6, 21),
  birthCountryCode: 'US',
  zodiacSign: ZodiacSign.cancer,
  useCurrentLocation: false,
  safetyAcknowledged: true,
);

void main() {
  group('the request itself is refused when the period has closed', () {
    testWidgets('a closed period never reaches the repository', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_study_morning.json'),
      );
      // 10:30 is morning's cutoff to the minute.
      await tester.pumpWidget(
        _host(rig, TimePeriod.morning, DateTime(2026, 9, 18, 10, 30)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();

      expect(rig.repository.requests, isEmpty);
      expect(find.byKey(const Key('reading_error')), findsOneWidget);
      expect(find.text('Passed'), findsOneWidget);
      expect(
        find.text(
          'There is not enough time left in Morning today. '
          'Choose another time.',
        ),
        findsOneWidget,
      );
      // Retrying would re-check the same instant against the same clock.
      expect(find.text('Try Again'), findsNothing);
    });

    testWidgets('a period that is over says so, not "too little time"', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_study_morning.json'),
      );
      await tester.pumpWidget(
        _host(rig, TimePeriod.morning, DateTime(2026, 9, 18, 12, 1)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();

      expect(rig.repository.requests, isEmpty);
      expect(
        find.text('Morning has passed. Choose another time.'),
        findsOneWidget,
      );
    });

    testWidgets('a minute before the cutoff the request is built and sent', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_study_morning.json'),
      );
      await tester.pumpWidget(
        _host(rig, TimePeriod.morning, DateTime(2026, 9, 18, 10, 29)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();

      expect(rig.sentRequest!.period, engine.TimePeriod.morning);
      expect(find.byKey(const Key('reading_error')), findsNothing);
    });

    testWidgets('NOW is never refused, at any hour', (tester) async {
      for (final hour in <int>[0, 6, 12, 18, 23]) {
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          _host(rig, TimePeriod.now, DateTime(2026, 9, 18, hour, 59)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 5400));
        await tester.pumpAndSettle();

        expect(
          rig.sentRequest!.period,
          engine.TimePeriod.now,
          reason: 'NOW was refused at ${hour}h59',
        );
      }
    });

    testWidgets('the zone that judges it is the one the reading will use', (
      tester,
    ) async {
      // 22:00 in Ho Chi Minh City is 11:00 in Auckland the next morning —
      // open — and 08:00 in Los Angeles, also open. The same instant is
      // judged against whichever clock the captured context carries, not
      // against the host machine's.
      final tapUtc = utcForLocal(
        DateTime(2026, 9, 18, 22),
        'Asia/Ho_Chi_Minh',
      );

      Future<void> run(String zone) async {
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_study_morning.json'),
          deviceTimezone: zone,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LoadingPage(
              mode: DecisionMode.yesNo,
              period: TimePeriod.morning,
              category: engine.ReadingCategory.study,
              profile: _profile,
              instantUtc: tapUtc,
              dependencies: rig.dependencies,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 5400));
        await tester.pumpAndSettle();
        _sent[zone] = rig.repository.requests.isNotEmpty;
      }

      // Ho Chi Minh City: 22:00, morning is long over.
      await run('Asia/Ho_Chi_Minh');
      // Auckland: 03:00 the next day, morning has not started.
      await run('Pacific/Auckland');

      expect(_sent['Asia/Ho_Chi_Minh'], isFalse);
      expect(_sent['Pacific/Auckland'], isTrue);
    });
  });
}

final _sent = <String, bool>{};
