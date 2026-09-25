import 'package:decision_compass/data/models/reading_status.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/result_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each mode gives its two directions distinct, legible tones', () {
    for (final mode in DecisionMode.values) {
      final first = resultPaletteFor(
        mode: mode,
        status: ReadingStatus.ready,
        winner: mode.first,
      );
      final second = resultPaletteFor(
        mode: mode,
        status: ReadingStatus.ready,
        winner: mode.second,
      );

      expect(first.accent, isNot(second.accent), reason: mode.label);
      expect(first.bottom, isNot(second.bottom), reason: mode.label);
      for (final palette in [first, second]) {
        final light = palette.accent.computeLuminance() + 0.05;
        final dark = palette.bottom.computeLuminance() + 0.05;
        expect(light / dark, greaterThan(3), reason: mode.label);
      }
    }
  });

  test('non-binary directions do not inherit the YES/NO caution colours', () {
    final go = resultPaletteFor(
      mode: DecisionMode.stayGo,
      status: ReadingStatus.ready,
      winner: 'GO',
    );
    final right = resultPaletteFor(
      mode: DecisionMode.leftRight,
      status: ReadingStatus.ready,
      winner: 'RIGHT',
    );
    final wait = resultPaletteFor(
      mode: DecisionMode.actWait,
      status: ReadingStatus.ready,
      winner: 'WAIT',
    );
    expect(go.accent, const Color(0xFF75D8C5));
    expect(right.accent, const Color(0xFFE8C979));
    expect(wait.accent, const Color(0xFFE8BE7B));
    for (final palette in [go, right, wait]) {
      expect(palette.accent, isNot(const Color(0xFFD88990)));
    }
  });

  test('YES/NO stays familiar; balanced and unavailable stay neutral', () {
    expect(
      resultPaletteFor(
        mode: DecisionMode.yesNo,
        status: ReadingStatus.ready,
        winner: 'YES',
      ).accent,
      const Color(0xFF62B7E8),
    );
    expect(
      resultPaletteFor(
        mode: DecisionMode.yesNo,
        status: ReadingStatus.ready,
        winner: 'NO',
      ).accent,
      const Color(0xFFD88990),
    );
    final balanced = resultPaletteFor(
      mode: DecisionMode.actWait,
      status: ReadingStatus.balanced,
      winner: null,
    );
    final unavailable = resultPaletteFor(
      mode: DecisionMode.actWait,
      status: ReadingStatus.insufficientData,
      winner: null,
    );
    expect(balanced.bottom, const Color(0xFF272659));
    expect(unavailable.bottom, const Color(0xFF18243C));
  });
}
