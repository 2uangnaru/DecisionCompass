import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app_locale.dart';
import '../l10n/app_localizations.dart';
import '../localized_presentation.dart';
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
    final l10n = AppLocalizations.of(context);
    return Semantics(
      image: true,
      label: l10n.zodiacAvatarSemantics(zodiacLabel(l10n, sign)),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: Container(
          key: ValueKey(sign),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: CompassColors.blueLight.withValues(alpha: 0.3),
                      blurRadius: size * 0.38,
                      spreadRadius: size * 0.05,
                    ),
                  ]
                : null,
          ),
          child: Image.asset(
            sign.assetPath,
            key: Key('zodiac_avatar_${sign.name}'),
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF11192B),
                border: Border.all(
                  color: CompassColors.gold.withValues(alpha: 0.72),
                ),
              ),
              child: Center(
                child: Text(
                  sign.glyph,
                  style: TextStyle(
                    color: CompassColors.gold,
                    fontSize: size * 0.46,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
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
    this.sign,
    this.ringScale = 1.0,
    this.ringOpacity = 1.0,
    this.avatarScale = 1.0,
    this.avatarOpacity = 1.0,
  });

  final double size;
  final List<String> labels;
  final ZodiacSign? sign;
  final double ringScale;
  final double ringOpacity;
  final double avatarScale;
  final double avatarOpacity;

  @override
  State<OrbitVisual> createState() => _OrbitVisualState();
}

class _OrbitVisualState extends State<OrbitVisual>
    with SingleTickerProviderStateMixin {
  static const _orbitDuration = Duration(seconds: 14);

  final ValueNotifier<double> _progress = ValueNotifier(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    // A 0..1 repeating controller jumps at each boundary because the rings
    // travel fractional turns per 14 seconds. Elapsed time never wraps, so
    // their angles and the orbit labels stay continuous at that boundary.
    _ticker = createTicker((elapsed) {
      _progress.value =
          elapsed.inMicroseconds / _orbitDuration.inMicroseconds;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final dimension = math.min(
      widget.size,
      math.max(180.0, MediaQuery.sizeOf(context).width - 48),
    );
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      fontFamily: theme.textTheme.displayLarge?.fontFamily ??
          theme.textTheme.bodyMedium?.fontFamily ??
          CompassFonts.display,
      fontFamilyFallback: theme.textTheme.displayLarge?.fontFamilyFallback ??
          theme.textTheme.bodyMedium?.fontFamilyFallback ??
          CompassFonts.fallbackFor(AppLocale.english),
      color: CompassColors.secondary.withValues(alpha: 0.86),
      fontSize: 8,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w600,
    );
    final centerChild = Center(
      child: widget.sign == null
          ? const Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: CompassColors.gold,
            )
          : ZodiacAvatar(size: 86, glow: true, sign: widget.sign!),
    );

    return SizedBox.square(
      dimension: dimension,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.scale(
            scale: widget.ringScale,
            child: Opacity(
              opacity: widget.ringOpacity.clamp(0.0, 1.0),
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) => CustomPaint(
                  size: Size.square(dimension),
                  painter: _OrbitPainter(
                    progress: reduceMotion ? 0.1 : _progress.value,
                    labels: widget.labels,
                    textStyle: textStyle,
                  ),
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: widget.avatarScale,
            child: Opacity(
              opacity: widget.avatarOpacity.clamp(0.0, 1.0),
              child: centerChild,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.progress,
    required this.labels,
    this.textStyle,
  });

  final double progress;
  final List<String> labels;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = CompassColors.blueLight.withValues(alpha: 0.24);
    final glow = Paint()..color = CompassColors.blueLight;
    final radii = [
      size.width * 0.24,
      size.width * 0.32,
      size.width * 0.40,
      size.width * 0.49,
    ];

    for (var i = 0; i < radii.length; i++) {
      canvas.drawCircle(center, radii[i], line);
      final speeds = [1.0, -0.72, 0.85, -0.5];
      final angle = progress * math.pi * 2 * speeds[i] + i * 1.5;
      final dot = Offset(
        center.dx + math.cos(angle) * radii[i],
        center.dy + math.sin(angle) * radii[i],
      );
      final dotRadius = (i == 1 || i == 3) ? 3.2 : 2.2;
      canvas.drawCircle(dot, dotRadius, glow);
    }

    final effectiveTextStyle = (textStyle ?? const TextStyle()).copyWith(
      color: textStyle?.color ?? CompassColors.secondary.withValues(alpha: 0.86),
      fontSize: textStyle?.fontSize ?? 8,
      letterSpacing: textStyle?.letterSpacing ?? 1.1,
      fontWeight: textStyle?.fontWeight ?? FontWeight.w600,
      fontFamily: textStyle?.fontFamily ?? CompassFonts.display,
    );
    final count = labels.length;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + progress * 0.35;
      final radius = size.width * (i.isEven ? 0.45 : 0.36);
      final offset = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: effectiveTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, offset - Offset(painter.width / 2, 5));
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.labels != labels ||
      oldDelegate.textStyle != textStyle;
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

/// A gentle frosted celestial badge indicating an option requires watching an Ad to unlock.
class AdOptionBadge extends StatelessWidget {
  const AdOptionBadge({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6.5 : 9.5,
        vertical: compact ? 2.5 : 3.5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE6101D33),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(
          color: CompassColors.blueLight.withValues(alpha: 0.38),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: CompassColors.blueLight.withValues(alpha: 0.16),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_filled_rounded,
            size: compact ? 10.5 : 12.5,
            color: const Color(0xFFE2EEF8),
          ),
          const SizedBox(width: 3.5),
          Text(
            'AD',
            style: TextStyle(
              fontSize: compact ? 8.5 : 9.8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: const Color(0xFFE2EEF8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a bottom sheet asking the user to watch an ad to unlock a specific option.
Future<bool> showOptionAdUnlockSheet(
  BuildContext context, {
  required String optionLabel,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: CompassColors.raised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: CompassColors.line),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 32, spreadRadius: 4),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    CompassColors.gold.withValues(alpha: 0.25),
                    CompassColors.gold.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: CompassColors.gold.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CompassColors.gold.withValues(alpha: 0.2),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_circle_filled_rounded,
                size: 28,
                color: CompassColors.gold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              optionLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.watchAdPrompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: CompassColors.secondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('option_unlock_ad_button'),
                onPressed: () => Navigator.of(sheetContext).pop(true),
                icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                label: Text(l10n.watchAdButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CompassColors.blueLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(false),
              child: Text(
                l10n.cancelAction,
                style: const TextStyle(color: CompassColors.muted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

