import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../data/models/daily_brief.dart';

/// Returns the signature accent color for each of the 8 daily energy states.
///
/// Follows the approved thermal progression:
/// Hot (low energy) ➔ Warm ➔ Gold ➔ Fresh ➔ Cool ➔ Radiant (high energy).
Color dailyEnergyColor(String? level) => switch (level) {
  'quiet' => const Color(0xFFF43F5E), // 1. Đỏ Mận / San Hô (< 49)
  'soft' => const Color(0xFFEC4899), // 2. Hồng Sen Vũ Trụ (= 49)
  'steady' => const Color(0xFFF97316), // 3. Cam Hổ Phách (50-51)
  'focused' => const Color(0xFFFB923C), // 4. Cam Đào Ấm Áp (Trục a)
  'flowing' => const Color(0xFFEAB308), // 5. Vàng Hoàng Gia (Trục c)
  'lively' => const Color(0xFF06B6D4), // 6. Xanh Cyan Biển Sâu (52-53)
  'bright' => const Color(0xFF0EA5E9), // 7. Xanh Nước Biển (54-57)
  'radiant' => const Color(0xFF34D399), // 8. Xanh Lá Ngọc Lục Bảo (>= 58)
  _ => const Color(0xFF64748B), // Unavailable / fallback
};

/// Computes the left-to-right fill progress (0.0 .. 1.0) for the energy bar.
///
/// Combines the categorical state tier with continuous micro-movements
/// from the internal [energy.index] (10–90) so that higher levels are always
/// longer, yet day-to-day progress coordinates vary organically.
double dailyEnergyProgress(DailyEnergy? energy) {
  if (energy == null || energy.level == 'unavailable') {
    return 0.50;
  }

  final index = energy.index;
  final progress = switch (energy.level) {
    'quiet' => index != null
        ? 0.22 + (((index - 20).clamp(0, 28)) / 28.0) * 0.16
        : 0.30,
    'soft' => 0.45,
    'steady' => (index == 50) ? 0.51 : 0.55,
    'focused' => index != null
        ? 0.56 + (((index - 48).clamp(0, 10)) / 10.0) * 0.04
        : 0.58,
    'flowing' => index != null
        ? 0.61 + (((index - 48).clamp(0, 10)) / 10.0) * 0.04
        : 0.63,
    'lively' => (index == 52) ? 0.68 : 0.72,
    'bright' => index != null
        ? 0.75 + (((index - 54).clamp(0, 3)) / 3.0) * 0.10
        : 0.80,
    'radiant' => index != null
        ? 0.88 + (((index - 58).clamp(0, 15)) / 15.0) * 0.07
        : 0.93,
    _ => 0.50,
  };

  return progress.clamp(0.20, 0.95);
}

/// A horizontal frosted glass capsule displaying the daily energy level.
///
/// Features a dark inner track, a left-to-right glowing beam filled according to
/// [dailyEnergyProgress], and a 4-point celestial star (✦) leading at the right tip.
class DailyEnergyCapsuleBar extends StatelessWidget {
  const DailyEnergyCapsuleBar({
    super.key,
    required this.energy,
    this.width = 64.0,
    this.height = 20.0,
  });

  final DailyEnergy? energy;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = dailyEnergyColor(energy?.level);
    final progress = dailyEnergyProgress(energy);

    return Semantics(
      label: 'Thanh năng lượng',
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _DailyEnergyCapsulePainter(
            color: color,
            progress: progress,
          ),
        ),
      ),
    );
  }
}

class _DailyEnergyCapsulePainter extends CustomPainter {
  const _DailyEnergyCapsulePainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height / 2);
    final outerRRect = RRect.fromRectAndRadius(rect, radius);

    // 1. Frosted glass capsule background
    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.10);
    canvas.drawRRect(outerRRect, bgPaint);

    // 2. Capsule border stroke
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = color.withValues(alpha: 0.35);
    canvas.drawRRect(outerRRect, borderPaint);

    // 3. Dark inner track channel
    const trackInset = 7.5;
    const trackHeight = 3.2;
    final trackWidth = math.max(0.0, size.width - trackInset * 2);
    final trackY = (size.height - trackHeight) / 2;
    final trackRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(trackInset, trackY, trackWidth, trackHeight),
      const Radius.circular(trackHeight / 2),
    );
    final trackPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF23304B);
    canvas.drawRRect(trackRRect, trackPaint);

    // 4. Active filled beam (Left-to-Right)
    final filledWidth = trackWidth * progress;
    final starCx = trackInset + filledWidth;
    final starCy = size.height / 2;

    if (filledWidth > 0) {
      final beamRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(trackInset, trackY, filledWidth, trackHeight),
        const Radius.circular(trackHeight / 2),
      );
      final beamPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0.70),
            color,
          ],
        ).createShader(Rect.fromLTWH(trackInset, trackY, filledWidth, trackHeight));
      canvas.drawRRect(beamRRect, beamPaint);
    }

    // 5. Subtle glow around the star tip
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(Offset(starCx, starCy), 4.0, glowPaint);

    // 6. 4-point Diamond Star ✦ at tip
    const outerR = 4.0;
    const innerR = 1.4;
    final starPath = Path()
      ..moveTo(starCx, starCy - outerR)
      ..lineTo(starCx + innerR, starCy - innerR)
      ..lineTo(starCx + outerR, starCy)
      ..lineTo(starCx + innerR, starCy + innerR)
      ..lineTo(starCx, starCy + outerR)
      ..lineTo(starCx - innerR, starCy + innerR)
      ..lineTo(starCx - outerR, starCy)
      ..lineTo(starCx - innerR, starCy - innerR)
      ..close();

    final starPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas.drawPath(starPath, starPaint);

    // Optional fine outer border for the star
    final starBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = color.withValues(alpha: 0.80);
    canvas.drawPath(starPath, starBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _DailyEnergyCapsulePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}
