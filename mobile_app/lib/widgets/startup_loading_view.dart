import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A quiet continuation of the native launch screen while startup completes.
class StartupLoadingView extends StatefulWidget {
  const StartupLoadingView({super.key, this.onFirstFrame});

  final VoidCallback? onFirstFrame;

  @override
  State<StartupLoadingView> createState() => _StartupLoadingViewState();
}

class _StartupLoadingViewState extends State<StartupLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFirstFrame?.call();
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
    } else {
      _dots.repeat();
    }
  }

  @override
  void dispose() {
    _dots.dispose();
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
                color: CompassColors.blueLight.withValues(alpha: 0.28),
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
    final glow = 0.72 + 0.18 * math.sin(progress * 2 * math.pi);
    return Opacity(
      opacity: glow,
      child: const CustomPaint(
        size: Size.square(16),
        painter: _LaunchStarPainter(),
      ),
    );
  }

  Widget _wordmark() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFBFDDF1), CompassColors.text, Color(0xFFE7CB8D)],
        stops: [0, 0.48, 1],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: const Text(
        'AstraCue',
        key: Key('startup_brand_name'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontFamily: CompassFonts.latin,
          fontSize: 34,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.4,
          height: 1.1,
          shadows: [
            Shadow(color: Color(0x664EB3E8), blurRadius: 20),
            Shadow(color: Color(0x55D8B66A), blurRadius: 28),
          ],
        ),
      ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_reduceMotion == true)
                  _star(0)
                else
                  AnimatedBuilder(
                    animation: _dots,
                    builder: (context, _) => _star(_dots.value),
                  ),
                const SizedBox(height: 11),
                _wordmark(),
                const SizedBox(height: 12),
                if (_reduceMotion == true)
                  _orbitDots(0)
                else
                  AnimatedBuilder(
                    animation: _dots,
                    builder: (context, _) => _orbitDots(_dots.value),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LaunchStarPainter extends CustomPainter {
  const _LaunchStarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..moveTo(center.dx, 0)
      ..quadraticBezierTo(center.dx + 2, center.dy - 2, size.width, center.dy)
      ..quadraticBezierTo(center.dx + 2, center.dy + 2, center.dx, size.height)
      ..quadraticBezierTo(center.dx - 2, center.dy + 2, 0, center.dy)
      ..quadraticBezierTo(center.dx - 2, center.dy - 2, center.dx, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = CompassColors.gold.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = CompassColors.gold);
  }

  @override
  bool shouldRepaint(covariant _LaunchStarPainter oldDelegate) => false;
}
