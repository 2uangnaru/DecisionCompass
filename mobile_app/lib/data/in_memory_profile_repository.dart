import '../app_profile.dart';
import 'profile_repository.dart';

/// In-memory [ProfileRepository] for tests and widget previews.
class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository({this.failSaves = false});

  AppProfile? _profile;

  /// When true, [save] throws the way a full or locked store would. Onboarding
  /// has to survive that without losing the form or changing the language.
  bool failSaves;

  /// Every save attempt that succeeded, so a test can tell one write from two.
  var saves = 0;

  @override
  Future<void> save(AppProfile profile) async {
    if (failSaves) throw StateError('the profile could not be written');
    saves++;
    _profile = profile;
  }

  @override
  Future<AppProfile?> load() async => _profile;
}
