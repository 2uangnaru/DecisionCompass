import '../app_profile.dart';

/// Abstraction over birth-profile persistence.
///
/// UI pages must never touch a storage plugin directly — they depend on this
/// interface instead, wired in via `ReadingDependencies.profileRepository`.
/// See [InMemoryProfileRepository] in `in_memory_profile_repository.dart` for
/// the test/preview double.
abstract interface class ProfileRepository {
  /// Persists [profile], replacing whatever was saved before.
  Future<void> save(AppProfile profile);

  /// The saved profile, or null when none has been saved yet.
  Future<AppProfile?> load();
}
