import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'home_description_deck.dart';

/// Persists the Home description rotation on-device via `shared_preferences`,
/// the same store the profile and history already use — no new package.
///
/// The whole record lives under one key so the deck, its progress and the day
/// assignments are always written together.
class SharedPreferencesHomeDescriptionStore implements HomeDescriptionStore {
  const SharedPreferencesHomeDescriptionStore();

  static const _key = 'home_description_deck_v1';

  @override
  Future<void> save(HomeDescriptionDeckState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  @override
  Future<HomeDescriptionDeckState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return HomeDescriptionDeckState.fromJson(jsonDecode(raw));
    } catch (_) {
      // Not JSON at all. Like a rejected record, this starts a fresh deck
      // rather than crashing the screen.
      return null;
    }
  }
}
