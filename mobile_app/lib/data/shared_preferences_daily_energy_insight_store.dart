import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'daily_energy_insight_deck.dart';

/// Persists the Daily Energy insight rotation on-device via
/// `shared_preferences` — the store the profile, history and Home description
/// rotation already use, so no new package.
///
/// Its own key, so a damaged insight record cannot take the Home description
/// deck or the saved profile down with it.
class SharedPreferencesDailyEnergyInsightStore
    implements DailyEnergyInsightStore {
  const SharedPreferencesDailyEnergyInsightStore();

  static const _key = 'daily_energy_insights_v1';

  @override
  Future<void> save(DailyEnergyInsightState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  @override
  Future<DailyEnergyInsightState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return DailyEnergyInsightState.fromJson(jsonDecode(raw));
    } catch (_) {
      // Not JSON at all. Like a rejected record, this starts fresh rather
      // than crashing the card.
      return null;
    }
  }
}
