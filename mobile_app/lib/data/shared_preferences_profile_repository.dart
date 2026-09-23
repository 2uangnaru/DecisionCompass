import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../app_profile.dart';
import 'profile_repository.dart';

/// Persists the birth profile on-device via `shared_preferences`, so
/// restarting the app returns to Home instead of onboarding.
class SharedPreferencesProfileRepository implements ProfileRepository {
  const SharedPreferencesProfileRepository();

  static const _key = 'app_profile_v1';

  @override
  Future<void> save(AppProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  @override
  Future<AppProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return AppProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt or outdated local data degrades to onboarding, never a crash.
      return null;
    }
  }
}
