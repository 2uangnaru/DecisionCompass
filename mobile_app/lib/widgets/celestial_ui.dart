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
    return Semantics(
      image: true,
      label: '${sign.label} zodiac avatar',
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

    final textStyle = TextStyle(
      color: CompassColors.secondary.withValues(alpha: 0.86),
      fontSize: 8,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w600,
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

/// A birth-time picker fully owned by this app's own widget state, unlike
/// Flutter's built-in `showTimePicker`. Hour, minute and AM/PM each live in
/// one `setState`-backed field here, so toggling AM/PM always combines with
/// whatever hour is currently selected immediately — there is no interaction
/// order where the combined value can lag behind until the dialog closes.
Future<TimeOfDay?> showCompassTimePicker(
  BuildContext context, {
  required TimeOfDay initial,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => _CompassTimePickerDialog(initial: initial),
  );
}

class _CompassTimePickerDialog extends StatefulWidget {
  const _CompassTimePickerDialog({required this.initial});

  final TimeOfDay initial;

  @override
  State<_CompassTimePickerDialog> createState() =>
      _CompassTimePickerDialogState();
}

class _CompassTimePickerDialogState extends State<_CompassTimePickerDialog> {
  late int _hour12;
  late int _minute;
  late bool _isPm;

  @override
  void initState() {
    super.initState();
    final hour24 = widget.initial.hour;
    _isPm = hour24 >= 12;
    _hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    _minute = widget.initial.minute;
  }

  TimeOfDay get _selected =>
      TimeOfDay(hour: _isPm ? (_hour12 % 12) + 12 : _hour12 % 12, minute: _minute);

  /// "1:30 PM" — reads straight off current state, so it updates the instant
  /// any control changes, with no separate "committed" value to fall behind.
  String get _previewLabel =>
      '$_hour12:${_minute.toString().padLeft(2, '0')} ${_isPm ? 'PM' : 'AM'}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Time of birth'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _previewLabel,
            key: const Key('birth_time_preview'),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: CompassColors.gold),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NumberDropdown(
                dropdownKey: const Key('birth_time_hour'),
                value: _hour12,
                values: List.generate(12, (i) => i + 1),
                onChanged: (value) => setState(() => _hour12 = value),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(':', style: TextStyle(fontSize: 20)),
              ),
              _NumberDropdown(
                dropdownKey: const Key('birth_time_minute'),
                value: _minute,
                values: List.generate(60, (i) => i),
                pad: true,
                onChanged: (value) => setState(() => _minute = value),
              ),
              const SizedBox(width: 16),
              SegmentedButton<bool>(
                key: const Key('birth_time_period'),
                segments: const [
                  ButtonSegment(value: false, label: Text('AM')),
                  ButtonSegment(value: true, label: Text('PM')),
                ],
                selected: {_isPm},
                onSelectionChanged: (selection) =>
                    setState(() => _isPm = selection.first),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('birth_time_confirm'),
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _NumberDropdown extends StatelessWidget {
  const _NumberDropdown({
    required Key dropdownKey,
    required this.value,
    required this.values,
    required this.onChanged,
    this.pad = false,
  }) : super(key: dropdownKey);

  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;
  final bool pad;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      items: values
          .map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(pad ? value.toString().padLeft(2, '0') : '$value'),
            ),
          )
          .toList(),
    );
  }
}
