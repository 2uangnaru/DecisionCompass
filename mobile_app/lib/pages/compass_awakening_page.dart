import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_profile.dart';
import '../data/models/models.dart' as engine;
import '../l10n/app_localizations.dart';
import '../local_engine/astronomy/astronomy.dart';
import '../local_engine/vedic/vedic.dart';
import '../models.dart';
import '../reading_dependencies.dart';
import '../theme.dart';
import 'home_page.dart';

/// Helper computing the 6 personalized metaphysical pillars for a birth date.
class CompassMetaphysicalPillars {
  const CompassMetaphysicalPillars({
    required this.zodiacSign,
    required this.zodiacName,
    required this.planetName,
    required this.planetGlyph,
    required this.vedicNakshatra,
    required this.lifePathNumber,
    required this.elementName,
    required this.elementIcon,
    required this.animalName,
    required this.animalIcon,
  });

  final ZodiacSign zodiacSign;
  final String zodiacName;
  final String planetName;
  final String planetGlyph;
  final String vedicNakshatra;
  final int lifePathNumber;
  final String elementName;
  final String elementIcon;
  final String animalName;
  final String animalIcon;

  static CompassMetaphysicalPillars fromProfile(
    AppProfile profile,
    AppLocalizations l10n,
    String langCode,
  ) {
    final date = profile.birthDate;

    // 1. Cung Hoàng Đạo
    final sign = profile.zodiacSign;
    final zName = _localizedZodiac(l10n, sign);

    // 2. Hành Tinh Bảo Hộ (Ruling Planet)
    final (pName, pGlyph) = _rulingPlanet(sign, langCode);

    // 3. Chòm Sao Vệ Đà (27 Nakshatras)
    final vName = _vedicNakshatra(date);

    // 4. Số Chủ Đạo Thần Số Học (Life Path Number)
    final lp = _lifePath(date);

    // 5. Ngũ Hành & 6. Địa Chi Con Giáp
    final (eName, eIcon, aName, aIcon) = _easternNatal(date, langCode);

    return CompassMetaphysicalPillars(
      zodiacSign: sign,
      zodiacName: zName,
      planetName: pName,
      planetGlyph: pGlyph,
      vedicNakshatra: vName,
      lifePathNumber: lp,
      elementName: eName,
      elementIcon: eIcon,
      animalName: aName,
      animalIcon: aIcon,
    );
  }

  static String _localizedZodiac(AppLocalizations l10n, ZodiacSign sign) {
    return switch (sign) {
      ZodiacSign.aries => l10n.zodiacAries,
      ZodiacSign.taurus => l10n.zodiacTaurus,
      ZodiacSign.gemini => l10n.zodiacGemini,
      ZodiacSign.cancer => l10n.zodiacCancer,
      ZodiacSign.leo => l10n.zodiacLeo,
      ZodiacSign.virgo => l10n.zodiacVirgo,
      ZodiacSign.libra => l10n.zodiacLibra,
      ZodiacSign.scorpio => l10n.zodiacScorpio,
      ZodiacSign.sagittarius => l10n.zodiacSagittarius,
      ZodiacSign.capricorn => l10n.zodiacCapricorn,
      ZodiacSign.aquarius => l10n.zodiacAquarius,
      ZodiacSign.pisces => l10n.zodiacPisces,
    };
  }

  static (String, String) _rulingPlanet(ZodiacSign sign, String lang) {
    final isVi = lang.startsWith('vi');
    return switch (sign) {
      ZodiacSign.aries => (isVi ? 'Sao Hỏa' : 'Mars', '♂️'),
      ZodiacSign.taurus => (isVi ? 'Sao Kim' : 'Venus', '♀️'),
      ZodiacSign.gemini => (isVi ? 'Sao Thủy' : 'Mercury', '☿️'),
      ZodiacSign.cancer => (isVi ? 'Mặt Trăng' : 'Moon', '☽'),
      ZodiacSign.leo => (isVi ? 'Mặt Trời' : 'Sun', '☉'),
      ZodiacSign.virgo => (isVi ? 'Sao Thủy' : 'Mercury', '☿️'),
      ZodiacSign.libra => (isVi ? 'Sao Kim' : 'Venus', '♀️'),
      ZodiacSign.scorpio => (isVi ? 'Sao Diêm Vương' : 'Pluto', '♇'),
      ZodiacSign.sagittarius => (isVi ? 'Sao Mộc' : 'Jupiter', '♃'),
      ZodiacSign.capricorn => (isVi ? 'Sao Thổ' : 'Saturn', '♄'),
      ZodiacSign.aquarius => (isVi ? 'Sao Thiên Vương' : 'Uranus', '♅'),
      ZodiacSign.pisces => (isVi ? 'Sao Hải Vương' : 'Neptune', '♆'),
    };
  }

  static String _vedicNakshatra(DateTime birthDate) {
    final ms = birthDate.millisecondsSinceEpoch.toDouble();
    final sky = skyAt(ms);
    final moonTropical = sky.positions['moon'];
    int idx;
    if (moonTropical != null) {
      final ayanamsa = ayanamsaLahiri(ms);
      final sidereal = toSidereal(moonTropical, ayanamsa);
      idx = (sidereal / (360.0 / 27.0)).floor() % 27;
    } else {
      idx = (birthDate.year * 372 + birthDate.month * 31 + birthDate.day) % 27;
    }
    return nakshatraNames[idx];
  }

  static int _lifePath(DateTime date) {
    int digitSum(int n) =>
        n.abs().toString().split('').fold<int>(0, (s, c) => s + int.parse(c));
    int reduce(int n) => 1 + ((n - 1) % 9);
    final sum = digitSum(date.year) + digitSum(date.month) + digitSum(date.day);
    return reduce(sum);
  }

  static (String, String, String, String) _easternNatal(
    DateTime date,
    String lang,
  ) {
    final year = date.year;
    final isVi = lang.startsWith('vi');

    const animalsVi = <String>[
      'Thân',
      'Dậu',
      'Tuất',
      'Hợi',
      'Tý',
      'Sửu',
      'Dần',
      'Mão',
      'Thìn',
      'Tỵ',
      'Ngọ',
      'Mùi',
    ];
    const animalsEn = <String>[
      'Monkey',
      'Rooster',
      'Dog',
      'Pig',
      'Rat',
      'Ox',
      'Tiger',
      'Rabbit',
      'Dragon',
      'Snake',
      'Horse',
      'Goat',
    ];
    const canVi = <String>[
      'Canh',
      'Tân',
      'Nhâm',
      'Quý',
      'Giáp',
      'Ất',
      'Bính',
      'Đinh',
      'Mậu',
      'Kỷ',
    ];
    const icons = <String>[
      '🐒',
      '🐓',
      '🐕',
      '🐖',
      '🐀',
      '🐂',
      '🐅',
      '🐈',
      '🐉',
      '🐍',
      '🐎',
      '🐐',
    ];

    final animalIdx = year % 12;
    final canIdx = year % 10;
    final aIcon = icons[animalIdx];
    final aName = isVi
        ? '${canVi[canIdx]} ${animalsVi[animalIdx]}'
        : '${animalsEn[animalIdx]} (${canVi[canIdx]})';

    final canVal = <int>[4, 4, 5, 5, 1, 1, 2, 2, 3, 3][canIdx];
    final chiVal = <int>[1, 1, 2, 2, 0, 0, 1, 1, 2, 2, 0, 0][animalIdx];
    var elemVal = canVal + chiVal;
    if (elemVal > 5) elemVal -= 5;

    final (eName, eIcon) = switch (elemVal) {
      1 => (isVi ? 'Mệnh Kim' : 'Metal', '⚔️'),
      2 => (isVi ? 'Mệnh Thủy' : 'Water', '🌊'),
      3 => (isVi ? 'Mệnh Hỏa' : 'Fire', '🔥'),
      4 => (isVi ? 'Mệnh Thổ' : 'Earth', '🏔️'),
      _ => (isVi ? 'Mệnh Mộc' : 'Wood', '🌿'),
    };

    return (eName, eIcon, aName, aIcon);
  }
}

/// The celestial transition screen displayed when a user finishes Onboarding.
///
/// Features the approved "Thiên Bàn 6 Trụ Bản Mệnh" (Approach 1):
/// - Central dormant Compass crucible.
/// - 6 outer satellite nodes (Zodiac, Planet, Vedic, LifePath, Element, Branch)
///   arranged in a sacred hexagram.
/// - Outer nodes illuminate sequentially in gold starlight (0% clunky lines).
/// - Once all 6 ignite, the central Compass awakens with a radiant golden aura.
/// - Pre-warms HomePage calculations under the hood for a 100% lag-free reveal.
class CompassAwakeningPage extends StatefulWidget {
  const CompassAwakeningPage({
    super.key,
    required this.profile,
    required this.dependencies,
    this.animationDuration = const Duration(milliseconds: 3600),
    this.onCompleted,
  });

  final AppProfile profile;
  final ReadingDependencies dependencies;
  final Duration animationDuration;
  final VoidCallback? onCompleted;

  @override
  State<CompassAwakeningPage> createState() => _CompassAwakeningPageState();
}

class _CompassAwakeningPageState extends State<CompassAwakeningPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _navigated = false;
  late final Future<engine.DailyBrief?> _prewarmedBrief;
  late final DateTime _prewarmedDate;

  @override
  void initState() {
    super.initState();

    // Pre-warm HomePage readings under the hood concurrently
    _prewarmedDate = widget.dependencies.nowLocal();
    _prewarmedBrief = widget.dependencies.dailyBriefProvider
        .preview(widget.profile)
        .catchError((Object _) => null);

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishAndNavigate();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finishAndNavigate() {
    if (_navigated) return;
    _navigated = true;

    if (widget.onCompleted != null) {
      widget.onCompleted!();
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) => HomePage(
          profile: widget.profile,
          dependencies: widget.dependencies,
          initialDailyBrief: _prewarmedBrief,
          initialDailyBriefDate: _prewarmedDate,
        ),
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final pillars = CompassMetaphysicalPillars.fromProfile(
      widget.profile,
      l10n,
      locale.languageCode,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF060911),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finishAndNavigate,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final isCentralAwakened = t >= 0.82;

            // Milestones for 6 nodes (0.0 to 0.80)
            final n1 = (t >= 0.08); // Cung Hoàng Đạo
            final n2 = (t >= 0.22); // Sao Bảo Hộ
            final n3 = (t >= 0.36); // Chòm Vệ Đà
            final n4 = (t >= 0.50); // Số Chủ Đạo
            final n5 = (t >= 0.64); // Ngũ Hành
            final n6 = (t >= 0.78); // Con Giáp Địa Chi

            // Active step text
            String headline;
            if (isCentralAwakened) {
              headline = l10n.compassAwakeningReady;
            } else if (n6) {
              headline =
                  '✦ ${l10n.orbitZiWei} · ${pillars.animalName} ${pillars.animalIcon}';
            } else if (n5) {
              headline = '✦ ${pillars.elementName} ${pillars.elementIcon}';
            } else if (n4) {
              headline =
                  '✦ ${l10n.compassPillarLifePath} ${pillars.lifePathNumber}';
            } else if (n3) {
              headline = '✦ ${pillars.vedicNakshatra}';
            } else if (n2) {
              headline = '✦ ${pillars.planetName} ${pillars.planetGlyph}';
            } else if (n1) {
              headline = '✦ ${pillars.zodiacName} ${pillars.zodiacSign.glyph}';
            } else {
              headline = l10n.compassAwakeningConnecting;
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                // Starry backdrop painter
                const CustomPaint(painter: _CosmicBackdropPainter()),

                // Sacred Astrolabe Disk & 6 Hexagonal Pillars
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 380,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dotted / Dashed Celestial Orbit Guide Ring
                        Transform.rotate(
                          angle: t * math.pi * 0.4,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CompassColors.gold.withValues(
                                  alpha: 0.15,
                                ),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),

                        // Outward Shockwave when central compass ignites
                        if (isCentralAwakened)
                          _AwakeningShockwave(
                            progress: ((t - 0.82) / 0.18).clamp(0.0, 1.0),
                          ),

                        // Central Compass Anchor (Dormant -> Awakened)
                        _CentralCompassAnchor(isAwakened: isCentralAwakened),

                        // 6 Hexagonal Satellite Nodes (Radius ~128px)
                        // 1. Top (North - 0°): Cung Hoàng Đạo
                        _SatelliteNode(
                          angle: -math.pi / 2, // 12 o'clock
                          radius: 128,
                          category: l10n.compassPillarZodiac,
                          value:
                              '${pillars.zodiacName} ${pillars.zodiacSign.glyph}',
                          glyph: pillars.zodiacSign.glyph,
                          isActive: n1,
                        ),

                        // 2. Top-Right (60°): Sao Bảo Hộ
                        _SatelliteNode(
                          angle: -math.pi / 6, // 2 o'clock
                          radius: 128,
                          category: l10n.compassPillarPlanet,
                          value: '${pillars.planetName} ${pillars.planetGlyph}',
                          glyph: pillars.planetGlyph,
                          isActive: n2,
                        ),

                        // 3. Bottom-Right (120°): Chòm Sao Vệ Đà
                        _SatelliteNode(
                          angle: math.pi / 6, // 4 o'clock
                          radius: 128,
                          category: l10n.compassPillarVedic,
                          value: pillars.vedicNakshatra,
                          glyph: '✦',
                          isActive: n3,
                        ),

                        // 4. Bottom (South - 180°): Số Chủ Đạo
                        _SatelliteNode(
                          angle: math.pi / 2, // 6 o'clock
                          radius: 128,
                          category: l10n.compassPillarLifePath,
                          value:
                              '${l10n.compassPillarLifePath} ${pillars.lifePathNumber}',
                          glyph: '${pillars.lifePathNumber}',
                          isActive: n4,
                        ),

                        // 5. Bottom-Left (240°): Bản Mệnh Ngũ Hành
                        _SatelliteNode(
                          angle: 5 * math.pi / 6, // 8 o'clock
                          radius: 128,
                          category: l10n.compassPillarElement,
                          value:
                              '${pillars.elementName} ${pillars.elementIcon}',
                          glyph: pillars.elementIcon,
                          isActive: n5,
                        ),

                        // 6. Top-Left (300°): Tử Vi
                        _SatelliteNode(
                          angle: -5 * math.pi / 6, // 10 o'clock
                          radius: 128,
                          category: l10n.orbitZiWei,
                          value: '${pillars.animalName} ${pillars.animalIcon}',
                          glyph: pillars.animalIcon,
                          isActive: n6,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Status Section
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 48,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCentralAwakened
                            ? l10n.compassAwakeningReady.toUpperCase()
                            : l10n.compassAwakeningConnecting.toUpperCase(),
                        style: TextStyle(
                          color: CompassColors.gold.withValues(alpha: 0.9),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          headline,
                          key: ValueKey<String>(headline),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Gold Progress Track
                      SizedBox(
                        width: 160,
                        height: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: t,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              CompassColors.gold,
                            ),
                          ),
                        ),
                      ),
                    ],
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

/// Central Compass Anchor featuring a custom vector Celestial Compass Rose.
class _CentralCompassAnchor extends StatelessWidget {
  const _CentralCompassAnchor({required this.isAwakened});

  final bool isAwakened;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      width: isAwakened ? 88 : 80,
      height: isAwakened ? 88 : 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isAwakened
              ? const [Color(0xFF382912), Color(0xFF1A1822)]
              : const [Color(0xFF161B2B), Color(0xFF0D101C)],
        ),
        border: Border.all(
          color: isAwakened
              ? CompassColors.gold
              : Colors.white.withValues(alpha: 0.18),
          width: isAwakened ? 2.0 : 1.2,
        ),
        boxShadow: isAwakened
            ? [
                BoxShadow(
                  color: CompassColors.gold.withValues(alpha: 0.80),
                  blurRadius: 42,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: const Color(0xFFFFD56B).withValues(alpha: 0.45),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeOutBack,
          turns: isAwakened ? 0.0 : -75.0 / 360.0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 450),
            opacity: isAwakened ? 1.0 : 0.38,
            child: SizedBox(
              width: isAwakened ? 64 : 58,
              height: isAwakened ? 64 : 58,
              child: CustomPaint(
                painter: _CelestialCompassRosePainter(isAwakened: isAwakened),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom-crafted faceted Celestial Compass Rose (Astrolabe needle).
class _CelestialCompassRosePainter extends CustomPainter {
  const _CelestialCompassRosePainter({required this.isAwakened});

  final bool isAwakened;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Outer subtle dashed compass rings
    final ringPaint = Paint()
      ..color = CompassColors.gold.withValues(alpha: isAwakened ? 0.55 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawCircle(center, r * 0.92, ringPaint);

    final innerRingPaint = Paint()
      ..color = CompassColors.gold.withValues(alpha: isAwakened ? 0.35 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawCircle(center, r * 0.72, innerRingPaint);
    canvas.drawCircle(center, r * 0.38, innerRingPaint);

    // Cardinal tick dots (North, East, South, West)
    final tickPaint = Paint()
      ..color = isAwakened ? const Color(0xFFFFE082) : Colors.white38
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy - r * 0.92), 1.8, tickPaint);
    canvas.drawCircle(Offset(center.dx + r * 0.92, center.dy), 1.4, tickPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + r * 0.92), 1.4, tickPaint);
    canvas.drawCircle(Offset(center.dx - r * 0.92, center.dy), 1.4, tickPaint);

    // 4 Diagonal minor needle points
    final diagPaint1 = Paint()
      ..color = const Color(0xFFD49B35)
          .withValues(alpha: isAwakened ? 0.8 : 0.4)
      ..style = PaintingStyle.fill;
    final diagPaint2 = Paint()
      ..color = const Color(0xFF996A1A)
          .withValues(alpha: isAwakened ? 0.8 : 0.4)
      ..style = PaintingStyle.fill;

    void drawFacetedDiagonal(double angle) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final p1 = Path()
        ..moveTo(0, 0)
        ..lineTo(-r * 0.08, 0)
        ..lineTo(0, -r * 0.50)
        ..close();
      canvas.drawPath(p1, diagPaint1);
      final p2 = Path()
        ..moveTo(0, 0)
        ..lineTo(r * 0.08, 0)
        ..lineTo(0, -r * 0.50)
        ..close();
      canvas.drawPath(p2, diagPaint2);
      canvas.restore();
    }

    drawFacetedDiagonal(math.pi / 4); // NE
    drawFacetedDiagonal(3 * math.pi / 4); // SE
    drawFacetedDiagonal(-3 * math.pi / 4); // SW
    drawFacetedDiagonal(-math.pi / 4); // NW

    // East / West primary needles
    final ewLight = Paint()
      ..color = isAwakened ? const Color(0xFFFFDF7A) : Colors.white54
      ..style = PaintingStyle.fill;
    final ewDark = Paint()
      ..color = isAwakened ? const Color(0xFFD49B35) : Colors.white30
      ..style = PaintingStyle.fill;

    // East needle
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx, center.dy - r * 0.14)
        ..lineTo(center.dx + r * 0.68, center.dy)
        ..close(),
      ewLight,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx, center.dy + r * 0.14)
        ..lineTo(center.dx + r * 0.68, center.dy)
        ..close(),
      ewDark,
    );

    // West needle
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx, center.dy - r * 0.14)
        ..lineTo(center.dx - r * 0.68, center.dy)
        ..close(),
      ewDark,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx, center.dy + r * 0.14)
        ..lineTo(center.dx - r * 0.68, center.dy)
        ..close(),
      ewLight,
    );

    // North Needle (celestial radiant gold)
    final northLight = Paint()
      ..color = isAwakened ? const Color(0xFFFFF0A6) : Colors.white70
      ..style = PaintingStyle.fill;
    final northDark = Paint()
      ..color = isAwakened ? const Color(0xFFE5A93C) : Colors.white38
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx - r * 0.16, center.dy)
        ..lineTo(center.dx, center.dy - r * 0.88)
        ..close(),
      northLight,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + r * 0.16, center.dy)
        ..lineTo(center.dx, center.dy - r * 0.88)
        ..close(),
      northDark,
    );

    // South Needle (antique bronze gold)
    final southLight = Paint()
      ..color = isAwakened ? const Color(0xFFC48B28) : Colors.white38
      ..style = PaintingStyle.fill;
    final southDark = Paint()
      ..color = isAwakened ? const Color(0xFF8A5D12) : Colors.white24
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx - r * 0.16, center.dy)
        ..lineTo(center.dx, center.dy + r * 0.88)
        ..close(),
      southLight,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + r * 0.16, center.dy)
        ..lineTo(center.dx, center.dy + r * 0.88)
        ..close(),
      southDark,
    );

    // Center Pivot Jewel (outer ring + glowing pearl core)
    final pivotBase = Paint()
      ..color = isAwakened ? const Color(0xFF281F12) : const Color(0xFF101422)
      ..style = PaintingStyle.fill;
    final pivotRing = Paint()
      ..color = isAwakened ? const Color(0xFFFFD56B) : Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final pivotCore = Paint()
      ..color = isAwakened ? const Color(0xFFFFF7DC) : Colors.white70
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, r * 0.16, pivotBase);
    canvas.drawCircle(center, r * 0.16, pivotRing);
    canvas.drawCircle(center, r * 0.16, pivotRing);
    canvas.drawCircle(center, r * 0.08, pivotCore);
  }

  @override
  bool shouldRepaint(covariant _CelestialCompassRosePainter oldDelegate) =>
      oldDelegate.isAwakened != isAwakened;
}

/// A satellite node on the hexagonal celestial orbit.
class _SatelliteNode extends StatelessWidget {
  const _SatelliteNode({
    required this.angle,
    required this.radius,
    required this.category,
    required this.value,
    required this.glyph,
    required this.isActive,
  });

  final double angle;
  final double radius;
  final String category;
  final String value;
  final String glyph;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final x = math.cos(angle) * radius;
    final y = math.sin(angle) * radius;

    return Transform.translate(
      offset: Offset(x, y),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        opacity: isActive ? 1.0 : 0.25,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFF252026)
                    : const Color(0xFF111726),
                border: Border.all(
                  color: isActive
                      ? CompassColors.gold
                      : Colors.white.withValues(alpha: 0.15),
                  width: isActive ? 1.5 : 1.0,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: CompassColors.gold.withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  glyph,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              category,
              style: TextStyle(
                color: isActive
                    ? CompassColors.gold.withValues(alpha: 0.9)
                    : Colors.white30,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              value,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shockwave circle expanding outward upon central compass awakening.
class _AwakeningShockwave extends StatelessWidget {
  const _AwakeningShockwave({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + progress * 2.5;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: CompassColors.gold.withValues(alpha: opacity * 0.8),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Gentle starlight cosmic backdrop painter.
class _CosmicBackdropPainter extends CustomPainter {
  const _CosmicBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF060911);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Subtle warm center nebula
    final center = Offset(size.width / 2, size.height * 0.45);
    final radial = RadialGradient(
      center: Alignment.center,
      radius: 0.65,
      colors: [CompassColors.gold.withValues(alpha: 0.06), Colors.transparent],
    );
    final auraPaint = Paint()
      ..shader = radial.createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.55),
      );
    canvas.drawCircle(center, size.width * 0.55, auraPaint);

    // Gentle fixed star sparkles
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    final goldStarPaint = Paint()
      ..color = CompassColors.gold.withValues(alpha: 0.7);

    final stars = <(double, double, double, bool)>[
      (size.width * 0.15, size.height * 0.12, 1.2, false),
      (size.width * 0.82, size.height * 0.15, 1.5, true),
      (size.width * 0.28, size.height * 0.28, 1.0, false),
      (size.width * 0.75, size.height * 0.32, 1.3, false),
      (size.width * 0.12, size.height * 0.55, 1.4, true),
      (size.width * 0.88, size.height * 0.60, 1.1, false),
      (size.width * 0.22, size.height * 0.78, 1.5, false),
      (size.width * 0.78, size.height * 0.82, 1.2, true),
    ];

    for (final s in stars) {
      canvas.drawCircle(
        Offset(s.$1, s.$2),
        s.$3,
        s.$4 ? goldStarPaint : starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
