import 'package:decision_compass/app.dart';
import 'package:decision_compass/data/current_context_provider.dart';
import 'package:decision_compass/data/fake_reading_repository.dart';
import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/reading_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'data/fixture_loader.dart';

/// Injected fakes for the reading flow. No network, GPS or platform channel is
/// touched: the repository, the context provider and the clock are all
/// in-memory.
class ReadingTestRig {
  ReadingTestRig({
    ReadingResponse? response,
    Object? error,
    Duration apiDelay = Duration.zero,
    DateTime? now,
    DateTime? localNow,
    String deviceTimezone = 'Asia/Ho_Chi_Minh',
    CurrentLocation? location,
  }) : localClock = localNow ?? _beforeEveryPeriod,
       repository = FakeReadingRepository(
         response: response,
         error: error,
         delay: apiDelay,
       ),
       contextProvider = FixedCurrentContextProvider(
         deviceTimezone: deviceTimezone,
         location: location,
       ),
       revealInstant = now ?? DateTime.utc(2026, 9, 18, 8, 30);

  /// Early enough that no period has elapsed, so a test that does not care
  /// about the clock can still reach every one of them.
  static final _beforeEveryPeriod = DateTime(2026, 9, 18, 5, 30);

  final FakeReadingRepository repository;
  final FixedCurrentContextProvider contextProvider;
  final DateTime revealInstant;

  /// Device wall clock the ritual reads to mute periods that are over.
  final DateTime localClock;

  /// How many times the flow asked for "now".
  var clockReads = 0;

  late final ReadingDependencies dependencies = ReadingDependencies(
    repository: repository,
    contextProvider: contextProvider,
    nowUtc: () {
      clockReads++;
      return revealInstant;
    },
    nowLocal: () => localClock,
  );

  late final Widget app = DecisionCompassApp(dependencies: dependencies);

  /// The single request the flow sent, or null when it sent none.
  ReadingRequest? get sentRequest =>
      repository.requests.isEmpty ? null : repository.requests.single;
}

ReadingResponse fixtureResponse(String name) =>
    ReadingResponse.fromJson(readFixture(name));

/// Walks the explainer and profile steps to Home.
Future<void> completeOnboarding(
  WidgetTester tester, {
  bool allowLocation = true,
}) async {
  await tester.tap(
    find.byKey(Key(allowLocation ? 'allow_location' : 'skip_location')),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('complete_profile')));
  await tester.tap(find.byKey(const Key('complete_profile')));
  await tester.pumpAndSettle();
}

/// From Home, selects an optional category/mode, enters the ritual, picks an
/// optional period there, then reveals. Stops as soon as loading begins.
Future<void> revealReading(
  WidgetTester tester, {
  String? modeLabel,
  String? periodName,
  ReadingCategory? category,
}) async {
  if (category != null) {
    // Keys mirror the wire value for stability; the value itself is never shown.
    final key = Key('category_${category.wireValue}');
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pump();
  }
  if (modeLabel != null) {
    await tester.ensureVisible(find.text(modeLabel).first);
    await tester.tap(find.text(modeLabel).first);
    await tester.pump();
  }

  await tester.ensureVisible(find.byKey(const Key('find_direction')));
  await tester.tap(find.byKey(const Key('find_direction')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));

  // The period now lives on the ritual screen, beside the Reveal tap.
  if (periodName != null) {
    await tester.tap(find.byKey(Key('ritual_period_$periodName')));
    await tester.pump();
  }

  await tester.tap(find.byKey(const Key('reveal_button')));
  await tester.pump(const Duration(milliseconds: 380));
  await tester.pump();
}
