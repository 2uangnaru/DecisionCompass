import 'dart:math';

import 'package:decision_compass/data/home_description_deck.dart';
import 'package:decision_compass/data/in_memory_home_description_store.dart';
import 'package:decision_compass/home_descriptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// The description Home is currently showing.
String? shownDescription(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('home_description'))).data;

/// Onboards, then settles the deck's first read.
Future<void> openHome(WidgetTester tester) async {
  await completeOnboarding(tester);
  await tester.pump();
}

void main() {
  group('the approved copy', () {
    test('is thirty distinct descriptions, verbatim', () {
      expect(homeDescriptions, hasLength(30));
      expect(homeDescriptions.toSet(), hasLength(30));
      for (final description in homeDescriptions) {
        expect(description.trim(), description);
        expect(description, isNotEmpty);
      }
      // Spot-check the ends of the approved list, including the punctuation
      // that a careless re-wrap would flatten.
      expect(
        homeDescriptions.first,
        'What might the universe be telling you today? Choose what’s on your '
        'mind and explore the signs around this moment.',
      );
      expect(
        homeDescriptions[2],
        'The stars may not decide for you—but their patterns might help you '
        'see your next step differently.',
      );
      expect(
        homeDescriptions.last,
        'You don’t have to find certainty here. Find a moment of calm, a '
        'cosmic cue, and a direction to consider.',
      );
    });
  });

  group('the deck', () {
    late InMemoryHomeDescriptionStore store;
    late HomeDescriptionDeck deck;

    setUp(() {
      store = InMemoryHomeDescriptionStore();
      deck = HomeDescriptionDeck(store: store, random: Random(7));
    });

    Future<String> on(int year, int month, int day) =>
        deck.descriptionFor(DateTime(year, month, day));

    test('deals every description once before repeating any', () async {
      final seen = <String>[];
      for (var day = 1; day <= 30; day++) {
        seen.add(await on(2026, 1, day));
      }
      expect(seen.toSet(), hasLength(30), reason: 'a description repeated');
      expect(seen.toSet(), homeDescriptions.toSet());
    });

    test('the order is shuffled, not the authoring order', () async {
      final seen = <String>[];
      for (var day = 1; day <= 30; day++) {
        seen.add(await on(2026, 1, day));
      }
      expect(
        seen,
        isNot(orderedEquals(homeDescriptions)),
        reason: 'the deck was dealt in list order',
      );

      // A different seed deals a different order, so the order really is drawn
      // rather than derived from the date.
      final other = HomeDescriptionDeck(
        store: InMemoryHomeDescriptionStore(),
        random: Random(99),
      );
      final otherSeen = <String>[];
      for (var day = 1; day <= 30; day++) {
        otherSeen.add(await other.descriptionFor(DateTime(2026, 1, day)));
      }
      expect(otherSeen, isNot(orderedEquals(seen)));
    });

    test('a reshuffle does not repeat any of the last seven', () async {
      final seen = <String>[];
      for (var day = 1; day <= 37; day++) {
        seen.add(await on(2026, 1, day));
      }
      // Descriptions 31–37 open the second deck; none may match the seven that
      // closed the first one.
      final closing = seen.sublist(23, 30);
      final opening = seen.sublist(30, 37);
      for (final description in opening) {
        expect(
          closing,
          isNot(contains(description)),
          reason: 'the second deck repeated a line from the first',
        );
      }
      expect(opening.toSet(), hasLength(7));
    });

    test('the same date is stable and consumes nothing', () async {
      final first = await on(2026, 3, 4);
      final saves = store.saves;
      expect(await on(2026, 3, 4), first);
      expect(await on(2026, 3, 4), first);
      expect(store.saves, saves, reason: 'a repeat asked the deck for a card');
    });

    test('returning to an earlier assigned date does not advance', () async {
      final day1 = await on(2026, 3, 1);
      final day2 = await on(2026, 3, 2);
      final saves = store.saves;

      expect(await on(2026, 3, 1), day1);
      expect(store.saves, saves);

      // The next new date still gets the card that was next in line.
      final day3 = await on(2026, 3, 3);
      expect(day3, isNot(day1));
      expect(day3, isNot(day2));
    });

    test('dates the reader never opens consume nothing', () async {
      final opening = await on(2026, 5, 1);
      // Two months pass with the app unopened.
      final next = await on(2026, 7, 1);
      final third = await on(2026, 7, 2);

      expect({opening, next, third}, hasLength(3));
      // Only three cards left the deck, not sixty-odd.
      final state = await store.load();
      expect(state!.deck, hasLength(homeDescriptions.length - 3));
    });

    test('survives a restart mid-deck and keeps going', () async {
      final before = <String>[];
      for (var day = 1; day <= 5; day++) {
        before.add(await on(2026, 2, day));
      }

      // A new deck object over the same stored record is what a cold start is.
      final restarted = HomeDescriptionDeck(store: store, random: Random(1));
      final after = <String>[];
      for (var day = 6; day <= 30; day++) {
        after.add(await restarted.descriptionFor(DateTime(2026, 2, day)));
      }

      expect([...before, ...after].toSet(), hasLength(30));
      // Days dealt before the restart still read back the same.
      expect(
        await restarted.descriptionFor(DateTime(2026, 2, 1)),
        before.first,
      );
    });

    test('remembered days stay bounded', () async {
      for (var day = 1; day <= 80; day++) {
        await deck.descriptionFor(
          DateTime(2026, 1, 1).add(Duration(days: day)),
        );
      }
      final state = await store.load();
      expect(
        state!.days.length,
        lessThanOrEqualTo(HomeDescriptionDeckState.maxRememberedDays),
      );
      // The newest days are the ones kept.
      expect(state.days.containsKey('2026-3-22'), isTrue);
    });
  });

  group('damaged or foreign stored state', () {
    for (final entry in <String, Object?>{
      'not a map': 'nonsense',
      'a list': [1, 2, 3],
      'a future version': {'version': 99, 'deck': [], 'recent': [], 'days': {}},
      'no version': {'deck': [], 'recent': [], 'days': {}},
      'an out-of-range card': {
        'version': 1,
        'deck': [0, 999],
        'recent': [],
        'days': <String, Object?>{},
      },
      'a negative card': {
        'version': 1,
        'deck': [-1],
        'recent': [],
        'days': <String, Object?>{},
      },
      'a duplicated card': {
        'version': 1,
        'deck': [3, 3],
        'recent': [],
        'days': <String, Object?>{},
      },
      'too long a cooldown': {
        'version': 1,
        'deck': <int>[],
        'recent': [0, 1, 2, 3, 4, 5, 6, 7],
        'days': <String, Object?>{},
      },
      'a day pointing nowhere': {
        'version': 1,
        'deck': <int>[],
        'recent': <int>[],
        'days': {'2026-1-1': 900},
      },
      'a non-string day': {
        'version': 1,
        'deck': <int>[],
        'recent': <int>[],
        'days': {5: 1},
      },
      'missing days': {'version': 1, 'deck': <int>[], 'recent': <int>[]},
    }.entries) {
      test('${entry.key} is rejected, not trusted', () {
        expect(HomeDescriptionDeckState.fromJson(entry.value), isNull);
      });
    }

    test('a rejected record starts a fresh deck instead of crashing', () async {
      final store = InMemoryHomeDescriptionStore(raw: 'nonsense');
      final deck = HomeDescriptionDeck(store: store, random: Random(3));
      final description = await deck.descriptionFor(DateTime(2026, 4, 9));
      expect(homeDescriptions, contains(description));
      // And the damaged record was replaced by a valid one.
      expect(await store.load(), isNotNull);
    });

    test('a valid record round-trips', () {
      const state = HomeDescriptionDeckState(
        deck: [4, 1, 9],
        recent: [2, 7],
        days: {'2026-1-1': 2, '2026-1-2': 7},
      );
      final restored = HomeDescriptionDeckState.fromJson(state.toJson());
      expect(restored!.deck, [4, 1, 9]);
      expect(restored.recent, [2, 7]);
      expect(restored.days, {'2026-1-1': 2, '2026-1-2': 7});
    });
  });

  group('on the Home screen', () {
    testWidgets('shows one approved description and keeps it across rebuilds', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 7),
      );
      await tester.pumpWidget(rig.app);
      await openHome(tester);

      final shown = shownDescription(tester);
      expect(homeDescriptions, contains(shown));

      // Rebuilds, and a round trip through another screen, leave it alone.
      await tester.tap(find.byKey(const Key('category_money')));
      await tester.pumpAndSettle();
      expect(shownDescription(tester), shown);

      // The ritual screen breathes forever, so it is stepped through with
      // fixed pumps rather than settled.
      await tester.ensureVisible(find.byKey(const Key('find_direction')));
      await tester.tap(find.byKey(const Key('find_direction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(shownDescription(tester), shown);
    });

    testWidgets('never flashes another day’s line while the deck loads', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 7),
        // Longer than the onboarding route transition, so the first Home
        // frames really are drawn before the record has answered.
        descriptionStore: InMemoryHomeDescriptionStore(
          delay: const Duration(seconds: 3),
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      // While the store is still answering, the slot is blank — never a stale
      // or placeholder sentence — but it already holds its space.
      expect(shownDescription(tester), '');
      final reserved = tester.getSize(
        find.byKey(const Key('home_description')),
      );
      expect(reserved.height, greaterThan(0));

      await tester.pump(const Duration(seconds: 4));
      expect(homeDescriptions, contains(shownDescription(tester)));
    });

    testWidgets('survives an app restart on the same local day', (
      tester,
    ) async {
      final store = InMemoryHomeDescriptionStore();
      final first = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 7),
        descriptionStore: store,
      );
      await tester.pumpWidget(first.app);
      await openHome(tester);
      final shown = shownDescription(tester);

      // Cold start: a new app over the same on-device record.
      final second = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 21),
        descriptionStore: store,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(second.app);
      await openHome(tester);

      expect(shownDescription(tester), shown);
    });

    testWidgets('changes at the local midnight boundary, on resume', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 22),
      );
      await tester.pumpWidget(rig.app);
      await openHome(tester);
      final yesterday = shownDescription(tester);

      // Same day, app resumed: nothing moves.
      rig.localClock = DateTime(2026, 9, 18, 23, 30);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(shownDescription(tester), yesterday);

      // Past midnight: a new line.
      rig.localClock = DateTime(2026, 9, 19, 0, 20);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      final today = shownDescription(tester);
      expect(today, isNot(yesterday));
      expect(homeDescriptions, contains(today));

      // And going back to yesterday's date restores yesterday's line.
      rig.localClock = DateTime(2026, 9, 18, 23, 59);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(shownDescription(tester), yesterday);
    });

    testWidgets('a new day blanks the old line rather than holding it', (
      tester,
    ) async {
      final store = InMemoryHomeDescriptionStore(
        delay: const Duration(seconds: 3),
      );
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 20),
        descriptionStore: store,
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await tester.pump(const Duration(seconds: 4));
      final yesterday = shownDescription(tester);
      expect(homeDescriptions, contains(yesterday));

      rig.localClock = DateTime(2026, 9, 19, 7);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();

      // The store has not answered for the new day yet. Yesterday's line must
      // not be standing in for today's.
      expect(
        shownDescription(tester),
        '',
        reason: 'yesterday’s line lingered while the deck answered',
      );

      await tester.pump(const Duration(seconds: 4));
      final today = shownDescription(tester);
      expect(homeDescriptions, contains(today));
      expect(today, isNot(yesterday));
    });

    testWidgets('changes while Home is on screen at midnight', (tester) async {
      var clock = DateTime(2026, 9, 18, 23, 59, 30);
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        liveLocalClock: () => clock,
      );
      await tester.pumpWidget(rig.app);
      await openHome(tester);
      final before = shownDescription(tester);

      // The page schedules a timer for its own local midnight.
      clock = DateTime(2026, 9, 19, 0, 0, 1);
      await tester.pump(const Duration(seconds: 31));
      await tester.pump();
      await tester.pump();

      final after = shownDescription(tester);
      expect(after, isNot(before));
      expect(homeDescriptions, contains(after));
    });

    testWidgets('a corrupt record still renders a description', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 7),
        descriptionStore: InMemoryHomeDescriptionStore(raw: {'version': 42}),
      );
      await tester.pumpWidget(rig.app);
      await openHome(tester);

      expect(tester.takeException(), isNull);
      expect(homeDescriptions, contains(shownDescription(tester)));
    });

    testWidgets('reads on a narrow screen without overflowing', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 640));
      // Seeded so the longest description is the one dealt.
      final longest = homeDescriptions.reduce(
        (a, b) => a.length >= b.length ? a : b,
      );
      final store = InMemoryHomeDescriptionStore(
        raw: HomeDescriptionDeckState(
          deck: [homeDescriptions.indexOf(longest)],
          recent: const [],
          days: const {},
        ).toJson(),
      );
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: DateTime(2026, 9, 18, 7),
        descriptionStore: store,
      );
      await tester.pumpWidget(rig.app);
      await openHome(tester);

      expect(shownDescription(tester), longest);
      expect(tester.takeException(), isNull);
      final box = tester.getRect(find.byKey(const Key('home_description')));
      expect(box.left, greaterThanOrEqualTo(0));
      expect(box.right, lessThanOrEqualTo(360));
    });
  });
}
