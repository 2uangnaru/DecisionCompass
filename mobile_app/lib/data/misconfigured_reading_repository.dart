import 'models/models.dart';
import 'reading_api_exception.dart';
import 'reading_repository.dart';

/// Stands in for the real repository when the build has no usable
/// `DECISION_API_BASE_URL`.
///
/// A missing define is a build mistake, not a reason to crash on launch or to
/// quietly invent readings. The app starts normally and the configuration
/// failure surfaces in the reading flow's own error state.
class MisconfiguredReadingRepository implements ReadingRepository {
  const MisconfiguredReadingRepository(this.failure);

  final ReadingApiException failure;

  @override
  Future<ReadingResponse> calculate(ReadingRequest request) async =>
      throw failure;
}
