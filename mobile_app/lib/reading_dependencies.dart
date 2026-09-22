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
  });

  final ReadingRepository repository;
  final CurrentContextProvider contextProvider;

  /// Injected so tests can pin the instant a Reveal tap records.
  final DateTime Function() nowUtc;

  static DateTime _systemNowUtc() => DateTime.now().toUtc();
}
