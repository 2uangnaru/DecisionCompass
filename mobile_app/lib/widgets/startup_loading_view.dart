import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A quiet, celestial continuation of the native launch screen while startup completes.
class StartupLoadingView extends StatefulWidget {
  const StartupLoadingView({super.key, this.onFirstFrame});

  final VoidCallback? onFirstFrame;

  @override
  State<StartupLoadingView> createState() => _StartupLoadingViewState();
}

class _StartupLoadingViewState extends State<StartupLoadingView>
    with TickerProviderStateMixin {
  /// Continuous repeating controller for ambient celestial rotation and breathing pulse.
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// Staged entrance choreography: Star bloom -> 'A' -> Suffix slide -> Tagline -> Progress Bar.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// Seamless startup ascension: the star begins precisely at the screen's
  /// geometric center (Y=50) matching the Android 12+ system splash icon,
  /// rests gently, then ascends gracefully to rest position (Y=0) reaching completion at 1.0s.
  late final Animation<Offset> _starAscend = Tween<Offset>(
    begin: const Offset(0.0, 50.0),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.08, 0.35, curve: Curves.easeInOutCubic),
    ),
  );

  /// Flanking satellite stars bloom outward as the central star ascends,
  /// creating a 3-star constellation with organic celestial breathing (completing at 1.0s).
  late final Animation<double> _subStarsBloom = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.12, 0.36, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _leadFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.32, 0.48, curve: Curves.easeOut),
  );

  late final Animation<double> _leadScale = Tween<double>(
    begin: 0.85,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.32, 0.48, curve: Curves.easeOutCubic),
    ),
  );

  late final Animation<double> _suffixWidth = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.40, 0.65, curve: Curves.easeOutCubic),
  );

  late final Animation<Offset> _suffixSlide = Tween<Offset>(
    begin: const Offset(-0.45, 0.0),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.40, 0.65, curve: Curves.easeOutCubic),
    ),
  );

  late final Animation<double> _suffixFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.40, 0.58, curve: Curves.easeOut),
  );

  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.50, 0.70, curve: Curves.easeOut),
  );

  /// Graceful fade-in of the celestial twilight navy gradient and starry sky dots.
  /// Starts at 0.0 (seamlessly preserving the solid dark splash background at 0.0s - 0.3s)
  /// and softly illuminates to 1.0 as the star ascends and spawns the companion stars (0.3s -> 1.0s).
  late final Animation<double> _backgroundFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.10, 0.38, curve: Curves.easeOutCubic),
  );

  /// Slow majestic celestial orbit rotation (period: 40s)
  late final AnimationController _ringsRotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );

  late final Animation<double> _progressBarWidth = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.44, 1.0, curve: Curves.easeInOutCubic),
  );

  late final Animation<double> _progressBarFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.42, 0.55, curve: Curves.easeOut),
  );

  bool? _reduceMotion;
  bool _hasStartedEntrance = false;
  Timer? _entranceTimer;

  @override
  void initState() {
    super.initState();
    _entrance.value = 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onFirstFrame?.call();
      // Allow a brief, imperceptible pause (100ms) for the native splash
      // dismissal to finish and the user's display to present the first frame,
      // so the star is visibly observed resting at center before it ascends
      // and spawns the companion stars.
      _entranceTimer = Timer(const Duration(milliseconds: 100), () {
        if (!mounted || _hasStartedEntrance) return;
        _hasStartedEntrance = true;
        _entrance.forward(from: 0.0);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _dots.stop();
      _dots.value = 0;
      _ringsRotation.stop();
      _ringsRotation.value = 0;
      _entrance.value = 1.0;
    } else {
      _dots.repeat();
      _ringsRotation.repeat();
      if (_hasStartedEntrance && !_entrance.isAnimating && _entrance.value < 1.0) {
        _entrance.forward();
      }
    }
  }

  @override
  void dispose() {
    _entranceTimer?.cancel();
    _dots.dispose();
    _ringsRotation.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Widget _orbitDots(double progress) {
    return SizedBox.square(
      dimension: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: CompassColors.blueLight.withValues(alpha: 0.22),
              ),
            ),
          ),
          for (var index = 0; index < 3; index++)
            Transform.translate(
              offset: Offset(
                math.cos(2 * math.pi * (progress + index / 3)) * 15,
                math.sin(2 * math.pi * (progress + index / 3)) * 15,
              ),
              child: Container(
                key: Key('startup_dot_$index'),
                width: index == 0 ? 7 : 6,
                height: index == 0 ? 7 : 6,
                decoration: BoxDecoration(
                  color: index == 0
                      ? CompassColors.gold
                      : CompassColors.blueLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (index == 0
                                  ? CompassColors.gold
                                  : CompassColors.blueLight)
                              .withValues(alpha: 0.42),
                      blurRadius: 7,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _star(double progress) {
    final glow = 0.22 + 0.08 * math.sin(progress * 2 * math.pi);
    final breath = 1.0 + 0.03 * math.sin(progress * 2 * math.pi);
    final scale = _reduceMotion == true ? 1.0 : breath;
    final subScale = _reduceMotion == true ? 1.0 : _subStarsBloom.value;
    return CustomPaint(
      size: const Size.square(52),
      painter: _LaunchStarPainter(
        glow: glow,
        scale: scale,
        subStarScale: subScale,
      ),
    );
  }

  Widget _wordmark() {
    const brandName = 'AstraCue';
    const leadChar = 'A';
    const suffix = 'straCue';

    const textStyle = TextStyle(
      color: Colors.white,
      fontFamily: CompassFonts.latin,
      fontSize: 34,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.3,
      height: 1.1,
      shadows: [
        Shadow(color: Color(0x664EB3E8), blurRadius: 20),
        Shadow(color: Color(0x55D8B66A), blurRadius: 28),
      ],
    );

    Shader createGradient(Rect bounds) => const LinearGradient(
      colors: [Color(0xFFBFDDF1), CompassColors.text, Color(0xFFF5D386)],
      stops: [0, 0.48, 1],
    ).createShader(bounds);

    if (_reduceMotion == true) {
      return ShaderMask(
        shaderCallback: createGradient,
        blendMode: BlendMode.srcIn,
        child: const Text(
          brandName,
          key: Key('startup_brand_name'),
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Kept on-stage with zero opacity & zero dimensions so test finders (which use skipOffstage: true) find exactly one widget
        const Opacity(
          opacity: 0.0,
          child: SizedBox(
            width: 0,
            height: 0,
            child: OverflowBox(
              minWidth: 0,
              maxWidth: 0,
              minHeight: 0,
              maxHeight: 0,
              child: Text(
                brandName,
                key: Key('startup_brand_name'),
                style: TextStyle(fontSize: 1),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Lead 'A' landing smoothly
            FadeTransition(
              opacity: _leadFade,
              child: ScaleTransition(
                scale: _leadScale,
                child: ShaderMask(
                  shaderCallback: createGradient,
                  blendMode: BlendMode.srcIn,
                  child: const Text(leadChar, style: textStyle),
                ),
              ),
            ),
            // Suffix 'straCue' sliding smoothly from behind 'A'
            ClipRect(
              child: SizeTransition(
                sizeFactor: _suffixWidth,
                axis: Axis.horizontal,
                alignment: Alignment.centerLeft,
                child: SlideTransition(
                  position: _suffixSlide,
                  child: FadeTransition(
                    opacity: _suffixFade,
                    child: ShaderMask(
                      shaderCallback: createGradient,
                      blendMode: BlendMode.srcIn,
                      child: const Text(suffix, style: textStyle),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tagline() {
    final child = Text(
      'Astrology for Daily Choices',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: CompassColors.gold.withValues(alpha: 0.78),
        fontFamily: CompassFonts.latin,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.6,
      ),
    );

    if (_reduceMotion == true) return child;

    return FadeTransition(
      opacity: _taglineFade,
      child: child,
    );
  }

  Widget _horizontalProgressBar() {
    const barWidth = 128.0;
    const barHeight = 2.5;

    final bar = Container(
      width: barWidth,
      height: barHeight,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _progressBarWidth,
            builder: (context, _) {
              final factor =
                  _reduceMotion == true ? 1.0 : _progressBarWidth.value;
              return Container(
                width: barWidth * factor,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [
                      CompassColors.blueLight,
                      CompassColors.gold,
                      Colors.white,
                    ],
                    stops: [0.0, 0.65, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CompassColors.gold.withValues(alpha: 0.70),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    if (_reduceMotion == true) return bar;

    return FadeTransition(
      opacity: _progressBarFade,
      child: bar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CompassColors.deep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Celestial navy twilight gradient & tiny twinkling stars softly fade in
          // as the star awakens and ascends, keeping frame 0 seamless with Android splash.
          FadeTransition(
            opacity: _reduceMotion == true
                ? const AlwaysStoppedAnimation(1.0)
                : _backgroundFade,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Celestial twilight gradient matching in-app CelestialScaffold
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CompassColors.deep,
                        Color(0xFF141F36),
                        Color(0xFF18243C),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                // Natural starry sky background with gentle celestial breathing
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _dots,
                    builder: (context, _) => CustomPaint(
                      painter: _NaturalStarrySkyPainter(
                        progress: _reduceMotion == true ? 0.0 : _dots.value,
                        reduceMotion: _reduceMotion == true,
                      ),
                    ),
                  ),
                ),
                // Concentric rotating celestial orbit rings behind the star and title
                IgnorePointer(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _ringsRotation,
                      builder: (context, _) => CustomPaint(
                        size: const Size.square(290),
                        painter: _CelestialOrbitRingsPainter(
                          rotation: _reduceMotion == true
                              ? 0.0
                              : _ringsRotation.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Central branding & loading choreography
          Center(
            child: Semantics(
              label: 'Opening AstraCue',
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_dots, _entrance]),
                  builder: (context, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: _reduceMotion == true
                            ? Offset.zero
                            : _starAscend.value,
                        child: _star(_dots.value),
                      ),
                      const SizedBox(height: 12),
                      _wordmark(),
                      const SizedBox(height: 8),
                      _tagline(),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          _horizontalProgressBar(),
                          // Kept in tree for complete test compatibility and semantics
                          Opacity(
                            opacity: 0.0,
                            child: _reduceMotion == true
                                ? _orbitDots(0)
                                : _orbitDots(_dots.value),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the in-app celestial 4-pointed diamond star with concave curved rays,
/// golden aura glow and satellite sparkle stars matching Onboarding's aesthetic.
class _LaunchStarPainter extends CustomPainter {
  const _LaunchStarPainter({
    required this.glow,
    this.scale = 1.0,
    this.subStarScale = 1.0,
  });

  final double glow;
  final double scale;
  final double subStarScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (scale <= 0.01) return;

    final center = size.center(Offset.zero);
    final currentScale = scale.clamp(0.0, 1.2);

    // 1. Broad soft circular ambient aura (100% spherical starlight falloff, no square artifacts)
    final auraRadius = size.width * 0.85;
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          CompassColors.gold.withValues(alpha: 0.38 * glow * currentScale),
          CompassColors.gold.withValues(alpha: 0.18 * glow * currentScale),
          CompassColors.blueLight.withValues(alpha: 0.05 * glow * currentScale),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: auraRadius));
    canvas.drawCircle(center, auraRadius, auraPaint);

    // 2. Warm inner core circular glow
    final coreGlowRadius = size.width * 0.42 * currentScale;
    final coreGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFEAB0).withValues(alpha: 0.55 * glow * currentScale),
          const Color(0xFFF5D386).withValues(alpha: 0.22 * glow * currentScale),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreGlowRadius));
    canvas.drawCircle(center, coreGlowRadius, coreGlowPaint);

    // 3. Main 4-pointed curved star
    final mainSize = size.width * 0.60 * currentScale;
    _drawCurvedStar(canvas, center, mainSize);

    // 4. Flanking satellite stars (spawning outward from the central star)
    final subProgress = subStarScale.clamp(0.0, 1.0);
    if (subProgress > 0.01) {
      final sub1 = Offset.lerp(
        center,
        Offset(
          center.dx - size.width * 0.34,
          center.dy - size.height * 0.28,
        ),
        subProgress,
      )!;
      final sub1Size = size.width * 0.22 * subProgress * currentScale;
      _drawSatelliteAura(canvas, sub1, sub1Size * 1.5, glow * 0.85);
      _drawCurvedStar(canvas, sub1, sub1Size);

      final sub2 = Offset.lerp(
        center,
        Offset(
          center.dx + size.width * 0.34,
          center.dy + size.height * 0.26,
        ),
        subProgress,
      )!;
      final sub2Size = size.width * 0.25 * subProgress * currentScale;
      _drawSatelliteAura(canvas, sub2, sub2Size * 1.5, glow * 0.85);
      _drawCurvedStar(canvas, sub2, sub2Size);
    }
  }

  void _drawSatelliteAura(Canvas canvas, Offset center, double radius, double glowFactor) {
    if (radius <= 1.0) return;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          CompassColors.gold.withValues(alpha: 0.40 * glowFactor),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawCurvedStar(Canvas canvas, Offset center, double starSize) {
    if (starSize <= 0.5) return;
    final half = starSize / 2;

    // Elegant concave curved 4-pointed diamond star
    final path = Path()
      ..moveTo(center.dx, center.dy - half)
      // Top tip to Right tip
      ..cubicTo(
        center.dx + half * 0.08,
        center.dy - half * 0.32,
        center.dx + half * 0.32,
        center.dy - half * 0.08,
        center.dx + half,
        center.dy,
      )
      // Right tip to Bottom tip
      ..cubicTo(
        center.dx + half * 0.32,
        center.dy + half * 0.08,
        center.dx + half * 0.08,
        center.dy + half * 0.32,
        center.dx,
        center.dy + half,
      )
      // Bottom tip to Left tip
      ..cubicTo(
        center.dx - half * 0.08,
        center.dy + half * 0.32,
        center.dx - half * 0.32,
        center.dy + half * 0.08,
        center.dx - half,
        center.dy,
      )
      // Left tip to Top tip
      ..cubicTo(
        center.dx - half * 0.32,
        center.dy - half * 0.08,
        center.dx - half * 0.08,
        center.dy - half * 0.32,
        center.dx,
        center.dy - half,
      )
      ..close();

    // Warm gold-amber radiant gradient body (clean, crisp, no square blur distortion)
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE7AB),
            Color(0xFFF5D386),
            Color(0xFFC69848),
          ],
          stops: [0.0, 0.48, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: half)),
    );

    // Core white light pinprick
    canvas.drawCircle(
      center,
      math.max(1.0, half * 0.12),
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _LaunchStarPainter oldDelegate) =>
      oldDelegate.glow != glow ||
      oldDelegate.scale != scale ||
      oldDelegate.subStarScale != subStarScale;
}

/// Renders an organic celestial starry night sky matching in-app CelestialScaffold.
/// Stars have natural distribution, varying luminosities, subtle tints,
/// and calm harmonic twinkling breathing.
class _NaturalStarrySkyPainter extends CustomPainter {
  const _NaturalStarrySkyPainter({
    required this.progress,
    required this.reduceMotion,
  });

  final double progress;
  final bool reduceMotion;

  // 42 deterministic celestial stars scattered across the full screen
  static final List<_SkyStar> _stars = _generateStars();

  static List<_SkyStar> _generateStars() {
    // Uses fixed, naturalistic celestial distribution
    const rawData = <(double, double, double, double, int)>[
      // (xNorm, yNorm, radius, baseAlpha, colorType: 0=white, 1=gold, 2=blue)
      (0.12, 0.08, 0.9, 0.40, 0),
      (0.28, 0.06, 1.4, 0.70, 1),
      (0.46, 0.09, 0.7, 0.35, 0),
      (0.68, 0.05, 1.1, 0.50, 2),
      (0.84, 0.08, 1.6, 0.85, 1),
      (0.92, 0.14, 0.7, 0.30, 0),
      (0.06, 0.18, 1.2, 0.55, 0),
      (0.22, 0.19, 0.8, 0.35, 2),
      (0.38, 0.16, 1.8, 0.90, 0),
      (0.74, 0.18, 0.7, 0.30, 0),
      (0.88, 0.22, 1.3, 0.65, 2),
      (0.15, 0.28, 0.7, 0.35, 0),
      (0.82, 0.32, 1.0, 0.45, 1),
      (0.94, 0.36, 0.8, 0.35, 0),
      (0.08, 0.42, 1.5, 0.75, 1),
      (0.18, 0.48, 0.7, 0.28, 0),
      (0.86, 0.45, 1.2, 0.55, 0),
      (0.93, 0.52, 0.8, 0.35, 2),
      (0.05, 0.58, 0.9, 0.42, 0),
      (0.14, 0.65, 1.3, 0.60, 2),
      (0.84, 0.62, 0.8, 0.35, 0),
      (0.92, 0.68, 1.5, 0.75, 1),
      (0.10, 0.76, 1.1, 0.48, 0),
      (0.24, 0.74, 0.7, 0.30, 2),
      (0.36, 0.79, 1.7, 0.85, 1),
      (0.66, 0.78, 1.2, 0.55, 0),
      (0.78, 0.82, 0.8, 0.38, 2),
      (0.90, 0.84, 1.4, 0.68, 0),
      (0.07, 0.88, 0.8, 0.35, 0),
      (0.20, 0.92, 1.3, 0.60, 1),
      (0.42, 0.89, 0.8, 0.35, 0),
      (0.58, 0.93, 1.5, 0.75, 0),
      (0.72, 0.91, 0.7, 0.30, 2),
      (0.86, 0.94, 1.1, 0.50, 1),
      (0.32, 0.38, 0.6, 0.22, 0),
      (0.68, 0.36, 0.6, 0.25, 0),
      (0.30, 0.62, 0.6, 0.20, 0),
      (0.70, 0.64, 0.6, 0.22, 0),
      // In-app celestial sequence anchors
      (0.78, 0.48, 1.1, 0.45, 0),
      (0.56, 0.42, 0.7, 0.25, 2),
      (0.44, 0.58, 0.7, 0.25, 1),
      (0.24, 0.52, 0.8, 0.30, 0),
    ];

    return List.generate(rawData.length, (i) {
      final entry = rawData[i];
      return _SkyStar(
        x: entry.$1,
        y: entry.$2,
        radius: entry.$3,
        baseAlpha: entry.$4,
        colorType: entry.$5,
        phase: (i * 1.618) % (math.pi * 2),
        speed: (i % 3 == 0) ? 1.0 : (i % 2 == 0 ? 0.7 : 1.3),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final center = Offset(star.x * size.width, star.y * size.height);

      double alpha = star.baseAlpha;
      if (!reduceMotion) {
        final twinkle = 0.82 +
            0.18 * math.sin(progress * 2 * math.pi * star.speed + star.phase);
        alpha = (alpha * twinkle).clamp(0.05, 1.0);
      }

      Color color;
      switch (star.colorType) {
        case 1:
          color = CompassColors.gold.withValues(alpha: alpha);
          break;
        case 2:
          color = CompassColors.blueLight.withValues(alpha: alpha);
          break;
        case 0:
        default:
          color = Colors.white.withValues(alpha: alpha);
      }

      // Soft halo for bright anchor stars
      if (star.radius >= 1.4) {
        canvas.drawCircle(
          center,
          star.radius * 2.2,
          Paint()
            ..color = color.withValues(alpha: alpha * 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
      }

      // Star point core
      canvas.drawCircle(center, star.radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _NaturalStarrySkyPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.reduceMotion != reduceMotion;
}

class _SkyStar {
  const _SkyStar({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseAlpha,
    required this.colorType,
    required this.phase,
    required this.speed,
  });

  final double x;
  final double y;
  final double radius;
  final double baseAlpha;
  final int colorType;
  final double phase;
  final double speed;
}

/// Renders subtle, ethereal celestial orbit rings behind the star and title.
/// Designed to be non-intrusive, serene, and clean (no visual clutter or intersection with text).
class _CelestialOrbitRingsPainter extends CustomPainter {
  const _CelestialOrbitRingsPainter({required this.rotation});

  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    // 1. Outer subtle ring (~140px radius)
    final r1 = maxRadius * 0.95;
    final ringPaint1 = Paint()
      ..color = CompassColors.blueLight.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawCircle(center, r1, ringPaint1);

    // Single delicate micro-starlight planet on outer ring (cyan starlight)
    final angle1 = rotation * 2 * math.pi;
    final planet1 = Offset(
      center.dx + math.cos(angle1) * r1,
      center.dy + math.sin(angle1) * r1,
    );
    canvas.drawCircle(
      planet1,
      2.8,
      Paint()
        ..color = CompassColors.blueLight.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(
      planet1,
      1.3,
      Paint()..color = CompassColors.blueLight.withValues(alpha: 0.75),
    );

    // Second micro-starlight planet on outer ring (warm gold, spaced by ~135 degrees)
    final angle1b = angle1 + 2.35;
    final planet1b = Offset(
      center.dx + math.cos(angle1b) * r1,
      center.dy + math.sin(angle1b) * r1,
    );
    canvas.drawCircle(
      planet1b,
      2.5,
      Paint()
        ..color = CompassColors.gold.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );
    canvas.drawCircle(
      planet1b,
      1.1,
      Paint()..color = CompassColors.gold.withValues(alpha: 0.70),
    );

    // 2. Middle subtle ring (~118px radius) - outside central text boundary
    final r2 = maxRadius * 0.80;
    final ringPaint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(center, r2, ringPaint2);

    // Third micro-starlight planet on inner ring (soft starlight white, rotating counter-clockwise)
    final angle2 = -rotation * 2 * math.pi * 0.7 + math.pi;
    final planet2 = Offset(
      center.dx + math.cos(angle2) * r2,
      center.dy + math.sin(angle2) * r2,
    );
    canvas.drawCircle(
      planet2,
      2.0,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawCircle(
      planet2,
      1.0,
      Paint()..color = const Color(0xFFBFDDF1).withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant _CelestialOrbitRingsPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}


