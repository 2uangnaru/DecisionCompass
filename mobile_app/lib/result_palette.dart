import 'package:flutter/material.dart';

import 'data/models/reading_status.dart';
import 'models.dart';
import 'theme.dart';

/// Presentation only. Neither the selected direction nor these colours imply
/// that one side is safer, better, or more likely to succeed.
class ResultPalette {
  const ResultPalette({
    required this.accent,
    required this.top,
    required this.bottom,
  });

  final Color accent;
  final Color top;
  final Color bottom;
}

const _balanced = ResultPalette(
  accent: Color(0xFFB8A9F2),
  top: Color(0xFF101429),
  bottom: Color(0xFF272659),
);

const _neutral = ResultPalette(
  accent: CompassColors.secondary,
  top: CompassColors.deep,
  bottom: Color(0xFF18243C),
);

/// The pair-specific accents follow the UX spec's mode table. The gradient is
/// derived from the winning accent so every mode keeps the same visual weight.
ResultPalette resultPaletteFor({
  required DecisionMode mode,
  required ReadingStatus status,
  required String? winner,
}) {
  if (status == ReadingStatus.balanced) return _balanced;
  if (status != ReadingStatus.ready || winner == null) return _neutral;
  if (winner != mode.first && winner != mode.second) return _neutral;

  final first = winner == mode.first;
  if (mode == DecisionMode.yesNo) {
    return first
        ? const ResultPalette(
            accent: CompassColors.blueLight,
            top: Color(0xFF071729),
            bottom: Color(0xFF103B68),
          )
        : const ResultPalette(
            accent: Color(0xFFD88990),
            top: Color(0xFF1A1018),
            bottom: Color(0xFF552D36),
          );
  }

  final accent = switch (mode) {
    DecisionMode.yesNo => throw StateError('Handled above'),
    DecisionMode.actWait =>
      first ? const Color(0xFF6BCDBF) : const Color(0xFFE8BE7B),
    DecisionMode.advanceRetreat =>
      first ? const Color(0xFF82BCEF) : const Color(0xFFC6A7D2),
    DecisionMode.stayGo =>
      first ? const Color(0xFFADAEF0) : const Color(0xFF75D8C5),
    DecisionMode.keepLetGo =>
      first ? const Color(0xFF84B6E8) : const Color(0xFFE7A5A4),
    DecisionMode.forwardBackward =>
      first ? const Color(0xFF7ABEEB) : const Color(0xFFB9A8E5),
    DecisionMode.leftRight =>
      first ? const Color(0xFFB6CCEA) : const Color(0xFFE8C979),
  };
  return ResultPalette(
    accent: accent,
    top: Color.lerp(CompassColors.deep, accent, 0.08)!,
    bottom: Color.lerp(const Color(0xFF18243C), accent, 0.22)!,
  );
}
