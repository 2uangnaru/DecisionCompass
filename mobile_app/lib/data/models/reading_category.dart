import 'json_types.dart';

/// Reading category.
///
/// `calculation-engine/src/index.d.ts` types this as the literal `'general'`,
/// and the engine rejects anything else with `MVP_CATEGORY_IS_GENERAL`. The app
/// never asks what the decision is about, so [general] is the only legal value;
/// modelling it as an enum makes an illegal category unrepresentable in Dart
/// and a typed parse failure on the wire.
enum ReadingCategory {
  general('general');

  const ReadingCategory(this.wireValue);

  final String wireValue;

  static ReadingCategory fromWire(
    String value, {
    String context = 'ReadingCategory',
  }) {
    for (final category in ReadingCategory.values) {
      if (category.wireValue == value) return category;
    }
    throw ReadingDtoException('Unknown $context value "$value"');
  }

  String toJson() => wireValue;
}
