import 'data/current_context_provider.dart';
import 'data/reading_repository.dart';

/// Everything the reading flow needs from outside the widget tree, passed down
/// by constructor so no page ever builds an HTTP client or touches a plugin
/// directly.
class ReadingDependencies {
  const ReadingDependencies({
    required this.repository,
    required this.contextProvider,
    this.nowUtc = _systemNowUtc,
    this.nowLocal = _systemNowLocal,
  });

  final ReadingRepository repository;
  final CurrentContextProvider contextProvider;

  /// Injected so tests can pin the instant a Reveal tap records.
  final DateTime Function() nowUtc;

  /// The device's wall clock, used only to mute time periods that are already
  /// over. It is separate from [nowUtc] so tests can pin an hour of the day
  /// without depending on the host machine's timezone.
  final DateTime Function() nowLocal;

  static DateTime _systemNowUtc() => DateTime.now().toUtc();

  static DateTime _systemNowLocal() => DateTime.now();
}
