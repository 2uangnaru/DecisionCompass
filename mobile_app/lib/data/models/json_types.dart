/// Shared JSON parsing helpers for the calculation-engine DTOs.
///
/// These mirror `calculation-engine/src/index.d.ts` field-by-field: a `?`
/// property in the TypeScript contract is "absent is allowed" (see
/// [optionalField]); a required property typed `T | null` is "the key must
/// exist but its value may be null" (see [requireNullableField]). Mixing the
/// two up is exactly how a real status like `period_elapsed` (which omits
/// `dataCoverage` entirely) would get misread as a parse failure.
library;

/// A JSON object as decoded by `dart:convert`.
typedef JsonMap = Map<String, dynamic>;

/// Thrown when a payload from the calculation engine does not match the
/// integration contract in `calculation-engine/src/index.d.ts`.
///
/// This signals a contract/parsing problem, not a reading outcome — a real
/// `insufficient_data` or `period_elapsed` result parses cleanly and never
/// throws this.
class ReadingDtoException implements Exception {
  const ReadingDtoException(this.message);

  final String message;

  @override
  String toString() => 'ReadingDtoException: $message';
}

/// Reads a required, non-null field of type [T]. Throws [ReadingDtoException]
/// when the key is missing, its value is null, or the value has the wrong
/// type.
T requireField<T>(JsonMap json, String key, String context) {
  if (!json.containsKey(key) || json[key] == null) {
    throw ReadingDtoException('Missing required field "$key" in $context');
  }
  final value = json[key];
  if (value is! T) {
    throw ReadingDtoException(
      'Field "$key" in $context expected $T but got ${value.runtimeType}',
    );
  }
  return value;
}

/// Reads a required field whose key must be present but whose value may be
/// `null` (a TypeScript `field: T | null`, e.g. `winner` or `percentages`).
/// Throws when the key itself is missing, or present with the wrong type.
T? requireNullableField<T>(JsonMap json, String key, String context) {
  if (!json.containsKey(key)) {
    throw ReadingDtoException('Missing required field "$key" in $context');
  }
  final value = json[key];
  if (value == null) return null;
  if (value is! T) {
    throw ReadingDtoException(
      'Field "$key" in $context expected $T but got ${value.runtimeType}',
    );
  }
  return value;
}

/// Reads an optional field (a TypeScript `field?: T`): returns null when the
/// key is absent or explicitly null. Throws when present with the wrong
/// type.
T? optionalField<T>(JsonMap json, String key, String context) {
  if (!json.containsKey(key) || json[key] == null) return null;
  final value = json[key];
  if (value is! T) {
    throw ReadingDtoException(
      'Field "$key" in $context expected $T but got ${value.runtimeType}',
    );
  }
  return value;
}

int requireInt(JsonMap json, String key, String context) {
  return requireField<num>(json, key, context).toInt();
}

int? optionalInt(JsonMap json, String key, String context) {
  return optionalField<num>(json, key, context)?.toInt();
}

double requireDouble(JsonMap json, String key, String context) {
  return requireField<num>(json, key, context).toDouble();
}

double? optionalDouble(JsonMap json, String key, String context) {
  return optionalField<num>(json, key, context)?.toDouble();
}

double? requireNullableDouble(JsonMap json, String key, String context) {
  return requireNullableField<num>(json, key, context)?.toDouble();
}

/// Recursively wraps maps and lists in unmodifiable views.
///
/// Shallow `Map.unmodifiable` still hands out mutable nested collections, which
/// would let a caller edit a parsed reading through e.g.
/// `inputSnapshot.raw['profile']`.
Object? deepUnmodifiable(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable({
      for (final entry in value.entries)
        entry.key.toString(): deepUnmodifiable(entry.value),
    });
  }
  if (value is List) {
    return List<dynamic>.unmodifiable(value.map(deepUnmodifiable));
  }
  return value;
}

JsonMap deepUnmodifiableMap(JsonMap value) =>
    deepUnmodifiable(value)! as JsonMap;

List<String> requireStringList(JsonMap json, String key, String context) {
  final value = requireField<List<dynamic>>(json, key, context);
  return List.unmodifiable(
    value.map((entry) {
      if (entry is! String) {
        throw ReadingDtoException(
          'Field "$key" in $context expected a list of String but found '
          '${entry.runtimeType}',
        );
      }
      return entry;
    }),
  );
}
