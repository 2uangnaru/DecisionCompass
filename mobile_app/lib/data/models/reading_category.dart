import 'json_types.dart';

/// Which part of life a reading is about.
///
/// Wire values match `Category` in `calculation-engine/src/index.d.ts`. The
/// category changes how the engine prepares and fuses module evidence before
/// the decision-mode projection — it is not a label on an otherwise identical
/// reading. The app still never asks *what* the decision is; it only asks which
/// area of life it belongs to.
///
/// [other] deliberately reuses the general formula as an honest fallback, but
/// remains a distinct category value with its own reading snapshot.
enum ReadingCategory {
  general('general'),
  love('love'),
  career('career'),
  money('money'),
  study('study'),
  friends('friends'),
  other('other');

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
