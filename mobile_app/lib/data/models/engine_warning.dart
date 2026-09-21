import 'json_types.dart';

/// A single machine-readable warning code from the engine, e.g.
/// "unknown_birth_time" or "location_timezone_ambiguous_using_device".
///
/// `calculation-engine/src/index.d.ts` types `warnings` as a plain
/// `string[]`. This wraps each entry so a future engine version can add
/// structure (e.g. a human-readable `message`) without changing this DTO's
/// shape or breaking existing callers; today [fromJson] simply accepts a
/// bare string.
class EngineWarning {
  const EngineWarning({required this.code, this.message});

  final String code;
  final String? message;

  factory EngineWarning.fromJson(
    Object? json, {
    String context = 'EngineWarning',
  }) {
    if (json is String) return EngineWarning(code: json);
    if (json is JsonMap) {
      return EngineWarning(
        code: requireField<String>(json, 'code', context),
        message: optionalField<String>(json, 'message', context),
      );
    }
    throw ReadingDtoException(
      'Field "warnings[]" in $context expected a String or object but got '
      '${json.runtimeType}',
    );
  }

  /// Serializes back to the current wire format: a bare string when there is
  /// no extra message, matching what the engine sends today.
  Object toJson() =>
      message == null ? code : {'code': code, 'message': message};

  @override
  String toString() => code;

  @override
  bool operator ==(Object other) =>
      other is EngineWarning && other.code == code && other.message == message;

  @override
  int get hashCode => Object.hash(code, message);
}
