import 'package:flutter/material.dart';

import 'data/models/models.dart' as engine;

/// How each wire category is presented to the user.
///
/// Wire values (`general`, `love`, …) never appear in visible UI; only [label]
/// does. Icons support the label, they never carry the meaning alone.
class CategoryChoice {
  const CategoryChoice({
    required this.category,
    required this.label,
    required this.icon,
  });

  final engine.ReadingCategory category;
  final String label;
  final IconData icon;

  /// Stable key for tests and semantics, not shown to the user.
  String get testKey => 'category_${category.wireValue}';
}

const categoryChoices = <CategoryChoice>[
  CategoryChoice(
    category: engine.ReadingCategory.general,
    label: 'Overall',
    icon: Icons.blur_on_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.love,
    label: 'Love & Relationships',
    icon: Icons.favorite_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.career,
    label: 'Career',
    icon: Icons.work_outline_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.money,
    label: 'Money',
    icon: Icons.savings_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.study,
    label: 'Study & Growth',
    icon: Icons.auto_stories_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.friends,
    label: 'Friends',
    icon: Icons.people_alt_rounded,
  ),
  CategoryChoice(
    category: engine.ReadingCategory.other,
    label: 'Something Else',
    icon: Icons.more_horiz_rounded,
  ),
];

/// Presentation for [category]. Throws only if a wire value has no presentation,
/// which would be a programming error rather than bad input.
CategoryChoice categoryChoiceFor(engine.ReadingCategory category) =>
    categoryChoices.firstWhere((choice) => choice.category == category);

String categoryLabel(engine.ReadingCategory category) =>
    categoryChoiceFor(category).label;
