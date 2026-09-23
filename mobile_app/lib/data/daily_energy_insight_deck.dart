/// Chooses which of a tone's eight insights to show, and remembers what the
/// reader has already opened.
///
/// The engine owns the tone. Nothing here can change a level, an index, a
/// coverage rule or a threshold — it only picks a sentence from the pool that
/// tone already named, so an insight can never disagree with the calculation.
///
/// State lives under its own versioned key, separate from the Home description
/// rotation, so damage to one cannot corrupt the other.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../daily_energy_messages.dart';

/// One date-and-level's chosen insight, and whether it has been opened.
class DailyEnergyInsightEntry {
  const DailyEnergyInsightEntry({required this.message, required this.read});

  /// Index into that level's pool.
  final int message;

  final bool read;

  Map<String, Object?> toJson() => {'m': message, 'read': read};

  static DailyEnergyInsightEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final message = raw['m'];
    final read = raw['read'];
    if (message is! int || message < 0 || message >= dailyEnergyPoolSize) {
      return null;
    }
    if (read is! bool) return null;
    return DailyEnergyInsightEntry(message: message, read: read);
  }
}

/// Everything the rotation remembers between runs, in one validated record.
class DailyEnergyInsightState {
  const DailyEnergyInsightState({
    required this.decks,
    required this.recent,
    required this.entries,
    this.orbitDay,
    this.coachMarkShown = false,
  });

  const DailyEnergyInsightState.empty()
    : decks = const {},
      recent = const {},
      entries = const {},
      orbitDay = null,
      coachMarkShown = false;

  static const version = 1;

  /// How many of a tone's most recent insights a reshuffle keeps out of its
  /// own opening hand.
  static const cooldown = 3;

  /// Date-and-level assignments are pruned to this many, newest first.
  static const maxRememberedEntries = 60;

  /// Level to the message indices still to be dealt for it, in order.
  final Map<String, List<int>> decks;

  /// Level to the last [cooldown] indices shown for it, oldest first.
  final Map<String, List<int>> recent;

  /// `yyyy-MM-dd|level` to what was chosen for it.
  final Map<String, DailyEnergyInsightEntry> entries;

  /// The last local date the discovery orbit played on, so it plays once a day
  /// however many times Home is rebuilt or reopened.
  final String? orbitDay;

  /// Whether the one-time coach mark has been shown.
  final bool coachMarkShown;

  Map<String, Object?> toJson() => {
    'version': version,
    'decks': decks,
    'recent': recent,
    'entries': {
      for (final entry in entries.entries) entry.key: entry.value.toJson(),
    },
    'orbitDay': orbitDay,
    'coachMarkShown': coachMarkShown,
  };

  /// Reads a stored record, or null when it is missing, from another version,
  /// or damaged in any way. Callers treat null as "start fresh" — a bad record
  /// must never be able to put an out-of-range sentence on screen.
  static DailyEnergyInsightState? fromJson(Object? raw) {
    if (raw is! Map) return null;
    if (raw['version'] != version) return null;

    final decks = _levelIndices(raw['decks'], unique: true);
    final recent = _levelIndices(raw['recent'], unique: false);
    if (decks == null || recent == null) return null;
    for (final value in recent.values) {
      if (value.length > cooldown) return null;
    }

    final rawEntries = raw['entries'];
    if (rawEntries is! Map) return null;
    final entries = <String, DailyEnergyInsightEntry>{};
    for (final entry in rawEntries.entries) {
      final key = entry.key;
      if (key is! String || !key.contains('|')) return null;
      final parsed = DailyEnergyInsightEntry.fromJson(entry.value);
      if (parsed == null) return null;
      // An entry naming a level this build does not know is not recoverable
      // as anything; dropping only it would leave the decks inconsistent.
      if (!dailyEnergyMessagePools.containsKey(key.split('|').last)) {
        return null;
      }
      entries[key] = parsed;
    }

    final orbitDay = raw['orbitDay'];
    if (orbitDay != null && orbitDay is! String) return null;
    final coachMarkShown = raw['coachMarkShown'];
    if (coachMarkShown is! bool) return null;

    return DailyEnergyInsightState(
      decks: decks,
      recent: recent,
      entries: entries,
      orbitDay: orbitDay as String?,
      coachMarkShown: coachMarkShown,
    );
  }

  static Map<String, List<int>>? _levelIndices(
    Object? raw, {
    required bool unique,
  }) {
    if (raw is! Map) return null;
    final result = <String, List<int>>{};
    for (final entry in raw.entries) {
      final level = entry.key;
      if (level is! String || !dailyEnergyMessagePools.containsKey(level)) {
        return null;
      }
      final values = entry.value;
      if (values is! List) return null;
      final indices = <int>[];
      for (final value in values) {
        if (value is! int || value < 0 || value >= dailyEnergyPoolSize) {
          return null;
        }
        indices.add(value);
      }
      if (unique && indices.toSet().length != indices.length) return null;
      result[level] = indices;
    }
    return result;
  }
}

/// Where the rotation's state lives between runs.
abstract interface class DailyEnergyInsightStore {
  Future<DailyEnergyInsightState?> load();

  Future<void> save(DailyEnergyInsightState state);
}

/// The local calendar date an insight belongs to, zero padded so it matches
/// the engine's own `context.localDate` and sorts as text.
///
/// Always built from a local `DateTime` — a reader near midnight would
/// otherwise be shown the wrong day's insight.
String dailyEnergyDayKey(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';

String _entryKey(String day, String level) => '$day|$level';

/// Deals insights and tracks what has been read.
///
/// It is a [ChangeNotifier] because Home and a Result opened from it both show
/// the same ⓘ: reading the insight on one has to clear the unread mark on the
/// other without either screen polling.
class DailyEnergyInsightController extends ChangeNotifier {
  DailyEnergyInsightController({required this.store, Random? random})
    : _random = random;

  final DailyEnergyInsightStore store;
  final Random? _random;

  DailyEnergyInsightState _state = const DailyEnergyInsightState.empty();
  Future<void>? _loading;
  var _loaded = false;

  /// True once the stored record has been read, so the widget knows whether
  /// its unread answer is trustworthy yet.
  bool get isLoaded => _loaded;

  bool get coachMarkShown => _state.coachMarkShown;

  /// Reads the stored record once. Repeat callers share the same future.
  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final stored = await store.load();
    _state = stored ?? const DailyEnergyInsightState.empty();
    _loaded = true;
    _loading = null;
    notifyListeners();
  }

  /// Whether [day]'s insight for [level] is still unopened.
  ///
  /// False for a level with no insights, and false until the record has been
  /// read, so a gold mark never appears and then vanishes.
  bool isUnread(String day, String level) {
    if (!_loaded || !hasDailyEnergyInsight(level)) return false;
    final entry = _state.entries[_entryKey(day, level)];
    return entry == null || !entry.read;
  }

  /// The insight already chosen for [day] and [level], or null when the reader
  /// has not opened it yet. Nothing is dealt here.
  String? peek(String day, String level) {
    final entry = _state.entries[_entryKey(day, level)];
    if (entry == null) return null;
    return dailyEnergyMessagePools[level]?[entry.message];
  }

  /// Opens [day]'s insight for [level]: deals one if this is the first time,
  /// marks it read, and returns it.
  ///
  /// Reopening the same date and level returns the same sentence and consumes
  /// nothing further, so a day's insight is fixed once it has been seen — on
  /// Home, on a Result from that day, and after a restart.
  Future<String?> open(String day, String level) async {
    final pool = dailyEnergyMessagePools[level];
    if (pool == null) return null;
    await ensureLoaded();

    final key = _entryKey(day, level);
    final existing = _state.entries[key];
    if (existing != null) {
      if (!existing.read) {
        _state = _copyWith(
          entries: {
            ..._state.entries,
            key: DailyEnergyInsightEntry(message: existing.message, read: true),
          },
        );
        await _persist();
      }
      return pool[existing.message];
    }

    final decks = {..._state.decks};
    final recent = {..._state.recent};
    final deck = [...?decks[level]];
    if (deck.isEmpty) deck.addAll(_shuffled(recent[level] ?? const []));

    final index = deck.removeAt(0);
    decks[level] = deck;
    final seen = [...?recent[level], index];
    while (seen.length > DailyEnergyInsightState.cooldown) {
      seen.removeAt(0);
    }
    recent[level] = seen;

    _state = _copyWith(
      decks: decks,
      recent: recent,
      entries: _pruned({
        ..._state.entries,
        key: DailyEnergyInsightEntry(message: index, read: true),
      }),
    );
    await _persist();
    return pool[index];
  }

  /// Whether the one-shot discovery orbit should run for [day].
  bool shouldPlayOrbit(String day) => _loaded && _state.orbitDay != day;

  /// Neither of these notifies: they are one screen's chrome, not state the
  /// other screens render, and notifying from a widget's first build would
  /// re-enter setState mid-build.
  Future<void> markOrbitPlayed(String day) async {
    if (_state.orbitDay == day) return;
    _state = _copyWith(orbitDay: day, clearOrbitDay: false);
    await _persist(notify: false);
  }

  Future<void> markCoachMarkShown() async {
    if (_state.coachMarkShown) return;
    _state = _copyWith(coachMarkShown: true);
    await _persist(notify: false);
  }

  Future<void> _persist({bool notify = true}) async {
    if (notify) notifyListeners();
    await store.save(_state);
  }

  /// A fresh deck for one tone, whose opening hand avoids everything in
  /// [recent].
  ///
  /// Bounded by construction: it shuffles once, then swaps at most [cooldown]
  /// cards. With eight messages and a cooldown of three there are always five
  /// free cards behind the opening hand, so the swap cannot fail and there is
  /// no retry loop to run away.
  List<int> _shuffled(List<int> recent) {
    final deck = List<int>.generate(dailyEnergyPoolSize, (i) => i)
      ..shuffle(_random ?? Random());
    final blocked = recent.toSet();
    if (blocked.isEmpty) return deck;

    const cooldown = DailyEnergyInsightState.cooldown;
    for (var i = 0; i < cooldown && i < deck.length; i++) {
      if (!blocked.contains(deck[i])) continue;
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

  /// Keeps the newest assignments. Keys start with a zero-padded date, so
  /// sorting them as text is chronological.
  static Map<String, DailyEnergyInsightEntry> _pruned(
    Map<String, DailyEnergyInsightEntry> entries,
  ) {
    if (entries.length <= DailyEnergyInsightState.maxRememberedEntries) {
      return entries;
    }
    final keys = entries.keys.toList()..sort();
    final keep = keys.sublist(
      keys.length - DailyEnergyInsightState.maxRememberedEntries,
    );
    return {for (final key in keep) key: entries[key]!};
  }

  DailyEnergyInsightState _copyWith({
    Map<String, List<int>>? decks,
    Map<String, List<int>>? recent,
    Map<String, DailyEnergyInsightEntry>? entries,
    String? orbitDay,
    bool clearOrbitDay = false,
    bool? coachMarkShown,
  }) => DailyEnergyInsightState(
    decks: decks ?? _state.decks,
    recent: recent ?? _state.recent,
    entries: entries ?? _state.entries,
    orbitDay: clearOrbitDay ? null : (orbitDay ?? _state.orbitDay),
    coachMarkShown: coachMarkShown ?? _state.coachMarkShown,
  );
}
