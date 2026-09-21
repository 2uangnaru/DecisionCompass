import 'json_types.dart';

/// Birth-data resolution summary. Mirrors the `birthData` object on
/// `ReadingResult` in `calculation-engine/src/index.d.ts`.
class BirthDataStatus {
  BirthDataStatus({
    required this.status,
    required this.timeKnown,
    required this.timezoneSource,
    required List<String> timezoneCandidates,
  }) : timezoneCandidates = List.unmodifiable(timezoneCandidates);

  /// Engine-defined status string, e.g. "exact", "uncertain",
  /// "birth_timezone_unresolved", "birth_time_nonexistent". Kept as a raw
  /// string (not an enum) so a new engine status does not break parsing.
  final String status;

  final bool timeKnown;
  final String timezoneSource;
  final List<String> timezoneCandidates;

  factory BirthDataStatus.fromJson(JsonMap json) {
    const context = 'BirthDataStatus';
    return BirthDataStatus(
      status: requireField<String>(json, 'status', context),
      timeKnown: requireField<bool>(json, 'timeKnown', context),
      timezoneSource: requireField<String>(json, 'timezoneSource', context),
      timezoneCandidates: requireStringList(
        json,
        'timezoneCandidates',
        context,
      ),
    );
  }

  JsonMap toJson() => {
    'status': status,
    'timeKnown': timeKnown,
    'timezoneSource': timezoneSource,
    'timezoneCandidates': timezoneCandidates,
  };
}
