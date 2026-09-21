import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class CelestialScaffold extends StatelessWidget {
  const CelestialScaffold({
    super.key,
    required this.child,
    this.topColor = CompassColors.deep,
    this.bottomColor = const Color(0xFF18243C),
    this.safeArea = true,
  });

  final Widget child;
  final Color topColor;
  final Color bottomColor;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, bottomColor],
            ),
          ),
        ),
        const IgnorePointer(child: CustomPaint(painter: _StarsPainter())),
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: child,
          ),
        ),
      ],
    );
    return Scaffold(body: safeArea ? SafeArea(child: content) : content);
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.selected = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xD11A2945) : CompassColors.glass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? CompassColors.blueLight : CompassColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class ZodiacAvatar extends StatelessWidget {
  const ZodiacAvatar({
    super.key,
    this.size = 72,
    this.glow = false,
    this.sign = ZodiacSign.cancer,
  });

  final double size;
  final bool glow;
  final ZodiacSign sign;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF223A62), Color(0xFF11192B)],
        ),
        border: Border.all(color: CompassColors.gold.withValues(alpha: 0.72)),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: CompassColors.blueLight.withValues(alpha: 0.28),
                  blurRadius: 32,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        sign.glyph,
        style: TextStyle(
          color: CompassColors.gold,
          fontSize: size * 0.46,
          height: 1,
        ),
      ),
    );
  }
}

class OrbitVisual extends StatefulWidget {
  const OrbitVisual({
    super.key,
    this.size = 250,
    this.labels = const [],
    this.sign = ZodiacSign.cancer,
  });

  final double size;
  final List<String> labels;
  final ZodiacSign sign;

  @override
  State<OrbitVisual> createState() => _OrbitVisualState();
}

class _OrbitVisualState extends State<OrbitVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final dimension = math.min(
      widget.size,
      math.max(180.0, MediaQuery.sizeOf(context).width - 48),
    );
    return SizedBox.square(
      dimension: dimension,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _OrbitPainter(
            progress: reduceMotion ? 0.1 : _controller.value,
            labels: widget.labels,
          ),
          child: child,
        ),
        child: Center(
          child: ZodiacAvatar(size: 86, glow: true, sign: widget.sign),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.progress, required this.labels});

  final double progress;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = CompassColors.blueLight.withValues(alpha: 0.24);
    final glow = Paint()..color = CompassColors.blueLight;
    final radii = [size.width * 0.29, size.width * 0.39, size.width * 0.48];

    for (var i = 0; i < radii.length; i++) {
      canvas.drawCircle(center, radii[i], line);
      final angle = progress * math.pi * 2 * (i.isEven ? 1 : -0.72) + i;
      final dot = Offset(
        center.dx + math.cos(angle) * radii[i],
        center.dy + math.sin(angle) * radii[i],
      );
      canvas.drawCircle(dot, i == 1 ? 3.5 : 2.5, glow);
    }

    final textStyle = TextStyle(
      color: CompassColors.secondary.withValues(alpha: 0.86),
      fontSize: 8,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w600,
    );
    for (var i = 0; i < labels.length && i < 8; i++) {
      final count = math.min(labels.length, 8);
      final angle = (i / count) * math.pi * 2 + progress * 0.35;
      final radius = size.width * (i.isEven ? 0.43 : 0.34);
      final offset = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, offset - Offset(painter.width / 2, 5));
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.labels != labels;
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.22);
    for (var i = 0; i < 28; i++) {
      final x = ((i * 79) % 101) / 101 * size.width;
      final y = ((i * 47) % 97) / 97 * size.height;
      canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 1.2 : 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
