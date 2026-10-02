import 'package:decision_compass/data/models/daily_brief.dart';
import 'package:decision_compass/widgets/daily_energy_capsule_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dailyEnergyColor', () {
    test('maps all 8 approved levels to distinct colors', () {
      final levels = [
        'quiet',
        'soft',
        'steady',
        'focused',
        'flowing',
        'lively',
        'bright',
        'radiant',
      ];

      final colors = levels.map(dailyEnergyColor).toList();

      expect(colors[0], const Color(0xFFF43F5E)); // quiet: Red
      expect(colors[1], const Color(0xFFEC4899)); // soft: Pink
      expect(colors[2], const Color(0xFFF97316)); // steady: Amber orange
      expect(colors[3], const Color(0xFFFB923C)); // focused: Peach orange
      expect(colors[4], const Color(0xFFEAB308)); // flowing: Royal gold
      expect(colors[5], const Color(0xFF06B6D4)); // lively: Cyan
      expect(colors[6], const Color(0xFF0EA5E9)); // bright: Ocean blue
      expect(colors[7], const Color(0xFF34D399)); // radiant: Green

      // Ensure all 8 colors are unique
      expect(colors.toSet().length, 8);
    });

    test('falls back safely on null or unavailable', () {
      expect(dailyEnergyColor(null), const Color(0xFF64748B));
      expect(dailyEnergyColor('unavailable'), const Color(0xFF64748B));
      expect(dailyEnergyColor('unknown'), const Color(0xFF64748B));
    });
  });

  group('dailyEnergyProgress', () {
    test('strictly preserves energy level hierarchy', () {
      final quiet = dailyEnergyProgress(const DailyEnergy(level: 'quiet', index: 40, dataCoverage: 1));
      final soft = dailyEnergyProgress(const DailyEnergy(level: 'soft', index: 49, dataCoverage: 1));
      final steady = dailyEnergyProgress(const DailyEnergy(level: 'steady', index: 51, dataCoverage: 1));
      final focused = dailyEnergyProgress(const DailyEnergy(level: 'focused', index: 52, dataCoverage: 1));
      final flowing = dailyEnergyProgress(const DailyEnergy(level: 'flowing', index: 53, dataCoverage: 1));
      final lively = dailyEnergyProgress(const DailyEnergy(level: 'lively', index: 53, dataCoverage: 1));
      final bright = dailyEnergyProgress(const DailyEnergy(level: 'bright', index: 56, dataCoverage: 1));
      final radiant = dailyEnergyProgress(const DailyEnergy(level: 'radiant', index: 70, dataCoverage: 1));

      expect(quiet < soft, isTrue);
      expect(soft < steady, isTrue);
      expect(steady < focused, isTrue);
      expect(focused < flowing, isTrue);
      expect(flowing < lively, isTrue);
      expect(lively < bright, isTrue);
      expect(bright < radiant, isTrue);
    });

    test('continuous micro-progress changes within level to avoid duplicate days', () {
      final bright54 = dailyEnergyProgress(const DailyEnergy(level: 'bright', index: 54, dataCoverage: 1));
      final bright57 = dailyEnergyProgress(const DailyEnergy(level: 'bright', index: 57, dataCoverage: 1));
      expect(bright54 < bright57, isTrue);

      final quiet30 = dailyEnergyProgress(const DailyEnergy(level: 'quiet', index: 30, dataCoverage: 1));
      final quiet45 = dailyEnergyProgress(const DailyEnergy(level: 'quiet', index: 45, dataCoverage: 1));
      expect(quiet30 < quiet45, isTrue);
    });

    test('clamps within safe display range [0.20, 0.95]', () {
      final low = dailyEnergyProgress(const DailyEnergy(level: 'quiet', index: 10, dataCoverage: 1));
      final high = dailyEnergyProgress(const DailyEnergy(level: 'radiant', index: 90, dataCoverage: 1));
      expect(low >= 0.20, isTrue);
      expect(high <= 0.95, isTrue);
    });
  });

  group('DailyEnergyCapsuleBar widget', () {
    testWidgets('renders properly with custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DailyEnergyCapsuleBar(
              energy: DailyEnergy(level: 'steady', index: 51, dataCoverage: 1),
              width: 70,
              height: 22,
            ),
          ),
        ),
      );

      expect(find.byType(DailyEnergyCapsuleBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DailyEnergyCapsuleBar),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });
  });
}
