import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../app_profile.dart';
import '../data/reading_quota_controller.dart';
import '../localized_presentation.dart';
import '../theme.dart';

/// Snapshot of the reader's daily Free reading turns (3/day, 3h cooldown)
/// paired with the +3 AstraCue Plus instant turns preview.
///
/// Computed from [ReadingQuotaController] and [nowLocal] so `HomePage`,
/// `RitualPage`, and `ResultPage` always render the exact same orb count and
/// cooldown countdown.
/// Represents a personalized 2-hour celestial window for a profile on a given day.
class AuspiciousWindowResult {
  const AuspiciousWindowResult({
    required this.windowText,
    required this.noteText,
  });

  final String windowText;
  final String noteText;
}

/// Resolves the optimal 2-hour auspicious window (Giờ hoàng đạo / Cosmic window)
/// tailored to [profile]'s natal anchor and [nowLocal] date across all 8 locales.
AuspiciousWindowResult resolvePersonalizedAuspiciousWindow({
  required AppProfile profile,
  required DateTime nowLocal,
  required AppLocale locale,
}) {
  int birthHour = 12;
  final rawTime = profile.birthTime;
  if (rawTime != null) {
    final parts = rawTime.split(':');
    if (parts.isNotEmpty) {
      birthHour = int.tryParse(parts[0]) ?? 12;
    }
  }
  final int birthHash = profile.birthDate.year * 10000 +
      profile.birthDate.month * 100 +
      profile.birthDate.day +
      birthHour;
  final int dayHash = nowLocal.year * 365 + nowLocal.month * 31 + nowLocal.day;
  final int slot = ((birthHash ^ dayHash).abs()) % 6;

  final windowText = switch (slot) {
    0 => '07:00 — 09:00',
    1 => '09:00 — 11:00',
    2 => '11:00 — 13:00',
    3 => '13:00 — 15:00',
    4 => '15:00 — 17:00',
    _ => '17:00 — 19:00',
  };

  final noteText = switch (locale) {
    AppLocale.vietnamese => switch (slot) {
        0 => 'Giờ Thìn · Thiên thời đắc lợi',
        1 => 'Giờ Tỵ · Cát khí hanh thông',
        2 => 'Giờ Ngọ · Dương khí cực thịnh',
        3 => 'Giờ Mùi · Cát khí đỉnh cao',
        4 => 'Giờ Thân · Thời vận tương sinh',
        _ => 'Giờ Dậu · Vượng khí bản mệnh',
      },
    AppLocale.english => switch (slot) {
        0 => 'Optimal cosmic focus',
        1 => 'Peak transit alignment',
        2 => 'Harmonic solar resonance',
        3 => 'Peak natal alignment',
        4 => 'High celestial clarity',
        _ => 'Favorable astral flow',
      },
    AppLocale.spanish => switch (slot) {
        0 => 'Enfoque cósmico óptimo',
        1 => 'Alineación de tránsito cumbre',
        2 => 'Resonancia solar armónica',
        3 => 'Máxima resonancia natal',
        4 => 'Alta claridad celeste',
        _ => 'Flujo astral favorable',
      },
    AppLocale.simplifiedChinese => switch (slot) {
        0 => '辰时 · 龙德显曜',
        1 => '巳时 · 吉星高照',
        2 => '午时 · 阳和启泰',
        3 => '未时 · 气运通达',
        4 => '申时 · 金水相生',
        _ => '酉时 · 旺气聚临',
      },
    AppLocale.japanese => switch (slot) {
        0 => '辰の刻 · 貴人相助の刻',
        1 => '巳の刻 · 万事吉祥の刻',
        2 => '午の刻 · 陽気極盛の刻',
        3 => '未の刻 · 命盤調和の刻',
        4 => '申の刻 · 生気充溢の刻',
        _ => '酉の刻 · 金気聚積の刻',
      },
    AppLocale.korean => switch (slot) {
        0 => '진시(辰時) · 귀인 상조 시간대',
        1 => '사시(巳時) · 매사 길상 시간대',
        2 => '오시(午時) · 양기 극성 시간대',
        3 => '미시(未時) · 명식 조화 시간대',
        4 => '신시(申時) · 생기 충일 시간대',
        _ => '유시(酉時) · 왕기 집중 시간대',
      },
    AppLocale.thai => switch (slot) {
        0 => 'ช่วงเวลาราชาโชค',
        1 => 'ช่วงเวลาพลังมงคลสูงสุด',
        2 => 'ช่วงเวลาธาตุเสริมเกื้อหนุน',
        3 => 'ช่วงเวลาพลังงานดวงชะตาสูงสุด',
        4 => 'ช่วงเวลาฤกษ์มังกรทอง',
        _ => 'ช่วงเวลาเปิดรับโชคลาภ',
      },
    AppLocale.hindi => switch (slot) {
        0 => 'शुभ मुहूर्त व उत्तम काल',
        1 => 'सर्वोत्तम ग्रह संरेखण काल',
        2 => 'शुभ योग व अनुकूल ऊर्जा',
        3 => 'कुंडली के लिए सर्वोत्तम समय',
        4 => 'दिव्य चेतना व समृद्धि काल',
        _ => 'सकारात्मक ऊर्जा का शिखर काल',
      },
  };

  return AuspiciousWindowResult(windowText: windowText, noteText: noteText);
}

class ReadingEnergySnapshot {
  const ReadingEnergySnapshot({
    required this.usedFreeTurns,
    required this.remainingFreeTurns,
    required this.cooldownRemaining,
    required this.timeUntilMidnight,
    this.bonusTurns = 0,
    this.isPlusActive = false,
    this.plusRemainingTurns = 6,
    this.auspiciousHourWindow,
    this.auspiciousHourNote,
  });

  static const int freeDailyMax = 3;
  static const int plusBonusMax = 3;
  static const int plusDailyMax = 6;
  static const Duration freeCooldown = Duration(hours: 3);

  /// Free turns already consumed on the current local calendar day (`0..3`).
  final int usedFreeTurns;

  /// Free turns still available on the current local calendar day (`0..3`).
  final int remainingFreeTurns;

  /// Remaining wait before the next Free turn is ready, when at least one turn
  /// was used today and at least one Free turn remains. `Duration.zero` when
  /// ready immediately or when all 3 Free turns are spent.
  final Duration cooldownRemaining;

  /// Time remaining until `00:00` local midnight when daily turns reset.
  final Duration timeUntilMidnight;

  /// Extra bonus turns earned via rewarded ads.
  final int bonusTurns;

  /// Whether the reader has unlocked AstraCue Plus (VIP Pass) lifetime or active entitlement.
  final bool isPlusActive;

  /// Remaining VIP reading turns for today (`0..6`). Defaults to 6 when active.
  final int plusRemainingTurns;

  /// Calculated 2-hour auspicious window for today (e.g. `13:00 — 15:00`).
  /// If null, localized default from [_PlusLocalizedCopy] is displayed.
  final String? auspiciousHourWindow;

  /// Optional astrological note for the auspicious hour (e.g. `Khung giờ cát khí đỉnh cao`).
  final String? auspiciousHourNote;

  /// Whether the reader is currently in the 3-hour cooldown between Free turns.
  bool get isCoolingDown =>
      remainingFreeTurns > 0 && cooldownRemaining > Duration.zero;

  /// Whether all 3 daily Free turns have been used today.
  bool get isDailyFreeExhausted => remainingFreeTurns <= 0;

  /// The 1-indexed turn number the reader is about to use on `RitualPage`
  /// (`1`, `2`, or `3`), or `3` when all Free turns are spent.
  int get activeTurnNumber => (usedFreeTurns + 1).clamp(1, freeDailyMax);

  static const ReadingEnergySnapshot initial = ReadingEnergySnapshot(
    usedFreeTurns: 0,
    remainingFreeTurns: freeDailyMax,
    cooldownRemaining: Duration.zero,
    timeUntilMidnight: Duration(hours: 6),
    isPlusActive: false,
    plusRemainingTurns: plusDailyMax,
  );

  /// Resolves the live energy snapshot directly from [ReadingQuotaController],
  /// matching the exact state shown by `RitualPage`'s orb and lock rules.
  static ReadingEnergySnapshot fromQuota({
    required ReadingQuotaController quota,
    required DateTime nowLocal,
    bool? isCooldownOverride,
    bool? isQuotaExhaustedOverride,
    bool? isPlusActiveOverride,
    int? plusRemainingTurnsOverride,
    String? auspiciousHourWindowOverride,
    String? auspiciousHourNoteOverride,
  }) {
    final maxFree = quota.maxDailyFreeReadings;
    final exhausted =
        isQuotaExhaustedOverride ??
        (quota.bonusReadings == 0 &&
            quota.dailyFreeReadingsUsed(nowLocal) >= maxFree);
    var used = exhausted
        ? maxFree
        : quota.dailyFreeReadingsUsed(nowLocal).clamp(0, maxFree);
    final inCooldown =
        isCooldownOverride ?? (!exhausted && quota.isCooldown(nowLocal));
    if (inCooldown && used == 0) {
      used = 1;
    }
    final remaining = (maxFree - used).clamp(0, maxFree);

    final nextMidnight = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day + 1,
    );
    final untilMidnight = nextMidnight.difference(nowLocal);
    final safeUntilMidnight = untilMidnight.isNegative
        ? Duration.zero
        : untilMidnight;

    Duration cooldownRem = Duration.zero;
    if (inCooldown && remaining > 0) {
      final rawCooldown = quota.remainingFreeEnergyCooldown(nowLocal);
      cooldownRem = rawCooldown > Duration.zero ? rawCooldown : freeCooldown;
    }

    final isPlus =
        isPlusActiveOverride ?? (quota.maxDailyFreeReadings > freeDailyMax);

    return ReadingEnergySnapshot(
      usedFreeTurns: used,
      remainingFreeTurns: remaining,
      cooldownRemaining: cooldownRem,
      timeUntilMidnight: safeUntilMidnight,
      bonusTurns: quota.bonusReadings,
      isPlusActive: isPlus,
      plusRemainingTurns:
          plusRemainingTurnsOverride ?? (isPlus ? remaining : plusDailyMax),
      auspiciousHourWindow: auspiciousHourWindowOverride,
      auspiciousHourNote: auspiciousHourNoteOverride,
    );
  }
}

/// Renders 6 glowing golden orbs for VIP Pass holders with active vs spent styling.
class AstralVipGoldOrbsRow extends StatelessWidget {
  const AstralVipGoldOrbsRow({
    super.key,
    required this.remainingTurns,
    this.totalTurns = ReadingEnergySnapshot.plusDailyMax,
    this.orbSize = 8.5,
  });

  final int remainingTurns;
  final int totalTurns;
  final double orbSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalTurns, (index) {
        final isActive = index < remainingTurns;
        return Padding(
          padding: EdgeInsets.only(right: index == totalTurns - 1 ? 0 : 3.0),
          child: isActive
              ? _GoldPlusOrb(size: orbSize)
              : Container(
                  width: orbSize,
                  height: orbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1710),
                    border: Border.all(
                      color: const Color(0xFF6B5322).withValues(alpha: 0.65),
                      width: 0.75,
                    ),
                  ),
                ),
        );
      }),
    );
  }
}

/// Formats a [Duration] as `HH:MM:SS` with localized digits when appropriate.
String formatEnergyCountdown(BuildContext context, Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 86399);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final localeName = intlLocaleOf(context);
  String twoDigits(int n) {
    final raw = formatWholeNumber(localeName, n);
    return n < 10 ? '${formatWholeNumber(localeName, 0)}$raw' : raw;
  }

  return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
}

/// Spot 1 on `HomePage`: Luxury animated **`✦ PLUS`** gem badge (`H3` Sparkling
/// Starlight Gem combined with `H1` Orbiting Conic Starlight Border Beam and
/// periodic metallic shimmer sweep).
class AstraCuePlusHeaderBadge extends StatefulWidget {
  const AstraCuePlusHeaderBadge({
    super.key,
    required this.onTap,
    this.isVip = false,
  });

  final VoidCallback onTap;
  final bool isVip;

  @override
  State<AstraCuePlusHeaderBadge> createState() =>
      _AstraCuePlusHeaderBadgeState();
}

class _AstraCuePlusHeaderBadgeState extends State<AstraCuePlusHeaderBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.22;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _PlusLocalizedCopy.of(
      Localizations.localeOf(context).languageCode,
    );
    final badgeLabel = widget.isVip ? copy.vipHeaderBadge : 'PLUS';
    final semanticsLabel =
        widget.isVip ? copy.vipSemanticsLabel : copy.headerSemanticsLabel;

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        key: const Key('home_plus_button'),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final angle = t * 2 * math.pi;
            final breath = 0.5 + 0.5 * math.sin(angle);

            // Out-of-phase twinkling stars around the gem corners (H3)
            final twinkle1 = (0.5 + 0.5 * math.sin(angle)).clamp(0.12, 1.0);
            final twinkle2 = (0.5 + 0.5 * math.sin(angle + 2.2)).clamp(
              0.12,
              1.0,
            );
            final twinkle3 = (0.5 + 0.5 * math.sin(angle + 4.3)).clamp(
              0.10,
              1.0,
            );

            // Shimmer sweep position (-1.4 .. 2.2) across the gem surface
            final shimmerPos = -1.4 + (t * 3.6);

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Outer breathing golden aura + Orbiting Starlight Border (H1)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: CompassColors.gold.withValues(
                          alpha: 0.24 + 0.26 * breath,
                        ),
                        blurRadius: 10 + 8 * breath,
                        spreadRadius: 0.4 + 0.8 * breath,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    foregroundPainter: _OrbitingGoldBorderPainter(
                      progress: t,
                      radius: 999,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Stack(
                        children: [
                          // Deep amber-gold jewel core (H3)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11.5,
                              vertical: 6.5,
                            ),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF281D0E),
                                  Color(0xFF422F15),
                                  Color(0xFF21170B),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.scale(
                                  scale: 0.90 + 0.22 * breath,
                                  child: Transform.rotate(
                                    angle: 0.22 * math.sin(angle),
                                    child: Text(
                                      widget.isVip ? '👑' : '✦',
                                      style: TextStyle(
                                        fontSize: widget.isVip ? 11.0 : 11.5,
                                        height: 1.0,
                                        color: const Color(0xFFFFE8A3),
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFFFFF2C2)
                                                .withValues(
                                                  alpha: 0.55 + 0.4 * breath,
                                                ),
                                            blurRadius: 6 + 4 * breath,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4.5),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          Color(0xFFFFF9E2),
                                          Color(0xFFF0CF82),
                                          Color(0xFFC99A3E),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ).createShader(bounds),
                                  blendMode: BlendMode.srcIn,
                                  child: Text(
                                    badgeLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.25,
                                      height: 1.05,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Diagonal metallic light sweep
                          Positioned.fill(
                            child: IgnorePointer(
                              child: FractionalTranslation(
                                translation: Offset(shimmerPos, 0),
                                child: Transform.rotate(
                                  angle: -0.38,
                                  child: Container(
                                    width: 22,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          const Color(0xFFFFF4D0)
                                              .withValues(alpha: 0.38),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top-left twinkling corner star (H3)
                Positioned(
                  top: -4.5,
                  left: -2.5,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: twinkle1,
                      child: Transform.scale(
                        scale: 0.65 + 0.60 * twinkle1,
                        child: Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 9.5,
                            height: 1.0,
                            color: const Color(0xFFFFE8A3),
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFFE8A3)
                                    .withValues(alpha: 0.85),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom-right twinkling corner star (H3)
                Positioned(
                  bottom: -4.5,
                  right: -2.0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: twinkle2,
                      child: Transform.scale(
                        scale: 0.60 + 0.65 * twinkle2,
                        child: Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 9.0,
                            height: 1.0,
                            color: const Color(0xFFFFE8A3),
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFFE8A3)
                                    .withValues(alpha: 0.85),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Top-right micro stardust spark (H3)
                Positioned(
                  top: -3.0,
                  right: 8.0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: twinkle3,
                      child: Transform.scale(
                        scale: 0.55 + 0.55 * twinkle3,
                        child: const Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 8.5,
                            height: 1.0,
                            color: Color(0xFFFFE8A3),
                            shadows: [
                              Shadow(color: Color(0xFFFFE8A3), blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Paints the base golden rim and the orbiting starlight comet beam (`H1`).
class _OrbitingGoldBorderPainter extends CustomPainter {
  const _OrbitingGoldBorderPainter({
    required this.progress,
    required this.radius,
  });

  final double progress;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(radius),
    );

    // Base warm gold border
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..color = CompassColors.gold.withValues(alpha: 0.42);
    canvas.drawRRect(rrect, basePaint);

    final w = size.width;
    final h = size.height;
    final double targetAngle;
    if (w > 0 && h > 0) {
      // Map progress uniformly along the perimeter so the starlight beam travels
      // at a constant, calm linear speed instead of warping/accelerating across long edges.
      final perimeter = 2 * (w + h);
      final d = (progress % 1.0) * perimeter;
      final double px;
      final double py;
      if (d < w) {
        px = d;
        py = 0;
      } else if (d < w + h) {
        px = w;
        py = d - w;
      } else if (d < 2 * w + h) {
        px = w - (d - (w + h));
        py = h;
      } else {
        px = 0;
        py = h - (d - (2 * w + h));
      }
      targetAngle = math.atan2(py - h / 2, px - w / 2);
    } else {
      targetAngle = progress * 2 * math.pi;
    }

    // Orbiting starlight comet sweep
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          CompassColors.gold.withValues(alpha: 0.55),
          const Color(0xFFF6DC93),
          const Color(0xFFFFFDF2),
          CompassColors.gold,
        ],
        stops: const [0.0, 0.52, 0.70, 0.86, 0.94, 1.0],
        transform: GradientRotation(targetAngle),
      ).createShader(rect);
    canvas.drawRRect(rrect, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitingGoldBorderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.radius != radius;
}

/// Spot 2 on `HomePage` (`T3 · 2 Ô Đôi Cân Xứng`):
/// Embedded at the bottom of `_dailySignals`, separated by a golden hairline
/// divider, with two symmetrical cells aligned directly beneath the two
/// `_TodaySignalTile`s (*Màu sắc hôm nay* & *Con số hôm nay*).
///
/// - Left cell: Current Free turns (`3 cyan orbs`) + live turn count &
///   cooldown countdown (`Còn 3/3 lượt` or `2/3 · ⏱ 02:59:41` — never shows
///   "Cách nhau 3h").
/// - Right cell: Luxury gold Plus cell (`✦ PLUS` + `3 gold orbs` +
///   `6 lượt · Tắt Ads ›`).
class HomeEmbeddedEnergyTray extends StatelessWidget {
  const HomeEmbeddedEnergyTray({
    super.key,
    required this.snapshot,
    required this.locale,
    required this.onTapPlus,
  });

  final ReadingEnergySnapshot snapshot;
  final AppLocale locale;
  final VoidCallback onTapPlus;

  @override
  Widget build(BuildContext context) {
    final copy = _PlusLocalizedCopy.forLocale(locale);
    final localeName = intlLocaleOf(context);

    // Option 2 for VIP Pass holders: Left Cell = 6 VIP Turns; Right Cell = 2-Hour Auspicious Window
    if (snapshot.isPlusActive) {
      final remainingVipText = formatWholeNumber(
        localeName,
        snapshot.plusRemainingTurns,
      );
      final maxVipText = formatWholeNumber(
        localeName,
        ReadingEnergySnapshot.plusDailyMax,
      );
      final vipStatusLine = copy.vipEnergyStatus(
        remainingVipText,
        maxVipText,
      );
      final auspiciousHour =
          snapshot.auspiciousHourWindow ?? copy.vipAuspiciousDefaultWindow;
      final auspiciousNote =
          snapshot.auspiciousHourNote ?? copy.vipAuspiciousNote;

      return Semantics(
        button: true,
        label:
            '${copy.vipEnergyLabel}: $vipStatusLine. ${copy.vipAuspiciousTag}: $auspiciousHour, $auspiciousNote',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Golden hairline divider separating upper tiles from Tray
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CompassColors.gold.withValues(alpha: 0.0),
                      CompassColors.gold.withValues(alpha: 0.55),
                      CompassColors.gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              key: const Key('home_daily_energy_tray'),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT CELL: VIP Energy 6 Turns (Option 2)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('home_vip_energy_cell'),
                          onTap: onTapPlus,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF221A11),
                                  Color(0xFF19130D),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: CompassColors.gold.withValues(alpha: 0.55),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CompassColors.gold.withValues(alpha: 0.10),
                                  blurRadius: 10,
                                  spreadRadius: 0.2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              '👑 ',
                                              style: TextStyle(fontSize: 10.5),
                                            ),
                                            Text(
                                              copy.vipEnergyLabel,
                                              maxLines: 1,
                                              style: const TextStyle(
                                                color: Color(0xFFFFDF99),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    AstralVipGoldOrbsRow(
                                      remainingTurns: snapshot.plusRemainingTurns,
                                      totalTurns:
                                          ReadingEnergySnapshot.plusDailyMax,
                                      orbSize: 8.0,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    vipStatusLine,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Color(0xFFF7D58C),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // RIGHT CELL: 2-Hour Auspicious Window (Option 2)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('home_auspicious_hour_cell'),
                          onTap: onTapPlus,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0F1B2E),
                                  Color(0xFF14243B),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF67B8F7).withValues(alpha: 0.45),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A90E2).withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  spreadRadius: 0.2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5.5,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF67B8F7).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF67B8F7).withValues(alpha: 0.35),
                                            width: 0.6,
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            copy.vipAuspiciousTag,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              color: Color(0xFFBDE1FF),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '✦',
                                      style: TextStyle(
                                        color: Color(0xFFFFDF99),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    auspiciousHour,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Color(0xFFE8F4FF),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    auspiciousNote,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Color(0xFF90B4D8),
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w500,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final freeRemainingText = formatWholeNumber(
      localeName,
      snapshot.remainingFreeTurns,
    );
    final freeMaxText = formatWholeNumber(
      localeName,
      ReadingEnergySnapshot.freeDailyMax,
    );

    final String statusLine;
    final Color statusColor;
    if (snapshot.isDailyFreeExhausted) {
      final countdown = formatEnergyCountdown(
        context,
        snapshot.timeUntilMidnight,
      );
      statusLine = copy.t3TimerStatus(
        freeRemainingText,
        freeMaxText,
        countdown,
      );
      statusColor = const Color(0xFFF09898);
    } else if (snapshot.isCoolingDown) {
      final countdown = formatEnergyCountdown(
        context,
        snapshot.cooldownRemaining,
      );
      statusLine = copy.t3TimerStatus(
        freeRemainingText,
        freeMaxText,
        countdown,
      );
      statusColor = const Color(0xFFF5D98E);
    } else {
      statusLine = copy.t3ReadyStatus(freeRemainingText, freeMaxText);
      statusColor = CompassColors.blueLight;
    }

    return Semantics(
      button: true,
      label: '${copy.t3CurrentLabel}: $statusLine. ${copy.t3PlusActionLabel}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Golden hairline divider separating the upper tiles from T3
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CompassColors.gold.withValues(alpha: 0.0),
                    CompassColors.gold.withValues(alpha: 0.55),
                    CompassColors.gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            key: const Key('home_daily_energy_tray'),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT CELL: Current Free Energy (aligned with Lucky Colors tile)
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTapPlus,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.045),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: CompassColors.line.withValues(alpha: 0.75),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        copy.t3CurrentLabel,
                                        maxLines: 1,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: CompassColors.secondary,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  AstralFreeOrbsRow(
                                    remainingFreeTurns:
                                        snapshot.remainingFreeTurns,
                                    orbSize: 9.5,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  statusLine,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // RIGHT CELL: AstraCue Plus Upgrade with Option 1 (100% H3+H1 animation)
                  Expanded(
                    child: _AnimatedPlusGemBox(
                      actionLabel: copy.t3PlusActionLabel,
                      onTap: onTapPlus,
                      singleRow: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displayed on `RitualPage` (`isPostReadingResult: false`, Plus-only capsule
/// without repeating remaining turns) and `ResultPage` (`isPostReadingResult: true`,
/// full 2-cell T3 layout showing remaining turns & countdown alongside Plus).
class AnalysisEnergyPlusCard extends StatelessWidget {
  const AnalysisEnergyPlusCard({
    super.key,
    required this.snapshot,
    required this.locale,
    required this.onTapPlus,
    this.isPostReadingResult = false,
  });

  final ReadingEnergySnapshot snapshot;
  final AppLocale locale;
  final VoidCallback onTapPlus;
  final bool isPostReadingResult;

  @override
  Widget build(BuildContext context) {
    // Option 1 for VIP: hide completely on RitualPage & ResultPage
    if (snapshot.isPlusActive) {
      return const SizedBox.shrink();
    }

    final copy = _PlusLocalizedCopy.forLocale(locale);

    // On RitualPage (màn phân tích), omit the remaining-turns box and show only
    // the animated H3+H1 golden Plus bar.
    if (!isPostReadingResult) {
      return Semantics(
        button: true,
        label: copy.headerSemanticsLabel,
        child: _AnimatedPlusGemBox(
          actionLabel: copy.t3PlusActionLabel,
          onTap: onTapPlus,
          singleRow: true,
        ),
      );
    }

    // On ResultPage (màn kết quả), keep the 2-cell T3 layout with remaining
    // turns & live cooldown countdown on the left and animated Plus upgrade on the right.
    final localeName = intlLocaleOf(context);
    final freeRemainingText = formatWholeNumber(
      localeName,
      snapshot.remainingFreeTurns,
    );
    final freeMaxText = formatWholeNumber(
      localeName,
      ReadingEnergySnapshot.freeDailyMax,
    );

    final String statusLine;
    final Color statusColor;
    if (snapshot.isDailyFreeExhausted) {
      final countdown = formatEnergyCountdown(
        context,
        snapshot.timeUntilMidnight,
      );
      statusLine = copy.t3TimerStatus(
        freeRemainingText,
        freeMaxText,
        countdown,
      );
      statusColor = const Color(0xFFF09898);
    } else if (snapshot.isCoolingDown) {
      final countdown = formatEnergyCountdown(
        context,
        snapshot.cooldownRemaining,
      );
      statusLine = copy.t3TimerStatus(
        freeRemainingText,
        freeMaxText,
        countdown,
      );
      statusColor = const Color(0xFFF5D98E);
    } else {
      statusLine = copy.t3ReadyStatus(freeRemainingText, freeMaxText);
      statusColor = CompassColors.blueLight;
    }

    return Semantics(
      button: true,
      label: '${copy.t3CurrentLabel}: $statusLine. ${copy.t3PlusActionLabel}',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTapPlus,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8.5,
                    ),
                    decoration: BoxDecoration(
                      color: CompassColors.raised.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: CompassColors.line.withValues(alpha: 0.85),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  copy.t3CurrentLabel,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: CompassColors.secondary,
                                        fontSize: 11,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            AstralFreeOrbsRow(
                              remainingFreeTurns: snapshot.remainingFreeTurns,
                              orbSize: 9.5,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            statusLine,
                            maxLines: 1,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AnimatedPlusGemBox(
                actionLabel: copy.t3PlusActionLabel,
                onTap: onTapPlus,
                singleRow: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Option 1 (`H3 + H1` 100% synchronized animation) for the bottom `✦ PLUS`
/// 6-turns box across `HomePage`, `RitualPage`, and `ResultPage`:
/// - Orbiting conic starlight border (`_OrbitingGoldBorderPainter`, 2.8s)
/// - 3 out-of-phase twinkling corner stars (`✦`)
/// - Deep amber-gold jewel gradient + diagonal metallic light sweep
/// - Breathing/rotating `✦` star + 3 pulsing golden orbs
class _AnimatedPlusGemBox extends StatefulWidget {
  const _AnimatedPlusGemBox({
    required this.actionLabel,
    required this.onTap,
    required this.singleRow,
  });

  final String actionLabel;
  final VoidCallback onTap;
  final bool singleRow;

  @override
  State<_AnimatedPlusGemBox> createState() => _AnimatedPlusGemBoxState();
}

class _AnimatedPlusGemBoxState extends State<_AnimatedPlusGemBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.singleRow ? 5200 : 2800),
  );
  bool? _reduceMotion;

  @override
  void didUpdateWidget(covariant _AnimatedPlusGemBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.singleRow != widget.singleRow) {
      _controller.duration = Duration(
        milliseconds: widget.singleRow ? 5200 : 2800,
      );
      if (_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.22;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildStarAndPlusLabel(double angle, double breath) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: 0.90 + 0.22 * breath,
          child: Transform.rotate(
            angle: 0.22 * math.sin(angle),
            child: Text(
              '✦',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.0,
                color: const Color(0xFFFFE8A3),
                shadows: [
                  Shadow(
                    color: const Color(0xFFFFF2C2)
                        .withValues(alpha: 0.55 + 0.4 * breath),
                    blurRadius: 6 + 4 * breath,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFF9E2), Color(0xFFF0CF82), Color(0xFFC99A3E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const Text(
            'PLUS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              height: 1.05,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPulsingPlusOrbs(double angle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < ReadingEnergySnapshot.plusBonusMax; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Builder(
            builder: (context) {
              final orbBreath = 0.5 + 0.5 * math.sin(angle - i * 0.85);
              return Transform.scale(
                scale: 0.93 + 0.14 * orbBreath,
                child: Container(
                  width: 9.5,
                  height: 9.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.3, -0.35),
                      radius: 0.85,
                      colors: [
                        Color(0xFFFFF6DA),
                        Color(0xFFE6C173),
                        Color(0xFF9E7325),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFEAB3),
                      width: 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CompassColors.gold.withValues(
                          alpha: 0.45 + 0.45 * orbBreath,
                        ),
                        blurRadius: 4 + 5 * orbBreath,
                        spreadRadius: 0.2 + 0.5 * orbBreath,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final cycleMultiplier = widget.singleRow ? 2.0 : 1.0;
          final angle = t * 2 * math.pi * cycleMultiplier;
          final breath = 0.5 + 0.5 * math.sin(angle);

          final twinkle1 = (0.5 + 0.5 * math.sin(angle)).clamp(0.12, 1.0);
          final twinkle2 = (0.5 + 0.5 * math.sin(angle + 2.2)).clamp(0.12, 1.0);
          final twinkle3 = (0.5 + 0.5 * math.sin(angle + 4.3)).clamp(0.10, 1.0);
          final shimmerPos = -1.4 + (t * 3.6);

          final Widget innerContent = widget.singleRow
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStarAndPlusLabel(angle, breath),
                        const SizedBox(width: 8),
                        _buildPulsingPlusOrbs(angle),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                widget.actionLabel,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Color(0xFFFFF3C8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Color(0xFFFFE8A3),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStarAndPlusLabel(angle, breath),
                        const SizedBox(width: 6),
                        _buildPulsingPlusOrbs(angle),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.actionLabel,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFFFFF3C8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 15,
                          color: Color(0xFFFFE8A3),
                        ),
                      ],
                    ),
                  ],
                );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: CompassColors.gold.withValues(
                        alpha: 0.18 + 0.22 * breath,
                      ),
                      blurRadius: 8 + 8 * breath,
                      spreadRadius: 0.2 + 0.6 * breath,
                    ),
                  ],
                ),
                child: CustomPaint(
                  foregroundPainter: _OrbitingGoldBorderPainter(
                    progress: t,
                    radius: 14,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.singleRow ? 13 : 10,
                            vertical: widget.singleRow ? 9.5 : 8,
                          ),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF281D0E),
                                Color(0xFF422F15),
                                Color(0xFF21170B),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: innerContent,
                        ),
                        // Diagonal metallic light sweep
                        Positioned.fill(
                          child: IgnorePointer(
                            child: FractionalTranslation(
                              translation: Offset(shimmerPos, 0),
                              child: Transform.rotate(
                                angle: -0.38,
                                child: Container(
                                  width: 34,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        const Color(0xFFFFF4D0)
                                            .withValues(alpha: 0.34),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Top-left twinkling corner star (H3)
              Positioned(
                top: -4.5,
                left: -2.5,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: twinkle1,
                    child: Transform.scale(
                      scale: 0.65 + 0.60 * twinkle1,
                      child: Text(
                        '✦',
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1.0,
                          color: const Color(0xFFFFE8A3),
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFFE8A3)
                                  .withValues(alpha: 0.85),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom-right twinkling corner star (H3)
              Positioned(
                bottom: -4.5,
                right: -2.0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: twinkle2,
                    child: Transform.scale(
                      scale: 0.60 + 0.65 * twinkle2,
                      child: Text(
                        '✦',
                        style: TextStyle(
                          fontSize: 9.0,
                          height: 1.0,
                          color: const Color(0xFFFFE8A3),
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFFE8A3)
                                  .withValues(alpha: 0.85),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Top-right micro stardust star (H3)
              Positioned(
                top: -4.5,
                right: widget.singleRow ? 42.0 : 14.0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: twinkle3,
                    child: Transform.scale(
                      scale: 0.60 + 0.55 * twinkle3,
                      child: const Text(
                        '✦',
                        style: TextStyle(
                          fontSize: 8.5,
                          height: 1.0,
                          color: Color(0xFFFFE8A3),
                          shadows: [
                            Shadow(color: Color(0xFFFFE8A3), blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Renders the 3 cyan Free energy orbs (`0..3` active).
class AstralFreeOrbsRow extends StatelessWidget {
  const AstralFreeOrbsRow({
    super.key,
    required this.remainingFreeTurns,
    this.orbSize = 10,
  });

  final int remainingFreeTurns;
  final double orbSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < ReadingEnergySnapshot.freeDailyMax; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _CyanEnergyOrb(active: i < remainingFreeTurns, size: orbSize),
        ],
      ],
    );
  }
}

/// Renders the 3 golden Plus energy orbs.
class AstralPlusOrbsRow extends StatelessWidget {
  const AstralPlusOrbsRow({super.key, this.orbSize = 10});

  final double orbSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < ReadingEnergySnapshot.plusBonusMax; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _GoldPlusOrb(size: orbSize),
        ],
      ],
    );
  }
}

/// Renders all 6 orbs (`3 cyan Free + 3 gold Plus`) on a single row.
class AstralEnergyOrbsRow extends StatelessWidget {
  const AstralEnergyOrbsRow({
    super.key,
    required this.remainingFreeTurns,
    this.orbSize = 10.5,
  });

  final int remainingFreeTurns;
  final double orbSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AstralFreeOrbsRow(
          remainingFreeTurns: remainingFreeTurns,
          orbSize: orbSize,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            '+',
            style: TextStyle(
              color: CompassColors.gold.withValues(alpha: 0.9),
              fontSize: orbSize + 1,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        AstralPlusOrbsRow(orbSize: orbSize),
      ],
    );
  }
}

class _CyanEnergyOrb extends StatelessWidget {
  const _CyanEnergyOrb({required this.active, required this.size});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF172236),
          border: Border.all(
            color: CompassColors.blueLight.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.35),
          radius: 0.85,
          colors: [Color(0xFFDFF3FF), Color(0xFF67B8F7), Color(0xFF286DA5)],
        ),
        border: Border.all(color: const Color(0xFFCDEEFF), width: 0.9),
        boxShadow: [
          BoxShadow(
            color: CompassColors.blueLight.withValues(alpha: 0.65),
            blurRadius: 6,
            spreadRadius: 0.4,
          ),
        ],
      ),
    );
  }
}

class _GoldPlusOrb extends StatelessWidget {
  const _GoldPlusOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.35),
          radius: 0.85,
          colors: [Color(0xFFFFF6DA), Color(0xFFE6C173), Color(0xFF9E7325)],
        ),
        border: Border.all(color: const Color(0xFFFFEAB3), width: 0.9),
        boxShadow: [
          BoxShadow(
            color: CompassColors.gold.withValues(alpha: 0.55),
            blurRadius: 6,
            spreadRadius: 0.3,
          ),
        ],
      ),
    );
  }
}

/// Opens the modal bottom sheet confirming active VIP Pass perks.
Future<void> showAstraCueVipStatusSheet(
  BuildContext context, {
  required AppLocale locale,
  required ReadingEnergySnapshot snapshot,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.76),
    builder: (sheetContext) => AstraCueVipStatusSheet(
      locale: locale,
      snapshot: snapshot,
    ),
  );
}

/// Modal bottom sheet presenting confirmed lifetime VIP privileges.
class AstraCueVipStatusSheet extends StatelessWidget {
  const AstraCueVipStatusSheet({
    super.key,
    required this.locale,
    required this.snapshot,
  });

  final AppLocale locale;
  final ReadingEnergySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final copy = _PlusLocalizedCopy.forLocale(locale);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          key: const Key('astracue_vip_status_sheet'),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1C1712), Color(0xFF14100D), Color(0xFF0C0A08)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: CompassColors.gold.withValues(alpha: 0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: CompassColors.gold.withValues(alpha: 0.18),
                blurRadius: 26,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Crown Badge + Title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CompassColors.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: CompassColors.gold.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👑', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        copy.vipSheetActiveBadge,
                        style: const TextStyle(
                          color: Color(0xFFFFDF99),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  copy.vipSheetTitle,
                  style: const TextStyle(
                    color: Color(0xFFFFF4D4),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  copy.vipSheetSubtitle,
                  style: const TextStyle(
                    color: CompassColors.secondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 16),

                // 4 Perks Rows
                _VipPerkTile(
                  icon: Icons.bolt_rounded,
                  iconColor: CompassColors.blueLight,
                  title: copy.vipPerk1Title,
                  description: copy.vipPerk1Desc,
                ),
                const SizedBox(height: 10),
                _VipPerkTile(
                  icon: Icons.wb_sunny_rounded,
                  iconColor: const Color(0xFFF5D98E),
                  title: copy.vipPerk2Title,
                  description: copy.vipPerk2Desc,
                ),
                const SizedBox(height: 10),
                _VipPerkTile(
                  icon: Icons.explore_rounded,
                  iconColor: const Color(0xFFF5D98E),
                  title: copy.vipPerk3Title,
                  description: copy.vipPerk3Desc,
                ),
                const SizedBox(height: 10),
                _VipPerkTile(
                  icon: Icons.shield_rounded,
                  iconColor: CompassColors.blueLight,
                  title: copy.vipPerk4Title,
                  description: copy.vipPerk4Desc,
                ),
                const SizedBox(height: 20),

                // Dismiss CTA Button
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('astracue_vip_status_cta'),
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE8BD65),
                              Color(0xFFC79532),
                              Color(0xFF9E701C),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: CompassColors.gold.withValues(alpha: 0.35),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            copy.vipCloseCta,
                            style: const TextStyle(
                              color: Color(0xFF1A1208),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VipPerkTile extends StatelessWidget {
  const _VipPerkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CompassColors.line.withValues(alpha: 0.65),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFFF2D0),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: CompassColors.secondary,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the compact `P1` 4-row checklist modal bottom sheet for AstraCue Plus.
Future<void> showAstraCuePlusSheet(
  BuildContext context, {
  required AppLocale locale,
  required ReadingEnergySnapshot snapshot,
  ReadingEnergySnapshot Function()? snapshotResolver,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.76),
    builder: (sheetContext) => AstraCuePlusSheet(
      locale: locale,
      snapshot: snapshot,
      snapshotResolver: snapshotResolver,
    ),
  );
}

/// Compact `P1 · Checklist 4 Dòng Ngắn Gọn` Bottom Sheet for AstraCue Plus.
/// Fits comfortably on a single screen without wordy paragraphs.
class AstraCuePlusSheet extends StatefulWidget {
  const AstraCuePlusSheet({
    super.key,
    required this.locale,
    required this.snapshot,
    this.snapshotResolver,
  });

  final AppLocale locale;
  final ReadingEnergySnapshot snapshot;
  final ReadingEnergySnapshot Function()? snapshotResolver;

  @override
  State<AstraCuePlusSheet> createState() => _AstraCuePlusSheetState();
}

class _AstraCuePlusSheetState extends State<AstraCuePlusSheet> {
  late ReadingEnergySnapshot _snapshot = widget.snapshot;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    if (widget.snapshotResolver != null) {
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _snapshot = widget.snapshotResolver!();
        });
      });
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _PlusLocalizedCopy.forLocale(widget.locale);
    final localeName = intlLocaleOf(context);
    final freeRemainingText = formatWholeNumber(
      localeName,
      _snapshot.remainingFreeTurns,
    );
    final freeMaxText = formatWholeNumber(
      localeName,
      ReadingEnergySnapshot.freeDailyMax,
    );
    final plusMaxText = formatWholeNumber(
      localeName,
      ReadingEnergySnapshot.plusDailyMax,
    );

    final String liveBarText;
    if (_snapshot.isDailyFreeExhausted) {
      final countdown = formatEnergyCountdown(
        context,
        _snapshot.timeUntilMidnight,
      );
      liveBarText = copy.p1BarExhausted(countdown);
    } else if (_snapshot.isCoolingDown) {
      final countdown = formatEnergyCountdown(
        context,
        _snapshot.cooldownRemaining,
      );
      final unlockedAfterPlus = formatWholeNumber(
        localeName,
        _snapshot.remainingFreeTurns + ReadingEnergySnapshot.plusBonusMax,
      );
      liveBarText = copy.p1BarCooldown(
        countdown,
        unlockedAfterPlus,
        plusMaxText,
      );
    } else {
      liveBarText = copy.p1BarReady(
        freeRemainingText,
        freeMaxText,
        plusMaxText,
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          key: const Key('astracue_plus_sheet'),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF181F33), Color(0xFF111626), Color(0xFF0C101C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: CompassColors.gold.withValues(alpha: 0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 32,
                offset: const Offset(0, -6),
              ),
              BoxShadow(
                color: CompassColors.gold.withValues(alpha: 0.14),
                blurRadius: 24,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Compact Header Row: Emblem + Title on left | $4.99 Lifetime badge on right
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF332613), Color(0xFF1C150C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: CompassColors.gold.withValues(alpha: 0.8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CompassColors.gold.withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFFFE8A3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AstraCue Plus',
                              style: TextStyle(
                                color: CompassColors.text,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              copy.p1HeaderSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CompassColors.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _B1LifetimeVipCrest(
                        lifetimeLabel: copy.p1LifetimeTag.toUpperCase(),
                        vipPassLabel: copy.p1VipPassSubtag,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1-Line Live Energy Comparison Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121829),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: CompassColors.line.withValues(alpha: 0.9),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AstralEnergyOrbsRow(
                          remainingFreeTurns: _snapshot.remainingFreeTurns,
                          orbSize: 9.5,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              liveBarText,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFFF7E3B5),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // P1: 4 Concise Single-Line Checklist Rows (only Row 1 has right badge)
                  _P1ChecklistRow(
                    icon: Icons.bolt_rounded,
                    iconColor: CompassColors.blueLight,
                    title: copy.p1Row1Title,
                    badgeText: copy.p1Row1Badge,
                    badgeColor: CompassColors.blueLight,
                  ),
                  const SizedBox(height: 7),
                  _P1ChecklistRow(
                    icon: Icons.block_rounded,
                    iconColor: const Color(0xFFF5D98E),
                    title: copy.p1Row2Title,
                  ),
                  const SizedBox(height: 7),
                  _P1ChecklistRow(
                    icon: Icons.lock_open_rounded,
                    iconColor: const Color(0xFFF5D98E),
                    title: copy.p1Row3Title,
                  ),
                  const SizedBox(height: 7),
                  _P1ChecklistRow(
                    icon: Icons.all_inclusive_rounded,
                    iconColor: CompassColors.secondary,
                    title: copy.p1Row4Title,
                  ),
                  const SizedBox(height: 11),

                  // 1-Line Transparent Footnote
                  Text(
                    copy.p1ShortFootnote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CompassColors.secondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option 3 Primary Gold CTA Button with localized currency & -60% OFF badge
                  _Option3SaleCtaButton(
                    ctaPrefix: copy.sheetPrimaryCtaPrefix,
                    originalPrice: copy.originalPriceFormatted,
                    salePrice: copy.salePriceFormatted,
                    saleBadgeLabel: copy.p1SaleOffBadge,
                    semanticsLabel: copy.sheetPrimaryCta,
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: CompassColors.raised,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: CompassColors.gold.withValues(alpha: 0.6),
                            ),
                          ),
                          content: Text(
                            copy.previewToastMessage,
                            style: const TextStyle(
                              color: CompassColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Secondary Actions: Restore · Maybe later
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: CompassColors.secondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(copy.sheetRestoreAction),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '·',
                            style: TextStyle(
                              color: CompassColors.muted.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: CompassColors.secondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(copy.sheetLaterAction),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Option `B1` (`✦ TRỌN ĐỜI / VIP PASS`) top-right crest inside `AstraCuePlusSheet`:
/// Synchronized `H3 + H1` starlight border + twinkling corner stars + metallic sweep
/// without repeating the numeric price shown on the bottom CTA button.
class _B1LifetimeVipCrest extends StatefulWidget {
  const _B1LifetimeVipCrest({
    required this.lifetimeLabel,
    required this.vipPassLabel,
  });

  final String lifetimeLabel;
  final String vipPassLabel;

  @override
  State<_B1LifetimeVipCrest> createState() => _B1LifetimeVipCrestState();
}

class _B1LifetimeVipCrestState extends State<_B1LifetimeVipCrest>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.22;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final angle = t * 2 * math.pi;
        final breath = 0.5 + 0.5 * math.sin(angle);
        final twinkle1 = (0.5 + 0.5 * math.sin(angle)).clamp(0.15, 1.0);
        final twinkle2 = (0.5 + 0.5 * math.sin(angle + 2.3)).clamp(0.15, 1.0);
        final shimmerPos = -1.4 + (t * 3.6);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: CompassColors.gold.withValues(
                      alpha: 0.18 + 0.20 * breath,
                    ),
                    blurRadius: 8 + 6 * breath,
                    spreadRadius: 0.2 + 0.4 * breath,
                  ),
                ],
              ),
              child: CustomPaint(
                foregroundPainter: _OrbitingGoldBorderPainter(
                  progress: t,
                  radius: 13,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6.5,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF281D0E),
                              Color(0xFF422F15),
                              Color(0xFF21170B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.scale(
                                  scale: 0.90 + 0.22 * breath,
                                  child: Transform.rotate(
                                    angle: 0.20 * math.sin(angle),
                                    child: Text(
                                      '✦',
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.0,
                                        color: const Color(0xFFFFE8A3),
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFFFFF2C2)
                                                .withValues(
                                                  alpha: 0.55 + 0.4 * breath,
                                                ),
                                            blurRadius: 6 + 4 * breath,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          Color(0xFFFFF9E2),
                                          Color(0xFFF0CF82),
                                          Color(0xFFC99A3E),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ).createShader(bounds),
                                  blendMode: BlendMode.srcIn,
                                  child: Text(
                                    widget.lifetimeLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      height: 1.05,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.vipPassLabel,
                              style: const TextStyle(
                                color: CompassColors.gold,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Diagonal metallic light sweep
                      Positioned.fill(
                        child: IgnorePointer(
                          child: FractionalTranslation(
                            translation: Offset(shimmerPos, 0),
                            child: Transform.rotate(
                              angle: -0.38,
                              child: Container(
                                width: 28,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      const Color(0xFFFFF4D0)
                                          .withValues(alpha: 0.35),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Top-left twinkling corner star
            Positioned(
              top: -4.5,
              left: -2.5,
              child: IgnorePointer(
                child: Opacity(
                  opacity: twinkle1,
                  child: Transform.scale(
                    scale: 0.65 + 0.55 * twinkle1,
                    child: const Text(
                      '✦',
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.0,
                        color: Color(0xFFFFE8A3),
                        shadows: [
                          Shadow(color: Color(0xFFFFE8A3), blurRadius: 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom-right twinkling corner star
            Positioned(
              bottom: -4.5,
              right: -2.0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: twinkle2,
                  child: Transform.scale(
                    scale: 0.60 + 0.60 * twinkle2,
                    child: const Text(
                      '✦',
                      style: TextStyle(
                        fontSize: 8.5,
                        height: 1.0,
                        color: Color(0xFFFFE8A3),
                        shadows: [
                          Shadow(color: Color(0xFFFFE8A3), blurRadius: 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Option 3 Primary Gold CTA Button inside `AstraCuePlusSheet`:
/// - Displays localized prefix + diagonally crossed-out original price + bold sale price
/// - Continuous metallic shimmer sweep across the button
/// - Floating pulsing `-60% OFF` ruby-gold pill badge at top-right edge
class _Option3SaleCtaButton extends StatefulWidget {
  const _Option3SaleCtaButton({
    required this.ctaPrefix,
    required this.originalPrice,
    required this.salePrice,
    required this.saleBadgeLabel,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String ctaPrefix;
  final String originalPrice;
  final String salePrice;
  final String saleBadgeLabel;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  State<_Option3SaleCtaButton> createState() => _Option3SaleCtaButtonState();
}

class _Option3SaleCtaButtonState extends State<_Option3SaleCtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.25;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.semanticsLabel}, ${widget.saleBadgeLabel}',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final badgePulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
          final shimmerPos = -1.5 + (t * 4.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('astracue_plus_sheet_cta'),
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF3D892),
                            Color(0xFFD8B36A),
                            Color(0xFFC29743),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: CompassColors.gold.withValues(alpha: 0.38),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13.5,
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.ctaPrefix,
                                        style: const TextStyle(
                                          color: Color(0xFF17120A),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.25,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _DiagonalStrikePrice(
                                        priceText: widget.originalPrice,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.salePrice,
                                        style: const TextStyle(
                                          color: Color(0xFF17120A),
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Diagonal metallic light sweep across CTA button
                            Positioned.fill(
                              child: IgnorePointer(
                                child: FractionalTranslation(
                                  translation: Offset(shimmerPos, 0),
                                  child: Transform.rotate(
                                    angle: -0.38,
                                    child: Container(
                                      width: 52,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0.0),
                                            Colors.white.withValues(
                                              alpha: 0.56,
                                            ),
                                            Colors.white.withValues(alpha: 0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Floating pulsing -60% OFF badge at top-right of CTA button
              Positioned(
                top: -10,
                right: 12,
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: 1.0 + 0.08 * badgePulse,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF3B30),
                            Color(0xFFD91B42),
                            Color(0xFFB8142C),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: const Color(0xFFFFE49E),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3B30)
                                .withValues(alpha: 0.50 + 0.35 * badgePulse),
                            blurRadius: 9 + 7 * badgePulse,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFD26E)
                                .withValues(alpha: 0.35 + 0.35 * badgePulse),
                            blurRadius: 8 + 6 * badgePulse,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.saleBadgeLabel,
                        style: const TextStyle(
                          color: Color(0xFFFFFDF7),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Renders an old price (e.g. `$11.99`) with an angled crimson strikethrough line.
class _DiagonalStrikePrice extends StatelessWidget {
  const _DiagonalStrikePrice({required this.priceText});

  final String priceText;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const _DiagonalStrikePainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Text(
          priceText,
          style: TextStyle(
            color: const Color(0xFF17120A).withValues(alpha: 0.52),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

class _DiagonalStrikePainter extends CustomPainter {
  const _DiagonalStrikePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA61B1B)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final start = Offset(0, size.height * 0.66);
    final end = Offset(size.width, size.height * 0.38);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _P1ChecklistRow extends StatelessWidget {
  const _P1ChecklistRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.badgeText,
    this.badgeColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? badgeText;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9.5),
      decoration: BoxDecoration(
        color: const Color(0xFF151C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CompassColors.line.withValues(alpha: 0.85)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CompassColors.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 8),
            Text(
              badgeText!,
              maxLines: 1,
              style: TextStyle(
                color: badgeColor ?? CompassColors.blueLight,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Localized copy for AstraCue Plus across all 8 supported languages.
class _PlusLocalizedCopy {
  const _PlusLocalizedCopy({
    required this.headerSemanticsLabel,
    required this.t3CurrentLabel,
    required this.t3ReadyStatus,
    required this.t3TimerStatus,
    required this.t3PlusActionLabel,
    required this.p1HeaderSubtitle,
    required this.p1LifetimeTag,
    required this.p1VipPassSubtag,
    required this.p1SaleOffBadge,
    required this.p1BarReady,
    required this.p1BarCooldown,
    required this.p1BarExhausted,
    required this.p1Row1Title,
    required this.p1Row1Badge,
    required this.p1Row2Title,
    required this.p1Row2Badge,
    required this.p1Row3Title,
    required this.p1Row3Badge,
    required this.p1Row4Title,
    required this.p1Row4Badge,
    required this.p1ShortFootnote,
    required this.originalPriceFormatted,
    required this.salePriceFormatted,
    required this.sheetPrimaryCtaPrefix,
    required this.sheetPrimaryCta,
    required this.sheetRestoreAction,
    required this.sheetLaterAction,
    required this.previewToastMessage,
    required this.vipHeaderBadge,
    required this.vipSemanticsLabel,
    required this.vipEnergyLabel,
    required this.vipEnergyStatus,
    required this.vipAuspiciousTag,
    required this.vipAuspiciousDefaultWindow,
    required this.vipAuspiciousNote,
    required this.vipSheetTitle,
    required this.vipSheetSubtitle,
    required this.vipSheetActiveBadge,
    required this.vipPerk1Title,
    required this.vipPerk1Desc,
    required this.vipPerk2Title,
    required this.vipPerk2Desc,
    required this.vipPerk3Title,
    required this.vipPerk3Desc,
    required this.vipPerk4Title,
    required this.vipPerk4Desc,
    required this.vipCloseCta,
  });

  final String headerSemanticsLabel;
  final String t3CurrentLabel;
  final String Function(String remaining, String max) t3ReadyStatus;
  final String Function(String remaining, String max, String countdown)
  t3TimerStatus;
  final String t3PlusActionLabel;

  final String p1HeaderSubtitle;
  final String p1LifetimeTag;
  final String p1VipPassSubtag;
  final String p1SaleOffBadge;
  final String Function(String remaining, String freeMax, String plusMax)
  p1BarReady;
  final String Function(String countdown, String unlocked, String plusMax)
  p1BarCooldown;
  final String Function(String countdown) p1BarExhausted;

  final String p1Row1Title;
  final String p1Row1Badge;
  final String p1Row2Title;
  final String p1Row2Badge;
  final String p1Row3Title;
  final String p1Row3Badge;
  final String p1Row4Title;
  final String p1Row4Badge;
  final String p1ShortFootnote;

  final String originalPriceFormatted;
  final String salePriceFormatted;
  final String sheetPrimaryCtaPrefix;
  final String sheetPrimaryCta;
  final String sheetRestoreAction;
  final String sheetLaterAction;
  final String previewToastMessage;

  // VIP localization fields
  final String vipHeaderBadge;
  final String vipSemanticsLabel;
  final String vipEnergyLabel;
  final String Function(String remaining, String max) vipEnergyStatus;
  final String vipAuspiciousTag;
  final String vipAuspiciousDefaultWindow;
  final String vipAuspiciousNote;
  final String vipSheetTitle;
  final String vipSheetSubtitle;
  final String vipSheetActiveBadge;
  final String vipPerk1Title;
  final String vipPerk1Desc;
  final String vipPerk2Title;
  final String vipPerk2Desc;
  final String vipPerk3Title;
  final String vipPerk3Desc;
  final String vipPerk4Title;
  final String vipPerk4Desc;
  final String vipCloseCta;

  static _PlusLocalizedCopy forLocale(AppLocale locale) => switch (locale) {
    AppLocale.vietnamese => _vi,
    AppLocale.english => _en,
    AppLocale.spanish => _es,
    AppLocale.japanese => _ja,
    AppLocale.thai => _th,
    AppLocale.hindi => _hi,
    AppLocale.simplifiedChinese => _zh,
    AppLocale.korean => _ko,
  };

  static _PlusLocalizedCopy of(String languageCode) => switch (languageCode) {
    'vi' => _vi,
    'es' => _es,
    'ja' => _ja,
    'th' => _th,
    'hi' => _hi,
    'zh' => _zh,
    'ko' => _ko,
    _ => _en,
  };

  static final _PlusLocalizedCopy _vi = _PlusLocalizedCopy(
    headerSemanticsLabel: 'AstraCue Plus, mở 6 lượt tức thì và tắt quảng cáo',
    t3CurrentLabel: 'Hiện tại',
    t3ReadyStatus: (rem, max) => 'Còn $rem/$max lượt',
    t3TimerStatus: (rem, max, cd) => '$rem/$max · ⏱ $cd',
    t3PlusActionLabel: '6 lượt · Tắt Ads',
    p1HeaderSubtitle: 'Mở khóa trọn vẹn',
    p1LifetimeTag: 'Trọn đời',
    p1VipPassSubtag: 'VIP PASS',
    p1SaleOffBadge: '-60% OFF',
    p1BarReady: (rem, freeMax, plusMax) =>
        '$rem/$freeMax Free → $plusMax/$plusMax lượt tức thì',
    p1BarCooldown: (cd, unlocked, plusMax) =>
        'Đang hồi $cd → Mở $unlocked/$plusMax ngay',
    p1BarExhausted: (cd) => 'Hết lượt ($cd) → Mở +3 lượt ngay',
    p1Row1Title: '6 lượt phân tích / ngày',
    p1Row1Badge: 'Xóa 3h chờ hồi',
    p1Row2Title: 'Tắt hoàn toàn quảng cáo',
    p1Row2Badge: '0 Banner & Video',
    p1Row3Title: 'Mở khóa mọi chế độ & buổi',
    p1Row3Badge: 'Chọn tự do ngay',
    p1Row4Title: 'Mua 1 lần dùng mãi mãi',
    p1Row4Badge: 'Không phí tháng',
    p1ShortFootnote:
        'Làm mới 6 lượt lúc 00:00 mỗi ngày · Không bao giờ bắt xem quảng cáo.',
    originalPriceFormatted: '289.000 ₫',
    salePriceFormatted: '119.000 ₫',
    sheetPrimaryCtaPrefix: '✦ Mở khóa AstraCue Plus',
    sheetPrimaryCta: '✦ Mở khóa AstraCue Plus — 119.000 ₫',
    sheetRestoreAction: 'Khôi phục giao dịch',
    sheetLaterAction: 'Để sau',
    previewToastMessage: 'Giao diện AstraCue Plus (119.000 ₫) đã sẵn sàng kết nối cổng thanh toán.',
    vipHeaderBadge: 'VIP PASS',
    vipSemanticsLabel: 'AstraCue VIP Pass, đặc quyền trọn đời đã kích hoạt',
    vipEnergyLabel: 'Năng lượng VIP',
    vipEnergyStatus: (rem, max) => 'Còn $rem/$max lượt · 0s chờ',
    vipAuspiciousTag: 'GIỜ HOÀNG ĐẠO',
    vipAuspiciousDefaultWindow: '13:00 — 15:00',
    vipAuspiciousNote: 'Khung giờ cát khí đỉnh cao',
    vipSheetTitle: 'ASTRACUE VIP',
    vipSheetSubtitle: 'Đặc quyền trọn đời đang hoạt động',
    vipSheetActiveBadge: 'ĐÃ KÍCH HOẠT',
    vipPerk1Title: '6 lượt phân tích mỗi ngày',
    vipPerk1Desc: 'Gấp đôi năng lượng, không cần chờ 3 tiếng giữa các lượt',
    vipPerk2Title: 'Khung giờ hoàng đạo 2 tiếng',
    vipPerk2Desc: 'Tính toán giờ cát khí vượng nhất mỗi ngày cho lá số',
    vipPerk3Title: 'Mở khóa toàn bộ chỉ dẫn',
    vipPerk3Desc: 'Xem sắc nét hướng dẫn Nên & Tránh không cần mở khóa',
    vipPerk4Title: 'Trải nghiệm thuần khiết',
    vipPerk4Desc: 'Loại bỏ 100% quảng cáo trọn đời',
    vipCloseCta: 'Đã hiểu · Tiếp tục',
  );

  static final _PlusLocalizedCopy _en = _PlusLocalizedCopy(
    headerSemanticsLabel:
        'AstraCue Plus, unlock 6 instant turns and remove ads',
    t3CurrentLabel: 'Current',
    t3ReadyStatus: (rem, max) => '$rem/$max turns left',
    t3TimerStatus: (rem, max, cd) => '$rem/$max · ⏱ $cd',
    t3PlusActionLabel: '6 turns · No Ads',
    p1HeaderSubtitle: 'Full access',
    p1LifetimeTag: 'Lifetime',
    p1VipPassSubtag: 'VIP PASS',
    p1SaleOffBadge: '-60% OFF',
    p1BarReady: (rem, freeMax, plusMax) =>
        '$rem/$freeMax Free → $plusMax/$plusMax instant turns',
    p1BarCooldown: (cd, unlocked, plusMax) =>
        'Cooling $cd → Unlock $unlocked/$plusMax now',
    p1BarExhausted: (cd) => '0 left ($cd) → Unlock +3 turns now',
    p1Row1Title: '6 readings / day',
    p1Row1Badge: 'No 3h cooldown',
    p1Row2Title: 'Remove all ads',
    p1Row2Badge: '0 Banner & Video',
    p1Row3Title: 'Unlock all modes & periods',
    p1Row3Badge: 'Instant access',
    p1Row4Title: 'One-time purchase',
    p1Row4Badge: 'No subscription',
    p1ShortFootnote:
        '6 daily turns reset at 00:00 · Never forces rewarded ads.',
    originalPriceFormatted: r'$11.99',
    salePriceFormatted: r'$4.99',
    sheetPrimaryCtaPrefix: '✦ Unlock AstraCue Plus',
    sheetPrimaryCta: r'✦ Unlock AstraCue Plus — $4.99',
    sheetRestoreAction: 'Restore purchase',
    sheetLaterAction: 'Maybe later',
    previewToastMessage:
        r'AstraCue Plus ($4.99) UI preview is ready for store billing.',
    vipHeaderBadge: 'VIP PASS',
    vipSemanticsLabel: 'AstraCue VIP Pass, lifetime privileges active',
    vipEnergyLabel: 'VIP Energy',
    vipEnergyStatus: (rem, max) => '$rem/$max turns · Instant',
    vipAuspiciousTag: 'COSMIC WINDOW',
    vipAuspiciousDefaultWindow: '13:00 — 15:00',
    vipAuspiciousNote: 'Peak natal alignment',
    vipSheetTitle: 'ASTRACUE VIP',
    vipSheetSubtitle: 'Lifetime privileges active',
    vipSheetActiveBadge: 'ACTIVE',
    vipPerk1Title: '6 daily cosmic readings',
    vipPerk1Desc: 'Double daily capacity with zero cooldown delays',
    vipPerk2Title: '2-hour cosmic window',
    vipPerk2Desc: 'Calculated optimal energy window for your natal chart',
    vipPerk3Title: 'Action guidance unlocked',
    vipPerk3Desc: 'Full deep actionable insights without ad unlocks',
    vipPerk4Title: 'Pure sanctuary',
    vipPerk4Desc: '100% ad-free lifetime experience',
    vipCloseCta: 'Got it · Continue',
  );

  static final _PlusLocalizedCopy _es = _PlusLocalizedCopy(
    headerSemanticsLabel:
        'AstraCue Plus, desbloquea 6 lecturas al instante y sin anuncios',
    t3CurrentLabel: 'Actual',
    t3ReadyStatus: (rem, max) => '$rem/$max turnos',
    t3TimerStatus: (rem, max, cd) => '$rem/$max · ⏱ $cd',
    t3PlusActionLabel: '6 turnos · Sin Ads',
    p1HeaderSubtitle: 'Acceso total',
    p1LifetimeTag: 'De por vida',
    p1VipPassSubtag: 'PASE VIP',
    p1SaleOffBadge: '-60% OFF',
    p1BarReady: (rem, freeMax, plusMax) =>
        '$rem/$freeMax Gratis → $plusMax/$plusMax al instante',
    p1BarCooldown: (cd, unlocked, plusMax) =>
        'Espera $cd → Abre $unlocked/$plusMax ya',
    p1BarExhausted: (cd) => '0 turnos ($cd) → +3 turnos ya',
    p1Row1Title: '6 lecturas / día',
    p1Row1Badge: 'Sin espera de 3h',
    p1Row2Title: 'Sin anuncios',
    p1Row2Badge: '0 Banners y Video',
    p1Row3Title: 'Todos los modos y horarios',
    p1Row3Badge: 'Acceso libre',
    p1Row4Title: 'Pago único',
    p1Row4Badge: 'Sin suscripción',
    p1ShortFootnote:
        '6 turnos se renuevan a las 00:00 · Nunca exige ver anuncios.',
    originalPriceFormatted: '11,99 €',
    salePriceFormatted: '4,99 €',
    sheetPrimaryCtaPrefix: '✦ Desbloquear AstraCue Plus',
    sheetPrimaryCta: '✦ Desbloquear AstraCue Plus — 4,99 €',
    sheetRestoreAction: 'Restaurar compra',
    sheetLaterAction: 'Más tarde',
    previewToastMessage:
        'La vista previa de AstraCue Plus (4,99 €) está lista.',
    vipHeaderBadge: 'PASE VIP',
    vipSemanticsLabel: 'AstraCue Pase VIP, privilegios vitalicios activos',
    vipEnergyLabel: 'Energía VIP',
    vipEnergyStatus: (rem, max) => '$rem/$max lecturas · Sin espera',
    vipAuspiciousTag: 'VENTANA CÓSMICA',
    vipAuspiciousDefaultWindow: '13:00 — 15:00',
    vipAuspiciousNote: 'Máxima resonancia natal',
    vipSheetTitle: 'ASTRACUE VIP',
    vipSheetSubtitle: 'Privilegios vitalicios activos',
    vipSheetActiveBadge: 'ACTIVO',
    vipPerk1Title: '6 lecturas diarias',
    vipPerk1Desc: 'Doble de energía sin tiempos de espera entre lecturas',
    vipPerk2Title: 'Ventana cósmica de 2 horas',
    vipPerk2Desc: 'Ventana de máxima resonancia según tu carta natal',
    vipPerk3Title: 'Orientación de acción desbloqueada',
    vipPerk3Desc: 'Indicaciones completas sin necesidad de ver anuncios',
    vipPerk4Title: 'Santuario puro',
    vipPerk4Desc: '100% sin publicidad para siempre',
    vipCloseCta: 'Entendido · Continuar',
  );

  static final _PlusLocalizedCopy _ja = _PlusLocalizedCopy(
    headerSemanticsLabel: 'AstraCue Plus、即時6回リーディング＆広告非表示',
    t3CurrentLabel: '現在',
    t3ReadyStatus: (rem, max) => '残り $rem/$max 回',
    t3TimerStatus: (rem, max, cd) => '$rem/$max · ⏱ $cd',
    t3PlusActionLabel: '6回即時 · 広告なし',
    p1HeaderSubtitle: 'フル解放',
    p1LifetimeTag: '永久版',
    p1VipPassSubtag: 'VIPパス',
    p1SaleOffBadge: '60% OFF',
    p1BarReady: (rem, freeMax, plusMax) =>
        '無料 $rem/$freeMax → 即時 $plusMax/$plusMax 回',
    p1BarCooldown: (cd, unlocked, plusMax) =>
        '回復 $cd → 今すぐ $unlocked/$plusMax 回解放',
    p1BarExhausted: (cd) => '残り0 ($cd) → +3回即時解放',
    p1Row1Title: '1日6回リーディング',
    p1Row1Badge: '3時間待機なし',
    p1Row2Title: '広告を完全オフ',
    p1Row2Badge: 'バナー・動画ゼロ',
    p1Row3Title: '全モード・時間帯を解放',
    p1Row3Badge: 'いつでも選択可能',
    p1Row4Title: '1回買い切り',
    p1Row4Badge: '月額課金なし',
    p1ShortFootnote: '毎日00:00に6回リセット · 動画広告の強制はありません。',
    originalPriceFormatted: '¥1,800',
    salePriceFormatted: '¥700',
    sheetPrimaryCtaPrefix: '✦ AstraCue Plus を解放',
    sheetPrimaryCta: '✦ AstraCue Plus を解放 — ¥700',
    sheetRestoreAction: '購入を復元',
    sheetLaterAction: 'あとで',
    previewToastMessage: 'AstraCue Plus (¥700) UIプレビューが有効です。',
    vipHeaderBadge: 'VIP PASS',
    vipSemanticsLabel: 'AstraCue VIPパス、無期限特典が有効です',
    vipEnergyLabel: 'VIPエネルギー',
    vipEnergyStatus: (rem, max) => '残り $rem/$max 回 · 待機なし',
    vipAuspiciousTag: '吉時・最適刻',
    vipAuspiciousDefaultWindow: '13:00 — 15:00',
    vipAuspiciousNote: '命式に最も調和する極上刻',
    vipSheetTitle: 'ASTRACUE VIP',
    vipSheetSubtitle: '無期限の特別権限が適用中',
    vipSheetActiveBadge: '有効',
    vipPerk1Title: '毎日6回の鑑定枠',
    vipPerk1Desc: '枠数2倍・3時間の待機時間なしで即座に鑑定',
    vipPerk2Title: '2時間の吉時ウィンドウ',
    vipPerk2Desc: 'あなたの命式に最も適した1日最良の吉刻を提示',
    vipPerk3Title: '行動指針の完全開放',
    vipPerk3Desc: '広告解除なしで推奨行動と注意点を常時閲覧',
    vipPerk4Title: '純粋な静謐空間',
    vipPerk4Desc: '生涯100%広告非表示の体験',
    vipCloseCta: '確認 · 続ける',
  );

  static final _PlusLocalizedCopy _th = _PlusLocalizedCopy(
    headerSemanticsLabel: 'AstraCue Plus ปลดล็อก 6 ครั้งทันทีและปิดโฆษณา',
    t3CurrentLabel: 'ปัจจุบัน',
    t3ReadyStatus: (rem, max) => 'เหลือ $rem/$max ครั้ง',
    t3TimerStatus: (rem, max, cd) => '$rem/$max · ⏱ $cd',
    t3PlusActionLabel: '6 ครั้ง · ปิด Ads',
    p1HeaderSubtitle: 'ปลดล็อกครบ',
    p1LifetimeTag: 'ตลอดชีพ',
    p1VipPassSubtag: 'VIP PASS',
    p1SaleOffBadge: 'ลด 60%',
    p1BarReady: (rem, freeMax, plusMax) =>
        'ฟรี $rem/$freeMax → ทันที $plusMax/$plusMax ครั้ง',
    p1BarCooldown: (cd, unlocked, plusMax) =>
        'รอ $cd → เปิด $unlocked/$plusMax ทันที',
    p1BarExhausted: (cd) => 'หมด ($cd) → เปิด +3 ครั้งทันที',
    p1Row1Title: 'วิเคราะห์ 6 ครั้ง / วัน',
    p1Row1Badge: 'ไม่ต้องรอ 3 ชม.',
    p1Row2Title: 'ปิดโฆษณาทั้งหมด',
    p1Row2Badge: 'ไม่มีแบนเนอร์/วิดีโอ',
    p1Row3Title: 'ปลดล็อกทุกโหมดและช่วงเวลา',
    p1Row3Badge: 'เลือกได้ทันที',
    p1Row4Title: 'ซื้อครั้งเดียวใช้ได้ตลอด',
    p1Row4Badge: 'ไม่หักรายเดือน',
    p1ShortFootnote: 'รีเซ็ต 6 ครั้งเวลา 00:00 น. ทุกวัน · ไม่บังคับดูโฆษณา',
    originalPriceFormatted: '฿429',
    salePriceFormatted: '฿179',
    sheetPrimaryCtaPrefix: '✦ ปลดล็อก AstraCue Plus',
    sheetPrimaryCta: '✦ ปลดล็อก AstraCue Plus — ฿179',
    sheetRestoreAction: 'กู้คืนการซื้อ',
    sheetLaterAction: 'ไว้ทีหลัง',
    previewToastMessage: 'ตัวอย่าง UI ของ AstraCue Plus (฿179) พร้อมใช้งานแล้ว',
    vipHeaderBadge: 'VIP PASS',
    vipSemanticsLabel: 'AstraCue VIP Pass สิทธิพิเศษตลอดชีพเปิดใช้งานแล้ว',
    vipEnergyLabel: 'พลังงาน VIP',
    vipEnergyStatus: (rem, max) => 'เหลือ $rem/$max ครั้ง · ไม่ต้องรอ',
    vipAuspiciousTag: 'ฤกษ์มงคล',
    vipAuspiciousDefaultWindow: '13:00 — 15:00',
    vipAuspiciousNote: 'ช่วงเวลาพลังงานสูงสุดของดวงชะตา',
    vipSheetTitle: 'ASTRACUE VIP',
    vipSheetSubtitle: 'สิทธิพิเศษตลอดชีพเปิดใช้งานแล้ว',
    vipSheetActiveBadge: 'เปิดใช้งาน',
    vipPerk1Title: 'วิเคราะห์ 6 ครั้งต่อวัน',
    vipPerk1Desc: 'พลังงานเพิ่ม 2 เท่า ไม่มีเวลารอ 3 ชั่วโมง',
    vipPerk2Title: 'ช่วงเวลาฤกษ์มงคล 2 ชั่วโมง',
    vipPerk2Desc: 'คำนวณช่วงเวลาที่ดีที่สุดในแต่ละวันสำหรับดวงคุณ',
    vipPerk3Title: 'ปลดล็อกคำแนะนำการกระทำ',
    vipPerk3Desc: 'ดูสิ่งที่ควรทำและหลีกเลี่ยงได้ทันทีโดยไม่ต้องดูโฆษณา',
    vipPerk4Title: 'พื้นที่แห่งความสงบ',
    vipPerk4Desc: 'ปราศจากโฆษณา 100% ตลอดชีพ',
    vipCloseCta: 'เข้าใจแล้ว · ใช้งานต่อ',
  );

  static final _PlusLocalizedCopy _hi = _PlusLocalizedCopy(
    headerSemanticsLabel:
        'AstraCue Plus, 6 तुरंत रीडिंग अनलॉक करें और विज्ञापन हटाएँ',
    t3CurrentLabel: 'वर्तमान',
    t3ReadyStatus: (rem, max) => '$rem/$max बारी शेष',
    t3TimerStatus: (rem, max, cd) => '$rem/$max · ⏱ $cd',
    t3PlusActionLabel: '6 बारी · बिना Ads',
    p1HeaderSubtitle: 'पूर्ण अनलॉक',
    p1LifetimeTag: 'लाइफटाइम',
    p1VipPassSubtag: 'VIP पास',
    p1SaleOffBadge: '60% छूट',
    p1BarReady: (rem, freeMax, plusMax) =>
        '$rem/$freeMax मुफ़्त → $plusMax/$plusMax तुरंत',
    p1BarCooldown: (cd, unlocked, plusMax) =>
        'प्रतीक्षा $cd → $unlocked/$plusMax अभी खोलें',
    p1BarExhausted: (cd) => '0 शेष ($cd) → +3 बारी अभी खोलें',
    p1Row1Title: '6 रीडिंग / दिन',
    p1Row1Badge: '3 घंटे प्रतीक्षा नहीं',
    p1Row2Title: 'सभी विज्ञापन बंद',
    p1Row2Badge: '0 बैनर व वीडियो',
    p1Row3Title: 'सभी मोड और समय अनलॉक',
    p1Row3Badge: 'तुरंत उपलब्ध',
    p1Row4Title: 'एक बार की खरीदारी',
    p1Row4Badge: 'कोई सब्सक्रिप्शन नहीं',
    p1ShortFootnote:
        'हर रात 00:00 बजे 6 बारी रीसेट · कभी विज्ञापन नहीं देखना पड़ेगा।',
    originalPriceFormatted: '₹999',
    salePriceFormatted: '₹399',
    sheetPrimaryCtaPrefix: '✦ AstraCue Plus अनलॉक करें',
    sheetPrimaryCta: '✦ AstraCue Plus अनलॉक करें — ₹399',
    sheetRestoreAction: 'खरीदारी रीस्टोर करें',
    sheetLaterAction: 'बाद में',
    previewToastMessage: 'AstraCue Plus (₹399) UI प्रीव्यू तैयार है।',
    vipHeaderBadge: 'VIP PASS',
    vipSemanticsLabel: 'AstraCue VIP पास, आजीवन विशेषाधिकार सक्रिय हैं।',
    vipEnergyLabel: 'वीआईपी ऊर्जा',
    vipEnergyStatus: (rem, max) => 'शेष $rem/$max चक्र · कोई प्रतीक्षा नहीं',
    vipAuspiciousTag: 'शुभ मुहूर्त',
    vipAuspiciousDefaultWindow: '13:00 — 15:00',
    vipAuspiciousNote: 'कुंडली के लिए सर्वोत्तम समय',
    vipSheetTitle: 'ASTRACUE VIP',
    vipSheetSubtitle: 'आजीवन विशेषाधिकार सक्रिय हैं।',
    vipSheetActiveBadge: 'सक्रिय',
    vipPerk1Title: 'प्रतिदिन 6 विश्लेषण',
    vipPerk1Desc: 'दोगुनी क्षमता और बिना किसी 3 घंटे के अंतराल के',
    vipPerk2Title: '2 घंटे का शुभ मुहूर्त',
    vipPerk2Desc: 'आपकी कुंडली के अनुसार दिन का सर्वोत्तम काल',
    vipPerk3Title: 'कार्य मार्गदर्शन अनलॉक',
    vipPerk3Desc: 'बिना विज्ञापन देखे पूर्ण मार्गदर्शन उपलब्ध',
    vipPerk4Title: 'विशुद्ध अनुभव',
    vipPerk4Desc: 'आजीवन 100% विज्ञापन-मुक्त अनुभव',
    vipCloseCta: 'समझ गया · आगे बढ़ें',
  );

  static final _PlusLocalizedCopy _zh = _PlusLocalizedCopy(
    headerSemanticsLabel: 'AstraCue Plus，立即解锁每日6次解读并去除广告',
    t3CurrentLabel: '当前',
    t3ReadyStatus: (rem, max) => '剩余 $rem/$max 次',
    t3TimerStatus: (rem, max, cd) => '$rem/$max · ⏱ $cd',
    t3PlusActionLabel: '6次即刻 · 免广告',
    p1HeaderSubtitle: '完整解锁',
    p1LifetimeTag: '永久版',
    p1VipPassSubtag: '尊享通行证',
    p1SaleOffBadge: '立省 60%',
    p1BarReady: (rem, freeMax, plusMax) =>
        '免费 $rem/$freeMax → 即刻 $plusMax/$plusMax 次',
    p1BarCooldown: (cd, unlocked, plusMax) =>
        '恢复中 $cd → 立即解锁 $unlocked/$plusMax 次',
    p1BarExhausted: (cd) => '已用完 ($cd) → 立即解锁 +3 次',
    p1Row1Title: '每日 6 次解读',
    p1Row1Badge: '免除3小时冷却',
    p1Row2Title: '彻底关闭所有广告',
    p1Row2Badge: '0 横幅与视频',
    p1Row3Title: '解锁全部模式与时段',
    p1Row3Badge: '自由畅选',
    p1Row4Title: '一次购买永久有效',
    p1Row4Badge: '无月费订阅',
    p1ShortFootnote: '每日 00:00 重置 6 次额度 · 绝不强制观看激励广告。',
    originalPriceFormatted: '¥88',
    salePriceFormatted: '¥35',
    sheetPrimaryCtaPrefix: '✦ 解锁 AstraCue Plus',
    sheetPrimaryCta: '✦ 解锁 AstraCue Plus — ¥35',
    sheetRestoreAction: '恢复购买',
    sheetLaterAction: '稍后再说',
    previewToastMessage: 'AstraCue Plus (¥35) 界面预览已就绪。',
    vipHeaderBadge: '尊享通行证',
    vipSemanticsLabel: 'AstraCue VIP 通行证，终身特权已激活',
    vipEnergyLabel: 'VIP 能量',
    vipEnergyStatus: (rem, max) => '剩余 $rem/$max 次 · 零等待',
    vipAuspiciousTag: '吉时良辰',
    vipAuspiciousDefaultWindow: '13:00 — 15:00',
    vipAuspiciousNote: '命盘能量巅峰时段',
    vipSheetTitle: 'ASTRACUE VIP',
    vipSheetSubtitle: '终身特权生效中',
    vipSheetActiveBadge: '已激活',
    vipPerk1Title: '每日 6 次星象解读',
    vipPerk1Desc: '翻倍解读次数，无需等待 3 小时冷却',
    vipPerk2Title: '2 小时专属吉时',
    vipPerk2Desc: '基于生辰命盘精算每日最佳能量时段',
    vipPerk3Title: '行动指南全量解锁',
    vipPerk3Desc: '无需观看广告，即刻查看宜忌指导',
    vipPerk4Title: '纯净专注体验',
    vipPerk4Desc: '终身 100% 免除一切广告干扰',
    vipCloseCta: '已知晓 · 继续使用',
  );

  static final _PlusLocalizedCopy _ko = _PlusLocalizedCopy(
    headerSemanticsLabel: 'AstraCue Plus, 즉시 6회 리딩 잠금 해제 및 광고 제거',
    t3CurrentLabel: '현재',
    t3ReadyStatus: (rem, max) => '$rem/$max회 남음',
    t3TimerStatus: (rem, max, cd) => '$rem/$max · ⏱ $cd',
    t3PlusActionLabel: '6회 즉시 · 광고 제거',
    p1HeaderSubtitle: '전체 잠금 해제',
    p1LifetimeTag: '평생 소장',
    p1VipPassSubtag: 'VIP 패스',
    p1SaleOffBadge: '60% 할인',
    p1BarReady: (rem, freeMax, plusMax) =>
        '무료 $rem/$freeMax → 즉시 $plusMax/$plusMax회',
    p1BarCooldown: (cd, unlocked, plusMax) =>
        '대기 $cd → 지금 $unlocked/$plusMax회 해제',
    p1BarExhausted: (cd) => '소진 ($cd) → 지금 +3회 해제',
    p1Row1Title: '일일 6회 분석 리딩',
    p1Row1Badge: '3시간 대기 없음',
    p1Row2Title: '모든 광고 완전 제거',
    p1Row2Badge: '배너·영상 0개',
    p1Row3Title: '모든 모드 및 시간대 해제',
    p1Row3Badge: '즉시 자유 선택',
    p1Row4Title: '1회 구매로 평생 이용',
    p1Row4Badge: '월 구독료 없음',
    p1ShortFootnote: '매일 00:00에 6회 초기화 · 보상형 광고를 강제하지 않습니다.',
    originalPriceFormatted: '₩16,000',
    salePriceFormatted: '₩6,600',
    sheetPrimaryCtaPrefix: '✦ AstraCue Plus 잠금 해제',
    sheetPrimaryCta: '✦ AstraCue Plus 잠금 해제 — ₩6,600',
    sheetRestoreAction: '구매 복원',
    sheetLaterAction: '나중에',
    previewToastMessage: 'AstraCue Plus (₩6,600) UI 프리뷰가 준비되었습니다.',
    vipHeaderBadge: 'VIP 패스',
    vipSemanticsLabel: 'AstraCue VIP 패스, 평생 특권이 활성화되었습니다',
    vipEnergyLabel: 'VIP 에너지',
    vipEnergyStatus: (rem, max) => '남은 횟수 $rem/$max회 · 대기 없음',
    vipAuspiciousTag: '길시 (황도길시)',
    vipAuspiciousDefaultWindow: '13:00 — 15:00',
    vipAuspiciousNote: '사주 명식 최적의 대길 시간대',
    vipSheetTitle: 'ASTRACUE VIP',
    vipSheetSubtitle: '평생 특권 활성화 중',
    vipSheetActiveBadge: '활성화됨',
    vipPerk1Title: '매일 6회 심층 분석',
    vipPerk1Desc: '2배 혜택 및 3시간 대기 시간 전면 해제',
    vipPerk2Title: '2시간 맞춤 황도길시',
    vipPerk2Desc: '사주 명식 기반 하루 중 가장 상서로운 시간 안내',
    vipPerk3Title: '행동 가이드 전면 개방',
    vipPerk3Desc: '광고 시청 없이 권장 및 주의 사항 즉시 확인',
    vipPerk4Title: '순수한 몰입 환경',
    vipPerk4Desc: '평생 100% 광고 없는 청정 환경',
    vipCloseCta: '확인 · 바로 시작',
  );
}
