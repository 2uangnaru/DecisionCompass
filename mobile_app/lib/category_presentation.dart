import 'package:flutter/material.dart';

import 'data/models/models.dart' as engine;

/// How each wire category is presented to the user.
///
/// Wire values (`general`, `love`, …) never appear in visible UI, and neither
/// does an English label: the words come from `localized_presentation.dart`'s
/// `categoryLabel`, so the same chip reads correctly in every language while
/// the value the engine receives is unchanged. Icons support the label, they
/// never carry the meaning alone.
class CategoryChoice {
  const CategoryChoice({required this.category, required this.icon});

  final engine.ReadingCategory category;
  final IconData icon;

  /// Stable key for tests and semantics, not shown to the user.
  String get testKey => 'category_${category.wireValue}';
}

const categoryChoices = <CategoryChoice>[
  CategoryChoice(
    category: engine.ReadingCategory.general,
    icon: Icons.blur_on_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.love,
    icon: Icons.favorite_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.career,
    icon: Icons.work_outline_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.money,
    icon: Icons.savings_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.study,
    icon: Icons.auto_stories_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.friends,
    icon: Icons.people_alt_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.other,
    icon: Icons.more_horiz_rounded,
  ),
];

/// Presentation for [category]. Throws only if a wire value has no presentation,
/// which would be a programming error rather than bad input.
CategoryChoice categoryChoiceFor(engine.ReadingCategory category) =>
    categoryChoices.firstWhere((choice) => choice.category == category);
