import '../app_profile.dart';
import 'profile_repository.dart';

/// In-memory [ProfileRepository] for tests and widget previews.
class InMemoryProfileRepository implements ProfileRepository {
  AppProfile? _profile;

  @override
  Future<void> save(AppProfile profile) async {
    _profile = profile;
  }

  @override
  Future<AppProfile?> load() async => _profile;
}
