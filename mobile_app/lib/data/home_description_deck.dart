/// Picks one approved Home description per local calendar day.
///
/// The rule is a shuffle bag, not a hash of the date: all thirty descriptions
/// are dealt in a random order before any of them comes round again, and the
/// order itself differs between installs. Nothing here touches the calculation
/// engine or a reading.
library;

import 'dart:math';

import '../home_descriptions.dart';

/// The whole persisted state of the rotation, in one record.
///
/// Deck, progress and the day assignments are saved and validated together on
/// purpose: split across keys they could be written half-way and leave a day
/// pointing at a description the deck has already dealt again.
class HomeDescriptionDeckState {
  const HomeDescriptionDeckState({
    required this.deck,
    required this.recent,
    required this.days,
  });

  const HomeDescriptionDeckState.empty()
    : deck = const [],
      recent = const [],
      days = const {};

  /// Format version of the stored record. A stored value that is not this is
  /// discarded rather than guessed at.
  static const version = 1;

  /// How many of the most recently shown descriptions a fresh deck must keep
  /// out of its own opening hand, so a reshuffle cannot repeat one straight
  /// away.
  static const cooldown = 7;

  /// Day assignments are pruned to this many entries, newest first. One full
  /// deck plus a fortnight: enough that going back over recent days is stable,
  /// bounded so the record cannot grow without limit.
  static const maxRememberedDays = 45;

  /// Indices still to be dealt from the current deck, in the order they will
  /// be dealt.
  final List<int> deck;

  /// The last [cooldown] indices shown, oldest first.
  final List<int> recent;

  /// Local day key (`yyyy-m-d`) to the description index shown on that day.
  final Map<String, int> days;

  Map<String, Object?> toJson() => {
    'version': version,
    'deck': deck,
    'recent': recent,
    'days': days,
  };

  /// Reads a stored record, or null when it is missing, from another format,
  /// or damaged in any way. Callers treat null as "start fresh".
  ///
  /// Every field is checked rather than cast: a half-written or hand-edited
  /// file must not be able to put an out-of-range index on screen.
  static HomeDescriptionDeckState? fromJson(Object? raw) {
    if (raw is! Map) return null;
    if (raw['version'] != version) return null;

    final deck = _indices(raw['deck']);
    final recent = _indices(raw['recent']);
    if (deck == null || recent == null) return null;
    // A deck may not deal the same description twice.
    if (deck.toSet().length != deck.length) return null;
    if (recent.length > cooldown) return null;

    final rawDays = raw['days'];
    if (rawDays is! Map) return null;
    final days = <String, int>{};
    for (final entry in rawDays.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || key.isEmpty) return null;
      if (value is! int || value < 0 || value >= homeDescriptions.length) {
        return null;
      }
      days[key] = value;
    }

    return HomeDescriptionDeckState(deck: deck, recent: recent, days: days);
  }

  static List<int>? _indices(Object? raw) {
    if (raw is! List) return null;
    final result = <int>[];
    for (final value in raw) {
      if (value is! int || value < 0 || value >= homeDescriptions.length) {
        return null;
      }
      result.add(value);
    }
    return result;
  }
}

/// Where the rotation's state lives between runs.
abstract interface class HomeDescriptionStore {
  /// The saved state, or null when nothing usable is stored.
  Future<HomeDescriptionDeckState?> load();

  Future<void> save(HomeDescriptionDeckState state);
}

/// The local calendar day a [DateTime] falls on.
///
/// Always built from a local `DateTime`, never a UTC one: a reader near
/// midnight would otherwise see tomorrow's description, or yesterday's.
String homeDayKey(DateTime local) =>
    '${local.year}-${local.month}-${local.day}';

/// Deals descriptions, one per local day.
class HomeDescriptionDeck {
  const HomeDescriptionDeck({required this.store, this.random});

  final HomeDescriptionStore store;

  /// Injected by tests to make a deal reproducible. Production leaves it null
  /// and gets a fresh [Random] per deal, which is plenty for a deck that is
  /// reshuffled once a month.
  final Random? random;

  /// The description for the day [local] falls on.
  ///
  /// A day already assigned returns its saved description and consumes
  /// nothing, so revisiting a date — or simply reopening Home — never advances
  /// the deck. A day that is never asked about is never dealt, so a stretch of
  /// days with the app unopened does not burn through the deck.
  Future<String> descriptionFor(DateTime local) async {
    final day = homeDayKey(local);
    final stored = await store.load() ?? const HomeDescriptionDeckState.empty();

    final assigned = stored.days[day];
    if (assigned != null) return homeDescriptions[assigned];

    final deck = [...stored.deck];
    final recent = [...stored.recent];
    if (deck.isEmpty) deck.addAll(_shuffled(recent));

    final index = deck.removeAt(0);
    recent.add(index);
    while (recent.length > HomeDescriptionDeckState.cooldown) {
      recent.removeAt(0);
    }

    final days = {...stored.days, day: index};
    await store.save(
      HomeDescriptionDeckState(deck: deck, recent: recent, days: _pruned(days)),
    );
    return homeDescriptions[index];
  }

  /// A fresh deck whose opening hand avoids everything in [recent], so the
  /// reader cannot see the same line twice across a reshuffle.
  List<int> _shuffled(List<int> recent) {
    final deck = List<int>.generate(homeDescriptions.length, (i) => i)
      ..shuffle(random ?? Random());
    final blocked = recent.toSet();
    if (blocked.isEmpty) return deck;

    const cooldown = HomeDescriptionDeckState.cooldown;
    for (var i = 0; i < cooldown && i < deck.length; i++) {
      if (!blocked.contains(deck[i])) continue;
      // Trade it for a later card that is not on cooldown. There are always
      // more such cards than opening slots, so this cannot fail to find one.
      for (var j = cooldown; j < deck.length; j++) {
        if (blocked.contains(deck[j])) continue;
        final held = deck[i];
        deck[i] = deck[j];
        deck[j] = held;
        break;
      }
    }
    return deck;
  }

  /// Keeps the newest [HomeDescriptionDeckState.maxRememberedDays] days.
  ///
  /// Sorting is chronological rather than by string, so `2026-9-2` is not
  /// dropped before `2026-9-10`.
  static Map<String, int> _pruned(Map<String, int> days) {
    if (days.length <= HomeDescriptionDeckState.maxRememberedDays) return days;
    final keys = days.keys.toList()
      ..sort((a, b) => _dayOrder(a).compareTo(_dayOrder(b)));
    final keep = keys.sublist(
      keys.length - HomeDescriptionDeckState.maxRememberedDays,
    );
    return {for (final key in keep) key: days[key]!};
  }

  static int _dayOrder(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return 0;
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final day = int.tryParse(parts[2]) ?? 0;
    return year * 10000 + month * 100 + day;
  }
}
