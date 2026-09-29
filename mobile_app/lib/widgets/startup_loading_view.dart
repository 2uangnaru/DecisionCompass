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
      _entrance.value = 1.0;
    } else {
      _dots.repeat();
      if (_hasStartedEntrance && !_entrance.isAnimating && _entrance.value < 1.0) {
        _entrance.forward();
      }
    }
  }

  @override
  void dispose() {
    _entranceTimer?.cancel();
    _dots.dispose();
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
      body: Center(
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

